-- SCRUM-15 / SCRUM-45. REVIEW SCRIPT: not applied to the shared database.
-- Run as database owner in a staging copy first. Everything rolls back on error.
begin;
lock table public.bookings,public.booking_items,public.time_slots in share row exclusive mode;

-- Historical prototype records contain random slot IDs. Never hide their bookings
-- or guess which of two successful customers should keep a disputed session.
do $$
begin
  if exists (
    select 1 from public.booking_items i
    left join public.time_slots s on s.id = i.time_slot_id
    where s.id is null and lower(i.status) in ('confirmed','pending_payment')
  ) or exists (
    select 1 from public.bookings b
    where lower(b.status) in ('confirmed','pending_payment')
      and (not exists (select 1 from public.booking_items i where i.booking_id=b.id)
        or (lower(b.status)='pending_payment' and b.payment_deadline is null))
  ) then
    raise exception 'LEGACY_RECONCILIATION_REQUIRED: review active prototype bookings before enabling checkout';
  end if;
end $$;

-- Normalize valid active records only. Conflicting historical records cause the
-- existing unique index to abort this transaction, rather than deleting evidence.
update public.booking_items set status=lower(status)
where lower(status) in ('pending_payment','confirmed') and status<>lower(status);
update public.bookings set status=lower(status)
where lower(status) in ('pending_payment','confirmed') and status<>lower(status);
alter table public.booking_items alter column time_slot_id drop default;
alter table public.booking_items alter column booking_id drop default;
-- NOT VALID preserves historical inactive orphans; all new writes are checked.
alter table public.booking_items add constraint checkout_item_real_slot_fk
  foreign key (time_slot_id) references public.time_slots(id) not valid;
alter table public.bookings add column checkout_request_id uuid;
alter table public.bookings add column checkout_payload jsonb;
create unique index checkout_user_request_unique
  on public.bookings(user_id,checkout_request_id) where checkout_request_id is not null;
create unique index if not exists uq_booking_items_active_time_slot
  on public.booking_items(time_slot_id) where status in ('pending_payment','confirmed');

-- Students read their orders but cannot insert bookings or declare payments paid.
-- Existing admin RLS policies remain in effect. Privileged writes occur only in
-- the narrow private function below, using auth.uid(), never a submitted user ID.
alter table public.bookings enable row level security;
alter table public.booking_items enable row level security;
alter table public.payments enable row level security;
revoke all on public.bookings, public.booking_items, public.payments from anon;
revoke insert, update, delete on public.bookings, public.booking_items, public.payments from authenticated;
grant select on public.bookings, public.booking_items, public.payments to authenticated;
create policy checkout_read_own_bookings on public.bookings for select to authenticated
  using (user_id=(select auth.uid()));
create policy checkout_read_own_items on public.booking_items for select to authenticated
  using (exists(select 1 from public.bookings b where b.id=booking_id and b.user_id=(select auth.uid())));
create policy checkout_read_own_payments on public.payments for select to authenticated
  using (exists(select 1 from public.bookings b where b.id=booking_id and b.user_id=(select auth.uid())));

-- The existing broad schedule policy allowed students to change the hours that
-- checkout validates. Rates and role/category likewise must be trusted inputs.
drop policy if exists "Authenticated users can manage schedules" on public.operating_schedules;
revoke insert,update,delete on public.operating_schedules,public.facilities from anon,authenticated;
revoke update on public.profiles from anon,authenticated;
grant update(full_name,phone_number,matric_number) on public.profiles to authenticated;
alter table public.profiles enable row level security;
create policy checkout_create_own_student_profile on public.profiles for insert to authenticated
  with check (id=(select auth.uid()) and role='student' and student_category in ('krp','non_krp'));
-- Administrators use trusted backend operations for privileged changes.

create schema if not exists checkout_private;
revoke all on schema checkout_private from public,anon;
grant usage on schema checkout_private to authenticated;

-- Price and category are server-derived. A single transaction-level lock makes
-- cart reservation/expiry ordering unambiguous for this small prototype. This
-- serializes CHECKOUT requests, not normal browsing; a larger service can use
-- sorted per-session locks after profiling.
create function checkout_private.reserve_cart(p_request_id uuid,p_items jsonb,p_expected_total numeric)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_user uuid:=auth.uid();
  v_category text;
  v_booking public.bookings%rowtype;
  v_item jsonb;
  v_time jsonb;
  v_facility public.facilities%rowtype;
  v_slot public.time_slots%rowtype;
  v_date date;
  v_start time;
  v_end time;
  v_price numeric;
  v_total numeric:=0;
  v_count integer:=0;
  v_seen uuid[]:='{}';
  v_now timestamptz;
