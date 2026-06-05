# เมนูบอร์ดหาทรัพย์

จุดตั้งค่ากลางสำหรับแท็บบอร์ด ความต้องการลูกค้า และปุ่มเสนอทรัพย์ — **แก้ที่เดียว** แล้วทั้งแอปอัปเดตตาม

## ไฟล์หลัก

| ไฟล์ | หน้าที่ |
|------|--------|
| `mobile/lib/config/demand_board_menu_config.dart` | แท็บบอร์ด, เส้นทาง, มุมมอง, รายการเมนูโปรไฟล์ |
| `mobile/lib/navigation/demand_board_navigation.dart` | `openBoardTab`, ความต้องการ, รายละเอียดบอร์ด, เสนอทรัพย์ |
| `mobile/lib/widgets/demand/demand_board_profile_menu.dart` | เมนูในแท็บโปรไฟล์ |
| `design/tokens.json` → `demandBoardMenu` | สรุปสำหรับดีไซน์ (อ้างอิง — โค้ดอ่านจาก Dart) |

## ปรับการตั้งค่า

### แท็บล่าง「บอร์ด」

```dart
static const boardTabIndex = 2; // ต้องตรงกับลำดับใน MainShell.pages
```

### เส้นทาง

| คีย์ | path |
|------|------|
| `createRequirementRoute` | `/requirements/create` |
| `myRequirementsRoute` | `/requirements/mine` |
| `boardDetailRoute(id)` | `/board/:id` |
| `boardOfferRoute(id)` | `/board/:id/offer` |

ต้องตรงกับ `app_router.dart`

### มุมมอง

| ชุด | มุมมอง | ความหมาย |
|-----|--------|----------|
| `boardFeedPerspectives` | ทั้งหมด | เห็นฟีดบอร์ด (business-rules §6) |
| `requirementPerspectives` | ลูกค้า | บอกความต้องการ → แอดมินเผยแพร่บนบอร์ด |
| `offerPerspectives` | เจ้าของ, เอเจนท์ | เสนอทรัพย์บนประกาศบอร์ด |

### รายการเมนูโปรไฟล์

แก้ `profileEntries()` — ลูกค้าได้ 3 รายการ (สร้าง/ของฉัน/เปิดบอร์ด), เจ้าของ+เอเจนท์ได้「บอร์ดส่งเสนอทรัพย์」

### หน้าแรก

| คีย์ | ความหมาย |
|------|----------|
| `showHomeQuickRequirementCard` | การ์ด「ช่วยหาทรัพย์ฟรี」 |
| `showHomeQuickBoardCard` | การ์ด「บอร์ดหาทรัพย์」→ สลับแท็บบอร์ด |
| `showCustomerRequirementBanner` | แถบจัดการความต้องการ (ลูกค้า) |
| `showHomePromoRequirementTile` | แถวโปรโมต「บอกความต้องการ」 |

## จุดที่ใช้ config แล้ว

- หน้าแรก: Quick cards, `HomePromoActionRow`, `CustomerRequirementBanner`
- โปรไฟล์: `DemandBoardProfileMenu`
- บอร์ด: `DemandBoardPage` (เปิดรายละเอียด / เสนอทรัพย์)
- Router: เส้นทางความต้องการอ้างจาก config

## คำเรียกในแอป (UI)

- บทบาท **Agent** ในโค้ด → แสดงเป็น **นายหน้า** (ไม่ใช้ เอเจนท์/เอเจนซี่)
- ระบบ **Co-agent** → แสดงเป็น **โคนายหน้า** (รับโค / โค 50/50)
- ตัวกรองบอร์ด「สถานะผู้หาทรัพย์」: หาเพื่อตัวเอง | **นายหน้า**

## เกี่ยวข้อง

- กฎธุรกิจบอร์ด: `docs/business-rules.md` §6
- เมนูลงประกาศ (คู่กัน): `docs/post-listing-menu.md`
- ฟีเจอร์บอร์ด: `mobile/lib/features/board/`

## นโยบายรับข้อเสนอ + แหล่งลีด

เก็บใน `demand_posts.extra_criteria`:

| คีย์ | ค่า | ความหมาย |
|------|-----|----------|
| `accepted_offerer_policy` | `owner_only` | รับเจ้าของทรัพย์เท่านั้น |
| | `owner_and_co_agent` | รับเจ้าของ + โคเอเจนท์ |
| `lead_source` | `customer_direct` | ลีดลูกค้าตรง |
| | `co_agent_sourced` | โคเอเจนหาให้ลูกค้า |
| `urgent_rush` | `true` | ลูกค้าเลือก「หาแบบด่วนที่สุด」— ป้าย 🔥 บนการ์ดบอร์ดก่อนกดอ่าน |

โค้ด: `mobile/lib/models/demand_offer_acceptance.dart` · UI กรองที่ `DemandBoardPage` · ป้ายที่ `DemandInquiryCard` / `DemandUrgentRushStrip`

ฟอร์มลูกค้า: `CreateRequirementPage` + `RequirementUrgentRushToggle` → บันทึกใน `CustomerRequirement.urgentRush` และ `notes` (ให้แอดมินใส่ `urgent_rush` ตอนเผยแพร่บนบอร์ด)

## บันทึกประกาศบอร์ด (Favorite)

| ไฟล์ | หน้าที่ |
|------|--------|
| `demand_board_favorites_service.dart` | เก็บ id + snapshot ในเครื่อง |
| `demand_post_favorite_button.dart` | ปุ่มหัวใจบนการ์ด/รายละเอียด |
| `saved_demand_board_page.dart` | หน้ารวม `/board/saved` |

กดหัวใจบนการ์ด · กรอง「บันทึกไว้」บนฟีด · AppBar หัวใจ → หน้ารวม · โปรไฟล์「บอร์ดที่บันทึกไว้」

## ตัวกรอง + Matching MyStock

| ไฟล์ | หน้าที่ |
|------|--------|
| `demand_board_filter_sheet.dart` | Bottom sheet ตัวกรอง (แบบ Inquiry) |
| `demand_board_filter_state.dart` | สถานะตัวกรอง |
| `demand_mystock_match_service.dart` | จับคู่ประกาศบอร์ด ↔ ประกาศใน MyStock |
| `my_stock_listing_pool.dart` | โหลดประกาศของผู้ใช้ (`ListingOwnerRepository`) |

**Matching MyStock** เปรียบเทียบ: ประเภทธุรกรรม · ประเภททรัพย์ · ทำเล/โครงการ · งบ · พื้นที่ — คะแนน ≥ 42 ถือว่าตรง

## ทดสอบ

```bash
cd mobile && flutter analyze lib/config/demand_board_menu_config.dart \
  lib/navigation/demand_board_navigation.dart \
  lib/widgets/demand/demand_board_profile_menu.dart
```

1. มุมมอง **ลูกค้า** → โปรไฟล์เห็นความต้องการ + บอร์ด  
2. มุมมอง **เจ้าของ/เอเจนท์** → โปรไฟล์เห็น「บอร์ดส่งเสนอทรัพย์」  
3. หน้าแรก → การ์ดบอร์ดสลับแท็บบอร์ดได้  
4. กดประกาศบอร์ด → รายละเอียด / เสนอทรัพย์ ทำงาน  
5. กดหัวใจ → เปิด「บันทึกไว้」/ หน้า `/board/saved` เห็นรายการเดิม  
6. ตัวกรอง → เปิด Matching MyStock (ต้องมีประกาศใน「ประกาศของฉัน」) → เห็นเฉพาะบอร์ดที่ตรงทรัพย์
