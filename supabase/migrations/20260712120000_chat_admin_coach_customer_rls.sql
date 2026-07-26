-- Hide admin_coach messages from customers (admin-only coach lane).
-- Customers still see holding AI replies; coach prompts stay in admin console.

DROP POLICY IF EXISTS chat_messages_select ON public.chat_messages;

CREATE POLICY chat_messages_select ON public.chat_messages
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR (
      EXISTS (
        SELECT 1 FROM public.chat_threads t
        WHERE t.id = thread_id AND t.user_id = auth.uid()
      )
      AND role <> 'admin_coach'::public.chat_message_role
    )
  );

COMMENT ON POLICY chat_messages_select ON public.chat_messages IS
  'Thread owners see messages except admin_coach; admins see all.';