begin
  if v_user is null then raise exception using errcode='42501',message='Sign in to reserve a slot'; end if;
  if p_request_id is null or jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) not between 1 and 12 then
    raise exception 'INVALID_CART';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('krp_checkout_v1',0));
  lock table public.operating_schedules,public.facility_blocks in share mode;
  v_now:=clock_timestamp();

  select student_category into v_category from public.profiles where id=v_user;
  if v_category is null or v_category not in ('krp','non_krp') then
    raise exception 'PROFILE_CATEGORY_REQUIRED';
  end if;

  select * into v_booking from public.bookings
    where user_id=v_user and checkout_request_id=p_request_id for update;
  if found then
    if v_booking.checkout_payload is distinct from p_items then raise exception 'IDEMPOTENCY_MISMATCH'; end if;
    if v_booking.status='confirmed' or
       (v_booking.status='pending_payment' and v_booking.payment_deadline>v_now) then
      return jsonb_build_object('id',v_booking.id,'reference',v_booking.booking_reference,
        'total_amount',v_booking.total_amount,'status',v_booking.status,'payment_deadline',v_booking.payment_deadline);
    end if;
    raise exception 'HOLD_EXPIRED';
  end if;

  -- Any later request reclaims expired holds. Availability excludes expired holds
  -- immediately, so expiry does not depend on a scheduled background job.
  with expired as (
    update public.bookings set status='expired',updated_at=v_now
    where status='pending_payment' and payment_deadline<=v_now returning id
  ) update public.booking_items set status='expired'
    where status='pending_payment' and booking_id in (select id from expired);

  insert into public.bookings(user_id,booking_reference,total_amount,status,
      payment_deadline,customer_category,booking_source,checkout_request_id,checkout_payload)
  values(v_user,'KRP-'||gen_random_uuid()::text,0,'pending_payment',
      v_now+interval '10 minutes',v_category,'online',p_request_id,p_items)
  returning * into v_booking;

  for v_item in select value from jsonb_array_elements(p_items) loop
    -- Name normalization preserves current UI's Court 01 vs database's Court 1.
    select * into strict v_facility from public.facilities
      where lower(regexp_replace(name,' 0+([0-9]+)$',' \1'))=
        lower(regexp_replace(v_item->>'facility_name',' 0+([0-9]+)$',' \1'))
        and is_active for share;
    v_date:=(v_item->>'date')::date;
    if v_date is null or v_date<(v_now at time zone 'Asia/Kuala_Lumpur')::date
       or v_date>(v_now at time zone 'Asia/Kuala_Lumpur')::date+30 then raise exception 'INVALID_DATE'; end if;
    if jsonb_typeof(v_item->'start_times') is distinct from 'array'
      or jsonb_array_length(v_item->'start_times') not between 1 and 2 then raise exception 'INVALID_SESSIONS'; end if;
    v_price:=case when v_category='krp' then v_facility.krp_price else v_facility.non_krp_price end;
    for v_time in select value from jsonb_array_elements(v_item->'start_times') loop
      v_start:=(v_time#>>'{}')::time;
      v_end:=v_start+interval '1 hour';
      if v_start is null or v_end<=v_start or
        (v_date+v_start) at time zone 'Asia/Kuala_Lumpur'<=v_now then raise exception 'INVALID_SESSION'; end if;
      -- An approved schedule must contain this whole hour on its interval grid.
      if not exists(select 1 from public.operating_schedules o
        where o.is_active and o.day_of_week=extract(dow from v_date)
          and o.slot_minutes=60 and v_start>=o.start_time and v_end<=o.end_time
          and mod(extract(epoch from (v_start-o.start_time))::integer,3600)=0) then
        raise exception 'OUTSIDE_OPERATING_HOURS';
      end if;
      if exists(select 1 from public.facility_blocks b where b.facility_id=v_facility.id
        and b.starts_at<(v_date+v_end) at time zone 'Asia/Kuala_Lumpur'
        and b.ends_at>(v_date+v_start) at time zone 'Asia/Kuala_Lumpur') then
        raise exception 'SLOT_UNAVAILABLE';
      end if;
      insert into public.time_slots(facility_id,slot_date,start_time,end_time)
        values(v_facility.id,v_date,v_start,v_end)
        on conflict(facility_id,slot_date,start_time,end_time) do nothing;
      select * into strict v_slot from public.time_slots where facility_id=v_facility.id
        and slot_date=v_date and start_time=v_start and end_time=v_end for update;
      if not v_slot.is_available or v_slot.closure_batch_id is not null then raise exception 'SLOT_UNAVAILABLE'; end if;
      if v_slot.id=any(v_seen) then raise exception 'DUPLICATE_CART_SLOT'; end if;
      v_seen:=array_append(v_seen,v_slot.id);
      insert into public.booking_items(booking_id,time_slot_id,price,status)
        values(v_booking.id,v_slot.id,v_price,'pending_payment');
      v_total:=v_total+v_price;
      v_count:=v_count+1;
    end loop;
  end loop;
  if v_count=0 then raise exception 'EMPTY_CART'; end if;
  if p_expected_total is null or p_expected_total<>v_total then raise exception 'PRICE_CHANGED'; end if;
  update public.bookings set total_amount=v_total where id=v_booking.id;
  return jsonb_build_object('id',v_booking.id,'reference',v_booking.booking_reference,
    'total_amount',v_total,'status','pending_payment','payment_deadline',v_booking.payment_deadline);
exception when unique_violation then
  raise exception using errcode='23505',message='SLOT_UNAVAILABLE';
end $$;
revoke all on function checkout_private.reserve_cart(uuid,jsonb,numeric) from public,anon;
grant execute on function checkout_private.reserve_cart(uuid,jsonb,numeric) to authenticated;

-- Public API is an invoker wrapper; privileged implementation is not in the
-- exposed public schema. Never expose checkout_private in Data API settings.
create function public.reserve_cart(p_request_id uuid,p_items jsonb,p_expected_total numeric)
returns jsonb language sql security invoker set search_path='' as $$
  select checkout_private.reserve_cart(p_request_id,p_items,p_expected_total);
$$;
revoke all on function public.reserve_cart(uuid,jsonb,numeric) from public,anon;
grant execute on function public.reserve_cart(uuid,jsonb,numeric) to authenticated;

-- Privacy-safe availability: no other customer's email, UUID or order details.
create function checkout_private.slot_availability(p_date date)
returns table(facility_name text,slot_date date,start_time time,status text)
language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null then raise exception using errcode='42501',message='Sign in first'; end if;
  return query
  with sessions as (
    select distinct f.id,f.name,p_date as d,g.t::time as st,(g.t+interval '1 hour')::time as et
    from public.facilities f cross join public.operating_schedules o
    cross join lateral generate_series(p_date+o.start_time,p_date+o.end_time-interval '1 hour',interval '1 hour') g(t)
    where f.is_active and o.is_active and o.slot_minutes=60 and o.day_of_week=extract(dow from p_date)
  )
  select s.name,s.d,s.st,
    case when (s.d+s.st) at time zone 'Asia/Kuala_Lumpur'<=clock_timestamp() then 'past'
    when t.is_available=false or t.closure_batch_id is not null or exists(
      select 1 from public.facility_blocks fb where fb.facility_id=s.id
      and fb.starts_at<(s.d+s.et) at time zone 'Asia/Kuala_Lumpur'
      and fb.ends_at>(s.d+s.st) at time zone 'Asia/Kuala_Lumpur') then 'closed'
    when exists(select 1 from public.booking_items i join public.bookings b on b.id=i.booking_id
      where i.time_slot_id=t.id and i.status='confirmed') then 'booked'
    when exists(select 1 from public.booking_items i join public.bookings b on b.id=i.booking_id
      where i.time_slot_id=t.id and i.status='pending_payment' and b.payment_deadline>clock_timestamp()) then 'reserved'
    else 'available' end
  from sessions s left join public.time_slots t on t.facility_id=s.id and t.slot_date=s.d
    and t.start_time=s.st and t.end_time=s.et;
end $$;
revoke all on function checkout_private.slot_availability(date) from public,anon;
grant execute on function checkout_private.slot_availability(date) to authenticated;
create function public.slot_availability(p_date date)
returns table(facility_name text,slot_date date,start_time time,status text)
language sql security invoker set search_path='' as $$
  select * from checkout_private.slot_availability(p_date);
$$;
revoke all on function public.slot_availability(date) from public,anon;
grant execute on function public.slot_availability(date) to authenticated;
commit;
