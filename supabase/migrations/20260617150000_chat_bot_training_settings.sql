-- Phase 29: Admin chat bot training — logic overrides editable from app

CREATE TABLE IF NOT EXISTS public.chat_bot_training_settings (
  id text PRIMARY KEY DEFAULT 'default',
  settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.chat_bot_training_settings (id, settings)
VALUES (
  'default',
  '{
    "voice_extra_rules": "",
    "unclear_escalate_threshold": 2,
    "coach_when_low_confidence": true,
    "strategy_hints": {
      "build_trust": "ทักทายอบอุ่น ไม่เร่งขาย ชวนถามต่ออย่างนุ่มนวล",
      "answer_question": "ตอบคำถามให้ครบก่อน แล้วค่อยชวนนัดดู",
      "invite_viewing": "ลูกค้าสนใจแล้ว — ชวนนัดดูชัด ไม่กดดัน",
      "collect_requirement": "ทรัพย์นี้อาจไม่ fit — ชวนกรอกฟอร์มช่วยหาห้อง",
      "close_ready": "ลูกค้าพร้อมปิด — สรุปขั้นตอนถัดไปชัดเจน",
      "negotiate_soft": "ราคา Net แล้ว — ถ้าจริงจังหลังนัดดู แอดมินช่วยคุยเจ้าของ"
    }
  }'::jsonb
)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.chat_bot_training_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS chat_bot_training_settings_admin
  ON public.chat_bot_training_settings;
DROP POLICY IF EXISTS chat_bot_training_settings_service
  ON public.chat_bot_training_settings;

CREATE POLICY chat_bot_training_settings_admin
  ON public.chat_bot_training_settings
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY chat_bot_training_settings_service
  ON public.chat_bot_training_settings
  FOR SELECT
  USING (auth.role() = 'service_role');

DROP TRIGGER IF EXISTS chat_bot_training_settings_updated_at
  ON public.chat_bot_training_settings;
CREATE TRIGGER chat_bot_training_settings_updated_at
  BEFORE UPDATE ON public.chat_bot_training_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.chat_bot_training_settings IS
  'Admin-editable bot communication logic — merged into chat-turn system prompt.';
