CREATE OR REPLACE FUNCTION checkout_private.slot_availability(p_date date)
 RETURNS TABLE(facility_name text, slot_date date, start_time time without time zone, status text)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'checkout_private'
AS $function$
  with hours as (
    select unnest(
      case
        when extract(isodow from p_date) in (6, 7)
          then array['10:00:00','11:00:00','12:00:00','15:00:00','16:00:00','17:00:00','18:00:00','21:00:00','22:00:00']::time[]
        else array['17:00:00','18:00:00','21:00:00','22:00:00']::time[]
      end
    ) as start_time
  ),
  norm_facilities as (
    select
      f.id,
      f.name,
      case
        when lower(trim(f.name)) in ('dart board', 'dart board 1', 'dart board 01', 'dart 1', 'dart 01') then 'dart 1'
        when lower(trim(f.name)) in ('snooker table', 'snooker table 1', 'snooker table 01', 'snooker 1', 'snooker 01') then 'snooker 1'
        else regexp_replace(lower(trim(f.name)), '\s+0+(\d+)$', ' \1')
      end as f_key
    from public.facilities f
    where f.is_active = true
  ),
  norm_bookings as (
    select
      b.status,
      b.start_time,
      case
        when lower(trim(b.facility_name)) in ('dart board', 'dart board 1', 'dart board 01', 'dart 1', 'dart 01') then 'dart 1'
        when lower(trim(b.facility_name)) in ('snooker table', 'snooker table 1', 'snooker table 01', 'snooker 1', 'snooker 01') then 'snooker 1'
        else regexp_replace(lower(trim(b.facility_name)), '\s+0+(\d+)$', ' \1')
      end as f_key
    from public.bookings b
    where b.booking_date = p_date
      and (lower(b.status) like '%closed%' or lower(b.status) like '%maintenance%'
        or not exists(select 1 from public.booking_items linked where linked.booking_id=b.id))
  )
  select
    nf.name as facility_name,
    p_date as slot_date,
    h.start_time,
    case
      -- 1. 管理員關場優先顯示 closed
      when exists (
        select 1
        from norm_bookings nb
        where nb.f_key = nf.f_key
          and nb.start_time = h.start_time
          and (lower(nb.status) like '%closed%' or lower(nb.status) like '%maintenance%')
      )
      or exists (
        select 1
        from public.time_slots ts
        where ts.facility_id = nf.id
          and ts.slot_date = p_date
          and ts.start_time = h.start_time
          and ts.is_available = false
      ) then 'closed'

      -- 2. 線上已確認訂單（排除已退款/取消的 bookings）
      when exists (
        select 1
        from public.booking_items bi
        join public.time_slots ts on ts.id = bi.time_slot_id
        join public.bookings b on b.id = bi.booking_id
        where ts.facility_id = nf.id
          and ts.slot_date = p_date
          and ts.start_time = h.start_time
          and lower(bi.status) in ('confirmed', 'pending_payment')
          and lower(b.status) not in ('refunded', 'cancelled', 'expired', 'failed')
      ) then 'booked'

      -- 3. Manual / Walk-in 訂單（只存在 bookings 表的 confirmed 訂單）
      when exists (
        select 1
        from norm_bookings nb
        where nb.f_key = nf.f_key
          and nb.start_time = h.start_time
          and lower(nb.status) in ('confirmed', 'paid', 'booked', 'pending_payment')
      ) then 'booked'

      else 'available'
    end as status
  from norm_facilities nf
  cross join hours h;
$function$

