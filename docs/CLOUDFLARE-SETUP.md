# Cloudflare + Netlify — RealXtateTH.com

**แนะนำหลัก** สำหรับ RealXtate: จดโดเมน + DNS ที่ Cloudflare แล้วชี้เว็บไป Netlify

| รายการ | ค่า |
|--------|-----|
| โดเมน | `realxtateth.com` |
| Registrar + DNS | [Cloudflare](https://dash.cloudflare.com) |
| เว็บแอป | `quiet-kangaroo-ab6073.netlify.app` |
| อีเมล | `privacy@realxtateth.com` (Email Routing ฟรี) |

---

## เริ่มเร็ว (สคริปต์นำทาง)

**ล็อกอิน Cloudflare แล้ว** → รันคำสั่งนี้ (เปิด Chrome ทุกแท็บ + อัปเดต repo):

```bash
./scripts/continue-cloudflare-login.sh
```

หรือ wizard เต็ม:

```bash
chmod +x scripts/setup-cloudflare-domain.sh scripts/verify-cloudflare-dns.sh
./scripts/setup-cloudflare-domain.sh
```

สคริปต์จะเปิด **Google Chrome** (ถ้ามี) ไปหน้าจดโดเมน + Netlify และบอก DNS ทีละขั้น — ทำใน Chrome ได้ทั้งหมด

---

## 1. จดโดเมนที่ Cloudflare Registrar

1. [Cloudflare Dashboard](https://dash.cloudflare.com/sign-up)
2. **Domain Registration** → **Register Domains**
3. ค้นหา `realxtateth.com` → ชำระบัตร
4. โดเมนจะอยู่ใน account เดียวกับ DNS อัตโนมัติ

ราคาโดยประมาณ **$10–12/ปี** (ราคาทุน ไม่บวกกำไร)

---

## 2. เพิ่มโดเมนใน Netlify

1. [Netlify → quiet-kangaroo-ab6073 → Domain management](https://app.netlify.com/sites/quiet-kangaroo-ab6073/domain-management)
2. **Add a domain** → `realxtateth.com`
3. เลือก **Set up using external DNS** (ไม่ย้าย NS ออกจาก Cloudflare)

---

## 3. DNS ใน Cloudflare

**Cloudflare → DNS → Records** — ตั้ง **Proxy status = DNS only** (เมฆเทา) ทุก record

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| **A** | `@` | `75.2.60.5` | DNS only |
| **CNAME** | `www` | `quiet-kangaroo-ab6073.netlify.app` | DNS only |

> IP apex อาจเปลี่ยน — ดูค่าล่าสุดใน Netlify → Domain settings → External DNS

**สำคัญ:** อย่าเปิด Proxy ส้ม (Orange) ที่ apex — จะทำให้ SSL กับ Netlify มีปัญหา

ตรวจ DNS:

```bash
./scripts/verify-cloudflare-dns.sh
```

---

## 4. HTTPS + Primary domain

1. รอ Netlify แสดง **HTTPS: Ready** (15 นาที – 24 ชม.)
2. Netlify → ตั้ง **Primary domain** = `realxtateth.com`
3. เปิด redirect `*.netlify.app` → โดเมนหลัก

---

## 5. Repo + Deploy

```bash
./scripts/setup-custom-domain.sh   # Enter → realxtateth.com
./scripts/sync-env.sh
./scripts/build-web.sh
./scripts/deploy-netlify.sh
```

---

## 6. Supabase Auth

| ช่อง | ค่า |
|------|-----|
| Site URL | `https://realxtateth.com` |
| Redirect URLs | `https://realxtateth.com/**` |

เก็บ `https://quiet-kangaroo-ab6073.netlify.app/**` ช่วงเปลี่ยนโดเมน

---

## 7. Email Routing (ฟรี)

Cloudflare → **Email** → **Email Routing** → Enable

- `privacy@realxtateth.com` → forward Gmail ของคุณ

---

## 8. ตรวจครบ

```bash
./scripts/verify-domain.sh
```

---

## ทำไมเลือกแบบนี้

- **Scale:** Cloudflare DNS + CDN รองรับทราฟฟิกระดับใหญ่
- **ปัญหาน้อย:** ไม่มี upsell แบบ GoDaddy
- **อีเมลฟรี:** ไม่ต้องซื้อ Google Workspace ตอนเริ่ม
- **แอป scale อยู่ที่ Netlify + Supabase** อยู่แล้ว — โดเมนแค่ชี้ทาง

---

## แก้ปัญหา

| อาการ | แก้ |
|-------|-----|
| SSL ไม่ขึ้น | ปิด Proxy ส้มที่ DNS · รอ propagate |
| เว็บไม่โหลด | รัน `verify-cloudflare-dns.sh` |
| ล็อกอิน redirect ผิด | เพิ่ม Supabase Redirect URL |

ดูเพิ่ม: [จดโดเมน-RealXtateTH.md](จดโดเมน-RealXtateTH.md) · [CUSTOM-DOMAIN.md](CUSTOM-DOMAIN.md)
