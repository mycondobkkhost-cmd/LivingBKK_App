# โฆษณา Carousel หน้าแรก — สเปกรูป

อ้างอิงกรอบใน `HomePromoCarousel` (21:9, สูงไม่เกิน 124pt)

## ขนาดที่แนะนำ

| รายการ | ค่า |
|--------|-----|
| อัตราส่วน | **21:9** |
| ขนาดพิกเซล (แนะนำ) | **1260 × 540 px** |
| ขนาดขั้นต่ำ | **1050 × 450 px** |
| รูปแบบ | PNG, WebP, JPEG |
| ขนาดไฟล์สูงสุด | **512 KB** |

## การแสดงผลในแอป

- Carousel ใช้ `BoxFit.cover` — ขอบรูปอาจถูก crop เล็กน้อย
- วางข้อความ/โลโก้สำคัญไว้กลางภาพ หลีกเลี่ยงขอบซ้าย-ขวา ~8%
- อัปโหลดผ่านแอดมิน → แท็บ **โฆษณา** หรือ bucket `home-promo`

## จำนวนรายการ

- เปิดใช้งานได้สูงสุด **10** รายการ
- เรียงด้วย `sort_order` (1–10)

## Fallback

ถ้ายังไม่อัปโหลดรูป แอปใช้ไฟล์ใน `assets/promo/` ตาม slug:

- `exclusive_rent` → `promo_exclusive_rent.png`
- `agent_partner` → `promo_agent_partner.png`
- `room_service` → `promo_room_service.png`
