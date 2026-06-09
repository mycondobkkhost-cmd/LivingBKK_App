-- role viewing_staff — แยก transaction ก่อนใช้ใน function/policy

ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'viewing_staff';
