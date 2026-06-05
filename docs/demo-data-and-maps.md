# ข้อมูลตัวอย่าง + Maps + Google Places

## ทรัพย์ตัวอย่าง (~72 รายการ)

เมื่อยังไม่ตั้งค่า Supabase แอปใช้ `DemoListingsFactory` สร้างทรัพย์จาก **24+ โครงการจริงในกรุงเทพ** (ชื่อและพิกัดอ้างอิง Google Maps):

- ทรู ทองหล่อ, Noble Remix, Rhythm 36, Ashton Asoke, The Lofts Ekkamai ฯลฯ
- แต่ละโครงการมี **2–4 ห้อง** พร้อม **รูป 3 ภาพ** (picsum แยก seed ต่อห้อง)

ไฟล์ข้อมูล: `mobile/lib/data/bangkok_projects.dart`, `mobile/lib/data/demo_listings_factory.dart`

## UX ตาม Wireframe

- หน้าแรก: ช่องค้นหา, หมวดคอนโด/บ้าน/ทาวน์เฮ้าส์, **แนะนำสำหรับคุณ**, สลับ **แผนที่ / รายการ**
- การ์ดมีรูป + หัวใจบันทึก
- รายละเอียดทรัพย์: **AI Chat** + **นัดดูห้อง**
- แท็บล่าง: หน้าแรก · บอร์ด · **บันทึก** · งาน · ติดต่อ · ฉัน

## Google Maps

1. เปิด [Google Cloud Console](https://console.cloud.google.com)
2. เปิด API:
   - **Maps JavaScript API** (Web)
   - **Maps SDK for Android / iOS** (มือถือ)
   - **Places API** (ค้นหาโครงการจาก Google — ถ้ามี key)
3. ใส่ key ใน `mobile/assets/env` และ `mobile/web/index.html`

## ค้นหาโครงการ

- **ออฟไลน์:** ฐาน `BangkokProjects` + ทรัพย์ demo
- **ออนไลน์:** `PlacesService` เรียก Google Places Text Search (เมื่อ key ถูกต้องและเปิด Places API)

ลองพิมพ์: `ทรู ทองหล่อ`, `อโศก`, `บางนา`
