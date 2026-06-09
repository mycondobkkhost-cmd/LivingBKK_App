# Phase 23: Admin Vault — คลังข้อมูลลับ + ลำดับชั้น CEO/SUPER/LEAD/ADMIN

**Status:** Planned (สเปกยืนยันแล้ว — รอ implement)  
**อัปเดต:** 2026-06-06  
**อ้างอิง:** [business-rules.md](business-rules.md) · [phase-16-chat-ops.md](phase-16-chat-ops.md) · [phase-18-li-import.md](phase-18-li-import.md) · [phase-19-listing-lifecycle-push.md](phase-19-listing-lifecycle-push.md)

---

## 1. วัตถุประสงค์

แยก **ข้อมูลลับ (PII / ลิงก์ต้นทาง / ข้อความโพสต์เต็ม)** ออกจากหน้าปฏิบัติการแอดมินปกติ โดย:

- แอดมิน **ADMIN** เห็นเฉพาะข้อมูลสาธารณะ (เซ็นเซอร์) — แก้รายละเอียดประกาศได้โดยไม่ขอสิทธิ์
- ข้อมูลลับต้อง **ขอสิทธิ์** (ติ๊กเลือก + เหตุผล) → **SUPER+** อนุมัติ
- **CEO / SUPER** เข้า **แท็บคลังลับ** เห็นข้อมูลเต็ม + แท็กกลับทุก entity
- ทุกการเปิดดู / อนุมัติ / แชท / แบน → **audit ย้อนหลังได้**

---

## 2. ลำดับชั้นบัญชี (Org chart)

```
CEO
 └── SUPER
      └── LEAD
           └── ADMIN
```

| ชั้น | คลังลับ (Vault tab) | แต่งตั้งตำแหน่ง | อนุมัติคำขอสิทธิ์ | มอบสิทธิ์ข้อมูล | แบนบัญชี/โพส | ปฏิบัติการ (โพส/แชทเซ็นเซอร์) |
|------|---------------------|----------------|-------------------|----------------|-------------|-------------------------------|
| **CEO** | ✓ | ✓ ทุกชั้น | ✓ | ✓ | ✓ | ✓ |
| **SUPER** | ✓ | ✗ (ยกเว้น CEO ชั่วคราว) | ✓ | ✓ | ✓ | ✓ |
| **LEAD** | ✗ | ✗ | ✗* | ✗* | ✗ | ✓ |
| **ADMIN** | ✗ | ✗ | ✗ (ขอเท่านั้น) | ✗ | ✗ | ✓ (เซ็นเซอร์) |

\* **LEAD อนุมัติไม่ได้** — ยกเว้น **SUPER มอบหมายชั่วคราว** ให้อนุมัติแทน (ดู §5.3)

### 2.1 CEO ชั่วคราว

CEO มอบให้ SUPER เป็น **CEO ชั่วคราว** เป็นเวลา X ชั่วโมง:

- ในช่วงนั้น SUPER แต่งตั้งตำแหน่ง (SUPER / LEAD / ADMIN) ได้
- หมดเวลา → สิทธิ์แต่งตั้งหายทันที
- บันทึก `admin_delegations` + audit

### 2.2 ของเดิมใน repo

Migration `20260605170000_gaps_pir_chat_requirements.sql` มี:

- `profiles.admin_tier` = `standard` | `lead` | `super` (ยังไม่ใช้ในแอป)
- `owner_contact_requests` (ขอเบอร์ต่อ listing — โครงเก่า)

**Phase 23** จะ:

1. เปลี่ยน `admin_tier` → `admin` | `lead` | `super` | `ceo`
2. แทนที่/ขยาย `owner_contact_requests` ด้วย `admin_access_requests` + `admin_access_grants`
3. ปิดรูรั่ว RLS (`listing_imports` ให้ ADMIN อ่านตรงไม่ได้)

---

## 3. โมเดลสิทธิ์ — แบบ A (Per-entity)

สิทธิ์ผูกกับ **รายการเดียว** เท่านั้น — ไม่มี “เปิดทั้งระบบ 24 ชม.”

