# Phase 20 — ทรัพย์ Exclusive (เจ้าของ + นายหน้า)

## 1. ฝาก Exclusive เจ้าของ

- ตัวเลือกในขั้น「ราคาและส่งตรวจ」เมื่อเลือกผู้ประกาศ = เจ้าของ
- เช่า: สัญญาเริ่มต้น 30 / 60 / 90 วัน (ห้ามฝากที่อื่น)
- ขาย / ขายฝาก: ขั้นต่ำ 3 เดือน (เทียบตลาด ~1 ปี)
- กดสนใจ → อ่านเงื่อนไขเบื้องต้น → ทีมติดต่อแชท + เซ็นออนไลน์ภายหลัง
- ฟิลด์ DB: `owner_exclusive_mandate`, `owner_exclusive_contract_days`, `owner_exclusive_status`

## 2. Exclusive นายหน้า

- ตัวเลือกในขั้น「ผู้ประกาศ」เมื่อเลือกเอเจนท์
- ฟิลด์ DB: `agent_exclusive`
- คะแนนฟีดสูงขึ้น (`ListingBrowseSorter` + `exclusive_agent_feed_boost`)

## 3. แอดมิน

- แดชบอร์ด → การ์ด「ตั้งค่า Exclusive & ดันฟีด」
- ตาราง `app_platform_settings`: ช่วงดันฟีดเช่า (ชม.) / ขาย (ชม.) / คะแนนฟีด
- Cron: `SELECT public.process_exclusive_auto_bumps();` (รายชั่วโมงแนะนำ)

## Migration

`supabase/migrations/20260604210000_listing_exclusive.sql`

```bash
supabase db push
```
