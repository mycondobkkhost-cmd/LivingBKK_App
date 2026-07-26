-- RealXtate: conversational chat — admin coach lane + learned answer memory

ALTER TYPE public.chat_message_role ADD VALUE IF NOT EXISTS 'admin_coach';

ALTER TABLE public.chat_threads
  ADD COLUMN IF NOT EXISTS coach_pending boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS coach_question text,
  ADD COLUMN IF NOT EXISTS coach_user_message_id uuid REFERENCES public.chat_messages (id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS public.chat_learned_answers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  topic_key text NOT NULL,
  question_example text NOT NULL,
  answer_guidance text NOT NULL,
  scope text NOT NULL DEFAULT 'global'
    CHECK (scope IN ('global', 'property_type', 'listing')),
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  property_type text,
  source_thread_id uuid REFERENCES public.chat_threads (id) ON DELETE SET NULL,
  created_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  use_count integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS chat_learned_answers_scope_idx
  ON public.chat_learned_answers (scope, is_active, use_count DESC);

CREATE INDEX IF NOT EXISTS chat_learned_answers_listing_idx
  ON public.chat_learned_answers (listing_id)
  WHERE listing_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS chat_learned_answers_topic_idx
  ON public.chat_learned_answers (topic_key);

CREATE TRIGGER chat_learned_answers_updated_at
  BEFORE UPDATE ON public.chat_learned_answers
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.chat_learned_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_learned_answers_admin_all ON public.chat_learned_answers
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY chat_learned_answers_service_read ON public.chat_learned_answers
  FOR SELECT
  USING (auth.role() = 'service_role');

COMMENT ON TABLE public.chat_learned_answers IS
  'Admin-coached answer guidance reused across chats; LLM paraphrases, never copy-pastes.';
