-- Property Hub is the project name master.
-- Pantip-curated rows (if seed was applied) stay as inactive alias reservoirs
-- until a Property Hub sync creates/activates the canonical project.

COMMENT ON TABLE public.property_projects IS
  'Project catalog. Canonical names from Property Hub (source_platform=propertyhub). LivingInsider may enrich lat/lng/transit only. Pantip may add aliases only.';

UPDATE public.property_projects
SET
  is_active = false,
  admin_notes = trim(
    both
    FROM
      concat_ws(
        ' | ',
        NULLIF(admin_notes, ''),
        'inactive_until_propertyhub_master'
      )
  ),
  updated_at = now()
WHERE source_platform = 'pantip_curated'
  AND coalesce(is_active, true) = true;