| `entity_type` | ตัวอย่าง |
|---------------|----------|
| `listing` | PPTR-2026-001234 |
| `listing_import` | แถวนำเข้าจาก LI/FB |
| `chat_thread` | แชท ops กับเจ้าของ/เอเจ้น |
| `profile` | บัญชีผู้โพสต์ |

สิทธิ์ที่ listing A **ใช้กับ listing B ไม่ได้** แม้โพสต์คนเดียวกัน

---

## 4. รายการสิทธิ์ (Scopes)

Enum ร่าง: `admin_access_scope`

| Scope | ความหมาย | อายุ |
|-------|----------|------|
| `contact.phone` | เบอร์โทรเต็ม | SUPER เลือกชม. (§5.2) |
| `contact.line` | Line ID | เหมือนกัน |
| `source.url` | ลิงก์ต้นทาง LI/FB/เว็บ | เหมือนกัน |
| `source.post_raw` | ข้อความโพสต์เต็ม (ก่อนตัดเบอร์) | เหมือนกัน |
| `source.poster_profile` | โปรไฟล์ผู้โพสต์ภายนอก | เหมือนกัน |
| `ops.send_seeker_profile` | ส่งโปรไฟล์ผู้สนใจให้เจ้าของยืนยันเคส | เหมือนกัน |
| `ops.chat_reply` | ตอบแชทเจ้าของ/เอเจ้นในเธรดนี้ | **ไม่จำกัดเวลา** (§5.1) |

**หมายเหตุ:** `mod.ban_user` / `mod.ban_post` ไม่ใช่ scope ต่อ entity — เป็นสิทระดับชั้น **SUPER+** เท่านั้น

---

## 5. กฎอายุสิทธิ์

### 5.1 ข้อยกเว้น — แชท (`ops.chat_reply`)

- อนุมัติแล้ว **คุยได้ยาวๆ ไม่หมดเวลา**
- หมดเมื่อ: SUPER+ **ถอนสิทธิ์** · ปิดเธรดถาวร · แบนบัญชี
- **ไม่ใช้** ช่องเลือกชั่วโมงร่วมกับ scope อื่น

### 5.2 Scope อื่นทั้งหมด

ตอน SUPER/CEO อนุมัติ:

1. ติ๊กยืนยัน scope ที่จะส่งกลับ (อาจ **น้อยกว่า** ที่ขอ)
2. เลือก **ชั่วโมงเดียว** → ใช้กับ **ทุก scope ที่ติ๊กในคำอนุมัติครั้งนั้น** (ยกเว้น `ops.chat_reply`)
3. ครบชั่วโมง → กลับเซ็นเซอร์อัตโนมัติ
4. ปิดโพส / จัดเก็บ import → หมดสิทธิ์ทันที (แม้ยังไม่ครบชั่วโมง)

### 5.3 LEAD อนุมัติคำขอ

| กฎ | รายละเอียด |
|----|------------|
| ปกติ | LEAD **อนุมัติไม่ได้** |
| ยกเว้น | SUPER มอบ `can_approve_requests` ชั่วคราว X ชม. ให้ LEAD คนใดคนหนึ่ง |
| ขอบเขตมอบหมาย | SUPER กำหนดได้ว่า LEAD อนุมัติ scope ใดได้บ้าง (หรือทั้งหมดยกเว้นแชทไม่จำกัดเวลา) |

---

## 6. โฟลว์ขอ / อนุมัติสิทธิ์

```
ADMIN
  → เลือก entity (โพส / import / แชท / บัญชี)
  → ☑ ติ๊ก scope ที่ต้องการ (หลายรายการ)
  → กรอกเหตุผล (บังคับ)
  → ส่งคำขอ (status = pending)

SUPER / CEO (หรือ LEAD ที่ได้มอบชั่วคราว)
  → เปิดคำขอ
  → ☑ ยืนยัน/ตัด scope ที่ส่งกลับ
  → ถ้ามี scope ที่ไม่ใช่แชท: เลือกชั่วโมงเดียว
  → อนุมัติ / ปฏิเสธ (+ admin_note)

ระบบ
  → สร้าง admin_access_grants ต่อ scope
  → audit: access.requested | access.approved | access.denied | vault.viewed
```

