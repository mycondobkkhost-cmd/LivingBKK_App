-- แยก enum ADD VALUE ออกจาก migration ถัดไป (PostgreSQL ห้ามใช้ค่า enum ใหม่ใน transaction เดียวกัน)

DO $$ BEGIN
  ALTER TYPE public.chat_thread_category ADD VALUE IF NOT EXISTS 'customer_requirement';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
