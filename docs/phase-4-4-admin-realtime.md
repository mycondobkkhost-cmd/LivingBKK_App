# Phase 4.4: Admin, Moderation, Realtime

## Delivered

| Feature | Location |
|---------|----------|
| Text moderation before publish | `moderate-listing-text` + `CreateListingPage` |
| Admin center | `/admin` — offers inbox, leads, create demand post |
| My listings + bump | `/listings/mine` |
| In-app lead alerts | `RealtimeService` + migration `realtime_leads` |
| Lead routing call | `route-lead-notification` after lead submit |
| Make.com guide | [MAKECOM.md](MAKECOM.md) |

## ตั้ง Admin user

หลังสมัครในแอป → Supabase **Table Editor** → `profiles` → แก้ `role` เป็น `admin`

หรือ SQL:

```sql
UPDATE profiles SET role = 'admin' WHERE id = 'YOUR_USER_UUID';
```

## Deploy

```bash
supabase db push
supabase functions deploy route-lead-notification
```

Dashboard → **Database** → **Replication** → ตรวจว่า `leads` อยู่ใน Realtime

## FCM (Phase 4.5)

ยังใช้ Realtime แทน push นอกแอป — ต่อ Firebase ตาม [mobile/docs/FCM_SETUP.md](../mobile/docs/FCM_SETUP.md) เมื่อพร้อม
