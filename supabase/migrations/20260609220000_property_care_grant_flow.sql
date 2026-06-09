-- มอบสิทธิ์ดูแลทรัพย์ — RPC รับสิทธิ์ · โอนดูแลในแอป · บังคับเติมข้อมูลเจ้าของ

DROP POLICY IF EXISTS property_care_rights_self_select ON public.property_care_rights;

CREATE POLICY property_care_rights_self_select ON public.property_care_rights
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() AND status IN ('active', 'pending_claim'));

CREATE OR REPLACE FUNCTION public.grant_property_care_right(
  p_user_id uuid,
  p_care_role public.property_care_role,
  p_inventory_id uuid DEFAULT NULL,
  p_listing_id uuid DEFAULT NULL,
  p_is_primary boolean DEFAULT false,
  p_status public.property_care_status DEFAULT 'active',
  p_notes text DEFAULT NULL,
  p_invite_code text DEFAULT NULL
)
RETURNS public.property_care_rights
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.property_care_rights;
  v_actor uuid := auth.uid();
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'admin_only';
  END IF;

  IF p_inventory_id IS NULL AND p_listing_id IS NULL THEN
    RAISE EXCEPTION 'inventory_or_listing_required';
  END IF;

  IF p_is_primary AND p_inventory_id IS NOT NULL THEN
    UPDATE public.property_care_rights
    SET is_primary = false, updated_at = now()
    WHERE inventory_id = p_inventory_id
      AND is_primary = true
      AND status = 'active';
  END IF;

  INSERT INTO public.property_care_rights (
    user_id,
    care_role,
    inventory_id,
    listing_id,
    status,
    is_primary,
    granted_by,
    notes,
    invite_code
  ) VALUES (
    p_user_id,
    p_care_role,
    p_inventory_id,
    p_listing_id,
    p_status,
    p_is_primary,
    v_actor,
    p_notes,
    p_invite_code
  )
  RETURNING * INTO v_row;

  INSERT INTO public.property_care_audits (right_id, action, actor_id, payload)
  VALUES (
    v_row.id,
    'grant',
    v_actor,
    jsonb_build_object(
      'care_role', p_care_role,
      'status', p_status,
      'is_primary', p_is_primary,
      'inventory_id', p_inventory_id,
      'listing_id', p_listing_id
    )
  );

  IF p_inventory_id IS NOT NULL
     AND p_care_role IN (
       'primary_caretaker',
       'customer_caretaker',
       'co_agent_caretaker'
     )
     AND p_status IN ('active', 'pending_claim') THEN
    UPDATE public.listings
    SET owner_data_status = 'pending',
        updated_at = now()
    WHERE inventory_id = p_inventory_id
      AND status = 'published'
      AND owner_data_status = 'not_required';
  END IF;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.accept_property_care_right(p_right_id uuid)
RETURNS public.property_care_rights
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.property_care_rights;
  v_uid uuid := auth.uid();
BEGIN
  SELECT * INTO v_row
  FROM public.property_care_rights
  WHERE id = p_right_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'right_not_found';
  END IF;

  IF v_row.user_id <> v_uid THEN
    RAISE EXCEPTION 'not_your_right';
  END IF;

  IF v_row.status <> 'pending_claim' THEN
    RAISE EXCEPTION 'not_pending_claim';
  END IF;

  UPDATE public.property_care_rights
  SET status = 'active', updated_at = now()
  WHERE id = p_right_id
  RETURNING * INTO v_row;

  IF v_row.inventory_id IS NOT NULL
     AND v_row.care_role = 'primary_caretaker' THEN
    UPDATE public.listings
    SET
      owner_id = v_uid,
      listed_by_role = 'owner',
      owner_verified = true,
      platform_has_owner_contact = false,
      updated_at = now()
    WHERE inventory_id = v_row.inventory_id
      AND status = 'published';
  END IF;

  INSERT INTO public.property_care_audits (right_id, action, actor_id, payload)
  VALUES (v_row.id, 'accept_claim', v_uid, '{}'::jsonb);

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_property_owner_data(p_inventory_id uuid)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_count int;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.property_care_rights
    WHERE inventory_id = p_inventory_id
      AND user_id = v_uid
      AND status = 'active'
      AND care_role IN (
        'primary_caretaker',
        'customer_caretaker',
        'co_agent_caretaker',
        'team_steward'
      )
  ) THEN
    RAISE EXCEPTION 'no_care_access';
  END IF;

  UPDATE public.listings
  SET owner_data_status = 'complete', updated_at = now()
  WHERE inventory_id = p_inventory_id
    AND owner_data_status = 'pending';

  GET DIAGNOSTICS v_count = ROW_COUNT;

  INSERT INTO public.property_care_audits (right_id, action, actor_id, payload)
  SELECT id, 'owner_data_complete', v_uid,
         jsonb_build_object('inventory_id', p_inventory_id, 'listings_updated', v_count)
  FROM public.property_care_rights
  WHERE inventory_id = p_inventory_id
    AND user_id = v_uid
    AND status = 'active'
  ORDER BY is_primary DESC
  LIMIT 1;

  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.revoke_property_care_right(p_right_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor uuid := auth.uid();
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'admin_only';
  END IF;

  UPDATE public.property_care_rights
  SET status = 'revoked', is_primary = false, updated_at = now()
  WHERE id = p_right_id;

  INSERT INTO public.property_care_audits (right_id, action, actor_id, payload)
  VALUES (p_right_id, 'revoke', v_actor, '{}'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public.grant_property_care_right TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_property_care_right TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_property_owner_data TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_property_care_right TO authenticated;

COMMENT ON FUNCTION public.grant_property_care_right IS
  'แอดมินมอบสิทธิ์ดูแล — ตั้ง owner_data_status=pending บนประกาศที่เผยแพร่แล้ว';
COMMENT ON FUNCTION public.accept_property_care_right IS
  'ผู้ใช้รับสิทธิ์ pending_claim — โอน owner_id เมื่อเป็นผู้ดูแลหลัก';
COMMENT ON FUNCTION public.complete_property_owner_data IS
  'ผู้ดูแลบันทึกว่าเติมข้อมูลครบแล้ว (สถานะประกาศยัง published)';
