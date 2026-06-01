# Phase 3: Database Schema & Backend

**Status:** Implemented in `supabase/migrations/`  
**Date:** 2026-06-02

---

## 1. Migration Files (run in order)

| File | Contents |
|------|----------|
| `20260602120000_extensions_and_enums.sql` | PostGIS, enums |
| `20260602120001_profiles.sql` | profiles + auth trigger |
| `20260602120002_geo_zones.sql` | Bangkok metro zones |
| `20260602120003_listings.sql` | listings + derived fields trigger |
| `20260602120004_listing_images.sql` | images |
| `20260602120005_leads.sql` | leads, assignments, `censor_phone()` |
| `20260602120006_co_agent.sql` | co_agent_requests |
| `20260602120007_demand_board.sql` | demand_posts, demand_offers |
| `20260602120008_commission_pm.sql` | tiers, e_contracts, PM |
| `20260602120009_moderation_audit.sql` | flags, audit, `lead_stats_daily` |
| `20260602120010_listings_public_view.sql` | public views |
| `20260602120011_auth_helpers.sql` | `is_admin()`, `get_my_role()` |
| `20260602120012_rls_policies.sql` | RLS (blind demand offers) |
| `20260602120013_storage_buckets.sql` | listing-images, demand-offers |

---

## 2. Key Tables

- **listings** — private fields: `unit_number`, `exact_floor`, `location_exact`
- **listings_public** (view) — safe columns only, `security_invoker`
- **demand_offers** — RLS: `offerer_id = auth.uid()` OR admin only
- **co_agent_eligible** — maintained by trigger `sync_listing_derived_fields`

---

## 3. Edge Functions

| Function | Path | Purpose |
|----------|------|---------|
| `smart-search-parse` | `/functions/v1/smart-search-parse` | NLP → filters (stub) |
| `submit-demand-offer` | `/functions/v1/submit-demand-offer` | Validate capacity + insert offer |
| `moderate-listing-text` | `/functions/v1/moderate-listing-text` | Phone/Line/URL scan |
| `lead-bot-turn` | `/functions/v1/lead-bot-turn` | Qualification step validator |

---

## 4. Local Setup

```bash
# Install Supabase CLI: https://supabase.com/docs/guides/cli
brew install supabase/tap/supabase

cd /Users/angkarn1996/Desktop/LivingBKK_App
cp .env.example .env.local

# Start local stack + apply migrations + seed
supabase start
supabase db reset

# Deploy functions (after linking project)
supabase link --project-ref YOUR_REF
supabase functions deploy submit-demand-offer
supabase functions deploy smart-search-parse
supabase functions deploy moderate-listing-text
supabase functions deploy lead-bot-turn
```

---

## 5. FlutterFlow Integration

| Use case | Supabase target |
|----------|-----------------|
| Map listings | `listings_public` |
| Listing detail (owner) | `listings` (RLS) |
| Demand board feed | `demand_posts` |
| Submit offer | Edge `submit-demand-offer` |
| Smart search | Edge `smart-search-parse` |
| Agent co-agent map | `listings` filter `co_agent_eligible = true` |

---

## 6. Phase 3 Sign-off

- [x] Schema migrations  
- [x] RLS + blind offers  
- [x] Public views  
- [x] Seed (zones, commission tiers)  
- [x] Storage buckets  
- [x] Edge function skeletons  
- [ ] Link production Supabase project  
- [ ] FlutterFlow Phase 4  

**Next:** Phase 4 — FlutterFlow screens per `phase-2-wireframes.md`
