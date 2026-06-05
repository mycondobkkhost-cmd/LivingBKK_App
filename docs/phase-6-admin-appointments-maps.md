# Phase 6: Admin นัดชม + Maps

**Status:** Implemented  
**Date:** 2026-06-02

---

## Delivered

| Feature | Location |
|---------|----------|
| ตาราง `appointments` | `supabase/migrations/20260602120017_appointments.sql` |
| แท็บ Admin **นัดชม** | `AdminAppointmentsTab` + แผนที่ `AppointmentsMap` |
| ประสาน Lead → นัดชม | `/admin/lead/:id` → `AdminLeadDetailPage` |
| แผนที่หน้าทรัพย์ | `ListingDetailPage` ใช้ `ListingsMap` |
| แผนที่ Web | `mobile/web/index.html` + `GOOGLE_MAPS_API_KEY` |
| ซูมอัตโนมัติ | `ListingsMap` / `AppointmentsMap` fit bounds |

---

## Flow Admin

1. แท็บ **ฉัน** → บทบาท **Admin** → **ศูนย์ Admin**
2. แท็บ **Leads** → กด Lead (เห็นคำขอนัดจากลูกค้า)
3. **ประสานงาน / ยืนยันนัดดู** → เลือกวัน/เวลา → บันทึก `appointments`
4. แท็บ **นัดชม** → รายการ + แผนที่หมุดส้ม/ม่วง → เปลี่ยนสถานะ (ยืนยัน/เสร็จ/ยกเลิก)

โหมด Demo (ไม่มี Supabase): Admin เปิดได้ทันที มี Lead + นัดชมตัวอย่าง

---

## ตั้งค่า Google Maps

1. สร้าง API key (Maps JavaScript API + Maps SDK Android/iOS ตามแพลตฟอร์ม)
2. ใส่ใน `mobile/assets/env`:
   ```
   GOOGLE_MAPS_API_KEY=AIza...
   ```
3. **Web (Chrome):** แก้ `mobile/web/index.html` — แทนที่ `YOUR_GOOGLE_MAPS_API_KEY` ด้วย key เดียวกัน
4. Android/iOS ตาม [mobile/docs/MAPS_SETUP.md](../mobile/docs/MAPS_SETUP.md)

---

## Deploy

```bash
supabase db push
```

---

## Next

- ~~Phase 7: Make.com + รายงาน~~ → [phase-7-reporting-push.md](phase-7-reporting-push.md)
- FCM ในแอป (Firebase) — [mobile/docs/FCM_SETUP.md](../mobile/docs/FCM_SETUP.md)
- Marker ราคาบนหมุด (custom overlay)
