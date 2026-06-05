# เมนูโพส์ประกาศลงทรัพย์

จุดตั้งค่ากลางสำหรับทุกปุ่ม/แถบที่พาไปลงประกาศ — **แก้ที่เดียว** แล้วทั้งแอปอัปเดตตาม

## ไฟล์หลัก

| ไฟล์ | หน้าที่ |
|------|--------|
| `mobile/lib/config/post_listing_menu_config.dart` | เส้นทาง, มุมมองที่เห็นเมนู, รายการเมนูโปรไฟล์ |
| `mobile/lib/navigation/post_listing_navigation.dart` | `openCreate`, `openMyListings`, ตรวจล็อกอินก่อนเปิดฟอร์ม |
| `mobile/lib/widgets/post_listing/post_listing_profile_menu.dart` | เมนูในแท็บโปรไฟล์ |
| `design/tokens.json` → `postListingMenu` | สรุปสำหรับดีไซน์/เอกสาร (อ้างอิง — โค้ดอ่านจาก Dart) |

## ปรับการตั้งค่า

### มุมมองที่เห็นเมนูลงประกาศ

ใน `PostListingMenuConfig.postPerspectives` (ตาม business-rules: เจ้าของ + เอเจนท์):

```dart
static const postPerspectives = <AppPerspective>{
  AppPerspective.owner,
  AppPerspective.agent,
};
```

### เส้นทาง

```dart
static const createRoute = '/listing/create';
static const myListingsRoute = '/listings/mine';
```

ต้องตรงกับ `app_router.dart` (อ้างอิงค่าจาก config แล้ว)

### รายการเมนูโปรไฟล์

แก้ `profileEntries()` — เพิ่ม/ลบ `PostListingMenuEntry` (ไอคอน, ข้อความ, route)

### หน้าแรก

| คีย์ | ความหมาย |
|------|----------|
| `showHomePromoForAllPerspectives` | แถบโปรโมตใต้ช่องค้นหา — `true` = ทุกมุมมองเห็น |
| `showHomeQuickPostCard` | การ์ด「ลงประกาศฟรี」ใน Quick actions |

## จุดที่ใช้ config แล้ว

- หน้าแรก: `PostListingPromoBanner`, `PropertyManageBanner`, Quick cards
- โปรไฟล์: `PostListingProfileMenu`
- ประกาศของฉัน: FAB ลงประกาศใหม่
- Push: `MainShell` → เปิด `/listings/mine`

## ฟอร์มสร้างประกาศ (Wizard)

อ้างอิง flow LI — ไฟล์หลัก:

| ไฟล์ | หน้าที่ |
|------|--------|
| `mobile/lib/features/listing/create_listing_page.dart` | Wizard 5 ขั้น |
| `mobile/lib/models/listing_create_rules.dart` | กฎลิงก์แผนที่ / เจ้าของ vs เอเจนท์ |
| `mobile/lib/config/create_listing_wizard_config.dart` | ชื่อขั้นตอน |

### ลิงก์โลเคชัน (Google Maps)

| กรณี | บังคับลิงก์? |
|------|----------------|
| เลือกโครงการจากทะเบียน | ไม่ |
| คอนโด/อพาร์ทเมนต์ กรอกเอง (ไม่มีในระบบ) | ไม่ |
| บ้าน/ทาวน์เฮ้าส์/ที่ดิน นอกโครงการ หรือ「ไม่ระบุโครงการ」 | **ใช่** |

เก็บใน `listings.source_url`

### ประเภทประกาศ (ฟอร์มลงประกาศ)

| มี | ไม่มี (ตัดออก) |
|----|----------------|
| เช่า (`rent`) | เซ้ง |
| ขาย (`sale`) | ขายดาวน์ |
| ขายฝาก (`sale_installment`) | ขาย+เช่า |

ค่า DB: `listing_type` enum — migration `20260604120100_listing_type_sale_installment.sql`

### ค่าคอม / นายหน้า (ขั้นสุดท้าย — บังคับ)

อ้างอิงธรรมเนียมไทย + แยกตามผู้ประกาศ (`OfferCommissionScheme`):

| ผู้ประกาศ | ขาย / ขายฝาก | เช่า |
|-----------|--------------|------|
| **เจ้าของ** | 3% / 4% / 5% หรือระบุสุทธิ+บวกคอมเอง + เงื่อนไขโอน | ~1 เดือนต่อสัญญา 12 เดือน |
| **นายหน้า** | 1.5% / 2% หรือสุทธิ+บวกคอม (50/50 จาก ~3%) | 0.5 เดือน / 70% / 100% ของค่าเช่า 1 เดือน |

วิดีโอ: **YouTube + TikTok เท่านั้น** · แฮชแท็กเพิ่ม: ทรัพย์มือสอง, ทรัพย์รีโนเวท

### หลังกดเผยแพร่

1. สถานะ `pending_review` (migration `20260604120000_listing_pending_review.sql`)
2. ไปหน้า **ประกาศของฉัน** — แสดง「รอตรวจสอบ」
3. แอดมินอนุมัติ → `published` (ภายหลัง)

## Migration (Supabase จริง)

รันก่อนใช้ `pending_review` และ `sale_installment`:

```bash
cd /path/to/LivingBKK_App
supabase db push
# หรือ apply ทีละไฟล์ใน Dashboard:
# supabase/migrations/20260604120000_listing_pending_review.sql
# supabase/migrations/20260604120100_listing_type_sale_installment.sql
```

## โหมดทดลอง (TRIAL_MODE)

- ส่งประกาศ → เก็บใน `TrialListingStore` (หน่วยความจำ)
- แอดมิน → Moderation → อนุมัติ/ปฏิเสธ มีผลทันที (ประกาศของฉันจะเห็นสถานะเปลี่ยน)
- ไฟล์: `mobile/lib/services/trial_listing_store.dart`

## ทดสอบ

1. สลับมุมมองเป็น **เจ้าของทรัพย์** หรือ **เอเจนท์** ที่หน้าแรก  
2. โปรไฟล์ → เห็น「ลงประกาศทรัพย์」และ「ประกาศของฉัน」  
3. หน้าแรก → แถบโปรโมต + ปุ่มลงประกาศทำงาน  
4. ปิด `TRIAL_MODE` + ยังไม่ล็อกอิน → กดลงประกาศควรพาไป `/login`
5. โหมดทดลอง: ลงประกาศ → สลับแอดมิน → อนุมัติ → กลับเจ้าของ → 「ประกาศของฉัน」เห็น `published`

```bash
cd mobile && flutter analyze lib/config/post_listing_menu_config.dart \
  lib/navigation/post_listing_navigation.dart \
  lib/widgets/post_listing/
```
