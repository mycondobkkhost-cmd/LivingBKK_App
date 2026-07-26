-- ร่างข้อความ AI รอแอดมินยืนยัน — เห็นเฉพาะแอดมิน
ALTER TYPE public.chat_message_role ADD VALUE IF NOT EXISTS 'ai_draft';
