-- Billplz payment outcomes (SCRUM-79 + SCRUM-80).
-- Run this whole file in Supabase > SQL Editor. Safe to run again.

-- SCRUM-79: one Billplz bill = one payment row.
create unique index if not exists uq_payments_billplz_id
  on public.payments(billplz_id) where billplz_id is not null;

-- SCRUM-80: release reservations whose 10-minute hold is over.
-- Returns how many bookings were expired.
create or replace function public.expire_unpaid_bookings()
returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_count integer;
begin
  with expired as (
    update public.bookings set status = 'expired', updated_at = now()
    where status = 'pending_payment' and payment_deadline <= now()
    returning id
  ), released as (
    update public.booking_items set status = 'expired'
    where status = 'pending_payment' and booking_id in (select id from expired)
    returning 1
  )
  select count(*) into v_count from expired;
  return v_count;
end $$;

-- SCRUM-79/80: confirm a paid Billplz bill in ONE transaction.
-- Results: confirmed | confirmed_late | refund_required | already_paid | amount_mismatch | unknown_bill
create or replace function public.confirm_billplz_payment(
  p_billplz_id text,
  p_paid_cents bigint,
  p_paid_at timestamptz,
  p_transaction_ref text
) returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_payment public.payments%rowtype;
  v_booking public.bookings%rowtype;
begin
  -- Lock the payment so two callbacks at the same time wait in line.
  select * into v_payment from public.payments
    where billplz_id = p_billplz_id for update;
  if not found then return 'unknown_bill'; end if;
  if v_payment.status = 'paid' then return 'already_paid'; end if;
  if round(v_payment.amount * 100)::bigint <> p_paid_cents then
    return 'amount_mismatch';
  end if;

  select * into v_booking from public.bookings
    where id = v_payment.booking_id for update;

  -- The money is real, so always record it as evidence.
  update public.payments
    set status = 'paid', paid_at = p_paid_at, transaction_reference = p_transaction_ref
    where id = v_payment.id;

  -- On time: the hold is still active.
  if v_booking.status = 'pending_payment' and v_booking.payment_deadline > now() then
    update public.bookings set status = 'confirmed', updated_at = now() where id = v_booking.id;
    update public.booking_items set status = 'confirmed'
      where booking_id = v_booking.id and status = 'pending_payment';
    return 'confirmed';
  end if;

  -- SCRUM-80: late payment. Take the sessions back ONLY if they are still free,
  -- still open and not already started. If another user now holds a session,
  -- the unique index on active booking_items blocks it and we refund instead.
  if v_booking.status in ('pending_payment', 'expired') then
    begin
      if exists (
        select 1 from public.booking_items i
        join public.time_slots t on t.id = i.time_slot_id
        where i.booking_id = v_booking.id
          and (t.is_available = false
               or t.closure_batch_id is not null
               or (t.slot_date + t.start_time) <= (now() at time zone 'Asia/Kuala_Lumpur'))
      ) then
        raise exception 'SLOT_UNAVAILABLE';
      end if;

      update public.booking_items set status = 'confirmed'
        where booking_id = v_booking.id and status in ('pending_payment', 'expired');
      update public.bookings set status = 'confirmed', updated_at = now()
        where id = v_booking.id;
      return 'confirmed_late';
    exception when unique_violation or raise_exception then
      null; -- a session is taken, closed or over: undo the re-claim and refund below
    end;
  end if;

  -- Cannot honour this payment (slot gone, or booking already paid another way):
  -- release any hold and open a refund for the admin Refunds page.
  update public.bookings set status = 'expired', updated_at = now()
    where id = v_booking.id and status = 'pending_payment';
  update public.booking_items set status = 'expired'
    where booking_id = v_booking.id and status = 'pending_payment';

  insert into public.refunds(refund_reference, booking_id, payment_id, amount, reason,
      refund_method, refund_channel, status, created_at, updated_at)
  values ('RF-LATE-' || upper(left(replace(v_payment.id::text, '-', ''), 8)),
      v_booking.id, v_payment.id, v_payment.amount,
      'Billplz payment arrived after the hold ended and the session was no longer available',
      'manual', 'bank_transfer', 'awaiting_action', now(), now());
  return 'refund_required';
end $$;

-- Only the backend (service_role) may call these, never the app.
revoke all on function public.expire_unpaid_bookings() from public, anon, authenticated;
grant execute on function public.expire_unpaid_bookings() to service_role;
revoke all on function public.confirm_billplz_payment(text, bigint, timestamptz, text)
  from public, anon, authenticated;
grant execute on function public.confirm_billplz_payment(text, bigint, timestamptz, text)
  to service_role;
