-- Isolated disposable PostgreSQL only. Never run this against hosted Supabase.
create role anon;
create role authenticated;
create schema auth;
create function auth.uid() returns uuid language sql stable as $$
 select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid;
$$;
grant usage on schema public,auth to anon,authenticated;
grant execute on function auth.uid() to public;
create table public.profiles(id uuid primary key, full_name text, phone_number text,matric_number text,
 role text default 'student',student_category text);
create table public.facilities(id uuid primary key default gen_random_uuid(),name text,
 krp_price numeric,non_krp_price numeric,is_active boolean default true);
create table public.operating_schedules(day_of_week int,start_time time,end_time time,
 slot_minutes int default 60,is_active boolean default true);
create table public.facility_blocks(facility_id uuid,starts_at timestamptz,ends_at timestamptz);
create table public.time_slots(id uuid primary key default gen_random_uuid(),facility_id uuid,
 slot_date date,start_time time,end_time time,is_available boolean default true,closure_batch_id uuid,
 unique(facility_id,slot_date,start_time,end_time));
create table public.bookings(id uuid primary key default gen_random_uuid(),user_id uuid references profiles,
 booking_reference text unique,total_amount numeric,status text,payment_deadline timestamptz,
 customer_category text,booking_source text,created_at timestamptz default now(),updated_at timestamptz default now(),admin_note text);
create table public.booking_items(id uuid primary key default gen_random_uuid(),booking_id uuid default gen_random_uuid() references bookings,
 time_slot_id uuid default gen_random_uuid(),price numeric,status text);
create unique index uq_booking_items_active_time_slot on booking_items(time_slot_id)
 where status in ('pending_payment','confirmed');
create table public.payments(id uuid primary key default gen_random_uuid(),booking_id uuid,amount numeric,status text);
grant all on all tables in schema public to anon,authenticated;
create policy profiles_self on profiles for select to authenticated using(id=auth.uid());
create policy profiles_self_update on profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
insert into profiles values
 ('00000000-0000-0000-0000-000000000001','A','','A1','student','krp'),
 ('00000000-0000-0000-0000-000000000002','B','','B1','student','non_krp');
insert into facilities values
 ('10000000-0000-0000-0000-000000000001','Badminton Court 1',6,8,true),
 ('10000000-0000-0000-0000-000000000002','Ping Pong Table 1',4,6,true);
insert into operating_schedules
 select d,'17:00','23:00',60,true from generate_series(0,6) d;
