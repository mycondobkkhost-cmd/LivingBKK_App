# Phase 28: Rental Ops Production (27c cron + เอกสาร)

**Status:** Implemented (Flutter + Edge cron; production schedule ตั้งใน Supabase Dashboard)  
**Brand:** RealXtate

---

## เป้าหมาย

ปิดช่องว่างหลัง Phase 27 — ให้ **แจ้งชำระค่าเช่าอัตโนมัติ** และ **แนบเอกสารในกลุ่ม** ใช้งานได้จริง (demo + cloud)

| Step | รายการ |
|------|--------|
| **28a** | Edge `rental-payment-cron` — สแกนสัญญา active · ส่ง reminder · อัปเดต `reminders_sent_days_before` |
| **28b** | Flutter `RentalPaymentCronService` + ปุ่ม admin รัน cron ทุกสัญญา · บันทึก last run |
| **28c** | แนบเอกสารในแชทกลุ่ม (sheet + PII guard) · โพสต์เข้า thread |
| **28d** | Migration คอลัมน์ reminder บน `rental_payment_installments` · maintenance เขียน DB เมื่อ live |

---

## Cron (production)

```bash
# รายวัน 08:00 ICT (ตั้งใน Supabase Dashboard → Cron)
POST /functions/v1/rental-payment-cron
Authorization: Bearer <SERVICE_ROLE or CRON secret>
```

Preview / admin: `/admin?nav=rentalManagement` → **รัน cron แจ้งชำระ**

---

## Flutter

| Area | Path |
|------|------|
| Cron service | `mobile/lib/services/rental_payment_cron_service.dart` |
| แนบเอกสาร | `mobile/lib/features/rental/rental_document_attach_sheet.dart` |
| Admin รัน cron | `admin_rental_management_tab.dart` |

---

## อ้างอิง

- [phase-27-rental-management-group-chat.md](phase-27-rental-management-group-chat.md)
- Edge: `supabase/functions/rental-payment-cron/`, `notify-rental-payment/`
