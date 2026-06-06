# PROPPITER — สเปก Asset โลโก้ (Official Master)

**หลักการ:** โลโก้ lockup ใช้ **ไฟล์ต้นฉบับที่ผู้ใช้ส่งเท่านั้น** (`proppiter-logo-master.png`) — ห้าม AI สร้าง lockup ใหม่ (จะคลาดเคลื่อน)

| องค์ประกอบ | สี (จาก master) |
|-----------|----------------|
| พื้นหลัง | `#070C2F` (navy จากไฟล์ต้นฉบับ) |
| ไอคอน P | `#5390A9` (cyan/teal) |
| คำว่า PROPPITER | `#FFFFFF` |

---

## 1. ไฟล์หลัก (บังคับ)

| ไฟล์ | ขนาดเป้าหมาย | วิธีสร้าง | ใช้ที่ไหน |
|------|-------------|----------|----------|
| `proppiter-logo-master.png` | **370×144** (ต้นฉบับ) | จากผู้ใช้ | Archive / source of truth |
| `logo-lockup-dark.png` | ~1480×576 (@4×) | Upscale master | Splash, auth dark, detail sheet |
| `logo-lockup-compact-dark.png` | สูง 128px, โปร่งใส | ลบพื้น navy จาก master | Header gradient, splash |
| `logo-lockup-compact-light.png` | สูง 128px, โปร่งใส | P cyan + ตัวอักษร navy | Header พื้นขาว, login |
| `logo-lockup-light.png` | สูง 128px | เหมือน compact-light | Default lockup |
| `logo-mark.png` | สูง 256px, โปร่งใส | Crop ไอคอน P ซ้าย | Favicon fallback, mark-only UI |

**คำสั่ง sync:** `python3 scripts/sync-proppiter-brand.py`

---

## 2. App Icon & Favicon

| ไฟล์ | ขนาด | วิธีสร้าง | ใช้ที่ไหน |
|------|------|----------|----------|
| `app-icon-navy.png` | **1024×1024** | P mark กลางจอ พื้น `#070C2F` + squircle | iOS/Android store master |
| `app-icon-gradient.png` | 1024×1024 | P บน `#1A1B41` | Marketing / alt icon |
| `app-icon-white.png` | 1024×1024 | P บนขาว | Light contexts |
| `favicon-256.png` | 256×256 | จาก app-icon-navy | Web `BrandAssets.favicon256` |
| `favicon-128.png` | 128×128 | จาก app-icon-navy | Web meta |

**Platform (อัตโนมัติจาก script):**
- Android `mipmap-*` → 48–192px
- iOS `AppIcon.appiconset` → 20–1024px
- Web `favicon.png` 32px, `Icon-192/512.png`

---

## 3. Prompt สำหรับ AI (ใช้เฉพาะสิ่งที่ **ไม่ใช่** lockup)

> ⚠️ **ห้าม**ใช้ prompt เหล่านี้กับ horizontal lockup — ใช้ master PNG เท่านั้น

### App Icon 1024×1024 (ถ้าต้อง regenerate แยก)

```
Square iOS app icon. EXACT copy of the PROPPITER "P" lettermark from the reference image only —
geometric cyan/teal (#5390A9) stylized P with sharp angular cuts, two-part construction.
Centered on solid navy background #070C2F. NO wordmark text. NO gradient on the P.
Modern flat design, generous padding (~14% inset). Subtle iOS squircle-safe composition.
Match reference pixel-perfect — do not redesign the P shape.
```

### Splash background (ไม่มีโลโก้)

```
Abstract premium mobile splash background only. Deep PROP Navy #1A1B41 fading to PITER Pink #E04070.
Soft subtle geometric shapes, no text, no logo, Robinhood-inspired clean gradient.
Portrait 1170×2532 — logo overlaid separately in Flutter.
```

---

## 4. การอัปเดต UI ในแอป

หลัง sync แล้ว `LivingBkkLogo` ใช้ **PNG lockup** แทนการประกอบ mark + ฟอนต์ Prompt เพื่อให้ตรงต้นฉบับ 100%
