# LivingBKK — คู่มือตั้งค่าทั้งระบบ

ทำตามลำดับนี้ครั้งเดียว แล้วพัฒนา/รันแอปได้

---

## 1. Supabase (Backend)

### 1.1 สร้างโปรเจกต์

1. https://supabase.com/dashboard → **New project**
2. ตั้งรหัสผ่าน DB → รอสร้างเสร็จ

### 1.2 รัน migrations

**แบบ Cloud (แนะนำ):**

```bash
brew install supabase/tap/supabase
cd /Users/angkarn1996/Desktop/LivingBKK_App
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

**แบบ Local (ต้องมี Docker):**

```bash
supabase start
supabase db reset
```

### 1.3 ตั้งค่า Auth

Dashboard → **Authentication** → **Providers** → Email:

- เปิด Email
- ปิด **Confirm email** ชั่วคราว (สะดวกตอนทดสอบ) หรือเปิดแล้วใช้ลิงก์ยืนยัน

### 1.4 Deploy Edge Functions

```bash
supabase functions deploy submit-demand-offer
supabase functions deploy smart-search-parse
supabase functions deploy moderate-listing-text
supabase functions deploy lead-bot-turn
```

### 1.5 คัดลอก API keys

Dashboard → **Settings** → **API**:

- Project URL → `SUPABASE_URL`
- `anon` `public` key → `SUPABASE_ANON_KEY`

---

## 2. แอปมือถือ (Flutter)

### 2.1 ติดตั้ง Flutter

https://docs.flutter.dev/get-started/install/macos  

ตรวจสอบ:

```bash
flutter doctor
```

### 2.2 ตั้งค่า env

แก้ไฟล์ `mobile/assets/env`:

```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbG...
```

### 2.3 รันแอป

```bash
cd mobile
flutter create . --project-name livingbkk --org com.livingbkk
flutter pub get
flutter run
```

- ไม่ตั้ง env → **โหมด Demo** (ข้อมูลตัวอย่าง)
- ตั้ง env แล้ว → ล็อกอิน + ดึงข้อมูลจริงจาก Supabase

---

## 3. GitHub (ทำแล้ว)

Remote: https://github.com/mycondobkkhost-cmd/LivingBKK_App

```bash
git pull
git push
```

---

## 4. Google Maps (Phase 4.3)

1. สร้าง API key ที่ Google Cloud Console  
2. ใส่ `GOOGLE_MAPS_API_KEY` ใน `mobile/assets/env`  
3. ตาม [mobile/docs/MAPS_SETUP.md](../mobile/docs/MAPS_SETUP.md) ใส่ key ใน AndroidManifest / iOS AppDelegate หลัง `flutter create`

---

## 5. Make.com → Google Sheets (Admin)

1. สร้าง Scenario จาก Supabase webhook หรือ scheduled query
2. ดึงจาก view `lead_stats_daily` เท่านั้น — **ไม่ดึงเบอร์โทรเต็ม**

---

## Checklist

- [ ] Supabase project + `db push`
- [ ] Edge functions deployed
- [ ] `mobile/assets/env` ใส่ keys
- [ ] Flutter รันได้
- [ ] สมัคร user ในแอป → ส่ง Lead ทดสอบ
- [ ] Google Maps API key + [MAPS_SETUP.md](../mobile/docs/MAPS_SETUP.md)
- [ ] ตั้ง `profiles.role = admin` สำหรับศูนย์ Admin
- [ ] `supabase db push` รวม migration Realtime
