# LivingBKK — สิ่งที่ทำแล้ว vs เหลืออยู่

อัปเดตหลัง **Phase 21 + PPTR inventory** (2026-06-04) — ดู [PRE-PUSH-STATUS.md](PRE-PUSH-STATUS.md)

---

## ทำครบแล้ว (Phase 1–11)

| หมวด | รายละเอียด |
|------|------------|
| ออกแบบ | Architecture, Wireframes, Business rules |
| Backend | Migrations, RLS, Edge Functions หลัก, Views รายงาน |
| แอป Flutter | Map-first, ค้นหา, ลงประกาศ, Lead, E-Contract, Co-Agent |
| บอร์ด | Demand posts + blind offers + Admin ตรวจ |
| Admin | Leads, นัดชม, รายงาน, Moderation, สร้างบอร์ด |
| แผนที่ | Google + OSM fallback, หมุดราคา, cluster |
| Discovery | Smart Search preview, Killer filters |
| Push | Realtime ในแอป + FCM (ทางเลือก) |
| โมเดล | โพสต์ฟรี, Success Fee, ไม่มีแพ็ก 20k |
| Ops | `deploy-all.sh`, `seed-cloud.sh`, PRODUCTION-CHECKLIST |
| UX Web | จอมือถือกลางจอ (`MobileViewportShell`) |
| เฟส 12–13 | AI Search + Security + เว็บมือถือ / ติดจอโฮม |

---

## เหลือ — ต้องทำเอง / ตั้งค่า (ยังไม่ใช่โค้ด)

| ลำดับ | รายการ | วิธีทำ |
|-------|--------|--------|
| 1 | **Supabase Cloud จริง** | `deploy-all.sh` + `seed-cloud.sh` + [บัญชี-admin.md](บัญชี-admin.md) |
| 2 | **Google Maps key** | `.env.local` → `sync-env.sh` (ไม่มี = OSM) |
| 3 | **Firebase FCM** | `FIREBASE_*` + `FCM_SERVER_KEY` (ไม่บังคับ) |
| 4 | **Make.com → Sheets** | [MAKECOM.md](MAKECOM.md) |
| 5 | **Cron lifecycle** | เรียก `listing-lifecycle-cron` รายวัน |
| 6 | **ทดสอบ E2E** | [PRODUCTION-CHECKLIST.md](PRODUCTION-CHECKLIST.md) |

---

## เหลือ — พัฒนาต่อ (Phase 12+)

| Phase | หัวข้อ | สถานะ |
|-------|--------|--------|
| **12** | AI Search + กัน self-admin | ✅ [phase-12-ai-and-security.md](phase-12-ai-and-security.md) |
| **13** | เว็บมือถือ + ติดจอโฮม + build-web | ✅ [phase-13-เปิดใช้บนมือถือ.md](phase-13-เปิดใช้บนมือถือ.md) |
| **14** | LI-inspired (Match, Compare, Notify Me, Near Me) | ✅ [phase-14-li-inspired-features.md](phase-14-li-inspired-features.md) |
| **15** | App Store / Play Store + Firebase มือถือจริง | ✅ [phase-15-app-store-firebase.md](phase-15-app-store-firebase.md) |
| **16** | Chat Ops — รับงาน / มอบหมาย / SLA | ✅ [phase-16-chat-ops.md](phase-16-chat-ops.md) |
| **17** | ทะเบียนโครงการ + ฟอร์มลงประกาศ LI-style | ✅ [phase-17-property-projects.md](phase-17-property-projects.md) |
| **20** | PPTR ทะเบียนทรัพย์รวม (dedupe + เจ้าของลำดับ 1) | ✅ [phase-20-property-inventory.md](phase-20-property-inventory.md) |
| **20b** | Exclusive เจ้าของ/เอเจ้นท์ + auto bump | ✅ [phase-20-exclusive-listings.md](phase-20-exclusive-listings.md) |
| **21** | เปิดห้องนัดดู (`viewing_access`) | ✅ [phase-21-viewing-access.md](phase-21-viewing-access.md) |
| 17 | E-Contract ผู้ให้บริการจริง (ลายเซ็นดิจิทัล) | UI มี · vendor ยังไม่เลือก |
| 18 | Lead Bot สนทนาเต็มรูปแบบ | มีแชททรัพย์ · ฟอร์มลีดยังต่อ |
| — | FlutterFlow export | คู่มือ [flutterflow-setup.md](flutterflow-setup.md) เท่านั้น |
| — | geo_zones polygon ละเอียด | ตอนนี้ใช้ center + alias |
| — | Web Push (VAPID) | ทางเลือก |

---

## Sprint จาก Phase 1 (เทียบ)

| Sprint | สถานะ |
|--------|--------|
| S0 Foundation | ✅ |
| S1 Listings MVP | ✅ |
| S2 Discovery | ✅ (Phase 9) |
| S3 AI Search | 🟡 stub + Phase 12 OpenAI ทางเลือก |
| S4 Lead + Push | ✅ (FCM ทางเลือก) |
| S5 E-Contract | 🟡 ในแอป · vendor ภายนอกยังไม่มี |
| S6 Co-Agent | ✅ |
| S7 Demand Board | ✅ |
| S8 Moderation | ✅ Phase 11 |
| S9 Admin + Make | 🟡 แอปครบ · Make ตั้งเอง |
| ~~S10 PM 20k~~ | ❌ ยกเลิก |

---

## แนะนำลำดับถัดไป

1. **ตั้ง Cloud + seed + admin** (ถ้ายังไม่ทำ)  
2. **Phase 12** deploy (`db push` + `smart-search-parse`)  
3. **ทดสอบ checklist** ทีละข้อ  
4. **Phase 13** `./scripts/build-web.sh` → อัปโหลด Netlify → ส่งลิงก์ให้มือถือ  
5. **Phase 15** `./scripts/build-android.sh` / `build-ios.sh` + Firebase → Store  

```bash
source scripts/dev-path.sh
./scripts/deploy-all.sh
./scripts/verify-ready.sh
```
