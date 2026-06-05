# Phase 7: รายงาน + Make.com + Push

**Status:** Implemented  
**Date:** 2026-06-02

---

## Delivered

| Feature | Location |
|---------|----------|
| View `appointment_stats_daily` | migration `20260602120018_phase7_reporting_notifications.sql` |
| View `platform_stats_daily` | รวม Lead + นัดชม (ไม่มี PII) |
| Edge `notify-appointment` | แจ้ง owner + Make.com เมื่อยืนยันนัด |
| Edge `route-lead-notification` | + FCM (ถ้ามี key) + Make.com webhook |
| แท็บ Admin **รายงาน** | `AdminReportsTab` — สถิติ + คัดลอก TSV |
| Realtime นัดชม | `RealtimeService` ฟังตาราง `appointments` |

---

## Make.com

### Scheduled export (แนะนำ)

REST:

```
GET {SUPABASE_URL}/rest/v1/platform_stats_daily?order=stat_date.desc&limit=7
Headers:
  apikey: {SERVICE_ROLE_KEY}
  Authorization: Bearer {SERVICE_ROLE_KEY}
```

→ Google Sheets Append row

รายละเอียด: [MAKECOM.md](MAKECOM.md)

### Webhook ทันที (ทางเลือก)

ตั้ง secret ใน Supabase Edge Functions:

```
MAKECOM_WEBHOOK_URL=https://hook.eu1.make.com/...
```

Events (ไม่มีเบอร์โทร):

- `lead_routed`
- `appointment_scheduled`

---

## FCM (Phase 4.5 ต่อ)

1. Firebase project + `firebase_messaging` ในแอป  
2. เก็บ token → `profiles.fcm_token` ผ่าน `NotificationService.saveFcmToken`  
3. ตั้ง `FCM_SERVER_KEY` (Legacy HTTP) ใน Edge Function secrets  

จนกว่าจะตั้ง FCM — ใช้ **Realtime + SnackBar** ในแอปเมื่อเปิดอยู่

---

## Deploy

```bash
supabase db push
supabase functions deploy route-lead-notification
supabase functions deploy notify-appointment
```

Secrets (Dashboard → Edge Functions):

- `MAKECOM_WEBHOOK_URL` (optional)
- `FCM_SERVER_KEY` (optional)

---

## ทดสอบ

1. Demo: ฉัน → Admin → แท็บ **รายงาน** → คัดลอก TSV  
2. Supabase จริง: ส่ง Lead → owner ได้ SnackBar · ยืนยันนัด → `notify-appointment`  
3. Make.com: รับ webhook หรือดึง `platform_stats_daily`

---

## Next

- ~~Firebase Messaging~~ → [phase-10-push-notifications.md](phase-10-push-notifications.md)  
- ~~Marker ราคา~~ → [phase-8-seed-and-map-markers.md](phase-8-seed-and-map-markers.md)  
- ~~Seed SQL~~ → [phase-8-seed-and-map-markers.md](phase-8-seed-and-map-markers.md)
