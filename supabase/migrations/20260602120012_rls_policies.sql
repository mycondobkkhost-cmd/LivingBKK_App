-- LivingBKK: Row Level Security

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.geo_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listing_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.co_agent_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demand_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demand_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demand_offer_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.e_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_management_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

-- profiles
CREATE POLICY profiles_select_own ON public.profiles
  FOR SELECT TO authenticated
  USING (id = auth.uid() OR public.is_admin());

CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid() OR public.is_admin())
  WITH CHECK (id = auth.uid() OR public.is_admin());

-- geo_zones: read for all authenticated + anon
CREATE POLICY geo_zones_select ON public.geo_zones
  FOR SELECT TO authenticated, anon
  USING (is_active = true);

CREATE POLICY geo_zones_admin_all ON public.geo_zones
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- listings
CREATE POLICY listings_select ON public.listings
  FOR SELECT TO authenticated, anon
  USING (
    public.is_admin()
    OR owner_id = auth.uid()
    OR created_by_id = auth.uid()
    OR (
      status = 'published'
      AND (expires_at IS NULL OR expires_at > now())
    )
  );

CREATE POLICY listings_insert ON public.listings
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR (
      public.get_my_role() IN ('owner', 'agent')
      AND created_by_id = auth.uid()
    )
  );

CREATE POLICY listings_update ON public.listings
  FOR UPDATE TO authenticated
  USING (
    public.is_admin()
    OR owner_id = auth.uid()
    OR created_by_id = auth.uid()
  )
  WITH CHECK (
    public.is_admin()
    OR owner_id = auth.uid()
    OR created_by_id = auth.uid()
  );

CREATE POLICY listings_delete ON public.listings
  FOR DELETE TO authenticated
  USING (public.is_admin() OR owner_id = auth.uid());

-- listing_images (via listing ownership)
CREATE POLICY listing_images_select ON public.listing_images
  FOR SELECT TO authenticated, anon
  USING (
    EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = listing_id
        AND (
          public.is_admin()
          OR l.owner_id = auth.uid()
          OR l.created_by_id = auth.uid()
          OR (l.status = 'published' AND (l.expires_at IS NULL OR l.expires_at > now()))
        )
    )
  );

CREATE POLICY listing_images_mutate ON public.listing_images
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = listing_id
        AND (public.is_admin() OR l.owner_id = auth.uid() OR l.created_by_id = auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = listing_id
        AND (public.is_admin() OR l.owner_id = auth.uid() OR l.created_by_id = auth.uid())
    )
  );

-- leads
CREATE POLICY leads_insert ON public.leads
  FOR INSERT TO authenticated
  WITH CHECK (seeker_id = auth.uid() OR seeker_id IS NULL OR public.is_admin());

CREATE POLICY leads_select ON public.leads
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR seeker_id = auth.uid()
    OR assigned_to = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = listing_id
        AND (l.owner_id = auth.uid() OR l.created_by_id = auth.uid())
    )
  );

CREATE POLICY leads_update ON public.leads
  FOR UPDATE TO authenticated
  USING (public.is_admin() OR assigned_to = auth.uid())
  WITH CHECK (public.is_admin() OR assigned_to = auth.uid());

-- lead_assignments
CREATE POLICY lead_assignments_select ON public.lead_assignments
  FOR SELECT TO authenticated
  USING (public.is_admin() OR assignee_id = auth.uid());

CREATE POLICY lead_assignments_insert ON public.lead_assignments
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() OR assignee_id = auth.uid());

-- co_agent_requests
CREATE POLICY co_agent_requests_select ON public.co_agent_requests
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR requesting_agent_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = listing_id AND l.owner_id = auth.uid()
    )
  );

CREATE POLICY co_agent_requests_insert ON public.co_agent_requests
  FOR INSERT TO authenticated
  WITH CHECK (
    public.get_my_role() IN ('agent', 'admin')
    AND requesting_agent_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.listings l
      WHERE l.id = listing_id
        AND l.co_agent_eligible = true
        AND l.status = 'published'
    )
  );

CREATE POLICY co_agent_requests_update ON public.co_agent_requests
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- demand_posts: all authenticated can read; admin writes
CREATE POLICY demand_posts_select ON public.demand_posts
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY demand_posts_admin_write ON public.demand_posts
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- demand_offers: BLIND — only self + admin
CREATE POLICY demand_offers_select_own ON public.demand_offers
  FOR SELECT TO authenticated
  USING (offerer_id = auth.uid() OR public.is_admin());

CREATE POLICY demand_offers_insert ON public.demand_offers
  FOR INSERT TO authenticated
  WITH CHECK (
    offerer_id = auth.uid()
    AND offerer_capacity IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.demand_posts dp
      WHERE dp.id = demand_post_id AND dp.status = 'open'
    )
  );

CREATE POLICY demand_offers_update_admin ON public.demand_offers
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- demand_offer_images
CREATE POLICY demand_offer_images_select ON public.demand_offer_images
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.demand_offers o
      WHERE o.id = demand_offer_id AND o.offerer_id = auth.uid()
    )
  );

CREATE POLICY demand_offer_images_insert ON public.demand_offer_images
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.demand_offers o
      WHERE o.id = demand_offer_id AND o.offerer_id = auth.uid()
    )
  );

-- commission_tiers: read all, admin write
CREATE POLICY commission_tiers_select ON public.commission_tiers
  FOR SELECT TO authenticated
  USING (is_active = true OR public.is_admin());

CREATE POLICY commission_tiers_admin ON public.commission_tiers
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- e_contracts
CREATE POLICY e_contracts_select ON public.e_contracts
  FOR SELECT TO authenticated
  USING (signer_id = auth.uid() OR public.is_admin());

CREATE POLICY e_contracts_insert ON public.e_contracts
  FOR INSERT TO authenticated
  WITH CHECK (signer_id = auth.uid() OR public.is_admin());

-- PM subscriptions
CREATE POLICY pm_select ON public.property_management_subscriptions
  FOR SELECT TO authenticated
  USING (owner_id = auth.uid() OR public.is_admin());

CREATE POLICY pm_admin_write ON public.property_management_subscriptions
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- moderation & audit: admin only
CREATE POLICY moderation_admin ON public.moderation_flags
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY audit_admin ON public.admin_audit_log
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Grant view access (inherits listings RLS via security_invoker)
GRANT SELECT ON public.listings_public TO authenticated, anon;
GRANT SELECT ON public.leads_for_assignee TO authenticated;
GRANT SELECT ON public.lead_stats_daily TO authenticated;
