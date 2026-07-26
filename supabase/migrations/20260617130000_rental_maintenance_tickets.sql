-- Phase 27d: maintenance tickets + rental-docs storage bucket

CREATE TABLE IF NOT EXISTS public.rental_maintenance_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lease_id uuid NOT NULL REFERENCES public.rental_leases (id) ON DELETE CASCADE,
  title text NOT NULL,
  description text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'inProgress', 'resolved', 'cancelled')),
  opened_by text NOT NULL DEFAULT '',
  opened_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS rental_maintenance_tickets_lease_idx
  ON public.rental_maintenance_tickets (lease_id, opened_at DESC);

CREATE INDEX IF NOT EXISTS rental_maintenance_tickets_open_idx
  ON public.rental_maintenance_tickets (status, opened_at)
  WHERE status IN ('open', 'inProgress');

ALTER TABLE public.rental_maintenance_tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rental_maintenance_tickets_select
  ON public.rental_maintenance_tickets;
DROP POLICY IF EXISTS rental_maintenance_tickets_insert
  ON public.rental_maintenance_tickets;
DROP POLICY IF EXISTS rental_maintenance_tickets_admin
  ON public.rental_maintenance_tickets;

CREATE POLICY rental_maintenance_tickets_select
  ON public.rental_maintenance_tickets
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.rental_lease_members m
      WHERE m.lease_id = rental_maintenance_tickets.lease_id
        AND m.user_id = auth.uid()
    )
    OR public.is_admin()
  );

CREATE POLICY rental_maintenance_tickets_insert
  ON public.rental_maintenance_tickets
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.rental_lease_members m
      WHERE m.lease_id = rental_maintenance_tickets.lease_id
        AND m.user_id = auth.uid()
    )
    OR public.is_admin()
  );

CREATE POLICY rental_maintenance_tickets_admin
  ON public.rental_maintenance_tickets
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

INSERT INTO storage.buckets (id, name, public)
VALUES ('rental-docs', 'rental-docs', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS rental_docs_select ON storage.objects;
DROP POLICY IF EXISTS rental_docs_insert ON storage.objects;
DROP POLICY IF EXISTS rental_docs_admin ON storage.objects;

CREATE POLICY rental_docs_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'rental-docs'
    AND (
      public.is_admin()
      OR EXISTS (
        SELECT 1
        FROM public.rental_group_attachments a
        WHERE a.storage_path = storage.objects.name
          AND EXISTS (
            SELECT 1 FROM public.rental_lease_members m
            WHERE m.lease_id = a.lease_id AND m.user_id = auth.uid()
          )
      )
    )
  );

CREATE POLICY rental_docs_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'rental-docs'
    AND (
      public.is_admin()
      OR EXISTS (
        SELECT 1 FROM public.rental_lease_members m
        WHERE m.user_id = auth.uid()
      )
    )
  );

CREATE POLICY rental_docs_admin ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'rental-docs' AND public.is_admin())
  WITH CHECK (bucket_id = 'rental-docs' AND public.is_admin());
