-- คำขอเพิ่มโครงการที่ยังไม่มีในทะเบียน (ลูกค้าส่งจากช่องค้นหา / แชท)
CREATE TABLE IF NOT EXISTS public.project_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  project_name text NOT NULL,
  source text NOT NULL DEFAULT 'search_bar',
  source_query text,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'reviewing', 'added', 'rejected')),
  admin_note text,
  linked_project_id uuid REFERENCES public.property_projects (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS project_requests_status_idx
  ON public.project_requests (status, created_at DESC);

CREATE INDEX IF NOT EXISTS project_requests_user_name_idx
  ON public.project_requests (user_id, lower(project_name));

DROP TRIGGER IF EXISTS project_requests_updated_at ON public.project_requests;
CREATE TRIGGER project_requests_updated_at
  BEFORE UPDATE ON public.project_requests
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.project_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS project_requests_insert_own ON public.project_requests;
CREATE POLICY project_requests_insert_own ON public.project_requests
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS project_requests_select_own ON public.project_requests;
CREATE POLICY project_requests_select_own ON public.project_requests
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS project_requests_update_admin ON public.project_requests;
CREATE POLICY project_requests_update_admin ON public.project_requests
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());
