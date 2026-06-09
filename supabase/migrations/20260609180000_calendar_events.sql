-- Calendar events: AI draft + human canonical + field locks (ปฏิทินหลังบ้าน)

CREATE TYPE public.calendar_event_type AS ENUM (
  'viewing',
  'maintenance',
  'ops',
  'personal'
);

CREATE TYPE public.calendar_event_status AS ENUM (
  'ai_draft',
  'pending',
  'confirmed',
  'completed',
  'cancelled'
);

CREATE TABLE public.calendar_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type public.calendar_event_type NOT NULL DEFAULT 'viewing',
  status public.calendar_event_status NOT NULL DEFAULT 'ai_draft',
  title text NOT NULL,
  description text,
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  color_hint text,

  lead_id uuid REFERENCES public.leads (id) ON DELETE SET NULL,
  listing_id uuid REFERENCES public.listings (id) ON DELETE SET NULL,
  listing_code text,
  appointment_id uuid REFERENCES public.appointments (id) ON DELETE SET NULL,
  thread_id uuid REFERENCES public.chat_threads (id) ON DELETE SET NULL,

  seeker_user_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  owner_user_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  assigned_to uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL,

  location_label text,
  lat double precision,
  lng double precision,
  owner_notes text,
  seeker_notes text,

  ai_draft jsonb NOT NULL DEFAULT '{}'::jsonb,
  field_locks jsonb NOT NULL DEFAULT '{}'::jsonb,
  version int NOT NULL DEFAULT 1,

  ai_last_run_at timestamptz,
  human_edited_at timestamptz,
  human_edited_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL,

  external_event_id text,
  external_calendar_provider text,
  external_synced_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT calendar_events_time_order CHECK (end_at > start_at)
);

CREATE INDEX calendar_events_start_idx ON public.calendar_events (start_at);
CREATE INDEX calendar_events_status_idx ON public.calendar_events (status);
CREATE INDEX calendar_events_thread_idx ON public.calendar_events (thread_id);
CREATE INDEX calendar_events_appointment_idx ON public.calendar_events (appointment_id);
CREATE INDEX calendar_events_owner_idx ON public.calendar_events (owner_user_id);
CREATE INDEX calendar_events_seeker_idx ON public.calendar_events (seeker_user_id);

-- หนึ่งร่าง AI ต่อ thread (กันซ้ำ)
CREATE UNIQUE INDEX calendar_events_thread_draft_uidx
  ON public.calendar_events (thread_id)
  WHERE thread_id IS NOT NULL AND status = 'ai_draft';

CREATE TRIGGER calendar_events_updated_at
  BEFORE UPDATE ON public.calendar_events
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.calendar_event_audits (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id uuid NOT NULL REFERENCES public.calendar_events (id) ON DELETE CASCADE,
  action text NOT NULL,
  actor_kind text NOT NULL CHECK (actor_kind IN ('ai', 'human', 'system')),
  actor_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX calendar_event_audits_event_idx
  ON public.calendar_event_audits (event_id, created_at DESC);

ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_event_audits ENABLE ROW LEVEL SECURITY;

CREATE POLICY calendar_events_admin_all ON public.calendar_events
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY calendar_events_assignee_select ON public.calendar_events
  FOR SELECT TO authenticated
  USING (assigned_to = auth.uid());

CREATE POLICY calendar_events_assignee_update ON public.calendar_events
  FOR UPDATE TO authenticated
  USING (assigned_to = auth.uid())
  WITH CHECK (assigned_to = auth.uid());

CREATE POLICY calendar_events_owner_select ON public.calendar_events
  FOR SELECT TO authenticated
  USING (owner_user_id = auth.uid());

CREATE POLICY calendar_events_owner_notes ON public.calendar_events
  FOR UPDATE TO authenticated
  USING (owner_user_id = auth.uid())
  WITH CHECK (owner_user_id = auth.uid());

CREATE POLICY calendar_events_seeker_select ON public.calendar_events
  FOR SELECT TO authenticated
  USING (seeker_user_id = auth.uid());

CREATE POLICY calendar_events_seeker_notes ON public.calendar_events
  FOR UPDATE TO authenticated
  USING (seeker_user_id = auth.uid())
  WITH CHECK (seeker_user_id = auth.uid());

CREATE POLICY calendar_event_audits_admin ON public.calendar_event_audits
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY calendar_event_audits_owner_read ON public.calendar_event_audits
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.calendar_events e
      WHERE e.id = event_id
        AND (e.owner_user_id = auth.uid() OR e.seeker_user_id = auth.uid())
    )
  );

COMMENT ON TABLE public.calendar_events IS
  'ปฏิทินหลังบ้าน — AI สร้าง draft, มนุษย์ยืนยัน/แก้; field_locks กัน AI ทับฟิลด์ที่คนแก้แล้ว';
COMMENT ON COLUMN public.calendar_events.field_locks IS
  'JSON map ฟิลด์→"human" เมื่อมนุษย์แก้แล้ว AI ห้ามทับ';
COMMENT ON COLUMN public.calendar_events.ai_draft IS
  'ค่าล่าสุดที่ AI เสนอ (ก่อน merge เข้า canonical)';
