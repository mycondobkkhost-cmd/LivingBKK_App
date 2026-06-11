-- ผู้ใช้เลือกมุมมอง owner/agent ในแอปได้โดยไม่ต้องเปลี่ยน profiles.role
-- จึงให้เจ้าของแถวสร้างประกาศได้เมื่อ created_by_id ตรงกับผู้ใช้ปัจจุบัน
DROP POLICY IF EXISTS listings_insert ON public.listings;
CREATE POLICY listings_insert ON public.listings
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR created_by_id = auth.uid()
  );

-- บังคับ RLS ของตารางต้นทางเมื่ออ่าน view หลังบ้านผ่าน API โดยตรง
ALTER VIEW public.chat_admin_inbox SET (security_invoker = true);
ALTER VIEW public.analytics_platform_stats SET (security_invoker = true);
ALTER VIEW public.client_error_summary SET (security_invoker = true);
