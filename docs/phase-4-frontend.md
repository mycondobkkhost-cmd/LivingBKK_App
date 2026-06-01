# Phase 4: Frontend

**Status:** 4.1 scaffold complete (Flutter)  
**Date:** 2026-06-02

---

## Deliverables

| Item | Location |
|------|----------|
| Flutter app | `mobile/` |
| Theme (purple/white) | `mobile/lib/theme/app_theme.dart` |
| Supabase services | `mobile/lib/services/` |
| Wireframe implementation | Matches `phase-2-wireframes.md` |
| FlutterFlow guide | `flutterflow-setup.md` |

---

## Run the app

```bash
cd mobile
flutter create . --project-name livingbkk --org com.livingbkk
flutter pub get
# Edit assets/env with Supabase credentials
flutter run
```

---

## Supabase tables used (Phase 4.1)

| Feature | API |
|---------|-----|
| Map listings | `listings_public` SELECT |
| Demand board | `demand_posts` SELECT |
| Submit offer | Edge `submit-demand-offer` |
| Smart search | Edge `smart-search-parse` |

---

## Phase 4.2 backlog

- [ ] `google_maps_flutter` + markers from `location_public`
- [ ] Supabase Auth UI (seeker / owner / agent)
- [ ] Insert `leads` from Lead Bot wizard
- [ ] Owner/Agent lead inbox with censored phone view
- [ ] Co-agent request button → `co_agent_requests`
- [ ] Image upload → Storage `listing-images`

---

## Sign-off

- [x] Bottom navigation (5 tabs)
- [x] Map home + draggable sheet + listing cards
- [x] Smart search bar + preview dropdown
- [x] Agent segmented control
- [x] Demand board + blind offer form
- [x] Demo mode without Supabase
- [ ] Production maps + auth (4.2)
