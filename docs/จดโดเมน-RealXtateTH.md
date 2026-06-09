# จดโดเมน RealXtateTH.com — ทำทีละขั้น

**ผู้ให้บริการที่เลือกแล้ว:** Cloudflare (จดโดเมน + DNS) → Netlify (เว็บแอป)

**โดเมน:** `RealXtateTH.com` → `https://realxtateth.com`

## เริ่มเลย (แนะนำ)

```bash
chmod +x scripts/setup-cloudflare-domain.sh scripts/verify-cloudflare-dns.sh
./scripts/setup-cloudflare-domain.sh
```

สคริปต์เปิดเบราว์เซอร์ไป Cloudflare + Netlify และบอก DNS ทีละขั้น

คู่มือเต็ม: [CLOUDFLARE-SETUP.md](CLOUDFLARE-SETUP.md)

---

## ขั้นที่ 1 — ซื้อโดเมน (15 นาที)

**[Cloudflare Registrar](https://dash.cloudflare.com/sign-up/registrar)** (ราคาทุน ~$10–12/ปี)

1. สมัคร / ล็อกอิน Cloudflare
2. เมนูซ้าย → **Domain Registration** → **Register Domains**
3. พิมพ์ `realxtateth.com` (หรือ `RealXtateTH.com` — ชื่อเดียวกัน)
4. Add to cart → ชำระเงิน (บัตร)
5. รอสถานะ **Active**

> ทางเลือกอื่น: Namecheap, GoDaddy — ขั้นตอนคล้ายกัน

---

## ขั้นที่ 2 — ผูกกับ Netlify (10 นาที + รอ DNS)

1. เปิด [Netlify](https://app.netlify.com) → site **`quiet-kangaroo-ab6073`**
2. **Domain management** → **Add a domain** → `realxtateth.com`
3. เลือกวิธี DNS:

### แบบ A — โดเมนอยู่ Cloudflare (แนะนำ)

ใน **Cloudflare** → DNS → Add record:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| CNAME | `@` | `quiet-kangaroo-ab6073.netlify.app` | DNS only (เทา) |
| CNAME | `www` | `quiet-kangaroo-ab6073.netlify.app` | DNS only |

> ถ้า Cloudflare ไม่ให้ CNAME ที่ root ใช้ **CNAME flattening** หรือเปลี่ยน nameserver ไป Netlify (แบบ B)

### แบบ B — ใช้ Netlify DNS

Netlify จะให้ nameservers 4 ตัว → ไป Cloudflare → **DNS** → เปลี่ยน nameservers เป็นของ Netlify

4. รอจน Netlify แสดง **HTTPS: Ready** (15 นาที – 24 ชม.)
5. ตั้ง **Primary domain** = `realxtateth.com`
6. เปิด redirect `*.netlify.app` → โดเมนหลัก

---

## ขั้นที่ 3 — อัปเดตแอปใน repo (5 นาที)

```bash
cd /path/to/LivingBKK_App
./scripts/setup-custom-domain.sh
# กด Enter (default realxtateth.com)

./scripts/sync-env.sh
./scripts/build-web.sh
./scripts/deploy-netlify.sh
```

---

## ขั้นที่ 4 — Supabase Auth (3 นาที)

[Supabase Dashboard](https://supabase.com/dashboard) → โปรเจกต → **Authentication** → **URL Configuration**

| ช่อง | ค่า |
|------|-----|
| Site URL | `https://realxtateth.com` |
| Redirect URLs | `https://realxtateth.com/**` |

เก็บ `https://quiet-kangaroo-ab6073.netlify.app/**` ไว้ช่วงเปลี่ยนโดเมน

---

## ขั้นที่ 5 — อีเมล privacy@realxtateth.com (ฟรี)

Cloudflare → **Email Routing** → เปิดใช้ → สร้าง `privacy@realxtateth.com` → forward ไป Gmail ของคุณ

---

## ขั้นที่ 6 — ตรวจว่าพร้อม

```bash
./scripts/verify-domain.sh
```

ต้องผ่าน:
- `https://realxtateth.com/`
- `https://realxtateth.com/legal/privacy.html`
- `https://realxtateth.com/legal/terms.html`

---

## หลังจดโดเมนแล้ว

- App Store / Play Store ใส่ Privacy URL: `https://realxtateth.com/legal/privacy.html`
- รัน migration FAQ: `supabase db push` (ข้อความบอท RealXtate)
- Deploy Edge Functions: `./scripts/deploy-all.sh`

คู่มือเต็ม: [CUSTOM-DOMAIN.md](CUSTOM-DOMAIN.md)
