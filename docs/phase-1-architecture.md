# Phase 1: System Architecture & Roadmap

**LivingBKK** — แพลตฟอร์มอสังหาริมทรัพย์ กทม. + ปริมณฑล  
**Version:** 1.0 · **Date:** 2026-06-02

---

## 1. Executive Summary

| หัวข้อ | กำหนด |
|--------|--------|
| ผลิตภัณฑ์ | เช่า / ซื้อ / ขาย |
| พื้นที่ | กรุงเทพฯ + ปริมณฑล |
| ไม่ทำ | Booking รายวัน |
| โมเดล | ตัวกลาง 100% — ไม่เปิดเบอร์/Line โดยตรง |
| รายได้ | Success Fee เท่านั้น (โพสต์ประกาศฟรี) |
| Roles | Owner, Agent, Admin, Seeker |

---

## 2. Design Principles

1. **Map-first** — แผนที่เป็นหน้าหลัก, Advanced Filter ซ่อนใน drawer  
2. **Net price only (public)** — ราคารวมคอมแล้วตอนลง; ผู้ชมเห็นแค่ราคาสุดท้าย  
3. **Location privacy** — ไม่แสดงเลขห้อง/ชั้น; pin สาธารณะแบบ approximate  
4. **Blind intermediation** — Lead, Co-agent request, Demand offers ไม่เปิดเผยต่อผู้ใช้รายอื่น  
5. **Contract gate** — รับเคส / co-agent ที่อนุมัติ → E-Contract ก่อนเริ่มงาน  
6. **AI as backend service** — Smart Search, Lead Bot, Moderation ผ่าน Edge Functions เท่านั้น  

---

## 3. Technology Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Client | **FlutterFlow** | Map, bottom nav, role-based UI, iOS/Android/Web |
| Backend | **Supabase** | PostgreSQL + PostGIS, RLS, Realtime, Storage |
| Maps | Google Maps Platform | โซน กทม., BTS distance |
| AI | OpenAI/Gemini via Edge Functions | ไม่ expose API keys ใน client |
| Admin analytics | Make.com → Google Sheets | สถิติ/Lead — ไม่ sync PII เต็ม |

**Development environment:** Mac Mini M2 (Apple Silicon), AI-assisted development

---

## 4. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  FlutterFlow App (Seeker / Owner / Agent)  │  Admin Web    │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│  Supabase Auth │ Edge Functions │ RLS                        │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│  PostgreSQL + PostGIS │ Storage │ Realtime                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   Google Maps          FCM Push           E-Contract
        │                   │                   │
        └───────────────────┴───────────────────┘
                            │
                      Make.com → Sheets
```

---

## 5. Bounded Contexts

| Context | Responsibility |
|---------|----------------|
| **Listings** | CRUD, net pricing, killer filters, yield tag, lifecycle (bump/hide/expire) |
| **Discovery** | Map, clustering, advanced filters, AI smart search |
| **Leads** | Qualification bot, censored push, accept/decline, availability dates |
| **Co-Agent** | `co_agent_eligible`, agent map mode, requests, E-Contract |
| **Demand Board** | Admin posts, blind offers, capacity dropdown, Seeker visibility |
| **Trust** | Text moderation, image dedup, audit log |
| **PM** | Annual package, commission tiers |

---

## 6. Role Capabilities Matrix

| Capability | Seeker | Owner | Agent | Admin |
|------------|:------:|:-----:|:-----:|:-----:|
| Map + search + AI | ✓ | ✓ | ✓ | ✓ |
| Net price, hidden unit/floor | ✓ | ✓ | ✓ | ✓ |
| Lead bot (นัดชม) | ✓ | — | — | — |
| Manage own listings | — | ✓ | ✓* | ✓ |
| Map mode「ขอโคเอเจ้นท์ได้」 | — | — | ✓ | ✓ |
| Request co-agent on eligible listing | — | — | ✓ | ✓ |
| Receive leads + E-Contract | — | ✓ | ✓ | ✓ |
| View Demand Board | ✓ | ✓ | ✓ | ✓ |
| Submit demand offer | ✓** | ✓ | ✓ | ✓ |
| See others' demand offers | — | — | — | ✓ |
| Moderation / owner contact flags | — | — | — | ✓ |

\* ตามนโยบายสิทธิ์ลงทรัพย์  
\*\* บังคับ dropdown + `capacity_verified` โดย Admin

---

## 7. Co-Agent Eligibility (Agent View)

```
co_agent_eligible = TRUE when:
  (listed_by_role = 'owner' AND owner_verified = TRUE)
  OR
  (platform_has_owner_contact = TRUE AND owner_co_agent_opt_in = TRUE)

co_agent_eligible = FALSE when:
  listed_by_role = 'agent' AND platform_has_owner_contact = FALSE
  OR co_agent_slot_status = 'assigned'
  OR listing.status != 'published'
