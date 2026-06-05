# Phase 15: App Store / Play Store + Firebase มือถือจริง

**สถานะ:** พร้อมใช้ (สคริปต์ + คู่มือ) · ต้องตั้งค่าบัญชีสโตร์เอง  
**อัปเดต:** 2026-06-02

---

## ทำอะไรในเฟสนี้

| สิ่งที่ได้ | ความหมาย |
|-----------|----------|
| สคริปต์ build Android | `./scripts/build-android.sh` → APK หรือ AAB |
| สคริปต์ build iOS | `./scripts/build-ios.sh` → เปิด Xcode Archive |
| Firebase บนมือถือ | FCM push เมื่อแอปปิด (ทางเลือก) |
| ตรวจความพร้อม | `./scripts/verify-ready.sh` รวม Firebase + migrations |

Phase 13 (PWA เว็บ) ยังใช้ได้ — Phase 15 คือ **แอป native** บน Store

---

## ลำดับแนะนำ

### 1. Backend + env (ถ้ายังไม่ทำ)

```bash
./scripts/deploy-all.sh    # migrations 23–24 รวม Phase 14
./scripts/seed-cloud.sh
```

`.env.local` → `./scripts/sync-env.sh`

### 2. Firebase (ทางเลือก — push เมื่อแอปปิด)

1. [Firebase Console](https://console.firebase.google.com) → สร้างโปรเจกต์  
2. เพิ่มแอป **Android** + **iOS** + **Web**  
3. ใส่ใน `.env.local`:

```env
FIREBASE_API_KEY=
FIREBASE_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
```

4. `./scripts/sync-env.sh`  
5. Native (แนะนำสำหรับ Store):

```bash
cd mobile
dart pub global activate flutterfire_cli
flutterfire configure
```

ได้ `android/app/google-services.json` และ `ios/Runner/GoogleService-Info.plist`

6. Supabase Edge secret: `FCM_SERVER_KEY` (Legacy HTTP API)

รายละเอียด: [mobile/docs/FCM_SETUP.md](../mobile/docs/FCM_SETUP.md)

### 3. Android (Play Store)

```bash
# ทดสอบ sideload
./scripts/build-android.sh apk

# อัปโหลด Play Console
./scripts/build-android.sh aab
```

**ก่อนขึ้น Store:**

- สร้าง keystore + ตั้ง `signingConfig` ใน `android/app/build.gradle` (ตอนนี้ใช้ debug key)  
- `applicationId`: `com.livingbkk.livingbkk`  
- นโยบายความเป็นส่วนตัว + สิทธิ์ Location (Near Me)

### 4. iOS (App Store)

```bash
./scripts/build-ios.sh
open mobile/ios/Runner.xcworkspace
```

**ต้องมี:** Mac + Xcode รุ่นรองรับ · Apple Developer Program · Bundle ID ตรงกับ Firebase

### 5. ทดสอบ push

1. ล็อกอินแอปบนมือถือจริง (ไม่ใช่ Chrome web)  
2. `NotificationService` บันทึก token → `profiles.fcm_token`  
3. สร้าง lead / นัดชม → Edge Function ส่ง push

---

## โหมดทดลอง vs ใช้จริง

| | ทดลอง (Chrome / PWA) | Store (Phase 15) |
|--|----------------------|------------------|
| Push | Realtime ในแอป | FCM + Realtime |
| Firebase | จาก `assets/env` | + native config files |
| ลงทะเบียน Store | ไม่ต้อง | Play / App Store Connect |

---

## เฟสถัดไป (16)

- E-Contract ผู้ให้บริการลายเซ็นดิจิทัลจริง  
- Lead Bot สนทนาเต็มรูปแบบ  

ดู [ROADMAP-REMAINING.md](ROADMAP-REMAINING.md)
