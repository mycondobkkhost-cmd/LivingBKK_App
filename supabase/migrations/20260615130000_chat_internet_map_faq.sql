-- Internet concierge + location FAQ (2026-06-15 confirm)
UPDATE public.chat_faq_rules SET reply_text = 'ตามรายละเอียดค่าเช่าจะไม่ได้รวมอินเทอร์เน็ตค่ะ ทางเรามีบริการช่างอินเทอร์เน็ตให้นะคะ ทั้งสองค่าย

ลูกค้าแค่ทำการเลือกแพ็กเกจ ไม่ต้องลำบากติดต่อพนักงานเองเลยค่ะ', escalate = false WHERE topic_th = 'อินเทอร์เน็ต/Wifi';
UPDATE public.chat_faq_rules SET reply_text = 'ทาง RealXtate มีทรัพย์ในหลายทำเลค่ะ ลูกค้าสามารถเปิดแชทจากทรัพย์ที่สนใจ แล้วขอลิงก์ Google Maps โครงการได้เลยนะคะ', escalate = false WHERE topic_th = 'ทำเล/BTS/MRT';
