-- Run on a LOCAL / TEST database after applying both reviewed SQL files.
-- This test creates isolated fixtures and always rolls them back. No gateway calls.
begin;
do $$
declare
  a uuid; u uuid; f uuid; b uuid; t1 uuid; t2 uuid; i1 uuid; i2 uuid;
  d date := (now() at time zone 'Asia/Kuala_Lumpur')::date + 1;
  result jsonb;
begin
  select id into strict a from public.profiles where role='admin' limit 1;
  select id into strict u from public.profiles where role='student' limit 1;
  insert into public.facilities(name,category,krp_price,non_krp_price,is_active)
    values('TEST closure '||gen_random_uuid(),'badminton',6,8,true) returning id into f;
  insert into public.bookings(user_id,booking_reference,total_amount,status,is_demo,
      facility_name,booking_date,start_time)
    values(u,'TEST-'||gen_random_uuid(),12,'confirmed',true,
      (select name from public.facilities where id=f),d,'17:00') returning id into b;
  insert into public.time_slots(facility_id,slot_date,start_time,end_time)
    values(f,d,'17:00','18:00') returning id into t1;
  insert into public.time_slots(facility_id,slot_date,start_time,end_time)
    values(f,d,'18:00','19:00') returning id into t2;
  insert into public.booking_items(booking_id,time_slot_id,price,status)
    values(b,t1,6,'confirmed') returning id into i1;
  insert into public.booking_items(booking_id,time_slot_id,price,status)
    values(b,t2,6,'confirmed') returning id into i2;
  insert into public.payments(booking_id,amount,payment_method,payment_gateway,status)
    values(b,12,'fpx','prototype_demo','simulated_success');
  perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated')::text,true);
  begin
    perform public.admin_set_session_closure(f,d,array['18:00'::time],true,'TEST');
    raise exception 'FAIL student was allowed to close';
  exception when insufficient_privilege then null;
  end;
  perform set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated')::text,true);
  result := public.admin_set_session_closure(f,d,array['18:00'::time],true,'TEST');
  if (result->>'refunds_created')::int<>1 then raise exception 'FAIL refund count'; end if;
  if (select status from public.booking_items where id=i1)<>'confirmed' then raise exception 'FAIL unaffected item'; end if;
  if (select status from public.bookings where id=b)<>'confirmed' then raise exception 'FAIL unaffected order'; end if;
  if (select status from public.booking_items where id=i2)<>'cancelled_by_management' then raise exception 'FAIL selected item'; end if;
  if (select sum(amount) from public.refunds where booking_id=b)<>6 then raise exception 'FAIL partial refund'; end if;
  if not (select is_available from public.time_slots where id=t1) then raise exception 'FAIL unaffected slot'; end if;
  if (select is_available from public.time_slots where id=t2) then raise exception 'FAIL closure'; end if;
  perform public.admin_set_session_closure(f,d,array['18:00'::time,'18:00'::time],true,'TEST');
  if (select count(*) from public.refunds where booking_id=b)<>1 then raise exception 'FAIL repeated refund'; end if;
  perform public.admin_set_session_closure(f,d,array['18:00'::time],false,'');
  if not (select is_available from public.time_slots where id=t2) then raise exception 'FAIL reopening'; end if;
  if (select status from public.booking_items where id=i2)<>'cancelled_by_management' then raise exception 'FAIL revived cancellation'; end if;
  if (select count(*) from public.refunds where booking_id=b)<>1 then raise exception 'FAIL lost refund'; end if;
  perform public.admin_set_session_closure(f,d,array['17:00'::time],true,'TEST');
  if (select sum(amount) from public.refunds where booking_id=b)<>12 then raise exception 'FAIL cumulative amount'; end if;
  if (select count(*) from public.refunds where booking_id=b)<>2 then raise exception 'FAIL second session refund'; end if;
  if (select status from public.bookings where id=b)<>'cancelled_by_management' then raise exception 'FAIL full cancellation'; end if;
  raise notice 'PASS: authorization, partial amount/status, repeat safety, reopening and second-hour refund';
end $$;
rollback;
