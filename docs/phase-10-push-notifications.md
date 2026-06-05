# Phase 10: Push Notifications (FCM)

**Status:** Implemented  
**Date:** 2026-06-02

---

## นโยบายธุรกิจ (อัปเดต)

- **โพสต์ประกาศฟรี** สำหรับ Owner / Agent — ไม่มีแพ็ก subscription 20k/ปี  
- รายได้แพลตฟอร์ม: **Success Fee** ตามขั้นคอมมิชชัน (E-Contract) เท่านั้น  
- ตาราง `property_management_subscriptions` ถูกลบแล้ว (migration `20260602120020`)

---

## Delivered

| Feature | Location |
|---------|----------|
| FCM token ลง `profiles.fcm_token` | `NotificationService` |
| เปิดใช้เมื่อมีค่า Firebase ใน `assets/env` | `Env.firebaseEnabled` |
| Foreground push → SnackBar | `MainShell` + `NotificationService.onForegroundMessage` |
| Edge ส่ง push (ถ้ามี `FCM_SERVER_KEY`) | `route-lead-notification`, `notify-appointment` |
| ในแอป (ไม่ต้อง FCM) | `RealtimeService` — Lead / นัดชม |

---

## ตั้งค่า Firebase (ทางเลือก — iOS/Android)

1. สร้างโปรเจกต์ที่ [Firebase Console](https://console.firebase.google.com)  
2. ใส่ใน `.env.local` แล้ว `./scripts/sync-env.sh`:

```env
FIREBASE_API_KEY=
FIREBASE_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
```

3. `cd mobile && flutter pub get`  
4. ล็อกอินแอป → token บันทึกอัตโนมัติ  
5. Supabase Edge secrets: `FCM_SERVER_KEY` (Legacy HTTP)

รายละเอียด: [mobile/docs/FCM_SETUP.md](../mobile/docs/FCM_SETUP.md)

**Web (Chrome):** ใช้ Realtime + SnackBar ในแอป — ไม่ลงทะเบียน FCM native

---

## Deploy

```bash
source scripts/dev-path.sh
supabase db push
supabase functions deploy route-lead-notification
supabase functions deploy notify-appointment
```

---

## ทดสอบ

1. ไม่ใส่ Firebase → แอปรันได้ · แจ้งเตือนในแอปผ่าน Realtime  
2. ใส่ Firebase + FCM_SERVER_KEY → ส่ง Lead → owner ได้ push นอกแอป  
3. `supabase db push` → ไม่มีตาราง PM subscription แล้ว

---

## Next

- ~~Production deploy ครบ~~ → [phase-11-production-complete.md](phase-11-production-complete.md)  
- FlutterFire `flutterfire configure` (production mobile)  
- Web Push (VAPID) — ทางเลือกในอนาคต
