# คำตอบฟอร์มความเป็นส่วนตัว (Apple App Privacy + Google Data safety)

ใช้กรอกตอนสมัครร้านแล้ว — ปรับให้ตรงแอปจริงก่อน Submit

---

## ข้อมูลที่เก็บ

| ประเภท | เก็บไหม | ใช้ทำอะไร | ผูกตัวตนผู้ใช้ |
|--------|---------|----------|--------------|
| อีเมล | ใช่ | บัญชี ล็อกอิน | ใช่ |
| ชื่อ / โปรไฟล์ | ใช่ | แสดงในแอป | ใช่ |
| เบอร์โทร | ใช่ (ถ้าผู้ใช้กรอก) | แชท ลีด นัดดู | ใช่ |
| รูปภาพ | ใช่ | โปรไฟล์ รูปประกาศ | ใช่ |
| ตำแหน่ง | ใช่ (เมื่ออนุญาต) | แผนที่ Near Me | ใช่ |
| ข้อความแชท | ใช่ | สนับสนุนลูกค้า AI/แอดมิน | ใช่ |
| Device ID / Push token | ใช่ (ถ้าเปิด Firebase) | แจ้งเตือน | ใช่ |

## ไม่เก็บ / ไม่ขาย

- ไม่ขายข้อมูลให้บุคคลที่สาม
- ไม่ใช้ข้อมูลเพื่อโฆษณาติดตาม (tracking) นอกแอป
- ไม่เปิดเบอร์เจ้าของทรัพย์ให้ลูกค้าโดยตรง

## วัตถุประสงค์หลัก (Google Data safety)

- App functionality
- Account management
- Customer support
- Fraud prevention / safety (moderation)

## ลบข้อมูล

- ผู้ใช้ลบบัญชีได้ใน **โปรไฟล์ → ลบบัญชี**
- นโยบาย: `{WEB_BASE_URL}/legal/privacy.html`
- ติดต่อ: `privacy@realxtateth.com`

## UGC (เนื้อหาจากผู้ใช้)

- ผู้ใช้โพสต์ประกาศทรัพย์
- มีการตรวจก่อนเผยแพร่ (moderation)
- มีเงื่อนไขการใช้งานและ checkbox ยอมรับก่อนโพสต์

## Privacy Policy URL

```
https://realxtateth.com/legal/privacy.html
```

> **หมายเหตุ:** ใช้ URL ด้านบนเมื่อตั้งโดเมน `RealXtateTH.com` และ deploy แล้ว  
> ระหว่างรอจดโดเมน ใช้ชั่วคราว: `https://quiet-kangaroo-ab6073.netlify.app/legal/privacy.html`  
> ตั้งค่า: `./scripts/setup-custom-domain.sh` · คู่มือ: [docs/CUSTOM-DOMAIN.md](../docs/CUSTOM-DOMAIN.md)
