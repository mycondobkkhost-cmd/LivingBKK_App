# Phase 30: Production gaps closed (rental + docs)

**Status:** Implemented  
**Brand:** RealXtate

---

## 30a — อัปโหลดเอกสารกลุ่มเช่าจริง

| รายการ | Path |
|--------|------|
| Storage upload | `mobile/lib/services/rental_storage_service.dart` |
| File picker | `mobile/lib/features/rental/rental_document_picker.dart` |
| UI แนบเอกสาร | `rental_document_attach_sheet.dart` |
| Bucket | `rental-docs` (migration Phase 27d) |

โหมด live: อัปโหลด binary → บันทึก `storage_path` ใน `rental_group_attachments`  
Demo: metadata + SharedPreferences (ไม่บังคับไฟล์)

---

## 30b — Admin เพิ่มสมาชิกกลุ่มเช่า

| รายการ | Path |
|--------|------|
| Lookup แท็ก/UUID | `mobile/lib/services/rental_member_lookup.dart` |
| UI | `admin_rental_add_member_sheet.dart` |
| Service | `RentalLeaseService.addLeaseMember()` |

Preview: `/admin?nav=rentalManagement` → **เพิ่มสมาชิก**

---

## 30c — เอกสาร production

- [PRODUCTION-CRON-SETUP.md](PRODUCTION-CRON-SETUP.md) — cron lifecycle + rental payment
- อัปเดต [ROADMAP-REMAINING.md](ROADMAP-REMAINING.md) Phase 22–30
