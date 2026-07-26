-- โทนทักทาย AI — สั้น เป็นแอดมินหญิง
UPDATE public.chat_faq_rules
SET reply_text = 'สวัสดีค่ะลูกค้า สามารถพิมพ์สอบถามได้เลยนะคะ'
WHERE scope = 'global'
  AND patterns @> ARRAY['สวัสดี']
  AND is_active = true;
