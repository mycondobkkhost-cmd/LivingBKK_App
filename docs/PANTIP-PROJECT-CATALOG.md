# Pantip → RealXtate project catalog

**อัปเดต:** 2026-07-26  
**สถานะ:** Seed + ETL ใน repo (รัน migration เพื่อโหลดขึ้น Supabase)

## ขอบเขต

นำ **แคตตาล็อกโครงการ/ทำเล/BTS** จาก Pantip Property hub เข้า RealXtate

| ทำ | ไม่ทำ |
|----|--------|
| ชื่อ TH/EN, aliases, zone tags, nearby transit | ดึง `properties.json` / sheet ประกาศ FB–Living เป็น inventory |
| จับคู่สถานี Pantip → สถานี RealXtate ที่มีพิกัด | scrape LivingInsider ใหม่ / redistribute Living HTML cache |
| upsert `property_projects` by `slug` | แทนที่พิกัดสถานีเดิมด้วยลิสต์ชื่อล้วน |

แหล่งต้นทาง (curated derivative): repo `pantip-property-hub` / `pantip-property-automation`

- `data/projects.json`
- `data/project_aliases.json`
- กฎ normalize ใน `src/hub/project_location_enrich.py` (อ้างอิงตอนออกแบบ ETL)

โทนแชท LINE อยู่ที่ `docs/CHAT-LINE-OA-PLAYBOOK-FROM-PANTIP.md` — **ไม่ใช่ข้อมูล geo**

## วิธีรัน ETL

```bash
# clone หรือชี้ไปที่ pantip hub ที่มี data/projects.json
export PANTIP_ROOT=/path/to/pantip-property-hub
python3 scripts/import-pantip-projects.py
```

ผลลัพธ์ใต้ `data/pantip_import/`:

| ไฟล์ | ความหมาย |
|------|----------|
| `property_projects_seed.json` | seed เต็มสำหรับตรวจ/ค้น |
| `coverage_report.json` | จำนวนโปรเจกต์ / % มี transit map / % มีพิกัด |
| `property_projects_seed.sql` | upsert SQL (สำเนาเข้า migration) |

พิกัด:

1. ถ้าจับคู่ bootstrap RealXtate (`bangkok_projects.dart`) → ใช้ lat/lng เดิม + slug เดิม  
2. ไม่มี bootstrap แต่ map สถานีได้ → `transit_approx` (พิกัดสถานี — รอ Places/admin)  
3. นอกนั้น → `lat/lng` null ใน DB (`source_platform = pantip_curated`)

## Migrations

- `supabase/migrations/20260726170000_property_projects_pantip_schema.sql` — nullable pin + aliases สถานี  
- `supabase/migrations/20260726170100_property_projects_pantip_seed.sql` — upsert แคตตาล็อก

แอป: `ProjectCatalog` / `project_picker_field` อ่านจาก `property_projects` (limit 5000) และค้น aliases แบบชื่อโครงการ (ไม่ใช้ alias ที่ขึ้นต้น BTS/MRT/ARL)

## ข้อจำกัด

- โครงการส่วนใหญ่ที่พิกัดเป็น `transit_approx` ยังไม่ใช่หมุดอาคารจริง — รอบถัดไป geocode  
- สถานีสายที่ยังไม่มีใน `bangkok_transit_station_coords.dart` เก็บเป็น label ใน `nearby_transit` ได้ แต่ไม่มีพิกัดสถานีในแอป  
