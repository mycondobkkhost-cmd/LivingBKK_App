# Production Cron Setup — RealXtate

ตั้ง cron บน **Supabase Dashboard** (หรือ pg_cron) หลัง `db push` + `deploy-all.sh`

---

## 1. Listing lifecycle (รายวัน)

| รายการ | ค่า |
|--------|-----|
| Edge | `listing-lifecycle-cron` |
| ความถี่ | รายวัน ~02:00 ICT |
| Auth | `Authorization: Bearer <SERVICE_ROLE_KEY>` |

```bash
curl -X POST "$SUPABASE_URL/functions/v1/listing-lifecycle-cron" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

---

## 2. Rental payment reminders (รายวัน)

| รายการ | ค่า |
|--------|-----|
| Edge | `rental-payment-cron` |
| ความถี่ | รายวัน ~08:00 ICT |
| Auth | Service role |

```bash
curl -X POST "$SUPABASE_URL/functions/v1/rental-payment-cron" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

Preview / ทดสอบมือ: `/admin?nav=rentalManagement` → **รัน cron แจ้งชำระ**

---

## 3. Exclusive auto bump (รายชั่วโมง — แนะนำ)

```sql
SELECT public.process_exclusive_auto_bumps();
```

---

## 4. ลำดับ deploy ครั้งแรก

```bash
source scripts/dev-path.sh
supabase db push          # migrations 101+ ไฟล์
./scripts/deploy-all.sh
./scripts/seed-cloud.sh
./scripts/verify-ready.sh
```

ดูรายการ E2E: [PRODUCTION-CHECKLIST.md](PRODUCTION-CHECKLIST.md)
