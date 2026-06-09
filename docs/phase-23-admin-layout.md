# Phase 23b: Admin Layout — เลย์เอาต์หลังบ้านใหม่

**Status:** ✅ Implemented (shell + nav) · Vault tabs = placeholder รอ Phase 23  
**อ้างอิง:** [phase-23-admin-vault.md](phase-23-admin-vault.md)

---

## หลักการ

| กฎ | รายละเอียด |
|----|------------|
| **เร่งด่วน = ปักหมุด** | รอรับงาน · ลีดใหม่ · แชท — **ไม่ซ่อนในดรอปดาวน์** |
| **งานอื่น = กลุ่ม + badge** | ทรัพย์ · ลูกค้า · ระบบ · คลังลับ (CEO/SUPER) |
| **Desktop** | Sidebar ซ้าย + พื้นที่เนื้อหา |
| **Mobile** | Bottom bar 3 ปุ่มเร่งด่วน + ปุ่ม「เมนู」กลุ่มพร้อม badge |
| **Console Web** | `/admin/console` = workspace แชท (inbox + panel) — ลิงก์จากปุ่ม「แชท」 |

---

## โครงสร้างนำทาง

```
┌─────────────────────────────────────────────────────────────┐
│  PROPPITER Ops          [badge รวม]    🔄  🏠  ⎋            │
├──────────┬──────────────────────────────────────────────────┤
│ ปักหมุด  │                                                  │
│ ──────── │              เนื้อหาแท็บที่เลือก                  │
│ 🔴รอรับ  │                                                  │
│ 🔴ลีดใหม่│                                                  │
│ 💬 แชท   │                                                  │
│ ──────── │                                                  │
│ ▾ ทรัพย์ │  (3)                                             │
│ ▾ ลูกค้า │  (2)                                             │
│ ▾ ระบบ   │                                                  │
│ ▾ คลังลับ│  CEO/SUPER only (1)                              │
└──────────┴──────────────────────────────────────────────────┘
```

### ปักหมุด (Primary — ไม่มีดรอปดาวน์)

| ID | ชื่อ | Badge จาก |
|----|------|-----------|
| `queue` | รอรับงาน | `chatWaiting` |
| `leads` | ลีดใหม่ | `leadsNew` |
| `inbox` | แชท | `chatWaiting` (รวมใน KPI) |

### กลุ่มทรัพย์ & โพสต์ (dropdown + badge รวม)

| ID | ชื่อ | Badge |
|----|------|-------|
| `inventory` | ทะเบียนทรัพย์ PPTR | — |
| `import` | นำเข้าลิงก์ | `importsPending` |
| `moderation` | ตรวจสอบ | `moderationImages + moderationFlags` |
| `projects` | ทะเบียนโครงการ | — |

### กลุ่มลูกค้า & เคส

| ID | ชื่อ | Badge |
|----|------|-------|
| `appointments` | นัดชม | `appointmentsPending` |
| `offers` | ข้อเสนอบอร์ด | `offersPending` |
| `requirements` | ความต้องการลูกค้า | `customerRequirementsPending` |

### กลุ่มระบบ & ตั้งค่า

| ID | ชื่อ |
|----|------|
| `dashboard` | ภาพรวม |
| `reports` | รายงาน |
| `boardCreate` | สร้างบอร์ด |
| `promos` | โฆษณา |
| `watermark` | ลายน้ำ |

### กลุ่มคลังลับ (CEO / SUPER เท่านั้น)

| ID | ชื่อ | Badge (อนาคต) |
|----|------|---------------|
| `vault` | คลังข้อมูลลับ | — |
| `accessRequests` | คำขอสิทธิ์ | `accessRequestsPending` |
| `org` | องค์กร / ตำแหน่ง | CEO only |

---

## Responsive

| จอ | พฤติกรรม |
|----|----------|
| ≥ 900px | `AdminShellScaffold` sidebar 220px |
| < 900px | Bottom nav: รอรับ · ลีด · เมนู |
| Web + แชท | กด「แชท」หรือ KPI แชท → `/admin/console` |

---

## สี Badge

| ระดับ | เงื่อนไข |
|-------|----------|
| แดง | `queue`, `leads` เมื่อ count > 0 |
| ส้ม | กลุ่มทรัพย์/ลูกค้า เมื่อ badge > 0 |
| ม่วง | คลังลับ / คำขอสิทธิ์ |

---

## โค้ด

| ไฟล์ | หน้าที่ |
|------|---------|
| `admin_nav_model.dart` | ID, กลุ่ม, badge |
| `admin_shell_scaffold.dart` | Sidebar + mobile bottom |
| `admin_home_page.dart` | ใช้ shell แทน TabBar 13 แท็บ |
| `admin_dashboard_bar.dart` | กด KPI → `AdminNavId` |

---

## ขั้นถัดไป (Phase 23 implement)

1. หน้า `vault` / `accessRequests` / `org` จริง (ตอนนี้ placeholder)
2. `queue` แยกฟิลเตอร์เฉพาะรอรับ (ตอนนี้ใช้ `AdminChatsTab` เหมือน inbox)
3. `fetchAdminTier()` จาก `profiles.admin_tier`
