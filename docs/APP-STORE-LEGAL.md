# App Store / Play Store — กฎหมายและความเป็นส่วนตัว (RealXtate)

## สรุปสั้น ๆ

| สิ่งที่มีในแอปตอนนี้ | ช่วย App Store แค่ไหน |
|----------------------|----------------------|
| ช่องติ๊กยอมรับก่อนเผยแพร่/สมัคร | ✅ แสดงความยินยอม (Guideline 5.1.1 / UGC) |
| ลิงก์เงื่อนไข + นโยบายกดเปิดได้ | ✅ ต้องมี URL สาธารณะใน Connect ด้วย |
| ฉบับเต็มในแอป + `mobile/web/legal/*.html` | ✅ ใช้เป็น Privacy Policy URL ได้หลัง deploy เว็บ |
| บันทึก `listing_policy_version` ใน metadata | ⚠️ audit เบื้องต้น — ไม่ใช่ตาราง compliance แยก |
| อีเมล `privacy@realxtateth.com` ในฉบับกฎหมาย | ⚠️ ต้องเป็นกล่องจริงก่อนส่งร้าน |

**ไม่มี checkbox ใดที่ “รับประกันผ่านร้าน” โดยอัตโนมัติ** — Apple/Google ดูทั้ง URL, การลบบัญชี, UGC moderation, และข้อมูลที่เก็บใน Privacy Nutrition Labels

## URL สำหรับ App Store Connect

หลัง deploy Flutter web (Netlify ฯลฯ) ตั้งใน `assets/env`:

```env
WEB_BASE_URL=https://your-site.netlify.app
```

ระบบจะใช้โดยอัตโนมัติ:

- Privacy: `{WEB_BASE_URL}/legal/privacy.html`
- Terms: `{WEB_BASE_URL}/legal/terms.html`

หรือ override:

```env
PRIVACY_POLICY_URL=https://...
TERMS_OF_SERVICE_URL=https://...
```

ใส่ **Privacy Policy URL** ใน App Store Connect → App Privacy → Privacy Policy URL (ต้องเปิดได้จากเบราว์เซอร์โดยไม่ต้องล็อกอิน)

## Checklist ก่อนส่งร้าน

- [ ] Deploy `mobile/web` รวมโฟลเดอร์ `legal/` แล้วทดสอบ URL สองลิงก์
- [ ] เปิดใช้กล่อง `privacy@realxtateth.com` (หรือแก้ใน `legal_config.dart` + HTML)
- [ ] ปิด `TRIAL_MODE` / `ALLOW_PASSWORDLESS_LOGIN` ใน production
- [ ] กรอก App Privacy (Data types: contact, photos, location ฯลฯ) ให้ตรงกับแอปจริง
- [ ] มี flow ลบบัญชี (Profile หรือติดต่อ support) ตาม Guideline 5.1.1(v)
- [ ] UGC: มีการตรวจ `pending_review` + แอดมิน moderate (มีในแอปแล้ว)
- [ ] ทนายตรวจฉบับไทย/อังกฤษถ้าจัดการเงิน/ข้อมูลจริงจัง (แอปให้ฉบับมาตรฐาน startup ไม่ใช่คำปรึกษากฎหมาย)

## ไฟล์ที่เกี่ยวข้อง

- `mobile/lib/data/legal_documents.dart` — เนื้อหาในแอป
- `mobile/lib/config/legal_config.dart` — เวอร์ชัน `2026-06-04-v1`
- `mobile/lib/widgets/legal_policy_rich_text.dart` — ลิงก์ในฟอร์ม
- `mobile/web/legal/privacy.html` / `terms.html` — ฉบับเว็บสาธารณะ
