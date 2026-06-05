# LivingBKK — Production Checklist

ทำครบก่อนเปิดใช้จริง (ยังไม่ต้องทดสอบทีละจุ ก็ทำตามลำดับได้)

## Backend

- [ ] `.env.local` มี `SUPABASE_URL` + `SUPABASE_ANON_KEY` (จาก Connect)
- [ ] `supabase db push` — **45 migrations** รวม `pending_review`, `sale_installment`, **PPTR inventory**, **exclusive**, **viewing_access** (ดู [PRE-PUSH-STATUS.md](PRE-PUSH-STATUS.md))
- [ ] `source scripts/dev-path.sh && ./scripts/deploy-all.sh`
- [ ] `./scripts/seed-cloud.sh` หรือรัน SQL ใน Dashboard
- [ ] Auth → Email → ปิด Confirm email (ช่วงทดสอบ)
- [ ] Admin: `demo-admin@livingbkk.local` / `demo12345` (หลัง seed) หรือดู [บัญชี-admin.md](บัญชี-admin.md)
- [ ] Edge secrets: `FCM_SERVER_KEY`, `MAKECOM_WEBHOOK_URL` (ทางเลือก)
- [ ] Cron รายวัน → `listing-lifecycle-cron`
- [ ] Cron (แนะนำ) → `SELECT public.process_exclusive_auto_bumps();` รายชั่วโมง

## Mobile / Web

- [ ] `./scripts/sync-env.sh`
- [ ] `cd mobile && flutter pub get`
- [ ] `./scripts/run-app.sh` (Chrome)
- [ ] `GOOGLE_MAPS_API_KEY` (ทางเลือก — ไม่มีก็ใช้ OSM)
- [ ] `FIREBASE_*` (ทางเลือก — push นอกแอป)

## ฟีเจอร์หลักที่ควรมีครบ

- [ ] หน้าแรก: ค้นหา, แผนที่, เลื่อนรายการ, Killer chips
- [ ] ลงประกาศฟรี + moderation ข้อความ
- [ ] Lead Bot + งาน (inbox) + E-Contract
- [ ] Demand Board + Admin ข้อเสนอ
- [ ] Admin: Leads, นัดชม, รายงาน, **Moderation**, **ทะเบียนทรัพย์ (PPTR)**
- [ ] Realtime แจ้งเตือนในแอป

## นโยบาย

- [ ] โพสต์ฟรี — **ไม่มี**แพ็ก 20k/ปี
- [ ] รายได้จาก Success Fee เท่านั้น

ดูรายละเอียดแต่ละ Phase ใน `docs/phase-*.md`
