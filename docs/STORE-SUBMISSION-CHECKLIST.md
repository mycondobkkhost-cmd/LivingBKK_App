# ส่งแอป RealXtate ขึ้น App Store / Play Store

**ยังไม่สมัครร้าน / ยังไม่จ่ายเงิน?** เริ่มที่ [STORE-FREE-PREP.md](STORE-FREE-PREP.md) ก่อน

คู่มือนี้สรุป **สิ่งที่ทำในโค้ดแล้ว** กับ **สิ่งที่คุณต้องทำเอง** ก่อนกดส่งร้าน

รันตรวจอัตโนมัติ:

```bash
./scripts/prepare-store-free.sh        # ฟรี — ไม่นับ Firebase/keystore เป็นข้อผิดพลาด
./scripts/verify-store-ready.sh        # เต็ม — รวม keystore + Firebase
```

---

## สิ่งที่เตรียมใน repo แล้ว

| รายการ | ไฟล์ / ฟีเจอร์ |
|--------|----------------|
| ลบบัญชีในแอป | โปรไฟล์ → ลบบัญชี + Edge Function `delete-account` |
| คำอธิบายสิทธิ์ iOS | `mobile/ios/Runner/Info.plist` (ตำแหน่ง, รูปภาพ) |
| สิทธิ์ Android | `AndroidManifest.xml` (internet, location, แจ้งเตือน, รูป) |
| Release signing (Android) | `key.properties.example` + `build.gradle` อ่าน `key.properties` |
| เวอร์ชันแอป | `pubspec.yaml` → `1.0.0+1` (ตรงกับ `./scripts/build-android.sh`) |
| นโยบาย/เงื่อนไขเว็บ | `mobile/web/legal/privacy.html`, `terms.html` |
| ตรวจความพร้อม | `scripts/verify-store-ready.sh` |

---

## ร่วมทุกร้าน (Shared)

### 1. โหมด production

ใน `.env.local` แล้วรัน:

```bash
./scripts/sync-env.sh
```

ตั้งค่าใน `assets/env`:

- `TRIAL_MODE=false`
- `ALLOW_PASSWORDLESS_LOGIN=false` (แนะนำ)
- `WEB_BASE_URL=https://your-site.netlify.app` (URL จริงหลัง deploy)

### 2. Deploy เว็บ + URL กฎหมาย

```bash
./scripts/deploy-netlify.sh    # หรือ deploy วิธีที่ใช้อยู่
```

เปิดในเบราว์เซอร์ (ไม่ต้องล็อกอิน):

- `{WEB_BASE_URL}/legal/privacy.html`
- `{WEB_BASE_URL}/legal/terms.html`

ใส่ **Privacy Policy URL** ใน App Store Connect และ Play Console

### 3. Deploy Edge Function ลบบัญชี

```bash
./scripts/deploy-all.sh
# หรือเฉพาะ: supabase functions deploy delete-account
```

ทดสอบ: ล็อกอินบัญชีทดสอบ → โปรไฟล์ → ลบบัญชี → ตรวจว่าล็อกอินซ้ำไม่ได้

### 4. อีเมลความเป็นส่วนตัว

เปิดกล่อง `privacy@realxtateth.com` (หรือแก้ใน `legal_config.dart` + HTML) ก่อนส่งร้าน

### 5. สกรีนช็อต + คำอธิบายร้าน

- สกรีนช็อต iPhone / iPad (ถ้ารองรับ) และ Android phone
- คำโปรโมตสั้น ๆ ภาษาไทย/อังกฤษ
- หมวดหมู่: Lifestyle หรือ Business (อสังหาริมทรัพย์)

---

## Google Play Store

### บัญชีและแอป

1. สมัคร [Google Play Console](https://play.google.com/console) (ค่าธรรมเนียมครั้งเดียว)
2. สร้างแอปใหม่ · Application ID: `com.livingbkk.livingbkk`

### สร้าง keystore (ทำครั้งเดียว — เก็บไฟล์และรหัสให้ปลอดภัย)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

### ตั้ง signing

```bash
cd mobile/android
cp key.properties.example key.properties
# แก้ storeFile เป็น path จริงของ .jks และใส่รหัส
```

**อย่า commit** `key.properties` หรือไฟล์ `.jks` (อยู่ใน `.gitignore` แล้ว)

### Build AAB

```bash
./scripts/build-android.sh aab
# ไฟล์: mobile/build/app/outputs/bundle/release/app-release.aab
```

### Play Console — กรอกเพิ่ม

- Data safety: ตำแหน่ง, รูป, ข้อมูลติดต่อ ตามที่แอปเก็บจริง
- Content rating questionnaire
- Privacy Policy URL = `{WEB_BASE_URL}/legal/privacy.html`
- อัปโหลด AAB ใน Production / Internal testing ก่อน

### Firebase (ถ้าใช้ push)

```bash
cd mobile && flutterfire configure
```

ได้ `android/app/google-services.json`

---

## Apple App Store

### สิ่งที่ต้องมี

- Mac + Xcode ล่าสุดที่รองรับ
- [Apple Developer Program](https://developer.apple.com/programs/) (รายปี)
- Bundle ID ตรงกับโปรเจกต (Firebase / Xcode)

### Build และ Archive

```bash
./scripts/build-ios.sh
open mobile/ios/Runner.xcworkspace
```

ใน Xcode:

1. เลือก Team → Signing & Capabilities
2. Product → Archive → Distribute App → App Store Connect

### App Store Connect

- Privacy Policy URL
- App Privacy (Nutrition Labels): Location, Photos, Contact Info ฯลฯ ให้ตรงแอป
- **Account deletion**: ระบุว่ามีในแอป (โปรไฟล์ → ลบบัญชี)
- สกรีนช็อตตามขนาดที่ Apple กำหนด

### Push (ทางเลือก)

- `flutterfire configure` → `GoogleService-Info.plist`
- เปิด Push Notifications capability ใน Xcode

---

## หลังส่งร้าน

- เก็บ keystore + รหัส Android ไว้สำรอง (สูญหาย = อัปเดตแอปยาก)
- ทุกครั้งที่อัปเวอร์ชัน: แก้ `pubspec.yaml` และ/หรือ `BUILD_NAME` / `BUILD_NUMBER` ตอน build
- ดูเพิ่ม: `docs/APP-STORE-LEGAL.md`, `docs/phase-15-app-store-firebase.md`
