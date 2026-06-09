# RealXtate — การตั้งชื่อแบรนด์และโดเมน

**อัปเดต:** 2026-06-05  
**สถานะ:** ตัดสินใจแล้ว — ใช้เป็นหลักในเอกสารและงานใหม่

---

## สรุป

| รายการ | ค่า |
|--------|-----|
| **ชื่อแบรนด์** | **RealXtate** |
| **โดเมนหลัก** | **RealXtateTH.com** → `https://realxtateth.com` |
| **ผู้ให้บริการโดเมน/DNS** | **Cloudflare** → เว็บที่ Netlify |
| **อีเมลติดต่อ/นโยบาย** | `privacy@realxtateth.com` |
| **ชื่อเดิม (เลิกใช้)** | LivingBKK, **PROPPITER** |

PROPPITER **ไม่ใช้อีกต่อไป** — รีแบรนด์เป็น RealXtate โดยสมบูรณ์

---

## โดเมน

- จด: **RealXtateTH.com** (DNS ไม่สนตัวพิมพ์ — ใช้ `realxtateth.com` ใน URL และ env)
- คู่มือตั้งค่า: [CUSTOM-DOMAIN.md](CUSTOM-DOMAIN.md)
- `WEB_BASE_URL=https://realxtateth.com` ใน `.env.local` → `./scripts/sync-env.sh`

---

## สิ่งที่ยังเป็น legacy ใน repo

| Legacy | สถานะ |
|--------|--------|
| `livingbkk` (package/bundle) | คงไว้จนกว่าจะเปลี่ยนแยกรอบ Store |
| asset ชื่อ `proppiter-*` | รอโลโก้ RealXtate ใหม่ — path ยังใช้ไฟล์เดิม |
| PROPPITER / LivingBKK ใน UI | **อัปเดตเป็น RealXtate แล้ว** (2026-06-10) |

---

## ข้อความมาตรฐาน (ร่าง)

- **TH:** RealXtate — แพลตฟอร์มอสังหาริมทรัพย์ กรุงเทพฯ และปริมณฑล
- **EN:** RealXtate — Bangkok & vicinity property platform

---

## ลิงก์สาธารณะ (หลัง deploy โดเมน)

- Privacy: `https://realxtateth.com/legal/privacy.html`
- Terms: `https://realxtateth.com/legal/terms.html`
