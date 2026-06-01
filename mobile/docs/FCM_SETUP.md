# Firebase Cloud Messaging (optional Phase 4.5)

LivingBKK ใช้ **Supabase Realtime** แจ้งในแอปก่อน — FCM สำหรับ push เมื่อแอปปิด

## Steps

1. https://console.firebase.google.com → สร้างโปรเจกต์  
2. เพิ่มแอป iOS + Android  
3. ดาวน์โหลด `google-services.json` / `GoogleService-Info.plist`  
4. `flutter pub add firebase_core firebase_messaging`  
5. เรียก `NotificationService.saveFcmToken(token)` ใน `lib/services/notification_service.dart`  
6. Edge Function ส่ง FCM ด้วย service account (ขั้นสูง)

จนกว่าจะตั้ง FCM — ใช้ Realtime + SnackBar ในแอปได้แล้ว