### 6.1 UI อนุมัติ (SUPER)

```
คำขอจาก ADMIN · listing PPTR-2026-001234
เหตุผล: ติดต่อเจ้าของยืนยันนัด

☑ เบอร์โทร
☑ ลิงก์ต้นทาง
☐ ข้อความโพสต์เต็ม
☑ ตอบแชทเจ้าของ        ← ไม่มีช่องชั่วโมง

ระยะเวลา (ชม.) สำหรับติ๊กด้านบน (ยกเว้นแชท): [ 48 ▼]

[อนุมัติ]  [ปฏิเสธ]
```

---

## 7. แท็บ UI หลังบ้าน

| ผู้ใช้ | แท็บที่เห็น |
|--------|-------------|
| **CEO / SUPER** | ปฏิบัติการ + **คลังลับ** + มอบสิทธิ์/แต่งตั้ง (CEO) + คิวคำขอสิทธิ์ |
| **LEAD** | ปฏิบัติการ + คิวงาน (ไม่มีคลังลับ) |
| **ADMIN** | ปฏิบัติการเท่านั้น — PII เซ็นเซอร์ + ปุ่ม「ขอเข้าถึงข้อมูลลับ」 |

Route ร่าง:

| Path | ชั้นขั้นต่ำ |
|------|-------------|
| `/admin/console` | ADMIN+ |
| `/admin/vault` | CEO, SUPER |
| `/admin/access-requests` | SUPER+ (LEAD ถ้าได้มอบชั่วคราว) |
| `/admin/org` | CEO (แต่งตั้งตำแหน่ง) |

### 7.1 สิ่งที่ ADMIN ทำได้โดยไม่ขอสิทธิ์

- แก้ title / รายละเอียดสาธารณะ / ราคา / รูป
- เปลี่ยนสถานะโพส (ซ่อน / เผยแพร่ — ตามนโยบาย)
- เปิดหน้าบัญชีผู้โพส (ชื่อแสดง, สถานะ — **ไม่มีเบอร์/Line**)
- เปิดแท็กโพส / import / แชท (ลิงก์ภายในองค์กร)

### 7.2 สิ่งที่ต้องขอสิทธิ์

- เบอร์ / Line / ลิงก์ต้นทาง / ข้อความโพสต์เต็ม
- ตอบแชทเจ้าของ (ถ้ายังไม่มี `ops.chat_reply` บนเธรด)
- ส่งโปรไฟล์ seeker ให้ยืนยันเคส

---

## 8. คลังลับ — โครงข้อมูล

### 8.1 หลักการ

- **ตารางกลาง** + แท็กกลับ entity — ย้อนดูง่าย ไม่งง
- ข้อความแชทอยู่ `chat_messages` (ไม่ยัด vault)
- ข้อมูล sensitives อ่านผ่าน **Edge Function / RPC** เท่านั้น — ไม่ SELECT ตรงจาก Flutter สำหรับ ADMIN

### 8.2 ตารางใหม่

#### `vault_assets`

เก็บ snapshot ข้อมูลลับต่อ entity

```sql
CREATE TABLE public.vault_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL
    CHECK (entity_type IN ('listing','listing_import','profile','chat_thread')),
  entity_id uuid NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}',
  -- payload ตัวอย่าง:
  -- listing_import: { source_url, post_text_full, phones[], lines[], poster_name, poster_url, post_links[] }
  -- listing: { owner_phones[], owner_lines[], signup_contact, internal_notes }
  -- profile: { phone, line_id, verified_contact }
  source_platform text,
  captured_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (entity_type, entity_id)
);
```

#### `admin_access_requests`

