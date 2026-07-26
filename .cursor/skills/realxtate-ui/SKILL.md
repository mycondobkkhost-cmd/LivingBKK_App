---
name: realxtate-ui
description: >-
  Design and refine Flutter UI for RealXtate (LivingBKK_App) so screens match
  the existing brand, map-first product, and design tokens — not generic AI SaaS
  look. Use when changing UI, layout, colors, typography, headers, listing cards,
  home/search/detail screens, admin chrome, or when the user asks for prettier /
  less AI-looking UI in this repo.
---

# RealXtate UI

Flutter + Supabase property marketplace for Bangkok. Brand: **RealXtate** (not PROPPITER / LivingBKK in user-facing copy).

## Before writing UI

1. Read `design/tokens.json` and `mobile/lib/theme/living_bkk_brand.dart`
2. Open a **nearby screen** in `mobile/lib/` and match spacing, radius, and header patterns
3. For anti-generic craft (hierarchy, anti-patterns), also apply personal skill **ui-design-brain** — then translate ideas into **Flutter widgets**, not React/Tailwind
4. Preview: `http://127.0.0.1:7357/?preview=1` (dev server via `./scripts/restart-cursor-dev.sh`). Prefer hot reload over restart

## Visual direction (must match product)

| Do | Don't |
|----|--------|
| Map-first, net price, Thai-friendly mobile density | Generic SaaS dashboard / sidebar-first |
| Primary red `#EE4D2D`, accent orange `#F58220` from tokens | Purple-on-white / indigo gradients, neon glow |
| Prompt / Noto Sans Thai via theme | Default Inter/Roboto/system stacks as “design” |
| One clear job per section; header brand strong | Pill clusters, fake stats strips, emoji decoration |
| Cards only when they wrap **interaction** (listing tap, form) | Cards everywhere / inset hero media collage |
| Respect Dynamic Island / safe areas (`IosDeviceLayout`, `page_safe_insets`) | Hard-coded top padding that clips under island |

Tone: marketplace (Shopee-like density OK on home) + trust for real estate — clean, energetic red header, not luxury-serif brochure or purple “AI startup”.

## Code sources of truth

- Colors / type: `design/tokens.json`, `mobile/lib/theme/living_bkk_brand.dart`
- Brand assets: `mobile/lib/` brand widgets + `mobile/assets/brand/`
- Strings: `app_strings` / i18n — user copy = **RealXtate**
- Device frame / preview: `mobile/lib/widgets/iphone_device_frame.dart`, `mobile_viewport_shell.dart`
- Branding rule (extra): `.cursor/rules/project-branding-ux.mdc`

## Implementation rules

- Prefer existing widgets/theme over one-off colors (`Color(0xFF…)`)
- Keep changes scoped to UI files; do not rewrite lead/map/chat business logic unless asked
- TH/EN: follow existing locale patterns on the screen you edit
- Light theme is primary; if touching dark tokens, keep contrast readable
- After visual changes: save → confirm in Simple Browser `?preview=1`

## Checklist before done

- [ ] Uses brand primary/accent (or existing theme aliases), not new random palette
- [ ] Safe area / island OK on iPhone 17 Pro Max preview
- [ ] No PROPPITER in new copy
- [ ] Layout matches sibling screens (padding 8/12/16 rhythm already in app)
- [ ] Feels RealXtate marketplace — not stock “AI landing page”

## Out of scope unless user asks

Lead matching, map algorithms, migrations, package rename `livingbkk`, commit/deploy.
