# จดโดเมนและเชื่อม RealXtate กับ Netlify

คู่มือนี้ช่วยให้คุณซื้อโดเมนเอง แล้วเชื่อมกับเว็บแอปที่ deploy บน Netlify ได้ทีละขั้น — **ไม่ต้องเขียนโค้ดเพิ่ม** ถ้าทำตาม checklist ครบ

> **เริ่มจดโดเมนทีละขั้น:** [จดโดเมน-RealXtateTH.md](จดโดเมน-RealXtateTH.md)

## โดเมนที่จะใช้

| โดเมน | หมายเหตุ |
|-------|----------|
| **RealXtateTH.com** | โดเมนหลักที่จะจด — ในระบบใช้ `realxtateth.com` (ตัวพิมพ์เล็ก, DNS ไม่สนตัวพิมพ์) |

**Production ปัจจุบัน:** https://quiet-kangaroo-ab6073.netlify.app  
หลังตั้งโดเมนแล้ว เปลี่ยนเป็น `https://realxtateth.com`

---

## Checklist สรุป (ทำตามลำดับ)

- [ ] 1. ซื้อโดเมน
- [ ] 2. เพิ่มโดเมนใน Netlify + ตั้ง DNS
- [ ] 3. รอ HTTPS (Let's Encrypt) พร้อม
- [ ] 4. อัปเดต `WEB_BASE_URL` ใน repo → sync-env → deploy ใหม่
- [ ] 5. ตั้ง Supabase Auth (Site URL + Redirect URLs)
- [ ] 6. ตั้งอีเมล `privacy@realxtateth.com`
- [ ] 7. อัปเดต Privacy URL ใน App Store / Play Store
- [ ] 8. รัน `./scripts/verify-domain.sh` ให้ผ่านครบ

---

## 1. ซื้อโดเมน

เลือกผู้ให้บริการใดก็ได้ — ราคา **.com** โดยประมาณ **$10–15/ปี (~350–500 บาท)**

| ผู้ให้บริการ | ข้อดี | ราคาโดยประมาณ |
|-------------|-------|---------------|
| [Cloudflare Registrar](https://www.cloudflare.com/products/registrar/) | ราคาทุน ไม่บวกกำไร DNS ฟรี Email Routing ฟรี | ~$10–12/ปี |
| [Namecheap](https://www.namecheap.com) | ใช้ง่าย มีโปรปีแรก | ~$10–15/ปี |
| [Squarespace Domains](https://domains.squarespace.com) (เดิม Google Domains) | คุ้นเคยถ้าเคยใช้ Google | ~$12–18/ปี |

**ขั้นตอน:**

1. ค้นหา `RealXtateTH.com` (หรือ `realxtateth.com` — ชื่อเดียวกัน)
2. ชำระเงินและเป็นเจ้าของโดเมน
3. เก็บ login ผู้ให้บริการ DNS ไว้ — จะใช้ในขั้นตอนถัดไป

> **หมายเหตุ:** AI/สคริปต์ **ซื้อโดเมนแทนคุณไม่ได้** — ต้องชำระเงินและยืนยันตัวตนเอง

---

## 2. เชื่อมโดเมนกับ Netlify

### 2.1 เปิด Netlify Dashboard

1. เข้า [Netlify](https://app.netlify.com) → เลือก site **`quiet-kangaroo-ab6073`**
2. ไปที่ **Domain management** (หรือ **Site configuration → Domain management**)
3. กด **Add a domain** → พิมพ์ `realxtateth.com` → **Verify**

### 2.2 ตั้ง DNS (เลือกวิธีใดวิธีหนึ่ง)

#### วิธี A — ใช้ Netlify DNS (แนะนำถ้าซื้อโดเมนที่ Cloudflare/Namecheap)

Netlify จะแสดง **nameservers** เช่น

```
dns1.p01.nsone.net
dns2.p01.nsone.net
...
```

ไปที่ผู้ให้บริการโดเมน → **เปลี่ยน nameservers** เป็นค่าที่ Netlify ให้ → รอ 15 นาที–48 ชม.

#### วิธี B — เก็บ DNS ที่ผู้ให้บริการเดิม (External DNS)

เพิ่ม record ตามที่ Netlify แนะนำ โดยทั่วไป:

| ประเภท | ชื่อ (Host) | ค่า (Value) |
|--------|-------------|-------------|
| **A** | `@` | IP ที่ Netlify ให้ (เช่น `75.2.60.5`) |
| **CNAME** | `www` | `quiet-kangaroo-ab6073.netlify.app` |

> ค่าจริงดูใน Netlify → Domain settings → **DNS configuration** (อาจต่างกันเล็กน้อย)

### 2.3 HTTPS อัตโนมัติ

Netlify ออกใบรับรอง **Let's Encrypt** ให้เองเมื่อ DNS ชี้ถูก  
สถานะ **HTTPS** ใน dashboard ต้องเป็น **Ready** ก่อน deploy จริง

### 2.4 (แนะนำ) Redirect โดเมน Netlify → โดเมนหลัก

ใน **Domain management** → ตั้ง **Primary domain** เป็น `realxtateth.com`  
และเปิด **Redirect** จาก `quiet-kangaroo-ab6073.netlify.app` → `https://realxtateth.com`

---

## 3. อัปเดต repo และ deploy

### วิธีเร็ว (สคริปต์ช่วย)

```bash
./scripts/setup-custom-domain.sh
```

สคริปต์จะ:

- ถามโดเมน (default `realxtateth.com`)
- ตั้ง `WEB_BASE_URL=https://realxtateth.com` ใน `.env.local`
- รัน `./scripts/sync-env.sh` (คัดลอกไป `mobile/assets/env`)

### วิธีมือ

```bash
# แก้ .env.local
WEB_BASE_URL=https://realxtateth.com

./scripts/sync-env.sh
./scripts/build-web.sh
./scripts/deploy-netlify.sh   # หรือ push ผ่าน Git ถ้าเชื่อม repo แล้ว
```

> **สำคัญ:** อย่า commit `.env.local` หรือ `mobile/assets/env` — มี key จริง

---

## 4. Supabase Auth

เปิด [Supabase Dashboard](https://supabase.com/dashboard) → โปรเจกต **`auflqgqrmpbioflnhsrj`** → **Authentication → URL Configuration**

| ช่อง | ค่าที่ต้องมี |
|------|-------------|
| **Site URL** | `https://realxtateth.com` |
| **Redirect URLs** | `https://realxtateth.com/**` |
| | `https://quiet-kangaroo-ab6073.netlify.app/**` (เก็บไว้ช่วงเปลี่ยนโดเมน) |

กด **Save** แล้วทดสอบล็อกอินบนเว็บ `https://realxtateth.com`

---

## 5. อีเมล privacy@realxtateth.com

แอปและนโยบายอ้างอิง `privacy@realxtateth.com` แล้ว — ต้องมีกล่องจริงก่อนส่ง App Store / Play Store

### ทางเลือก A — Cloudflare Email Routing (ฟรี)

เหมาะถ้าโดเมนอยู่ Cloudflare:

1. **Email → Email Routing** → เปิดใช้
2. สร้าง address `privacy@realxtateth.com` → forward ไป Gmail ส่วนตัว
3. ตั้ง **Send** (ถ้าต้องการตอบจาก `@realxtateth.com`) — ตามคู่มือ Cloudflare

### ทางเลือก B — Google Workspace (เสียเงิน ~$6/เดือน)

เหมาะถ้าต้องการอีเมลองค์กรเต็มรูปแบบหลายคน

---

## 6. App Store / Play Store

อัปเดต **Privacy Policy URL** เป็น:

```
https://realxtateth.com/legal/privacy.html
```

ดูรายละเอียดเพิ่ม:

- [docs/STORE-SUBMISSION-CHECKLIST.md](STORE-SUBMISSION-CHECKLIST.md)
- [store-listing/app-privacy-answers.md](../store-listing/app-privacy-answers.md)

---

## 7. ตรวจสอบว่าพร้อม

```bash
# ตรวจโดเมนหลัก (default realxtateth.com)
./scripts/verify-domain.sh

# หรือระบุโดเมนเอง
DOMAIN=realxtateth.com ./scripts/verify-domain.sh
```

สคริปต์จะตรวจ:

- HTTPS ตอบ **200** ที่ `/`, `/legal/privacy.html`, `/legal/terms.html`
- redirect จาก subdomain Netlify (ถ้าตั้งไว้)
- แสดง checklist ผ่าน/ไม่ผ่าน

---

## แก้ปัญหาเบื้องต้น

| อาการ | สาเหตุที่พบบ่อย | แก้ |
|-------|-----------------|-----|
| DNS ยังไม่ขึ้น | ยังไม่ propagate | รอ 15 นาที–48 ชม. ลอง `dig realxtateth.com` |
| HTTPS ไม่ Ready | DNS ยังชี้ผิด | ตรวจ record ใน Netlify dashboard |
| ล็อกอิน redirect ผิด | Supabase Redirect URLs ไม่ครบ | เพิ่ม `https://realxtateth.com/**` |
| ลิงก์แชร์ยังเป็น netlify | ยังไม่ sync-env / deploy | รัน `setup-custom-domain.sh` แล้ว deploy ใหม่ |
| privacy.html 404 | ยังไม่ deploy build ล่าสุด | `./scripts/build-web.sh && ./scripts/deploy-netlify.sh` |

---

## คำสั่งอ้างอิง (หลังซื้อโดเมนแล้ว)

```bash
# 1) ตั้งค่า env ใน repo
./scripts/setup-custom-domain.sh

# 2) ตั้ง DNS + HTTPS ใน Netlify (ทำในเว็บ — ดูข้อ 2 ด้านบน)

# 3) ตั้ง Supabase Auth URLs (ทำใน dashboard — ดูข้อ 4)

# 4) Deploy เว็บใหม่
./scripts/build-web.sh
./scripts/deploy-netlify.sh

# 5) ตรวจครบ
./scripts/verify-domain.sh
```
