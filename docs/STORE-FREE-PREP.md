# เตรียมขึ้น Store แบบฟรี (ยังไม่สมัครร้าน / ยังไม่จ่ายเงิน)

คู่มือนี้แยกชัดว่า **ทำอะไรได้แล้วใน repo** กับ **อะไรต้องรอจนกว่าจะสมัคร Developer**

---

## สรุปสถานะตอนนี้

รันตรวจ (ไม่นับ Firebase / keystore เป็นข้อผิดพลาด):

```bash
./scripts/verify-store-free.sh
```

| หมวด | สถานะ |
|------|--------|
| นโยบาย Privacy/Terms บนเว็บ | ✅ URL เปิดได้ (หลัง deploy Netlify) |
| ลบบัญชีในแอป | ✅ โค้ดพร้อม — deploy `delete-account` |
| สิทธิ์ iOS / Android | ✅ ใส่คำอธิบายแล้ว |
| เวอร์ชันแอป | ✅ `1.0.0+1` |
| ข้อความร้าน (copy-paste) | ✅ `store-listing/` |
| คำตอบ App Privacy / Data safety | ✅ `store-listing/app-privacy-answers.md` |
| Keystore Android | สคริปต์ฟรี `./scripts/generate-android-keystore.sh` |
| Build ทดสอบ | `./scripts/build-android.sh apk` |

---

## สิ่งที่ทำได้ฟรี (ทำตามลำดับ)

### 1. โหมด production ในแอป

`.env.local`:

```env
TRIAL_MODE=false
ALLOW_PASSWORDLESS_LOGIN=false
WEB_BASE_URL=https://quiet-kangaroo-ab6073.netlify.app
```

```bash
./scripts/sync-env.sh
```

### 2. Deploy backend ที่ร้านต้องการ

```bash
./scripts/deploy-all.sh    # รวม delete-account
./scripts/build-web.sh     # ถ้าแก้ legal หรือ branding
# อัป Netlify ตามวิธีเดิม
```

ทดสอบ URL (ต้องได้ 200):

- `{WEB_BASE_URL}/legal/privacy.html`
- `{WEB_BASE_URL}/legal/terms.html`

### 3. สร้าง keystore Android (ฟรี — ยังไม่ต้องสมัคร Play)

```bash
./scripts/generate-android-keystore.sh
```

เก็บรหัสและไฟล์ `.jks` ไว้ปลอดภัย — **อย่า commit**

### 4. Build ทดสอบบนมือถือ (sideload ฟรี)

```bash
./scripts/build-android.sh apk
# ติดตั้ง app-release.apk บน Android จริง
```

iOS (ต้องมี Mac + Xcode — ยังไม่ต้องจ่าย Apple จนกว่าจะ Archive ส่งร้าน):

```bash
./scripts/build-ios.sh
open mobile/ios/Runner.xcworkspace
```

### 5. เตรียมข้อความร้าน

คัดลอกจาก `store-listing/` ไปวางใน Play Console / App Store Connect **ตอนสมัครแล้ว**

---

## สิ่งที่ยังไม่ทำ (ต้องจ่ายหรือสมัคร)

| รายการ | ค่าใช้จ่าย | เมื่อไหร่ทำ |
|--------|-----------|------------|
| Google Play Console | ~$25 ครั้งเดียว | ก่อนอัปโหลด AAB |
| Apple Developer Program | ~$99/ปี | ก่อน Archive ส่ง App Store |
| Firebase (push นอกแอป) | ฟรี tier แต่ต้องสมัคร | ทางเลือก — ไม่บังคับตอนส่งร้าน |
| กล่อง `privacy@realxtateth.com` | ฟรี–ถูก (email routing) | ก่อนกด Submit |
| Screenshot จริง | ฟรี (ถ่ายเอง) | ก่อน Submit |

---

## Checklist ก่อนสมัครร้าน

- [ ] `./scripts/verify-store-free.sh` ผ่านทุกข้อบังคับ
- [ ] ทดสอบล็อกอิน / โพสต์ / แชท / ลบบัญชี บนมือถือจริง
- [ ] ไม่มีปุ่ม "เข้าแบบทดลอง" บนหน้า login (`TRIAL_MODE=false`)
- [ ] อ่าน `store-listing/app-privacy-answers.md` เตรียมกรอกฟอร์มร้าน
- [ ] ถ่าย screenshot ตาม `store-listing/screenshot-specs.md`

เมื่อพร้อมสมัคร → ต่อที่ [STORE-SUBMISSION-CHECKLIST.md](STORE-SUBMISSION-CHECKLIST.md)
