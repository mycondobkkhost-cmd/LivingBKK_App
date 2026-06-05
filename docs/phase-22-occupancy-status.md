# Phase 22 — สถานะทรัพย์ตอนลงประกาศ

## วัตถุประสงค์

ให้ผู้ลงประกาศระบุสถานะทรัพย์ตอนสร้างรายการ เพื่อใช้ในการตลาดและนัดดู:

| สถานะ | ใช้กับ | ข้อมูลเพิ่ม |
|--------|--------|-------------|
| `ready` | ทุกประเภท | ข้อความปรับตามประเภททรัพย์ (เช่น ห้องว่างพร้อมอยู่ / บ้านว่างพร้อมอยู่) |
| `renovating` | ทุกประเภท | วันที่พร้อมเข้าอยู่ + ติ๊ก「นัดดูระหว่างนี้ได้」 |
| `tenanted` | เช่า | วันที่ว่างอีกครั้ง + ติ๊ก「นัดดูระหว่างนี้ได้」 |
| `sale_with_tenant` | ขาย | ค่าเช่าปัจจุบัน → คำนวณ yield % สำหรับนักลงทุน |

## UI

- ขั้นตอน **รายละเอียด** (`create_listing_page` step 2): `ListingOccupancySection`
- ขั้นตอน **ราคา**: แสดง yield preview เมื่อเลือก「ขายพร้อมผู้เช่า」และกรอกราคาขาย + ค่าเช่าแล้ว

## ฐานข้อมูล

Migration: `supabase/migrations/20260604230000_listing_occupancy_status.sql`

คอลัมน์ใหม่บน `listings`:

- `occupancy_status` — `ready | renovating | tenanted | sale_with_tenant`
- `viewing_allowed_during` — boolean

ฟิลด์ที่มีอยู่แล้วที่ถูกเติมจากสถานะ:

- `available_from` — รีโนเวท
- `available_again` / `contract_occupied_until` — มีผู้เช่า
- `investor_category` = `with_tenant`, `monthly_rent_for_yield`, `yield_percent` — ขายพร้อมผู้เช่า

`listings_public` เปิดเผย: `occupancy_status`, `viewing_allowed_during`, `monthly_rent_for_yield`

## โค้ดหลัก

- `mobile/lib/models/listing_occupancy.dart`
- `mobile/lib/widgets/listing_occupancy_section.dart`
- `mobile/lib/services/listing_create_repository.dart` — ส่ง `occupancy.toDbFields(salePrice:)`
- `mobile/lib/services/trial_listing_store.dart` — โหมดทดลอง

## Deploy

```bash
supabase db push
```
