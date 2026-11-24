-- SCRUM-38: standardise student category values.
-- Run in Supabase > SQL Editor. Safe to run again.
--
-- Stored values are ONLY 'krp' or 'non_krp' (UI shows "KRP Student" /
-- "Non-KRP Student"). NULL means "not set yet": the app shows
-- "Category not set", charges nothing at the KRP rate and reserve_cart
-- refuses checkout (PROFILE_CATEGORY_REQUIRED) until an admin sets it.

-- 1. Turn old labels into stored values, and blanks into NULL.
update public.profiles set student_category = case
    when lower(regexp_replace(trim(student_category), '[\s_-]+', ' ', 'g'))
         in ('krp', 'krp student') then 'krp'
    when lower(regexp_replace(trim(student_category), '[\s_-]+', ' ', 'g'))
         in ('non krp', 'non krp student', 'nonkrp') then 'non_krp'
    else null
  end
where student_category is distinct from 'krp'
  and student_category is distinct from 'non_krp'
  and student_category is not null;

update public.bookings set customer_category = case
    when lower(regexp_replace(trim(customer_category), '[\s_-]+', ' ', 'g'))
         in ('krp', 'krp student') then 'krp'
    when lower(regexp_replace(trim(customer_category), '[\s_-]+', ' ', 'g'))
         in ('non krp', 'non krp student', 'nonkrp') then 'non_krp'
    else null
  end
where customer_category is distinct from 'krp'
  and customer_category is distinct from 'non_krp'
  and customer_category is not null;

-- 2. From now on only the two stored values (or NULL) can be saved.
alter table public.profiles drop constraint if exists profiles_student_category_check;
alter table public.profiles add constraint profiles_student_category_check
  check (student_category is null or student_category in ('krp', 'non_krp'));

alter table public.bookings drop constraint if exists bookings_customer_category_check;
alter table public.bookings add constraint bookings_customer_category_check
  check (customer_category is null or customer_category in ('krp', 'non_krp'));

-- 3. Students who still need a category (an admin must set it):
-- select id, email, full_name, matric_number from public.profiles
--   where role = 'student' and student_category is null;
