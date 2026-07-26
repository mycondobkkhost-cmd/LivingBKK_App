-- รวบรวมคำถามก่อนส่งเจ้าของทีเดียว
ALTER TABLE public.chat_threads
  ADD COLUMN IF NOT EXISTS owner_inquiry_collecting boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS owner_inquiry_draft text NOT NULL DEFAULT '';
