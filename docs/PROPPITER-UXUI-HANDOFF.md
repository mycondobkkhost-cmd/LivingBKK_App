# ส่งมอบงาน UX/UI — รีแบรนด์ PROPPITER

เอกสารนี้สำหรับทำงานต่อใน **โปรเจกต UX/UI** (หรือวางเป็น Cursor rule / ข้อความแรกในแชท)

**แอปหลัก (โค้ดจริง):** `LivingBKK_App` — Flutter + Supabase  
**เป้าหมาย:** รีแบรนด์จาก LivingBKK → **PROPPITER** ทั้งหน้าตาแอป โดย **ไม่กระทบ** logic ธุรกิจ / API / DB

---

## งานที่กำลังจะทำ (scope)

1. **Brand identity** — โลโก้, สี, ฟอนต์, สโลแกัน ไทย/EN  
2. **Design tokens** — ให้ตรง `design/tokens.json` และ theme ใน Flutter  
3. **Asset pipeline** — ไฟล์ PNG ใน `mobile/assets/brand/` + รัน `scripts/sync-brand-assets.py` สร้างไอคอน Android/iOS/Web  
4. **UI ที่เห็นชื่อ/โลโก้** — login, header หน้าแรก, profile, manifest, ข้อความแชร์  
5. **ไม่ทำในรอบนี้ (เว้นแต้ขอ)** — ฟีเจอร์ใหม่, schema Supabase, lead/chat/admin logic, เปลี่ยน bundle id / package name

---

## หลักการ — ไม่กระทบงานเดิม

- **แทนที่รูปทับชื่อไฟล์เดิม** ใน `mobile/assets/brand/` (ไม่ต้องเปลี่ยน path ในโค้ดมาก)  
- **ข้อความและสี** แก้ที่ศูนย์กลาง: `living_bkk_brand.dart`, `app_strings.dart`, `design/tokens.json`  
- **ไม่แตะ:** migrations, RLS, Edge Functions, demo email (`demo-admin@livingbkk.local`), ชื่อ package Dart `livingbkk`

---

## ไฟล์ที่ต้องเตรียม (ส่งเข้า `mobile/assets/brand/`)

| ชื่อไฟล์ | ประเภท | รายละเอียดที่ต้องมี | ใช้กับ |
|----------|--------|---------------------|--------|
| `proppiter-brand-brief.txt` | text | ชื่อ PROPPITER, tagline TH/EN, HEX สี, ฟอนต์ | อัปเดต theme/ข้อความ |
| `logo-mark.png` | PNG โปร่งใส | สัญลักษณ์อย่างเดียว ไม่มีคำ PROPPITER | หัวแอป, คู่ wordmark |
| `app-icon-gradient.png` | PNG 1024² | ไอคอนแอป อ่านง่ายขนาดเล็ก | Store + สคริปต์สร้างไอคอนทุกแพลตฟอร์ม |
| `favicon-256.png` | PNG | ไอคอนเว็บ | Browser tab |
| `logo-lockup-light.png` | PNG โปร่งใส | mark + PROPPITER บนพื้นอ่อน | พื้นขาว, Supabase horizontal logo |
| `logo-lockup-dark.png` | PNG โปร่งใส | mark + PROPPITER บนพื้นเข้ม | header มืด, splash |
| `logo-lockup-compact-light.png` | PNG | mark + ชื่อ ไม่มีสโลแกัน | แถบแคบ |
| `logo-lockup-compact-dark.png` | PNG | เหมือน compact บนพื้นเข้ม | แถบแคบ มืด |
| `logo-lockup.png` | PNG | = light หรือ copy จาก light | default lockup |
| `logo-lockup-en-light.png` / `-en-dark.png` | PNG | ถ้า tagline EN ต่างจาก TH | ภาษาอังกฤษ |
| `proppiter-brand-guide.png` | PNG | แผ่นรวม mark, lockup, สี | อ้างอิงทีม (แทน livingbkk-brand-guide) |

**ไม่ต้องส่ง:** ไอคอน iOS/Android หลายขนาด — สร้างจาก `app-icon-gradient.png` ผ่านสคริปต์

---

## จุดอ้างอิงใน repo หลัก

| หัวข้อ | path |
|--------|------|
| Tokens | `design/tokens.json` |
| สี + สโลแกัน | `mobile/lib/theme/living_bkk_brand.dart` |
| Asset paths | `mobile/lib/theme/brand_assets.dart` |
| Widget โลโก้ | `mobile/lib/widgets/living_bkk_logo.dart` |
| ข้อความ UI | `mobile/lib/l10n/app_strings.dart` |
| Sync icons | `scripts/sync-brand-assets.py` |
| PWA / ชื่อแอปเว็บ | `mobile/web/manifest.json` |
| ชื่อแอป Android | `mobile/android/app/src/main/AndroidManifest.xml` |
| Brand ใน DB (อ่านอย่างเดียว/อัปเดตแถว) | `supabase/migrations/20260602120032_app_brand_settings.sql` |

---

## สถานะปัจจุบัน

- แอปยังแสดง **LivingBKK** (wordmark แยกคำ Living + BKK ในโค้ด)  
- สีหลัก: `#6C5DD3`, `#9B6DFF`, `#FF5B8A`, `#12122B`, `#F7F8FB`  
- โหมดทดลอง (`TRIAL_MODE`) แยกจาก production — รีแบรนด์ไม่ควรพัง flow นี้  
- มี rule แชท Q&A: `.cursor/rules/project-qa.mdc`  
- มี rule แบรนด์ (repo หลัก): `.cursor/rules/project-branding-ux.mdc`

---

## ลำดับงานแนะนำหลังได้ไฟล์จากดีไซน์

1. วาง PNG + `proppiter-brand-brief.txt`  
2. รัน `python3 scripts/sync-brand-assets.py`  
3. อัปเดต `living_bkk_brand.dart`, `tokens.json`, ข้อความ manifest / share  
4. ตรวจหน้า: login, `li_home_header`, `home_browse_layout`, profile  
5. `flutter run` ทั้ง light/dark และภาษา TH/EN  

---

## ข้อความสำหรับวางในโปรเจกต UX/UI (copy ด้านล่าง)

ดูบล็อกใน README ของโปรเจกต uxui หรือ copy จากแชทที่สร้างให้