```

**Agent UI:** Segmented control — `ทั้งหมด | ขอโคเอเจ้นท์ได้ | งานของฉัน`

---

## 8. Demand Board (Blind Offers)

```
Admin creates demand_post
    → Seeker / Owner / Agent read feed (no offer counts)
    → User taps「เสนอทรัพย์」
    → Mandatory dropdown: owner_direct_100 | co_agent_50_50 | listing_agent
    → In-app (photos + details) OR external_link (e.g. Facebook)
    → demand_offers (RLS: only self + admin)
    → Admin inbox → verify → create listing / close post
```

**Privacy:** No API to list offers by `demand_post_id` for non-admin users.

---

## 9. Core Data Entities (Preview for Phase 3)

| Table | Purpose |
|-------|---------|
| `profiles` | role, display, push token |
| `listings` | property + private fields (unit, exact floor, exact geo) |
| `listings_public` | view — censored fields |
| `listing_images` | storage + perceptual_hash |
| `leads` | qualification data |
| `lead_assignments` | accept/decline, dates |
| `co_agent_requests` | agent requests on eligible listings |
| `demand_posts` | board announcements |
| `demand_offers` | blind offers + `offerer_capacity` |
| `commission_tiers` | contract duration → split |
| `e_contracts` | signed agreements |
| `moderation_flags` | text/image issues |
| `admin_audit_log` | compliance |

---

## 10. Edge Functions Plan

| Function | Purpose |
|----------|---------|
| `smart-search-parse` | NLP → filter entities + preview |
| `lead-bot-turn` | Chat + mandatory field validation |
| `moderate-listing-text` | Detect phone/line/external URLs |
| `compute-yield` | Annual yield % for investor listings |
| `listing-lifecycle-cron` | Expire, auto-hide, bump rules |
| `route-lead-notification` | FCM with censored payload |
| `submit-demand-offer` | Validate capacity dropdown + RLS insert |
| `image-dedup-hash` | Perceptual hash on upload |

---

## 11. Security & RLS Summary

| Data | Public/Seeker | Owner/Agent (assigned) | Admin |
|------|---------------|------------------------|-------|
| Owner phone/Line | ✗ | ✗ (via platform) | ✓ |
| unit_number, exact_floor | ✗ | Policy after contract | ✓ |
| Full lead phone | ✗ | censored → per policy | ✓ |
| Others' demand_offers | ✗ | ✗ | ✓ |
| offerer_capacity on feed | ✗ | own offers only | ✓ |

---

## 12. Roadmap

| Sprint | Goal | Deliverables |
|--------|------|--------------|
| **P1** ✅ | Architecture + Roadmap | This document |
| **P2** ✅ | Wireframes | `phase-2-wireframes.md` |
| **S0** | Foundation | Supabase, Auth, roles, geo_zones, design tokens |
| **S1** | Listings MVP | CRUD, net price, fuzzy map, killer filters |
| **S2** | Discovery | Bottom sheet, filters, clustering |
| **S3** | AI Search | NLP bar + real-time preview |
| **S4** | Lead Bot + Push | Qualification, censored push |
| **S5** | E-Contract | Commission tiers, accept gate |
| **S6** | Co-Agent | Eligible filter, requests |
| **S7** | Demand Board | Posts, blind offers, capacity dropdown |
| **S8** ✅ | Moderation | Text AI, image dedup, lifecycle — [phase-11-production-complete.md](phase-11-production-complete.md) |
| **S9** | Admin + Make | Dashboard, Sheets sync |
| ~~**S10**~~ | ~~PM Package~~ | ยกเลิก — โพสต์ฟรีทุกคน |

---

## 13. Open Decisions (Lock before build)

| # | Topic | Recommendation |
|---|-------|----------------|
| 1 | E-Contract vendor | Select before S5 |
| 2 | Metro polygon | Define in `geo_zones` seed |
| 3 | Yield formula | `(monthly_rent × 12) / sale_price × 100` |
| 4 | Seeker can submit board offers | Yes + Admin verify |

---

## 14. Repository Structure

```
LivingBKK_App/
├── README.md
├── docs/
│   ├── phase-1-architecture.md   ← this file
│   ├── phase-2-wireframes.md
│   └── business-rules.md
├── design/
│   └── tokens.json
└── supabase/                     ← Phase 3
    ├── migrations/
    ├── seed/
    └── functions/
```

---

## Phase 1 Sign-off

- [x] Architecture defined  
- [x] Bounded contexts & roles  
- [x] Co-agent eligible rules  
- [x] Demand board + blind offers + capacity dropdown  
- [x] Roadmap S0–S9 (โพสต์ฟรี — ไม่มีแพ็ก subscription)  
- [ ] Supabase project created (Phase 3)  

**Next:** Phase 3 — Database migrations + RLS
