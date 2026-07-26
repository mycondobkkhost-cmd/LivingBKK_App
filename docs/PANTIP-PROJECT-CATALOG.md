# Pantip → RealXtate (ออปชัน — ไม่ใช่สมุดชื่อหลัก)

**อัปเดต:** 2026-07-27  
**สถานะ:** ลดบทบาท — ดูมาสเตอร์จริงที่ `docs/PROJECT-MASTER.md`

## สรุปหนึ่งประโยค

Pantip ใช้ได้แค่ **ชื่อเล่น / คำค้นเสริม**  
**ชื่อมาสเตอร์ + หมุดอาคาร = Property Hub**  
**ทำเล/รถไฟฟ้าเสริม = Property Hub + LivingInsider**

## อย่าใช้ Pantip เป็นสมุดหลัก

รอบนำเข้า Pantip (~2k) มีชื่อซ้ำ/เพี้ยน และพิกัดหลายอันเป็นแค่ใกล้สถานี  
ถ้า migration seed ถูก apply แถว `source_platform=pantip_curated` จะถูกตั้ง `is_active=false`
จนกว่า Property Hub จะยืนยันชื่อจริง (`20260727120000_property_projects_ph_name_master.sql`)

Upsert ของ Pantip **ไม่ทับ** `name_*` / พิกัด ของแถว `propertyhub`

## ทางที่ถูก

ดู `docs/PROJECT-MASTER.md` และรัน:

```bash
./scripts/build-project-master.sh
```

## ETL (ถ้ายังอยาก regenerate alias seed)

```bash
export PANTIP_ROOT=/path/to/pantip-property-hub
python3 scripts/import-pantip-projects.py
```

แถวใหม่จาก Pantip ถูกสร้างแบบ inactive เป็นค่าเริ่มต้น
