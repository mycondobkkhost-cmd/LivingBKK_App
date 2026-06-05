# รันครบชุดในครั้งเดียว

ใช้ไฟล์ **`.env.local`** ที่ root โปรเจกต์ เป็นที่เก็บ key ทั้งหมด แล้วสคริปต์จะ sync ไปแอปให้อัตโนมัติ

---

## ขั้นที่ 1 — สร้าง Supabase (Cloud)

1. เปิด https://supabase.com/dashboard → **New project**
2. รอสร้างเสร็จ → **Settings → API**
3. กดปุ่ม **Connect** (เขียว) → แท็บ **`.env.local`** → Copy:
   - `NEXT_PUBLIC_SUPABASE_URL` → ใส่เป็น `SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` → ใส่เป็น `SUPABASE_ANON_KEY` (คีย์ `sb_publishable_…`)

### อัปโหลด schema

```bash
cd /Users/angkarn1996/Desktop/LivingBKK_App
supabase login
supabase link --project-ref YOUR_PROJECT_REF   # จาก URL: https://app.supabase.com/project/REF
supabase db push
```

### Auth ทดสอบ

Dashboard → **Authentication → Providers → Email**:

- เปิด Email
- **ปิด Confirm email** ชั่วคราว (สะดวกตอนทดสอบ)

### Seed ทรัพย์ (ทางเลือก)

Dashboard → **SQL Editor** → วางรัน `supabase/seed_listings.sql`  
หรือสมัคร user role `owner` แล้วรันไฟล์นั้น

---

## ขั้นที่ 2 — Google Maps API Key

1. https://console.cloud.google.com → สร้าง/เลือกโปรเจกต์ → **เปิด Billing**
2. **APIs & Services → Library** → เปิด:
   - Maps JavaScript API
   - Places API (ค้นหาโครงการ)
3. **Credentials → Create API key**
4. จำกัดแอป (Web):
   - HTTP referrers: `http://localhost:*`, `http://127.0.0.1:*`
5. คัดลอก key → `GOOGLE_MAPS_API_KEY`

---

## ขั้นที่ 3 — ใส่ key ครั้งเดียว

```bash
cd /Users/angkarn1996/Desktop/LivingBKK_App
cp .env.local.example .env.local
# แก้ .env.local ใส่ URL, anon key, Maps key จริง
```

---

## ขั้นที่ 4 — รันสคริปต์

```bash
chmod +x scripts/*.sh
./scripts/setup-all.sh
```

สคริปต์จะ:

1. Sync → `mobile/assets/env` + `mobile/web/index.html`
2. `supabase db push` (ถ้า link แล้ว)
3. `flutter pub get` + ถามว่าจะรัน Chrome หรือไม่

รันแอปเอง:

```bash
source scripts/dev-path.sh
./scripts/sync-env.sh
cd mobile && flutter run -d chrome --web-port=8082
```

---

## ดูแบบหน้าจอมือถือ (Chrome)

1. **อัตโนมัติ (แนะนำ):** หลัง `flutter run` แอปจะอยู่กลางจอ กว้าง ~430px (มือถือ) พื้นหลังเทา  
   ถ้ายังเต็มจอ → กด **`R`** (hot restart) หรือรันใหม่

2. **Chrome DevTools:** `F12` → ไอคอนมือถือ/แท็บเล็ต (Toggle device toolbar) → เลือก **iPhone 14** หรือกำหนด 390×844

3. **มือถือจริง:** เปิด `http://IP-เครื่อง-Mac:8084` บน Safari/Chrome ในมือถือ (Mac กับมือถือ Wi‑Fi เดียวกัน)

---

## ทดสอบว่าครบ

| สิ่งที่เห็น | แปลว่า |
|------------|--------|
| หน้าแรก ~38–72 ทรัพย์ + รูป | Supabase หรือ Demo OK |
| แผนที่ Google + หมุดราคา | Maps key OK |
| ล็อกอินได้ | Supabase Auth OK |
| ไม่ขึ้น InvalidKey ใน Console | `index.html` sync แล้ว |

---

## ปัญหาที่พบบ่อย

**Docker ไม่มีบน Mac** → ใช้ Supabase **Cloud** + `db push` ไม่ใช่ `supabase start`

**แผนที่ยังเทา** → รัน `./scripts/sync-env.sh` อีกครั้ง แล้ว restart `flutter run` (ไม่ใช่แค่ refresh)

**ยังเป็น Demo** → ตรวจ `mobile/assets/env` ไม่มีคำว่า `YOUR_`
