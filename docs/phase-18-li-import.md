# Phase 18: LI Link Import (Admin)

**Status:** Implemented  
**Date:** 2026-06-02

---

## ฟีเจอร์

| รายการ | รายละเอียด |
|--------|------------|
| ช่องวางลิงก์ | 8 ช่อง + bulk paste |
| ดึงอัตโนมัติ | Edge `listing-import-fetch` |
| Parser | `_shared/li_parser.ts` — istockdetail / livingdetail |
| รูป | ดาวน์โหลดจาก LI → Storage `listing-images` |
| ตัดคอนแทค | เบอร์/Line/URL ใน description |
| อนุมัติ | `listing-import-approve` → publish |
| จัดเก็บ | `listing-import-archive` |
| UI | Admin → แท็บ **นำเข้า** หรือ `/admin/import` |

---

## Deploy

```bash
source scripts/dev-path.sh
supabase db push
supabase functions deploy listing-import-fetch
supabase functions deploy listing-import-approve
supabase functions deploy listing-import-archive
```

---

## Workflow

1. วางลิงก์ LI (ทดสอบแล้ว: ไม่ต้อง login)
2. กด **ดึงข้อมูลทั้งหมด**
3. ตรวจในตาราง (โครงการ / รูป / ราคา)
4. **อนุมัติเผยแพร่** หรือ **จัดเก็บ**

---

## DB

- `listing_imports` — คิว + raw/parsed JSON (admin RLS)
- `listings.source_*` — อ้างอิง LI ID กันซ้ำ

---

## ทดสอบแล้ว

ลิงก์ตัวอย่าง: `istockdetail/DIoooI_DojybCI.html`

- ราคา ฿50,000/เดือน · 71.8 ตร.ม. · 9 รูป · LI ID 3097128
