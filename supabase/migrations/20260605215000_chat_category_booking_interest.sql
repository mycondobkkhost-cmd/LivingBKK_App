-- enum สำหรับแชทสนใจจอง — ต้องแยก transaction ก่อนใช้ใน view

DO $$ BEGIN
  ALTER TYPE public.chat_thread_category ADD VALUE IF NOT EXISTS 'booking_interest';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
