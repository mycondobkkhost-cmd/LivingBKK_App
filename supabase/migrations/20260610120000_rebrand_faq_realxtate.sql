-- Rebrand FAQ bot copy: PROPPITER → RealXtate (production DB)
UPDATE public.chat_faq_rules
SET reply_text = REPLACE(reply_text, 'PROPPITER', 'RealXtate')
WHERE reply_text LIKE '%PROPPITER%';
