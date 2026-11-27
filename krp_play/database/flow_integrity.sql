begin;
-- Reports belong to their author; administrators review all reports.
alter table public.reports enable row level security;
revoke all on public.reports from anon, authenticated;
grant select, insert, update on public.reports to authenticated;
drop policy if exists reports_owner_or_admin_read on public.reports;
create policy reports_owner_or_admin_read on public.reports for select to authenticated
using (user_id = (select auth.uid()) or (select public.is_admin()));
drop policy if exists reports_owner_insert on public.reports;
create policy reports_owner_insert on public.reports for insert to authenticated
with check (user_id = (select auth.uid()) and status = 'submitted'
 and admin_response is null and reviewed_by is null and reviewed_at is null
 and (related_booking_id is null or exists (
 select 1 from public.bookings b where b.id = related_booking_id and b.user_id = (select auth.uid()))));

-- Keep refund state, item state and the audit event in one transaction.
create or replace function checkout_private.refund_before_write()
returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if TG_OP = 'INSERT' then
   new.created_at := now(); new.updated_at := now(); return new;
 end if;
 new.updated_at := now();
 if new.status is distinct from old.status then
   if old.status = 'refunded' then raise exception 'REFUND_ALREADY_COMPLETED'; end if;
   if new.status not in ('processing','failed','refunded') then raise exception 'INVALID_REFUND_TRANSITION'; end if;
   new.processed_by := coalesce(auth.uid(),new.processed_by);
   if new.status = 'processing' then new.initiated_at := now(); end if;
   if new.status = 'refunded' then new.completed_at := now(); new.failure_reason := null; end if;
 end if;
 return new;
end $$;
create or replace function checkout_private.refund_after_status_write()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 -- The triggering UPDATE must already have passed refunds RLS.
 if new.booking_item_id is not null and new.status='refunded' then
   perform 1 from public.booking_items i
     where i.id=new.booking_item_id and i.booking_id=new.booking_id
       and i.status in ('cancelled_by_management','refunded') for update;
   if not found then raise exception 'REFUND_SESSION_STATE_MISMATCH'; end if;
   update public.booking_items set status='refunded'
     where id=new.booking_item_id and status='cancelled_by_management';
 elsif new.booking_item_id is null and new.status='refunded' then
   -- Legacy whole-order cancellations only. Extra-payment refunds must not
   -- cancel an otherwise confirmed reservation.
   update public.booking_items set status='refunded'
     where booking_id=new.booking_id and status='cancelled_by_management';
 end if;
 insert into public.refund_events(refund_id,event_type,previous_status,new_status,note,performed_by)
 values(new.id,'status_updated',old.status,new.status,
 coalesce(new.manual_remark,new.failure_reason,new.admin_note,'Refund status updated'),auth.uid());
 return new;
end $$;
revoke all on function checkout_private.refund_before_write() from public,anon,authenticated;
revoke all on function checkout_private.refund_after_status_write() from public,anon,authenticated;
drop trigger if exists refund_server_timestamps on public.refunds;
create trigger refund_server_timestamps before insert or update on public.refunds
for each row execute function checkout_private.refund_before_write();
drop trigger if exists refund_atomic_status on public.refunds;
create trigger refund_atomic_status after update of status on public.refunds
for each row when (old.status is distinct from new.status)
execute function checkout_private.refund_after_status_write();

-- A permanent claim prevents concurrent or uncertain provider retries from
-- issuing another payable bill. Only the trusted backend may access it.
create table if not exists public.payment_bill_claims (
 booking_id uuid primary key references public.bookings(id) on delete restrict,
 state text not null default 'creating' check(state in ('creating','ready','uncertain')),
 billplz_id text, payment_url text, created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.payment_bill_claims enable row level security;
revoke all on public.payment_bill_claims from public,anon,authenticated;
grant select,insert,update on public.payment_bill_claims to service_role;
commit;
