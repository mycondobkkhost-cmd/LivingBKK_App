-- ผูก Lead นัดดูกับห้องแชทเดียวกัน (ลูกค้า ↔ แอดมิน)

ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS thread_id uuid REFERENCES public.chat_threads (id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS leads_thread_id_idx
  ON public.leads (thread_id)
  WHERE thread_id IS NOT NULL;
