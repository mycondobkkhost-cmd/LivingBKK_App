# Phase 21: Analytics Platform — รองรับผู้ใช้แสนคน

**สถานะ:** Implemented (foundation)  
**อัปเดต:** 2026-06-05

---

## เป้าหมาย

ระบบรายงานระดับองค์กรสำหรับ PROPPITER — **ละเอียด ครอบคลุม และ scale** โดยไม่ query ข้อมูลดิบทุกครั้งที่เปิดแอดมิน

| หลัก | รายละเอียด |
|------|------------|
| **Append-only events** | `analytics_events` — บันทึก view/share/chat (ไม่มี PII) |
| **Pre-aggregate rollups** | ตาราง `analytics_*_daily` — อ่านเร็ว |
| **OLTP sync** | Lead, นัด, e-contract, chat รวมใน `refresh_analytics_rollups()` |
| **No PII ใน export** | Make.com / Sheets ใช้ rollups เท่านั้น |

---

## สถาปัตยกรรม (100k+ users)

```
Client (Flutter)
  └─ AnalyticsService (batch) → Edge analytics-track
        └─ analytics_events (append, BRIN index)

Cron ทุก 1 ชม.
  └─ Edge analytics-rollup-cron
        └─ refresh_analytics_rollups()
              ├─ analytics_platform_daily
              ├─ analytics_district_daily
              ├─ analytics_listing_daily
              └─ analytics_chat_daily

Admin UI (6 แท็บ)
  └─ AnalyticsAdminRepository → rollup tables only

Owner UI
  └─ analytics_listing_daily (RLS: owner_id = auth.uid())

อนาคต (แสนคน+)
  └─ Export rollups → BigQuery / ClickHouse / Looker
```

---

## ตาราง / View

| ชื่อ | ใช้กับ |
|------|--------|
| `analytics_events` | raw product events |
| `analytics_platform_daily` | KPI รายวันทั้งแพลตฟอร์ม |
| `analytics_district_daily` | breakdown เขต |
| `analytics_listing_daily` | ต่อประกาศ + owner insights |
| `analytics_chat_daily` | แชทตาม category + SLA |
| `analytics_platform_stats` | view สำหรับ Make.com (backward compatible) |

Migration: `supabase/migrations/20260605120000_analytics_platform.sql`

---

## Edge Functions

| Function | หน้าที่ |
|----------|---------|
| `analytics-track` | รับ batch events จาก client (สูงสุด 50/ครั้ง) |
| `analytics-rollup-cron` | เรียก `refresh_analytics_rollups` (ตั้ง cron รายชั่วโมง) |

Deploy: `./scripts/deploy-all.sh`

### Cron (Supabase Dashboard)

```
POST .../functions/v1/analytics-rollup-cron?days=30
Authorization: Bearer {CRON_SECRET}
```

แนะนำ: ทุก **1 ชั่วโมง**

---

## UI ในแอป

| ที่อยู่ | เนื้อหา |
|--------|---------|
| Admin → แท็บ **รายงาน** | `AdminAnalyticsHub` — 8 แท็บ |
| ความถี่ | **ทุก 12 ชม.** / **ทุก 24 ชม.** / รายวัน (7–30 วัน) |
| ภาพรวม | KPI + กราฟตามช่วง 12/24 ชม. หรือรายวัน |
| แอป | ติดตั้ง · เปิดแอป · ถอน (ประมาณ) |
| ข้อผิดพลาด | รวม error + **คำแปลไทย + แนวทางแก้** (`error_catalog.dart`) |
| Funnel | 8 ขั้น ถึงปิดดีล |
| เขต/โซน | Top districts |
| แชท/SLA | volume, claim rate, breaches |
| ทรัพย์ยอดนิยม | engagement score |
| ส่งออก | rollup refresh + TSV + Make.com |

| ประกาศของฉัน | local + server rollup (เมื่อ login) |

---

## Make.com (อัปเดต)

ดึงจาก rollup แทน view เก่า (ยังใช้ `platform_stats_daily` ได้):

```
GET .../rest/v1/analytics_platform_daily?order=stat_date.desc&limit=30
```

หรือ view:

```
GET .../rest/v1/analytics_platform_stats?order=stat_date.desc&limit=30
```

---

## Scale path (ถัดไป)

1. **Partition** `analytics_events` รายเดือน เมื่อ >10M แถว  
2. **Retention** — archive events >90 วัน ไป cold storage  
3. **BigQuery sync** — nightly export rollups  
4. **Real-time dashboard** — Supabase Realtime บน rollup refresh (optional)  
5. **Listing impressions** — map marker tap batching  

---

## ทดสอบ

1. `./scripts/deploy-all.sh`  
2. Admin → รายงาน → กด **รีเฟรช rollup**  
3. เปิดประกาศ / แชร์ → รอ flush 30s → rollup อีกครั้ง  
4. โหมด Demo: ตัวเลขตัวอย่างใน `AnalyticsAdminRepository`