```sql
CREATE TABLE public.admin_access_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  requested_by uuid NOT NULL REFERENCES public.profiles (id),
  reason text NOT NULL CHECK (length(trim(reason)) >= 8),
  scopes_requested text[] NOT NULL,
  scopes_approved text[],
  grant_hours int,                    -- NULL ถ้าอนุมัติแค่ ops.chat_reply
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','approved','denied','expired','revoked')),
  reviewed_by uuid REFERENCES public.profiles (id),
  admin_note text,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

#### `admin_access_grants`

```sql
CREATE TABLE public.admin_access_grants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid REFERENCES public.admin_access_requests (id),
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  grantee_id uuid NOT NULL REFERENCES public.profiles (id),
  scope text NOT NULL,
  granted_by uuid NOT NULL REFERENCES public.profiles (id),
  expires_at timestamptz,             -- NULL = ops.chat_reply (ไม่หมดเวลา)
  revoked_at timestamptz,
  revoked_by uuid REFERENCES public.profiles (id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX admin_access_grants_active_idx
  ON public.admin_access_grants (grantee_id, entity_type, entity_id)
  WHERE revoked_at IS NULL;
```

#### `admin_delegations`

CEO ชั่วคราว + SUPER มอบ LEAD อนุมัติ

```sql
CREATE TABLE public.admin_delegations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  delegator_id uuid NOT NULL REFERENCES public.profiles (id),
  delegatee_id uuid NOT NULL REFERENCES public.profiles (id),
  delegation_type text NOT NULL
    CHECK (delegation_type IN ('ceo_acting','approve_requests')),
  allowed_scopes text[],
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

#### `admin_audit_log` (ขยาย)

เพิ่ม action มาตรฐาน:

| action | เมื่อไหร่ |
|--------|----------|
| `vault.view` | เปิดดูข้อมูลลับ (ระบุ scope + entity) |
| `access.request` | ส่งคำขอ |
| `access.approve` / `access.deny` | อนุมัติ/ปฏิเสธ |
| `access.revoke` | ถอนสิทธิ์ |
| `delegation.grant` | มอบ CEO ชั่วคราว / มอบ LEAD อนุมัติ |
| `org.tier_change` | CEO เปลี่ยนตำแหน่ง |
| `mod.ban_user` / `mod.ban_post` | SUPER+ แบน |
| `chat.admin_reply` | แอดมินส่งข้อความ (มี sender_admin_id) |

### 8.3 ย้ายข้อมูลเดิม

| แหล่งเดิม | ไปที่ |
|-----------|-------|
| `listing_imports.raw_payload.contact_private` | `vault_assets` entity=`listing_import` |
| `listing_imports.raw_payload.source_meta` | `vault_assets.payload` |
| `listings.source_url` (admin-only column) | ย้ายเข้า vault · ลบจาก SELECT มาตรฐาน |
| `profiles.phone` / `line_id` | vault entity=`profile` · RLS บังสำหรับ ADMIN |
| `owner_contact_requests` | migrate → `admin_access_requests` แล้ว deprecate |

---

## 9. RLS และ API

### 9.1 หลัก

| ตาราง | ADMIN | SUPER/CEO |
|-------|-------|-----------|
| `vault_assets` | **ไม่มี policy SELECT** | ผ่าน RPC/Edge เท่านั้น |
| `listing_imports` | แถวคิว **ไม่มี** `raw_payload` / `parsed.contact` | SUPER+ หรือมี grant |
| `listings` | `listings_public` + ฟิลด์ ops เซ็นเซอร์ | เต็มผ่าน vault API |
| `profiles` | `display_name`, `role` — ไม่มี phone/line | vault API |

### 9.2 Edge Functions ร่าง

| Function | หน้าที่ |
|----------|---------|
| `vault-read` | อ่าน payload ตาม scope + ตรวจ grant + audit |
| `access-request-create` | ADMIN ส่งคำขอ |
| `access-request-review` | SUPER+/delegated LEAD อนุมัติ |
| `access-grant-revoke` | SUPER+ ถอนสิทธิ์ |
| `admin-delegation-grant` | CEO/SUPER มอบชั่วคราว |
| `admin-tier-set` | CEO เปลี่ยนตำแหน่ง |

### 9.3 Helper SQL

```sql
CREATE OR REPLACE FUNCTION public.has_vault_grant(
  p_grantee uuid,
  p_entity_type text,
  p_entity_id uuid,
  p_scope text
) RETURNS boolean ...
-- ตรวจ grant ยัง active: revoked_at IS NULL AND (expires_at IS NULL OR expires_at > now())
```

---

## 10. แชทหลายแอดมิน (ปรับจาก Phase 16)

Phase 16 ล็อก `assigned_admin_id` คนเดียว — Phase 23 ปรับดังนี้:

| หัวข้อ | กฎใหม่ |
|--------|--------|
| Inbox | แอดมินทุกคน **เห็นแชทร่วมกัน** (shared inbox) |
| รับเคส | กรอก/เลือก thread id → เข้าตอบต่อได้ |
| สิทตอบ | ต้องมี `ops.chat_reply` บน `chat_thread` (ไม่จำกัดเวลา) |
| ชื่อที่ลูกค้าเห็น | ก่อนมีคนรับ = **ชื่อแบรนด์ PROPPITER** · หลังตอบ = **ชื่อแอดมิน** (เช่น Agent NAT) |
| สลับคน | แอดมินคนใหม่ตอบ → ชื่อเปลี่ยนตามผู้ส่ง |
| บันทึก | `chat_messages.sender_admin_id` + `admin_audit_log` |
| เก็บข้อความ | **ไม่หมดอายุ** (พิจารณา archive ทีหลังถ้าโหลดหนัก) |

Migration ร่าง:

```sql
ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS sender_display_name text;

-- เก็บ active responders (หลายคนต่อเธรด)
CREATE TABLE public.chat_thread_participants (
  thread_id uuid REFERENCES public.chat_threads (id) ON DELETE CASCADE,
  admin_id uuid REFERENCES public.profiles (id) ON DELETE CASCADE,
  display_name text NOT NULL,
  joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (thread_id, admin_id)
);
```

---

## 11. สถานะประกาศปิด / หมดอายุ (หน้าบ้าน)

ประกาศปิด/หมดอายุ **ยังแสดงในแอป** แต่ **คาดแดงทับรูปทั้งหมด**:

| สถานะ | ข้อความบนรูป | เมื่อไหร่ |
|-------|-------------|----------|
| เช่า — ไม่ว่าง / ยกเลิก / หมดอายุ | **NOT AVAILABLE** | 30 วันไม่ยืนยัน → auto ([phase-19](phase-19-listing-lifecycle-push.md)) |
| ขาย — ยืนยันขายแล้ว | **SOLD** | เจ้าของ/เอเจ้น/แอดมินยืนยัน |
| ขาย — ยกเลิก / หมดอายุ | **NOT AVAILABLE** | เหมือนเช่า |

- แท็กกลับ vault / audit ยังทำได้
- คอลัมน์ร่าง: `listings.display_overlay` = `null` | `not_available` | `sold`
- View `listings_public` เปิด overlay + ไม่แสดง pin แม่นยำ (ตามนโยบายเดิม)

---

## 12. แท็กกลับภายในองค์กร (Cross-links)

ทุกหน้าปฏิบัติการต้องลิงก์ได้:

```
listing ←→ listing_import ←→ vault_asset
   ↓              ↓
profile (ผู้โพส) ←→ chat_thread ←→ lead / appointment
   ↓
admin ที่ edit / approve / chat (audit log)
```

| จาก | ไป |
|----|-----|
| โพสต์ | บัญชีผู้โพส · import ต้นทาง · แชท ops · แอดมินที่อนุมัติเผยแพร่ |
| Import | ลิงก์ต้นทาง (vault) · listing ที่สร้าง · แอดมินที่ดึง |
| แชท | โพสต์ · ผู้โพส · แอดมินที่ตอบ (ทุกคน) · คำขอสิทธิ์ที่เกี่ยวข้อง |
| บัญชีผู้ใช้ | โพสต์ทั้งหมด · แชท · audit แบน |

---

## 13. เลย์เอาต์ UI

ดู [phase-23-admin-layout.md](phase-23-admin-layout.md) — sidebar + ปักหมุดเร่งด่วน + กลุ่มดรอปดาวน์พร้อม badge

---

## 14. แผน implement (ลำดับแนะนำ)

| ลำดับ | งาน | ผลลัพธ์ |
|-------|-----|---------|
| **23.1** | Migration: `admin_tier` ใหม่ + ตาราง vault/grants/requests/delegations | Schema พร้อม |
| **23.2** | Backfill `vault_assets` จาก `listing_imports` + listings | ข้อมูลเดิมไม่หาย |
| **23.3** | RLS ปิดรูรั่ว + Edge `vault-read` / `access-*` | ADMIN อ่าน PII ตรงไม่ได้ |
| **23.4** | UI: แท็บคลังลับ (CEO/SUPER) + หน้าขอสิทธิ์ + คิวอนุมัติ | โฟลว์ครบ |
| **23.5** | UI: ปฏิบัติการเซ็นเซอร์ + ปุ่มขอสิทธิ์บน listing/import/chat | ADMIN ใช้งานได้ |
| **23.6** | แชท shared inbox + ชื่อแอดมินแยก + participants | หลายคนตอบได้ |
| **23.7** | Overlay NOT AVAILABLE / SOLD | หน้าบ้าน |
| **23.8** | หน้า CEO `/admin/org` + CEO ชั่วคราว + audit viewer | องค์กรครบ |

---

## 15. Flutter / ไฟล์ที่จะเพิ่ม (ร่าง)

```
mobile/lib/features/admin/vault/
  admin_vault_tab.dart          -- CEO/SUPER only
  admin_access_request_sheet.dart
  admin_access_review_sheet.dart
  admin_org_page.dart           -- CEO แต่งตั้งตำแหน่ง
  censored_contact_chip.dart    -- ███ + ปุ่มขอสิทธิ์

mobile/lib/services/
  vault_repository.dart
  admin_access_repository.dart
  admin_org_repository.dart
```

---

## 16. ทดสอบ (Acceptance)

1. ADMIN เปิด import → **ไม่เห็น** ลิงก์ FB/LI · เห็น `███` แทนเบอร์
2. ADMIN ขอ `contact.phone` + `source.url` + เหตุผล → SUPER อนุมัติแค่เบอร์ 12 ชม. → ADMIN เห็นเบอร์อย่างเดียว 12 ชม.
3. ADMIN ขอ `ops.chat_reply` → SUPER อนุมัติ → คุยได้ · ไม่หมด 48 ชม.
4. LEAD อนุมัติคำขอ → **ถูกปฏิเสิ์** (ยกเว้น SUPER มอบชั่วคราว)
5. CEO มอบ SUPER เป็น CEO 2 ชม. → SUPER แต่งตั้ง LEAD ได้ · หมด 2 ชม. แล้วทำไม่ได้
6. SUPER แบนบัญชี → audit มี · ADMIN แบนไม่ได้
7. โพสต์หมดอายุ 30 วัน → รูปมีคาด **NOT AVAILABLE**
8. ขายยืนยันแล้ว → คาด **SOLD**
9. แชท 2 แอดมินตอบสลับ → ลูกค้าเห็นชื่อคนละชื่อ · audit ครบ

---

## 17. Deploy (เมื่อ implement เสร็จ)

```bash
supabase db push
supabase functions deploy vault-read access-request-create access-request-review \
  access-grant-revoke admin-delegation-grant admin-tier-set
cd mobile && flutter build web
```

---

## 18. สรุปกฎที่ยืนยันแล้ว (Quick reference)

| หัวข้อ | กฎ |
|--------|-----|
| ลำดับชั้น | CEO → SUPER → LEAD → ADMIN |
| คลังลับ | แท็บแยก · CEO + SUPER เท่านั้น |
| แต่งตั้งตำแหน่ง | CEO (SUPER = CEO ชั่วคราวได้) |
| อนุมัติคำขอ | SUPER+ · LEAD ไม่ได้ (ยกเว้นมอบชั่วคราว) |
| ผูกสิทธิ์ | แบบ A — รายการเดียว |
| อายุข้อมูลลับ | SUPER เลือกชม.เดียวต่อคำอนุมัติ (ทุกติ๊กยกเว้นแชท) |
| แชทเจ้าของ | `ops.chat_reply` ไม่จำกัดเวลา |
| ขอสิทธิ์ | ติ๊ก scope + เหตุผลบังคับ |
| แบน | SUPER+ |
| แชท | Inbox ร่วม · ชื่อแอดมินแยก · audit กลาง |
| ปิดโพสต์ | NOT AVAILABLE / SOLD overlay |
