# ใส่ Google Maps API key (ครั้งเดียว)

**ผมสร้าง key แทนคุณไม่ได้** — ต้องใช้บัญชี Google ของคุณ (โปรเจกต `livingbkk` มีใน Console แล้ว)

## 1) สร้าง key (5 นาที)

1. เปิด [Google Maps Platform → Keys & Credentials](https://console.cloud.google.com/google/maps-apis/credentials?project=livingbkk)
2. ถ้ายังไม่เคยเปิด Maps Platform → กด **Get Started** / ผูก billing (มี free tier ~\$200/เดือน)
3. เปิด API ให้ครบ:
   - **Maps JavaScript API** (แผนที่ Web)
   - **Places API (New)** ← geocode ชื่อโครงการ LI ([เปิดที่นี่](https://console.cloud.google.com/marketplace/product/google/places.googleapis.com?project=livingbkk))
4. **Create credentials → API key** → Copy คีย์ (`AIzaSy...`)

## 2) ผูกเข้า RealXtate (คำสั่งเดียว)

```bash
cd /Users/angkarn1996/Desktop/LivingBKK_App
./scripts/setup-google-maps.sh AIzaSy...วางคีย์ตรงนี้
```

สคริปต์จะ:
- ใส่ใน `.env.local`
- sync ไป `mobile/assets/env` + `mobile/web/index.html`
- ตั้ง `GOOGLE_MAPS_API_KEY` บน **Supabase Edge** (geocode fallback ลิงก์สั้น)

## 3) ตรวจว่าใช้ได้

```bash
./scripts/verify-google-maps-key.sh
```

## 4) ดูใน preview

```bash
./scripts/restart-cursor-dev.sh
```

เปิด Admin → นำเข้า → เพิ่มโครงการ → วางลิงก์ goo.gl → **ดึงพิกัดและชื่อจากลิงก์**

---

**ส่ง key มาในแชทได้** — ผมรัน `setup-google-maps.sh` ให้ (อย่า commit key ลง git)
