# Phase 8: Seed ทรัพย์ + หมุดราคาบนแผนที่

**Status:** Implemented  
**Date:** 2026-06-02

---

## Delivered

| Feature | Location |
|---------|----------|
| Seed ~38 ทรัพย์ + รูป | `supabase/seed_listings.sql` (สร้างด้วย `tool/generate_seed_listings.dart`) |
| Demo owner (local) | `supabase/seed.sql` — `demo-owner@livingbkk.local` / `demo12345` |
| รูปใน `listings_public` | migration `20260602120019_listings_public_images.sql` |
| หมุดราคาแบบ wireframe | `MapPriceMarker` + `ListingsMap` |
| FCM hook หลังล็อกอิน | `NotificationService.registerIfPossible()` |

---

## รัน Seed (Supabase local)

```bash
cd LivingBKK_App
supabase db reset
```

หรือหลังมี user owner แล้ว:

```bash
psql "$DATABASE_URL" -f supabase/seed_listings.sql
```

สร้าง seed ใหม่จากโครงการ:

```bash
dart run tool/generate_seed_listings.dart
```

---

## ทดสอบแอปกับ Supabase

1. ใส่ `SUPABASE_URL` + `SUPABASE_ANON_KEY` ใน `mobile/assets/env`
2. `supabase db reset` (ได้ demo owner + listings)
3. ล็อกอิน `demo-owner@livingbkk.local` / `demo12345`
4. หน้าแรก → แผนที่ (ต้องมี Google Maps key) → หมุดม่วงมีราคา

---

## หมุดราคา

เมื่อ `showPriceOnMarker: true` (หน้าแรกโหมดแผนที่) แสดงป้ายม่วง เช่น `฿25k/ด` แทนหมุด default

---

## Next

- ~~Marker clustering เมื่อซูมออก~~ → [phase-9-discovery-smart-search.md](phase-9-discovery-smart-search.md)
- ติด `firebase_messaging` สำหรับ push นอกแอป (iOS/Android) — Phase 10
