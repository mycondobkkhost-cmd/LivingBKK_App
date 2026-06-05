-- Unified chat: FAQ rules (admin-configurable) + discovery thread index

DO $$ BEGIN
  ALTER TYPE public.chat_thread_category ADD VALUE 'discovery';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TYPE public.chat_faq_scope AS ENUM ('global', 'property', 'discovery');

CREATE TABLE public.chat_faq_rules (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  scope public.chat_faq_scope NOT NULL DEFAULT 'global',
  patterns text[] NOT NULL,
  reply_text text NOT NULL,
  priority int NOT NULL DEFAULT 100,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX chat_faq_rules_scope_priority_idx
  ON public.chat_faq_rules (scope, priority ASC)
  WHERE is_active = true;

CREATE TRIGGER chat_faq_rules_updated_at
  BEFORE UPDATE ON public.chat_faq_rules
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.chat_faq_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_faq_rules_select ON public.chat_faq_rules
  FOR SELECT TO authenticated
  USING (is_active = true OR public.is_admin());

CREATE POLICY chat_faq_rules_admin ON public.chat_faq_rules
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- One general discovery thread per user (property room, no listing)
CREATE UNIQUE INDEX IF NOT EXISTS chat_threads_user_discovery_uidx
  ON public.chat_threads (user_id)
  WHERE room_kind = 'property' AND listing_id IS NULL;

-- Default FAQ (0-token replies) — admin can edit in Dashboard
INSERT INTO public.chat_faq_rules (scope, patterns, reply_text, priority) VALUES
(
  'global',
  ARRAY['ค่าส่วนกลาง', 'common fee', 'cam fee'],
  'ราคาที่แสดงเป็นราคา Net สำหรับผู้เช่า/ผู้ซื้อแล้วครับ รายละเอียดค่าใช้จ่ายเพิ่มเติม (เช่น ค่าส่วนกลาง) เจ้าหน้าที่จะยืนยันให้เมื่อติดต่อกลับ',
  10
),
(
  'global',
  ARRAY['net', 'เน็ต', 'รวมค่า'],
  'ราคาบนแพลตฟอร์มเป็นราคา Net ที่ผู้เช่า/ผู้ซื้อเห็นแล้วครับ หากต้องการรายละเอียดครบถ้วน แจ้งในแชทได้เลย',
  15
),
(
  'property',
  ARRAY['ราคา', 'เท่าไร', 'เท่าไหร่', 'กี่บาท'],
  'ราคาที่แสดงเป็นราคา Net สำหรับทรัพย์นี้แล้วครับ หากต้องการรายละเอียดครบถ้วน เจ้าหน้าที่จะยืนยันให้เมื่อติดต่อกลับ',
  20
),
(
  'property',
  ARRAY['สัตว', 'เลี้ยง', 'pet'],
  'เงื่อนไขสัตว์เลี้ยงขึ้นกับแต่ละห้องครับ เจ้าหน้าที่จะยืนยันให้เมื่อติดต่อกลับ',
  25
),
(
  'property',
  ARRAY['จอด', 'รถ', 'parking'],
  'ที่จอดรถและค่าใช้จ่ายเพิ่มเติม เจ้าหน้าที่จะยืนยันให้เมื่อติดต่อกลับครับ',
  30
),
(
  'property',
  ARRAY['bts', 'mrt', 'ทำเล', 'ใกล้'],
  'ทำเลแสดงแบบโซนโดยประมาณบนแผนที่ (ไม่เปิดเผยเลขห้อง/ชั้น) หากต้องการรายละเอียดเพิ่ม แจ้งในแชทได้ครับ',
  35
),
(
  'discovery',
  ARRAY['นัดดู', 'ดูห้อง', 'เข้าชม'],
  'กด「ขอนัดดูห้อง」ที่หน้าทรัพย์ที่สนใจ หรือบอกทำเล/งบมา ผมช่วยแนะนำทรัพย์ในระบบให้ก่อนได้ครับ',
  40
);
