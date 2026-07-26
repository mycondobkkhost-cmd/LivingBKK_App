# ถ้า `supabase db push` ติด — รัน SQL นี้ใน Supabase Dashboard → SQL Editor

โปรเจกต: `auflqgqrmpbioflnhsrj`

> **อัปเดต 2026-06-13:** `db push` สำเร็จแล้ว (รวม `inventory_members` + migration AI ทั้งหมด) — ใช้เอกสารนี้เฉพาะกรณี push ติดอีกครั้ง

## ลำดับ (เฉพาะ migration AI — ถ้า push ติดก่อนถึงชุดนี้)

1. เปิดไฟล์ทีละไฟล์ คัดลอกทั้งไฟล์ วางใน SQL Editor กด Run  
2. รันตามลำดับ (ห้ามข้าม):

| ลำดับ | ไฟล์ |
|-------|------|
| 1 | `supabase/migrations/20260613120000_project_requests.sql` |
| 2 | `supabase/migrations/20260613140000_owner_inquiries.sql` |
| 3 | `supabase/migrations/20260613150000_owner_inquiry_collect.sql` |
| 4 | `supabase/migrations/20260613160000_admin_ai_feed.sql` |
| 5 | `supabase/migrations/20260613170000_admin_ai_feed_phase_d.sql` |
| 6 | `supabase/migrations/20260613180000_admin_ai_feed_phase_e.sql` |

## สาเหตุที่ db push เคยติด (แก้แล้ว)

1. `inventory_members` หายจาก migration บน cloud ที่ถูก revert → เพิ่ม `20260610129500_inventory_members.sql`
2. `listings_public` อ้าง `listing_images.is_public` ที่ไม่มีบน remote → ใช้ `moderation_status IN ('approved','pending')` แทน

## หลังรัน SQL แล้ว

```bash
./scripts/setup-openai-secret.sh   # หลังใส่ OPENAI_API_KEY ใน .env.local
./scripts/restart-cursor-dev.sh
```

ทดสอบ: http://127.0.0.1:7357/admin/console (ปุ่ม ✨)
