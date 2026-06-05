-- Phase 19: Project catalog admin — CRUD + import metadata

ALTER TABLE public.property_projects
  ADD COLUMN IF NOT EXISTS source_url text,
  ADD COLUMN IF NOT EXISTS source_platform text NOT NULL DEFAULT 'manual',
  ADD COLUMN IF NOT EXISTS source_external_id text,
  ADD COLUMN IF NOT EXISTS description_th text,
  ADD COLUMN IF NOT EXISTS description_en text,
  ADD COLUMN IF NOT EXISTS cover_image_url text,
  ADD COLUMN IF NOT EXISTS admin_notes text,
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES public.profiles (id),
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES public.profiles (id);

CREATE INDEX IF NOT EXISTS property_projects_source_ext_idx
  ON public.property_projects (source_external_id)
  WHERE source_external_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS property_projects_source_platform_idx
  ON public.property_projects (source_platform);

-- Admin sees inactive projects too
DROP POLICY IF EXISTS property_projects_admin_read_all ON public.property_projects;
CREATE POLICY property_projects_admin_read_all ON public.property_projects
  FOR SELECT TO authenticated
  USING (public.is_admin());

CREATE OR REPLACE FUNCTION public.slugify_project_name(raw text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  s text;
BEGIN
  s := lower(trim(coalesce(raw, '')));
  s := regexp_replace(s, '[^a-z0-9]+', '-', 'g');
  s := regexp_replace(s, '-+', '-', 'g');
  s := trim(both '-' from s);
  IF s = '' OR length(s) < 2 THEN
    s := 'project-' || substr(replace(uuid_generate_v4()::text, '-', ''), 1, 8);
  END IF;
  RETURN left(s, 80);
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_property_project_location()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.lat IS NOT NULL AND NEW.lng IS NOT NULL THEN
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326)::geography;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS property_projects_sync_location ON public.property_projects;
CREATE TRIGGER property_projects_sync_location
  BEFORE INSERT OR UPDATE OF lat, lng ON public.property_projects
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_property_project_location();

CREATE OR REPLACE FUNCTION public.ensure_unique_project_slug()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  base text;
  candidate text;
  n int := 0;
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := public.slugify_project_name(coalesce(NEW.name_en, NEW.name_th));
  END IF;
  base := NEW.slug;
  candidate := base;
  WHILE EXISTS (
    SELECT 1 FROM public.property_projects p
    WHERE p.slug = candidate AND p.id IS DISTINCT FROM NEW.id
  ) LOOP
    n := n + 1;
    candidate := base || '-' || n::text;
  END LOOP;
  NEW.slug := candidate;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS property_projects_unique_slug ON public.property_projects;
CREATE TRIGGER property_projects_unique_slug
  BEFORE INSERT OR UPDATE OF slug, name_th, name_en ON public.property_projects
  FOR EACH ROW
  EXECUTE FUNCTION public.ensure_unique_project_slug();
