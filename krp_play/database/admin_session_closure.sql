create or replace function checkout_private.closure_facility_key(p_name text)
returns text language sql immutable security invoker set search_path='' as $$
  with n as (select regexp_replace(lower(trim(p_name)),' 0+([0-9]+)$',' \1') as name)
  select case
    when name in ('dart board','dart board 1','dart','board 1','dart 1') then 'dart'
    when name in ('snooker table','snooker table 1','snooker','table 1','snooker 1') then 'snooker'
    when name in ('badminton 1','badminton court 1') then 'badminton court 1'
    when name in ('badminton 2','badminton court 2') then 'badminton court 2'
    when name in ('ping pong 1','ping pong table 1') then 'ping pong table 1'
    when name in ('ping pong 2','ping pong table 2') then 'ping pong table 2'
    else name end from n;
$$;
revoke all on function checkout_private.closure_facility_key(text) from public,anon;

-- Apply through a reviewed Supabase migration. No historical data is repaired.
create or replace function checkout_private.admin_set_session_closure(
  p_facility_id uuid, p_date date, p_start_times time[],
  p_closed boolean, p_reason text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_admin uuid := auth.uid();
  v_start time;
  v_slot public.time_slots%rowtype;
  v_item public.booking_items%rowtype;
  v_order public.bookings%rowtype;
  v_payment public.payments%rowtype;
  v_refund uuid;
  v_count integer := 0;
  v_changed integer := 0;
  v_name text;
begin
  if v_admin is null or not public.is_admin() then
    raise exception using errcode='42501', message='Admin access required';
  end if;
  if p_closed is null or p_date is null or p_start_times is null
     or cardinality(p_start_times) not between 1 and 24
     or (p_closed and nullif(trim(p_reason),'') is null) then
    raise exception 'INVALID_CLOSURE';
  end if;
  -- Same lock as reserve_cart: a reservation cannot slip into a closing slot.
  perform pg_advisory_xact_lock(hashtextextended('krp_checkout_v1',0));
  select name into strict v_name from public.facilities where id=p_facility_id;
  for v_start in select distinct t from unnest(p_start_times) t order by t loop
    if v_start is null or extract(minute from v_start)<>0
       or extract(second from v_start)<>0 or v_start >= '23:00'::time
       or (p_date+v_start+interval '1 hour') at time zone 'Asia/Kuala_Lumpur' <= clock_timestamp() then
      raise exception 'INVALID_OR_ENDED_SESSION';
    end if;
    -- Legacy bookings have no per-session price/status: fail instead of guessing.
    if exists(select 1 from public.bookings b
      where b.booking_date=p_date and b.start_time=v_start
        and checkout_private.closure_facility_key(b.facility_name)=checkout_private.closure_facility_key(v_name)
        and b.booking_reference not like 'ADMIN-%'
        and (lower(b.status) in ('confirmed','paid','booked','pending_payment') or lower(b.status) like '%closed%')
        and not exists(select 1 from public.booking_items i where i.booking_id=b.id)) then
      raise exception 'LEGACY_BOOKING_REQUIRES_REVIEW';
    end if;
    insert into public.time_slots(facility_id,slot_date,start_time,end_time)
      values(p_facility_id,p_date,v_start,v_start+interval '1 hour')
      on conflict(facility_id,slot_date,start_time,end_time) do nothing;
    select * into strict v_slot from public.time_slots
      where facility_id=p_facility_id and slot_date=p_date and start_time=v_start
        and end_time=v_start+interval '1 hour' for update;
    if p_closed then
      if exists(select 1 from public.booking_items i join public.bookings b on b.id=i.booking_id
        where i.time_slot_id=v_slot.id and i.status='pending_payment' and b.status='pending_payment') then
        raise exception 'ACTIVE_PAYMENT_HOLD: wait for payment or expiry before closing';
      end if;
      for v_item in select * from public.booking_items
        where time_slot_id=v_slot.id and status='confirmed' for update loop
        select * into strict v_order from public.bookings where id=v_item.booking_id for update;
        -- A prior whole-order request needs human review, not a second refund.
        if exists(select 1 from public.refunds r where r.booking_id=v_order.id and r.booking_item_id is null) then
          raise exception 'EXISTING_WHOLE_ORDER_REFUND_REQUIRES_REVIEW';
        end if;
        if v_item.price>0 then
          select * into v_payment from public.payments
            where booking_id=v_order.id and status in ('paid','simulated_success')
            order by paid_at desc nulls last,created_at desc limit 1;
          if not found then raise exception 'SETTLED_PAYMENT_REQUIRED'; end if;
          if not exists(select 1 from public.refunds where booking_item_id=v_item.id) then
            if coalesce((select sum(amount) from public.refunds where booking_id=v_order.id),0)+v_item.price > v_order.total_amount then
              raise exception 'REFUND_WOULD_EXCEED_ORDER_TOTAL';
            end if;
            insert into public.refunds(refund_reference,booking_id,booking_item_id,payment_id,
              amount,reason,refund_method,refund_channel,status)
            values('RF-SESSION-'||v_item.id,v_order.id,v_item.id,v_payment.id,v_item.price,
              'Facility closed by KRP Management: '||trim(p_reason),
              'manual','bank_transfer','awaiting_action') returning id into v_refund;
            insert into public.refund_events(refund_id,event_type,new_status,note,performed_by)
              values(v_refund,'created','awaiting_action',
                v_name||' '||p_date||' '||v_start||' - '||(v_start+interval '1 hour'),v_admin);
            v_count:=v_count+1;
          end if;
        end if;
        update public.booking_items set status='cancelled_by_management' where id=v_item.id;
        -- Keep the original paid amount. It is not the remaining playable value.
        if not exists(select 1 from public.booking_items where booking_id=v_order.id and status in ('confirmed','pending_payment')) then
          update public.bookings set status='cancelled_by_management',updated_at=now() where id=v_order.id;
        end if;
      end loop;
      update public.time_slots set is_available=false,locked_reason=trim(p_reason),
        locked_at=now(),locked_by=v_admin where id=v_slot.id;
    else
      -- Remove only this slot's standalone legacy closure marker.
      delete from public.bookings b where b.booking_reference like 'ADMIN-%'
        and b.booking_date=p_date and b.start_time=v_start
        and checkout_private.closure_facility_key(b.facility_name)=checkout_private.closure_facility_key(v_name)
        and not exists(select 1 from public.booking_items i where i.booking_id=b.id)
        and not exists(select 1 from public.refunds r where r.booking_id=b.id);
      if exists(select 1 from public.bookings b join public.booking_items i on i.booking_id=b.id
        where i.time_slot_id=v_slot.id and lower(b.status) like '%closed%') then
        raise exception 'HISTORICAL_ORDER_CLOSURE_REQUIRES_REVIEW';
      end if;
      update public.time_slots set is_available=true,locked_reason=null,
        locked_at=null,locked_by=null,closure_batch_id=null where id=v_slot.id;
      -- Reopening never revives cancelled/refunded reservations or cancels refunds.
    end if;
    v_changed:=v_changed+1;
  end loop;
  return jsonb_build_object('sessions',v_changed,'refunds_created',v_count);
end $$;
revoke all on function checkout_private.admin_set_session_closure(uuid,date,time[],boolean,text) from public,anon;
grant execute on function checkout_private.admin_set_session_closure(uuid,date,time[],boolean,text) to authenticated;
create or replace function public.admin_set_session_closure(
  p_facility_id uuid,p_date date,p_start_times time[],p_closed boolean,p_reason text
) returns jsonb language sql security invoker set search_path='' as $$
  select checkout_private.admin_set_session_closure(p_facility_id,p_date,p_start_times,p_closed,p_reason);
$$;
revoke all on function public.admin_set_session_closure(uuid,date,time[],boolean,text) from public,anon;
grant execute on function public.admin_set_session_closure(uuid,date,time[],boolean,text) to authenticated;
