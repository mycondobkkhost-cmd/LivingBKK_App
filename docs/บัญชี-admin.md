# บัญชี Admin — LivingBKK

## บัญชี Demo (หลังรัน seed)

| บทบาท | อีเมล | รหัสผ่าน |
|--------|--------|----------|
| **Admin** | `demo-admin@livingbkk.local` | `demo12345` |
| Owner (ทดสอบลงประกาศ) | `demo-owner@livingbkk.local` | `demo12345` |
| **เอเจ้นพานัด Agent One** | `agent-one@proppiter.local` | `demo12345` |
| เอเจ้นพานัด Agent Two | `agent-two@proppiter.local` | `demo12345` |
| เอเจ้นพานัด Agent Three | `agent-three@proppiter.local` | `demo12345` |
| เอเจ้นพานัด Agent Four | `agent-four@proppiter.local` | `demo12345` |
| เอเจ้นพานัด Agent Five | `agent-five@proppiter.local` | `demo12345` |

รัน seed: `./scripts/seed-cloud.sh` หรือ SQL Editor → `supabase/seed.sql`

ในแอป: **เข้าสู่ระบบ** → แท็บ **ฉัน** → **ศูนย์ Admin**

**โหมดทีม (แนะนำ):** ทุกคนล็อกอิน `demo-admin@livingbkk.local` แล้วกด **สลับตัวละคร** ภายใน — ดู `docs/โหมดสลับตัวละคร.md`  
ตัวอย่าง: `admin-01` / `admin-01`, `guide-03` / `guide-03`, `ceo-01` / `ceo-01`

**ตอบแชทบนคอม (Web):** เปิด `/admin/console` — inbox + แชทในจอเดียว  
**นำเข้าทรัพย์ LI:** Admin → แท็บ **นำเข้า** หรือ `/admin/import`  
รัน local: `./scripts/run-admin-console.sh`

---

## Supabase Cloud (โปรเจกต์จริง)

ยังไม่มี admin อัตโนมัติ — เลือกอย่างใดอย่างหนึ่ง:

### วิธี A — สมัครในแอปแล้วตั้ง role

1. สมัคร/ล็อกอินด้วยอีเมลของคุณในแอป  
2. Supabase Dashboard → **SQL Editor** → รัน:

```sql
UPDATE public.profiles
SET role = 'admin', display_name = 'Admin'
WHERE id = (
  SELECT id FROM auth.users WHERE email = 'อีเมลที่คุณสมัคร@example.com'
);
```

3. ออกจากระบบแล้วล็อกอินใหม่ → เปิด **ศูนย์ Admin**

### วิธี B — ในแอป (ถ้าล็อกอินแล้ว)

แท็บ **ฉัน** → **บทบาท** → เลือก **Admin** (บันทึกลง `profiles.role`)  
จากนั้นกด **ศูนยี Admin**

### วิธี C — รัน demo admin บน Cloud

SQL Editor → วางเนื้อหาส่วน `demo-admin` จาก `supabase/seed.sql` (บล็อก `demo-admin@livingbkk.local`)  
แล้วล็อกอินด้วยอีเมล/รหัสด้านบน

---

## โหมด Demo (ยังไม่ต่อ Supabase)

แท็บ **ฉัน** → เลือกบทบาท **Admin** → เปิด Admin ได้ (UI ทดสอบ · ไม่มีข้อมูลจริง)

---

## Auth

Dashboard → **Authentication → Providers → Email** → ปิด **Confirm email** ช่วงทดสอบ
