# Firebase Cloud Messaging (Phase 10)

LivingBKK ใช้ **Supabase Realtime** แจ้งในแอปเสมอ — **FCM** เป็นทางเลือกสำหรับ push เมื่อแอปปิด (iOS/Android)

## ไม่บังคับ

- ไม่ใส่ `FIREBASE_*` → แอปรันได้ · แจ้งเตือนผ่าน Realtime + SnackBar  
- Web (Chrome) → ไม่ลงทะเบียน FCM native

## Steps

1. https://console.firebase.google.com → สร้างโปรเจกต์  
2. Project settings → คัดลอก Web app config (apiKey, appId, messagingSenderId, projectId)  
3. ใส่ใน `.env.local`:

```env
FIREBASE_API_KEY=
FIREBASE_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
```

4. `./scripts/sync-env.sh`  
5. `cd mobile && flutter pub get && flutter run`  
6. ล็อกอิน → `NotificationService` บันทึก token ไป `profiles.fcm_token`  
7. Supabase Edge secrets: `FCM_SERVER_KEY` (Legacy HTTP API)  
8. Production iOS/Android: รัน `flutterfire configure` แล้วเพิ่ม `google-services.json` / `GoogleService-Info.plist`

Edge Functions `route-lead-notification` และ `notify-appointment` ส่ง push อัตโนมัติเมื่อมี token

ดู [docs/phase-10-push-notifications.md](../../docs/phase-10-push-notifications.md)
