# Phase 19: แจ้งเตือนประกาศ + Lifecycle (Push นอกแอป)

**Status:** Implemented  
**Migration:** `20260602120031_listing_lifecycle_push.sql`

---

## นโยบาย (ตามที่เจ้าของ/เอเจนซี่ต้องการ)

| ช่วงเวลา | ระบบทำอะไร |
|----------|-------------|
| **ทุก 7 วัน** | Push (FCM) + แบนเนอร์ในแอป → กด「ยืนยันว่าง」= bump |
| **ครบ 30 วัน** ไม่ยืนยัน | เก็บประกาศ (`status = archived`, `closed_reason = stale_30d`) + Push แจ้ง owner |
| **ปิดการขาย/เช่าเอง** | เก็บทันที — ไม่รอ 30 วัน |
| **เช่า** | ระบุ `available_again` ก่อนเก็บ |
| **ขาย** | `reuse_blocked = true` — ไม่นำกลับมาเป็นประกาศเดิม |
| **ลบถาวร (UI)** | `owner_deleted_at` — ซ่อนจาก「ประกาศของฉัน」แต่ **แถวใน DB ยังอยู่** |

---

## ในแอป (ฟรี — ไม่ต้อง Firebase)

- แบนเนอร์สีเหลืองบนหน้าแรก (`ListingBumpReminderBanner`)
- หน้า `/listings/mine` — ยืนยันว่าง / ปิดขาย-เช่า / ลบจากรายการ
- SnackBar เมื่อแอดมินตอบแชท (Supabase Realtime)

---

## Push นอกแอป (เหมือน LINE — iOS/Android)

1. ตั้ง `FIREBASE_*` ใน `.env.local` → `./scripts/sync-env.sh`
2. Supabase Edge secret: `FCM_SERVER_KEY`
3. ล็อกอินแอบบนมือถือ → token ไป `profiles.fcm_token`

**ส่ง Push จาก:**

| เหตุการณ์ | Edge / Cron |
|-----------|-------------|
| ยืนยันว่างทุก 7 วัน | `listing-lifecycle-cron` |
| เก็บอัตโนมัติ 30 วัน | `listing-lifecycle-cron` |
| แอดมินตอบแชท | `chat-admin-reply` |
| Lead / นัดชม | `route-lead-notification`, `notify-appointment` |

**Web (Chrome):** ไม่มี push นอกแอป — ใช้ Realtime ตอนเปิดแอปอยู่เท่านั้น

---

## Cron (บังคับ production)

Supabase Dashboard → Edge Functions → `listing-lifecycle-cron` → Schedule **รายวัน** (เช่น 09:00 กรุงเทพ)

```http
POST {SUPABASE_URL}/functions/v1/listing-lifecycle-cron
Authorization: Bearer {CRON_SECRET}
```

---

## RPC สำหรับ owner

- `owner_close_listing_rent(listing_id, available_again)`
- `owner_close_listing_sale(listing_id)`
- `owner_soft_delete_listing(listing_id)` — เฉพาะ `archived`

---

## Deploy

```bash
./scripts/deploy-all.sh
```

---

## ทดสอบ

1. ลงประกาศ → ไป `/listings/mine` → กด「ยืนยันว่าง」
2. ปิดเช่า → เลือกวันว่างอีกครั้ง → อยู่ใน「เก็บในคลัง」
3. ปิดขาย → ข้อความ「ไม่นำกลับมาใช้เป็นประกาศเดิม」→ ลบจากรายการ
4. มือถือ + Firebase → รอ cron หรือให้แอดมินตอบแชท → ได้ push นอกแอป
