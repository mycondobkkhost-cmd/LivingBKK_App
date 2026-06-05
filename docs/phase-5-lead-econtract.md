# Phase 5: Lead Routing + E-Contract (S5)

**Status:** Implemented in Flutter + migration  
**Date:** 2026-06-02

---

## Delivered

| Feature | Location |
|---------|----------|
| Lead inbox detail | `/work/lead/:id` — `LeadInboxDetailPage` |
| Accept + E-Contract gate | `e_contract_sheet.dart` → `e_contracts` + `lead_assignments` |
| Property unavailable | `lead_unavailable_sheet.dart` → updates `listings.available_again` |
| Commission tiers | `commission_repository.dart` + seed `commission_tiers` |
| Owner can update leads | migration `20260602120016_lead_owner_actions.sql` |
| Route assignee to owner | `route-lead-notification` edge function |

---

## User flow (Owner / Agent)

1. ลูกค้าส่งคำขอนัดดูจากแชท → `leads` + `qualification_json`
2. Edge `route-lead-notification` ตั้ง `assigned_to` = `listings.owner_id`, `status = routed`
3. แท็บ **งาน** → **กล่อง Lead** → เปิดรายละเอียด
4. **รับเคส** → ยอมรับ E-Contract (แสดง % คอมตามระยะสัญญา) → `accepted`
5. **ทรัพย์ไม่ว่าง** → เลือกวันที่ → `declined` + อัปเดต `available_again`

---

## Demo mode

- ตั้งโปรไฟล์เป็น **Owner** หรือ **Agent** (แท็บ ฉัน)
- เปิด **งาน** → กล่อง Lead มีรายการ demo `demo-lead-1`
- ทดสอบรับเคส / ไม่ว่างได้โดยไม่ต้อง Supabase

---

## Deploy backend

```bash
cd LivingBKK_App
supabase db push
supabase functions deploy route-lead-notification
```

---

## Next: Phase 4.5 (optional)

FCM push เมื่อแอปปิด — [mobile/docs/FCM_SETUP.md](../mobile/docs/FCM_SETUP.md)

## Next: Phase 6 (S9)

Admin dashboard ขยาย, Make.com sync, appointment workflow
