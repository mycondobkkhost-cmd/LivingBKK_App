# Phase 4: Frontend

**Status:** 4.3 (Maps, images, listing create)  
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

## Phase 4.2 (current)

- [x] Login / Sign up (`/login`)
- [x] Lead Bot 4-step wizard → `leads` table
- [x] Work tab: my leads, inbox (censored), offers, co-agent requests
- [x] Co-agent request on listing detail (agent + eligible)
- [x] Profile: sign in/out, sync role to `profiles`
- [x] `google_maps_flutter` + markers (`lat`/`lng` on view)
- [x] Image upload → Storage `listing-images`
- [x] Create listing page (draft / publish)
- [ ] FCM full setup (firebase_messaging) — stub `NotificationService`

---

## Sign-off

- [x] Bottom navigation (5 tabs)
- [x] Map home + draggable sheet + listing cards
- [x] Smart search bar + preview dropdown
- [x] Agent segmented control
- [x] Demand board + blind offer form
- [x] Demo mode without Supabase
- [x] Auth + Leads + Work (4.2)
- [x] Google Maps widget (4.3)
- [ ] FCM push (4.4)
