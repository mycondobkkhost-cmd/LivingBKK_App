# นโยบายคัดกรองรูป — ไม่ใช้บริการเสียเงินแฝง

## หลักการ

- **ไม่ใช้** Google Vision, AWS Rekognition, Cloudinary AI Moderation หรือ API อื่นที่คิดค่าบริการตามจำนวนรูป/เดือน
- ใช้เฉพาะสิ่งที่อยู่ใน Supabase + โค้ดใน repo (Edge Functions, Postgres, Storage)
- ลายน้ำ / โลโก้ → **แอดมินตรวจด้วยตา** ใน Admin → Moderation (ไม่มีค่า API)

## สิ่งที่ทำงานอยู่แล้ว (ฟรี)

| ขั้นตอน | วิธี | ค่าใช้จ่าย |
|--------|------|-----------|
| อัปโหลดรูป | Supabase Storage bucket `listing-images` | ตามแพ็ก Supabase |
| Hash รูป | SHA-256 ย่อในแอป (`StorageService`) | 0 |
| ตรวจรูปซ้ำ | Edge Function `image-dedup-check` เทียบ `perceptual_hash` ในตาราง `listing_images` | 0 (invocation ในโควต้า Supabase) |
| รูปซ้ำ / สงสัย | แถว `moderation_flags` ประเภท `duplicate_image` + สถานะรูป `pending` | 0 |
| ข้อความประกาศ | Edge Function `moderate-listing-text` — regex ใน Deno (เบอร์/LINE/URL) | 0 |
| ลายน้ำเว็บอื่น | ข้อความเตือนตอนอัปโหลด + คิวแอดมิน | 0 |
| ลายน้ำ PROPPITER (หน้าบ้าน) | Edge `listing-watermark-images` — สร้างไฟล์ `wm/` แยกจากต้นฉบับ · `public_url` = มีลายน้ำ · `storage_path` = ต้นฉบับ | 0 |
| แอดมินดาวน์โหลดต้นฉบับ | พรีวิวประกาศ → **ดาวน์โหลดรูปต้นฉบับ** (จาก `storage_path`) | 0 |
| อัปโหลดรูปลายน้ำ | แอดมิน → แท็บ **ลายน้ำ** → Storage `brand-assets/watermark/` | 0 |

## สิ่งที่ไม่ทำ (เพื่อไม่ให้มีค่าใช้จ่ายแฝง)

- Auto-detect ลายน้ำด้วย AI ภายนอก
- OCR / logo detection แบบ metered API
- บริการ third-party moderation ที่คิดเงินตาม volume

## อนาคต (ยังคงฟรี)

ถ้าต้องการตรวจซ้ำแม่นขึ้นโดยไม่เสียเงิน API:

- ปรับ hash เป็น aHash/dHash ใน Dart (`package:image`) ฝั่ง client
- เทียบ Hamming distance ใน Postgres หรือ Edge Function

ยังไม่รวมบริการ cloud vision ที่คิดค่าตามใช้งาน

## ไฟล์ที่เกี่ยวข้อง

- `mobile/lib/services/storage_service.dart` — อัปโหลด + hash + เรียก dedup
- `supabase/functions/image-dedup-check/index.ts`
- `supabase/functions/listing-watermark-images/index.ts` — ฝังโลโก้ PROPPITER หลัง publish
- `supabase/functions/_shared/watermark_listing_images.ts`
- `supabase/functions/moderate-listing-text/index.ts`
- `mobile/lib/features/admin/admin_moderation_tab.dart`
