-- ผู้ดูแลทรัพย์ (Property Care) ต้องอ่านทะเบียน + อ่าน/แก้ประกาศที่ได้รับมอบ
-- นโยบายเดิมให้เฉพาะแอดมิน/เจ้าของ ทำให้หน้า "ของฉัน" ว่าง และบันทึกข้อมูลเจ้าของไม่ขึ้น

DROP POLICY IF EXISTS property_inventory_care_select ON public.property_inventory;
CREATE POLICY property_inventory_care_select ON public.property_inventory
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.property_care_rights r
      WHERE r.user_id = auth.uid()
        AND r.status IN ('active', 'pending_claim')
        AND r.inventory_id = property_inventory.id
    )
  );

DROP POLICY IF EXISTS listings_select_care ON public.listings;
CREATE POLICY listings_select_care ON public.listings
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.property_care_rights r
      WHERE r.user_id = auth.uid()
        AND r.status IN ('active', 'pending_claim')
        AND (
          r.listing_id = listings.id
          OR (
            r.inventory_id IS NOT NULL
            AND r.inventory_id = listings.inventory_id
          )
        )
    )
  );

DROP POLICY IF EXISTS listings_update_care ON public.listings;
CREATE POLICY listings_update_care ON public.listings
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.property_care_rights r
      WHERE r.user_id = auth.uid()
        AND r.status = 'active'
        AND r.care_role IN (
          'primary_caretaker',
          'customer_caretaker',
          'co_agent_caretaker',
          'team_steward'
        )
        AND (
          r.listing_id = listings.id
          OR (
            r.inventory_id IS NOT NULL
            AND r.inventory_id = listings.inventory_id
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.property_care_rights r
      WHERE r.user_id = auth.uid()
        AND r.status = 'active'
        AND r.care_role IN (
          'primary_caretaker',
          'customer_caretaker',
          'co_agent_caretaker',
          'team_steward'
        )
        AND (
          r.listing_id = listings.id
          OR (
            r.inventory_id IS NOT NULL
            AND r.inventory_id = listings.inventory_id
          )
        )
    )
  );
