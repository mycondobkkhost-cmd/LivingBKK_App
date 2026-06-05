# LivingBKK Mobile (Flutter)

LivingBKK — Map-first property platform · Bangkok metro · Rent · Buy · Sell.

## Prerequisites

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (Apple Silicon)
2. Xcode (iOS) / Android Studio (optional)
3. Supabase project with migrations applied (see `../docs/phase-3-database.md`)

## First-time setup

```bash
cd mobile

# Generate ios/android/web platform folders (keeps existing lib/)
flutter create . --project-name livingbkk --org com.livingbkk

# Dependencies
flutter pub get

# Configure Supabase — edit assets/env with your project URL + anon key
# SUPABASE_URL=https://xxxx.supabase.co
# SUPABASE_ANON_KEY=eyJ...

flutter run
```

Without Supabase configured, the app runs in **Demo mode** with sample listings and demand posts.

## Project structure

```
lib/
  main.dart                 # Entry + Supabase init
  app.dart                  # MaterialApp + theme
  router/                   # go_router
  shell/main_shell.dart     # Bottom nav (5 tabs)
  features/
    search/map_home_page.dart
    board/                  # Demand board + offer form
    listing/
    work/
    contact/
    profile/
  services/                 # Supabase repositories
  widgets/
  theme/app_theme.dart      # Purple & white
```

## Screens (Phase 4.1)

| Screen | Status |
|--------|--------|
| Map Home + bottom sheet cards | ✅ |
| Smart Search preview | ✅ (Edge Function / demo) |
| Agent co-agent segment | ✅ |
| Demand Board feed + detail | ✅ |
| Submit offer + capacity dropdown | ✅ |
| Listing detail + Lead bot sheet | ✅ |
| Work / Profile tabs | ✅ skeleton |

## Phase 4.2 (included)

- Login / Sign up at `/login`
- Lead Bot 4 steps → Supabase `leads`
- Work tab loads your leads, offers, co-agent requests
- Agent: request co-agent on eligible listings

## Phase 4.3 (next)

- Google Maps Flutter plugin + API key
- Image upload to Storage
- Push notifications (FCM)

## FlutterFlow

If you use FlutterFlow instead of this codebase, see [../docs/flutterflow-setup.md](../docs/flutterflow-setup.md).
