-- Lean ops: defer admin until 2nd unclear message + tighter inbox view

ALTER TABLE public.chat_threads
  ADD COLUMN IF NOT EXISTS unclear_streak int NOT NULL DEFAULT 0;

-- More FAQ = fewer admin tickets (0 token)
INSERT INTO public.chat_faq_rules (scope, patterns, reply_text, priority) VALUES
(
  'global',
  ARRAY['สวัสดี', 'hello', 'hi', 'หวัดดี'],
  'สวัสดีครับ ยินดีช่วยเหลือครับ บอกทำlez โครงการ งบ หรือถามเรื่องทรัพย์ที่สนใจได้เลย',
  5
),
(
  'global',
  ARRAY['ขอบคุณ', 'thanks', 'thank you'],
  'ยินดีครับ หากมีคำถามเพิ่มเติม แจ้งในแชทได้เลยครับ',
  6
),
(
  'global',
  ARRAY['deposit', 'มัดจำ', 'ประกัน'],
  'เงื่อนไขมัดจำ/ประกันขึ้นกับแต่ละทรัพย์ครับ เจ้าหน้าที่จะยืนยันให้เมื่อติดต่อกลับ',
  38
),
(
  'global',
  ARRAY['สัญญา', 'contract', 'ระยะเวลา'],
  'ระยะสัญญาและเงื่อนไขขึ้นกับแต่ละห้องครับ แจ้งระยะที่ต้องการได้ เราช่วยสรุปให้',
  39
),
(
  'property',
  ARRAY['furniture', 'เฟอร์', 'ตู้', 'เตียง'],
  'เฟอร์นิเจอร์และของใช้ขึ้นกับแต่ละห้องครับ เจ้าหน้าที่จะยืนยันรายการให้เมื่อติดต่อกลับ',
  36
),
(
  'discovery',
  ARRAY['แนะนำ', 'มีอะไร', 'มีทรัพย์'],
  'บอกทำlez · ประเภท (เช่า/ซื้อ) · งบประมาณ — ผมจะคัดทรัพย์ในระบบให้ครับ',
  12
);

-- Admin inbox: only threads that truly need a human
DROP VIEW IF EXISTS public.chat_admin_inbox CASCADE;

CREATE OR REPLACE VIEW public.chat_admin_inbox AS
SELECT
  t.id,
  t.user_id,
  t.room_kind,
  t.listing_id,
  t.listing_code,
  t.listing_title,
  t.project_name,
  t.category,
  t.status,
  t.priority,
  t.viewing_submitted,
  t.admin_escalated,
  t.admin_reply_done,
  t.unclear_streak,
  t.last_message_at,
  t.created_at,
  (
    SELECT m.text
    FROM public.chat_messages m
    WHERE m.thread_id = t.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) AS last_message_text,
  (
    SELECT m.role::text
    FROM public.chat_messages m
    WHERE m.thread_id = t.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) AS last_message_role
FROM public.chat_threads t
WHERE EXISTS (
  SELECT 1 FROM public.chat_messages um
  WHERE um.thread_id = t.id AND um.role = 'user'
)
AND (
  (t.viewing_submitted AND NOT t.admin_reply_done)
  OR t.category IN ('escalation', 'viewing_request')
  OR (t.category = 'staff_support' AND t.status = 'waiting_admin')
  OR (t.status = 'waiting_admin' AND t.priority = 'high')
  OR (t.status = 'waiting_admin' AND t.unclear_streak >= 2)
);

GRANT SELECT ON public.chat_admin_inbox TO authenticated;
