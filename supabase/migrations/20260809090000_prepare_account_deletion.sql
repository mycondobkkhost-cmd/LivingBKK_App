-- RealXtate: clear user-owned FKs so auth.admin.deleteUser → profiles CASCADE can succeed

CREATE OR REPLACE FUNCTION public.prepare_account_deletion(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_listing_ids uuid[];
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id_required';
  END IF;

  SELECT coalesce(array_agg(id), '{}')
  INTO v_listing_ids
  FROM public.listings
  WHERE owner_id = p_user_id OR created_by_id = p_user_id;

  -- Demand board
  UPDATE public.demand_offers
  SET capacity_verified_by = NULL
  WHERE capacity_verified_by = p_user_id;
  DELETE FROM public.demand_offers WHERE offerer_id = p_user_id;
  DELETE FROM public.demand_posts WHERE created_by = p_user_id;

  -- Imports
  UPDATE public.listing_imports
  SET reviewed_by = NULL
  WHERE reviewed_by = p_user_id;
  DELETE FROM public.listing_imports WHERE created_by = p_user_id;

  -- Co-agent
  IF to_regclass('public.co_agent_requests') IS NOT NULL THEN
    UPDATE public.co_agent_requests
    SET reviewed_by = NULL
    WHERE reviewed_by = p_user_id;
    DELETE FROM public.co_agent_requests WHERE requesting_agent_id = p_user_id;
  END IF;

  -- Leads / assignments
  DELETE FROM public.lead_assignments WHERE assignee_id = p_user_id;
  UPDATE public.leads
  SET listing_id = NULL
  WHERE listing_id = ANY (v_listing_ids);
  UPDATE public.leads
  SET seeker_id = NULL
  WHERE seeker_id = p_user_id;
  UPDATE public.leads
  SET assigned_to = NULL
  WHERE assigned_to = p_user_id;

  -- Contracts
  IF to_regclass('public.e_contracts') IS NOT NULL THEN
    DELETE FROM public.e_contracts WHERE signer_id = p_user_id;
  END IF;

  -- Inventory owner pointer
  IF to_regclass('public.property_inventory') IS NOT NULL THEN
    UPDATE public.property_inventory
    SET owner_profile_id = NULL
    WHERE owner_profile_id = p_user_id;
  END IF;

  -- Moderation / audit soft refs
  IF to_regclass('public.moderation_flags') IS NOT NULL THEN
    UPDATE public.moderation_flags
    SET resolved_by = NULL
    WHERE resolved_by = p_user_id;
  END IF;
  IF to_regclass('public.admin_audit_log') IS NOT NULL THEN
    UPDATE public.admin_audit_log
    SET actor_id = NULL
    WHERE actor_id = p_user_id;
  END IF;

  -- Project catalog editors
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'property_projects'
      AND column_name = 'created_by'
  ) THEN
    EXECUTE 'UPDATE public.property_projects SET created_by = NULL WHERE created_by = $1'
      USING p_user_id;
    EXECUTE 'UPDATE public.property_projects SET updated_by = NULL WHERE updated_by = $1'
      USING p_user_id;
  END IF;

  -- Listings (child rows mostly CASCADE / SET NULL)
  UPDATE public.listings
  SET assigned_co_agent_id = NULL
  WHERE assigned_co_agent_id = p_user_id;
  DELETE FROM public.listings
  WHERE owner_id = p_user_id OR created_by_id = p_user_id;

  -- Chat / appointments
  UPDATE public.chat_threads
  SET assigned_admin_id = NULL
  WHERE assigned_admin_id = p_user_id;
  UPDATE public.chat_messages
  SET sender_id = NULL
  WHERE sender_id = p_user_id;
  UPDATE public.appointments
  SET created_by = NULL
  WHERE created_by = p_user_id;
  UPDATE public.appointments
  SET assigned_to = NULL
  WHERE assigned_to = p_user_id;

  -- Vault access requests/grants (admin-only data; safe to drop with account)
  IF to_regclass('public.admin_access_requests') IS NOT NULL THEN
    DELETE FROM public.admin_access_requests WHERE requested_by = p_user_id;
    UPDATE public.admin_access_requests
    SET reviewed_by = NULL
    WHERE reviewed_by = p_user_id;
  END IF;
  IF to_regclass('public.admin_access_grants') IS NOT NULL THEN
    DELETE FROM public.admin_access_grants
    WHERE grantee_id = p_user_id OR granted_by = p_user_id;
    UPDATE public.admin_access_grants
    SET revoked_by = NULL
    WHERE revoked_by = p_user_id;
  END IF;

  IF to_regclass('public.owner_contact_requests') IS NOT NULL THEN
    DELETE FROM public.owner_contact_requests WHERE requested_by = p_user_id;
    UPDATE public.owner_contact_requests
    SET approved_by = NULL
    WHERE approved_by = p_user_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.prepare_account_deletion(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.prepare_account_deletion(uuid) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.prepare_account_deletion(uuid) TO service_role;

COMMENT ON FUNCTION public.prepare_account_deletion(uuid) IS
  'Service-role only: clear user-owned FKs before auth user deletion';
