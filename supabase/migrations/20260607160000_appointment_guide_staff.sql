-- คนพาดู (demo-staff-* หรือชื่ออ้างอิง) แยกจาก assigned_to ที่เป็น profiles.uuid

ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS guide_staff_id text;

COMMENT ON COLUMN public.appointments.guide_staff_id IS
  'Staff guide label/id for viewing — text (demo-staff-*) or profile ref';
