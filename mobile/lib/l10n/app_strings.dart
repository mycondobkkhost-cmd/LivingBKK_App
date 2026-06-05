import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/demand_offer_acceptance.dart';
import '../models/listing_public.dart';
import '../models/search_filters.dart';
import '../state/locale_controller.dart';
import '../theme/living_bkk_brand.dart';

/// ข้อความ UI หลัก (ไทย / อังกฤษ)
class AppStrings {
  AppStrings(this.isEnglish);

  final bool isEnglish;

  static AppStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
    return scope?.strings ?? AppStrings(false);
  }

  String t(String th, String en) => isEnglish ? en : th;

  // Nav
  String get navHome => t('ค้นหา', 'Search');
  String get navMap => t('แผนที่', 'Map');
  String get navBoard => t('บอร์ด', 'Board');
  String get navWork => t('งาน', 'Work');
  String get navSaved => t('บันทึก', 'Saved');
  String get navMessages => t('ติดต่อ', 'Contact');
  String get navProfile => t('โปรไฟล์', 'Profile');
  String get navExplore => t('สำรวจ', 'Explore');
  String get navInbox => t('กล่องข้อความ', 'Inbox');

  // Explore hero (Airbnb-style)
  String get exploreHeroTitle =>
      t('ค้นหาบ้าน คอนโด และอสังหาฯ ที่ใช่', 'Find places you\'ll love');
  String get exploreHeroSubtitle => t(
        'กรุงเทพฯ + ปริมณฑล · ค้นผ่านแผนที่ · ราคา Net',
        'Bangkok metro · Map discovery · Net prices',
      );
  String get exploreSearchCta => t('ค้นหา', 'Search');
  String get exploreFieldArea => t('เลือกทำเลหรือโซน', 'Choose area or zone');
  String get exploreFieldBudget => t('กำหนดงบประมาณ', 'Set your budget');
  String get exploreFieldType => t('ทุกประเภท', 'All property types');
  String get exploreFieldAreaLabel => t('ทำเล', 'Area');
  String get exploreFieldBudgetLabel => t('งบประมาณ', 'Budget');
  String get exploreFieldTypeLabel => t('ประเภท', 'Type');
  String exploreBudgetSummary(num? min, num? max) {
    if (min == null && max == null) return exploreFieldBudget;
    final fmt = NumberFormat.compact(locale: isEnglish ? 'en' : 'th');
    if (min != null && max != null) {
      return t('฿${fmt.format(min)} – ฿${fmt.format(max)}', '฿${fmt.format(min)} – ฿${fmt.format(max)}');
    }
    if (min != null) return t('ตั้งแต่ ฿${fmt.format(min)}', 'From ฿${fmt.format(min)}');
    return t('ไม่เกิน ฿${fmt.format(max!)}', 'Up to ฿${fmt.format(max)}');
  }

  String get exploreMapSectionTitle => t('ค้นหาบนแผนที่', 'Search on map');
  String get exploreMapSectionSubtitle =>
      t('ดูหมุดราคาและทำเลใกล้คุณ', 'Price markers & nearby areas');
  String get exploreOpenMap => t('เปิดแผนที่เต็มจอ', 'Open full map');
  String get netPriceBadge => t('ราคา Net', 'Net price');

  // Theme
  String get themeSetting => t('ธีมแสดงผล', 'Appearance');
  String get themeLight => t('สว่าง', 'Light');
  String get themeDark => t('มืด', 'Dark');
  String get themeSystem => t('ตามระบบ', 'System');
  String get menuDemandBoard => t('บอร์ดส่งเสนอทรัพย์', 'Demand board');

  // Header
  String get headerTagline => t('กทม. + ปริมณฑล · เช่า ซื้อ ขาย', 'Bangkok metro · Rent & Buy');
  String get account => t('บัญชี', 'Account');

  // Perspective
  String get perspectiveLabel => t('คุณคือ', 'You are');
  String get perspectiveCaption => t('คุณกำลัง', 'You\'re');
  String get agentCoOnly => t('· เฉพาะทรัพย์รับโค', '· Co-broker listings only');

  // Demand board
  String get demandBoardTitle => t('ประกาศหาทรัพย์', 'Property wanted');
  String get demandBoardHint => t(
        'เจ้าของและนายหน้า — เข้ามาเสนอทรัพย์ที่ตรงความต้องการได้',
        'Owners & brokers — submit matching listings here',
      );
  String get demandBoardHero => t(
        'รวบรวมความต้องการลูกค้าให้แล้ว! มีทรัพย์ตรงๆ เสนอมาได้เลย',
        'We’ve gathered real buyer/renter needs — offer your property if it fits',
      );
  String get demandFilterPropertyType => t('ประเภทอสังหาฯ', 'Property type');
  String get demandFilterTransaction => t('หาซื้อ-หาเช่า', 'Buy / rent');
  String get demandFilterPrice => t('เรียงราคา', 'Sort by price');
  String get demandFilterAll => t('ทั้งหมด', 'All');
  String get demandSearchLocationHint => t(
        'ค้นหาชื่อโครงการ ย่าน หรือทำเล — เช่น พระราม 9 สุขุมวิท อโศก',
        'Search project, area or location — e.g. Rama 9, Sukhumvit, Asok',
      );
  String get demandFilterOfferAcceptance =>
      t('รับข้อเสนอจาก', 'Accepts offers from');
  String get demandFilterOfferAcceptanceAll => t('ทุกประเภท', 'All types');
  String get demandOfferAcceptOwnerOnly =>
      t('เจ้าของทรัพย์เท่านั้น', 'Property owners only');
  String get demandOfferAcceptOwnerAndCoAgent => t(
        'เจ้าของ + โคนายหน้า',
        'Owners + co-brokers',
      );
  String get demandFilterLeadSource => t('แหล่งลีด', 'Lead source');
  String get demandFilterLeadSourceAll => t('ทุกแหล่ง', 'All sources');
  String get demandLeadCustomerDirect =>
      t('ลูกค้าตรง', 'Direct customer');
  String get demandLeadCoAgentSourced =>
      t('โคนายหน้าหาให้ลูกค้า', 'Co-broker for customer');
  String demandOfferPolicyBadge(DemandOfferAcceptancePolicy policy) {
    switch (policy) {
      case DemandOfferAcceptancePolicy.ownerOnly:
        return demandOfferAcceptOwnerOnly;
      case DemandOfferAcceptancePolicy.ownerAndCoAgent:
        return demandOfferAcceptOwnerAndCoAgent;
    }
  }

  String demandOfferPolicyDetail(DemandOfferAcceptancePolicy policy) {
    switch (policy) {
      case DemandOfferAcceptancePolicy.ownerOnly:
        return t(
          'ประกาศนี้รับข้อเสนอจากเจ้าของทรัพย์เท่านั้น (Owner 100%)',
          'This post accepts offers from property owners only (Owner 100%)',
        );
      case DemandOfferAcceptancePolicy.ownerAndCoAgent:
        return t(
          'ประกาศนี้รับข้อเสนอจากเจ้าของทรัพย์และโคนายหน้า (Owner / Co-broker)',
          'This post accepts offers from owners and co-brokers',
        );
    }
  }

  String? demandLeadSourceBadge(DemandLeadSource? source) {
    switch (source) {
      case DemandLeadSource.customerDirect:
        return demandLeadCustomerDirect;
      case DemandLeadSource.coAgentSourced:
        return demandLeadCoAgentSourced;
      case null:
        return null;
    }
  }

  String demandLeadSourceFootnote(DemandLeadSource? source) {
    switch (source) {
      case DemandLeadSource.customerDirect:
        return t('ลีดจากลูกค้าตรง', 'Direct customer lead');
      case DemandLeadSource.coAgentSourced:
        return t('ลีดจากโคนายหน้าหาให้ลูกค้า', 'Co-broker sourced lead');
      case null:
        return t('ลูกค้า PROPPITER', 'PROPPITER customer');
    }
  }

  String get demandOfferCapacityNotAllowed => t(
        'ประกาศนี้ไม่รับข้อเสนอในฐานะที่เลือก — เลือกประเภทผู้เสนอให้ตรงกับประกาศ',
        'This post does not accept the selected offerer type — choose a matching role',
      );
  String get demandFilterLocation => t('ทำเล / โครงการ', 'Area / project');
  String get demandLookingRent => t('หาเช่า', 'For rent');
  String get demandLookingSale => t('หาซื้อ', 'For sale');
  String get demandSubmitOffer => t('เสนอทรัพย์', 'Offer');
  String get demandCashBadge => t('เงินสด', 'Cash');
  String demandBudgetUpTo(String price) => t('งบ $price', 'Budget $price');
  String demandBudgetFrom(String price) => t('งบตั้งแต่ $price', 'From $price');
  String demandBudgetRange(String min, String max) => t('งบ $min - $max', 'Budget $min - $max');
  String get demandPriceRentLow => t('≤ ฿20,000/เดือน', '≤ ฿20k/mo');
  String get demandPriceRentMid => t('฿20,001-40,000', '฿20k-40k/mo');
  String get demandPriceRentHigh => t('> ฿40,000/เดือน', '> ฿40k/mo');
  String get demandPriceSaleLow => t('≤ ฿5 ล้าน', '≤ ฿5M');
  String get demandPriceSaleMid => t('฿5-10 ล้าน', '฿5-10M');
  String get demandPriceSaleHigh => t('> ฿10 ล้าน', '> ฿10M');
  String get demandOfferOpen => t('เปิดรับข้อเสนอ', 'Open for offers');
  String get demandOfferClosed => t('ปิดแล้ว', 'Closed');
  String get savedDemandBoardTitle =>
      t('บอร์ดที่บันทึกไว้', 'Saved board posts');
  String get savedDemandBoardEmpty => t(
        'ยังไม่มีประกาศบอร์ดที่บันทึก',
        'No saved board posts yet',
      );
  String get savedDemandBoardHint => t(
        'กดไอคอนหัวใจที่ประกาศบอร์ดเพื่อเก็บไว้ดูทีหลัง',
        'Tap the heart on a board post to save it for later',
      );
  String get demandFavoriteSaved =>
      t('บันทึกประกาศบอร์ดแล้ว', 'Board post saved');
  String get demandFavoriteRemoved =>
      t('นำออกจากรายการบันทึกแล้ว', 'Removed from saved');
  String get demandFilterFavoritesOnly => t('บันทึกไว้', 'Saved');
  String demandSavedBoardCount(int n) =>
      t('บันทึกไว้ $n', '$n saved');
  String get demandFilterSheetTitle => t('ตัวกรอง', 'Filter');
  String get demandFilterMatchMyStock =>
      t('Matching MyStock', 'Matching MyStock');
  String demandFilterMatchMyStockHint(int n) => t(
        'ดูเฉพาะประกาศที่ตรงกับ MyStock ของฉัน ($n รายการ)',
        'Show posts matching my MyStock ($n listings)',
      );
  String get demandFilterMatchMyStockEmpty => t(
        'ยังไม่มีประกาศใน MyStock — ลงประกาศก่อนเพื่อใช้ตัวกรองนี้',
        'No listings in MyStock yet — post first to use this filter',
      );
  String get demandFilterSeekerStatus =>
      t('สถานะผู้หาทรัพย์', 'Seeker status');
  String get demandSeekerSelf => t('หาเพื่อตัวเอง', 'For themselves');
  String get demandSeekerAgent => t('นายหน้า', 'Broker');
  String get demandFilterAnnouncementType =>
      t('ประเภทประกาศ', 'Listing type');
  String get demandFilterPropertyOptional =>
      t('ประเภทอสังหาฯ (ถ้ามี)', 'Property type (optional)');
  String get demandFilterIncludeCommercial =>
      t('ดูอสังหาฯ เชิงพาณิชย์', 'Include commercial');
  String get demandFilterResidential => t('ที่อยู่อาศัย', 'Residential');
  String get demandFilterCommercial => t('เชิงพาณิชย์', 'Commercial');
  String get demandFilterCondo => t('คอนโด', 'Condo');
  String get demandFilterHouse => t('บ้าน/บ้านเดี่ยว', 'House');
  String get demandFilterLand => t('ที่ดิน', 'Land');
  String get demandFilterClear => t('ล้างค่า', 'Clear');
  String get demandFilterApply => t('แสดงรายการ', 'Show results');
  String get demandFilterSortRecent => t('ล่าสุด', 'Recent');
  String demandFilterActive(int n) => t('ตัวกรอง ($n)', 'Filter ($n)');
  String get demandFilterButton => t('ตัวกรอง', 'Filter');
  String get demandMyStockMatchBadge => t('ตรง MyStock', 'Matches MyStock');
  String demandMyStockMatchScore(int score) =>
      t('ตรง MyStock · $score%', 'MyStock match · $score%');
  String postedAgo(String relative) => t('ลงเมื่อ $relative', 'Posted $relative');
  String updatedAgo(String relative) => t('อัปเดต $relative', 'Updated $relative');

  // Home
  String get filtersActive => t('ตัวกรอง (ใช้งานอยู่)', 'Filters (active)');
  String get advancedFilters => t('ตัวกรองขั้นสูง', 'Advanced filters');
  String get processingPleaseWait =>
      t('กำลังดำเนินการ กรุณารอสักครู่…', 'Processing, please wait…');
  String get applyFilters => t('ใช้ตัวกรอง', 'Apply filters');
  String browseResultsCount(int n) => t('พบ $n รายการ', '$n listings found');
  String get browseRecommendedTop =>
      t('ทรัพย์แนะนำ', 'Recommended');
  String get browseRecentlyUpdated =>
      t('อัปเดตล่าสุด', 'Recently updated');
  String get sortRecommended => t('เรียงแนะนำ', 'Recommended order');
  String get sortPriceHighToLow => t('ราคา มาก→น้อย', 'Price: high to low');
  String get sortPriceLowToHigh => t('ราคา น้อย→มาก', 'Price: low to high');
  String get sortByPrice => t('เรียงตามราคา', 'Sort by price');
  String projectUnitsAvailable(int n) =>
      t('ห้องในโครงการนี้ $n รายการ', '$n units in this project');
  String get chatAdminInquiry =>
      t('สอบถามข้อมูลกับแอดมิน', 'Ask admin for info');
  String get chatAdminInquiryHint => t(
        'บอทช่วยคัดโครงการ/ทรัพย์ก่อน · ขอคุยแอดมินได้เมื่อจำเป็น',
        'Bot filters projects first · request admin when needed',
      );
  String get chatAdminWelcome => t(
        'สวัสดีครับ ผมช่วยคัดโครงการและทรัพย์ใน PROPPITER ให้ได้\n\n'
        'ลองพิมพ์ เช่น:\n'
        '• ช่วยหาห้อง The Line งบ 25,000\n'
        '• คอนโดใกล้ BTS อ่อนนุช\n'
        '• ก้อปปี้รหัสทรัพย์ RENT-CD-…\n\n'
        'หากต้องการคุยแอดมินโดยตรง พิมพ์「ขอคุยกับแอดมิน」'
        ' — อาจรอตามคิวเนื่องจากมีผู้ติดต่อจำนวนมาก',
        'Hi — I can match projects and listings in PROPPITER.\n\n'
        'Try:\n'
        '• Find The Line units, budget 25,000\n'
        '• Condo near BTS On Nut\n'
        '• Paste listing code RENT-CD-…\n\n'
        'Type「ขอคุยกับแอดมิน」for a human — queue may apply.',
      );
  String get chatAdminQueueNotice => t(
        'แจ้งทีมแอดมินแล้ว — ให้บริการตามคิว อาจใช้เวลานานกว่าปกติ',
        'Notified admin team — served in queue, may take longer',
      );
  String chatListingCodeFound(String code) =>
      t('พบทรัพย์รหัส $code — กดลิงก์ด้านล่างเพื่อดู', 'Found listing $code — tap link below');
  String moreRoomsInProject(int n, String project) =>
      t('ดูห้องอื่นใน$project อีก $n ห้อง', 'See $n more units in $project');
  String get sectionLatest => t('อัปเดตล่าสุด', 'Latest updates');
  String get sectionRecommended => t('ประกาศแนะนำ', 'Recommended');
  String get sectionPopularArea => t('ยอดนิยมในพื้นที่คุณ', 'Popular in your areas');
  String get sectionCoAgent => t('ทรัพย์รับโคนายหน้า', 'Co-broker listings');
  String get sectionAffordable => t('ราคาเข้าถึงง่าย', 'Budget-friendly');
  String get popularAreasTitle => t('ทำเลยอดฮิตใน กทม', 'Hot areas in Bangkok');
  String get popularAreasHint => t(
        'ครอบคลุมทำเลใกล้ BTS/MRT ย่านธุรกิจ และทำเลยอดฮิต — แตะการ์ดเพื่อดูประกาศในย่านนั้น',
        'Near BTS/MRT, business districts & hot spots — tap a card to browse listings in that area',
      );
  String popularAreaListingCount(int n) {
    final formatted = NumberFormat('#,###').format(n);
    return t('$formatted ประกาศ', '$formatted listings');
  }
  String get popularAreaBrowse => t('ดูประกาศในย่านนี้', 'Browse this area');
  String get viewAll => t('ดูทั้งหมด', 'View all');
  String get allListings => t('ประกาศทั้งหมด', 'All listings');
  String get seeMoreInProject => t('ดูห้องอื่นในโครงการ', 'More units in project');
  String seeProjectUnits(int n, String name) =>
      t('ดูห้องอื่นใน $name ($n)', 'See $n more in $name');
  String get backToBrowse => t('กลับรายการ', 'Back to list');
  String get noListings => t('ไม่พบประกาศตามเงื่อนไข', 'No listings match');
  String get loadFailed => t('โหลดข้อมูลไม่สำเร็จ', 'Failed to load');
  String get ownerBarTitle => t('มุมมองเจ้าของ — ลงประกาศฟรี', 'Owner view — List for free');
  String get postListing => t('ลงประกาศ', 'Post listing');
  String get demoData => t('ข้อมูลตัวอย่าง', 'Sample data');
  String get propertyManageTitle => t('จัดการทรัพย์', 'Manage listings');
  String get propertyManageOwnerHint =>
      t('ประกาศของฉัน · ลงประกาศใหม่ · ยืนยันว่าง', 'My listings · post new · mark available');
  String get propertyManageAgentHint =>
      t('ประกาศของฉัน · ทรัพย์รับโคนายหน้า', 'My listings · co-broker eligible');
  String get demoSampleLabel => t('ตัวอย่าง', 'Sample');

  // Customer requirements
  String get requirementManageTitle => t('จัดการความต้องการ', 'Manage my search');
  String get requirementManageHint => t(
        'บอกเงื่อนไขหาซื้อ/เช่า · ทีมงานช่วยประกาศหาเจ้าของและโคนายหน้า',
        'Describe what you need · our team posts to find owners & co-brokers',
      );
  String get requirementCreateCta => t('บอกความต้องการ', 'Submit need');
  String get myRequirementsTitle => t('ความต้องการของฉัน', 'My requirements');
  String get requirementListIntro => t(
        'สรุปเงื่อนไขที่คุณต้องการ — ทีม PROPPITER จะตรวจสอบแล้วนำไปประกาศบนบอร์ด「ประกาศหาทรัพย์」เพื่อให้เจ้าของและนายหน้าเข้ามาเสนอทรัพย์ที่ตรงความต้องการ',
        'Your search criteria — our team reviews and publishes on the board so owners and brokers can offer matching listings',
      );
  String requirementSubmittedOn(String date) => t('ส่งเมื่อ $date', 'Submitted $date');
  String get requirementLocalOnlyNote => t(
        'บันทึกในเครื่อง — ทีมงานจะติดต่อเมื่อเชื่อมระบบครบ',
        'Saved locally — team will follow up when backend is connected',
      );
  String get requirementCreateTitle => t('บอกความต้องการหาทรัพย์', 'Describe your property need');
  String get requirementCreateIntro => t(
        'กรอกให้ละเอียดที่สุด — ทีมงานจะช่วยหาทรัพย์ที่ตรงเงื่อนไขและติดต่อกลับ',
        'Fill in as much detail as you can — our team will find matches and follow up',
      );
  String get requirementUrgentRushTitle =>
      t('หาแบบด่วนที่สุด', 'Fastest match needed');
  String get requirementUrgentRushSubtitle => t(
        'เปิดแล้วจะมีป้าย 🔥 บนบอร์ดประกาศหาทรัพย์ — เจ้าของและนายหน้าเห็นก่อนกดอ่านและรีบเสนอทรัพย์',
        'Shows a 🔥 badge on the demand board before opening — owners and brokers see it and rush offers',
      );
  String get requirementUrgentRushSummary =>
      t('ด่วนที่สุด', 'Urgent rush');
  String demandUrgentRushBadge(bool isRent) => isRent
      ? t('🔥 หาเช่า · ด่วนที่สุด', '🔥 For rent · urgent')
      : t('🔥 หาซื้อ · ด่วนที่สุด', '🔥 For sale · urgent');
  String get demandUrgentRushHint => t(
        'ลูกค้าเร่งมาก — กรุณารีบเสนอทรัพย์ที่ตรงเงื่อนไข',
        'Customer needs this urgently — please submit matching listings quickly',
      );
  String get requirementFieldTransaction => t('ประเภท', 'Transaction');
  String get requirementFieldProperty => t('ประเภททรัพย์', 'Property type');
  String get requirementFieldRequesterRole => t('คุณเป็น', 'You are');
  String get requirementRoleDirect =>
      t('ลูกค้าโดยตรง', 'Direct customer');
  String get requirementRoleDirectHint =>
      t('หาเช่า/ซื้ออยู่เอง หรือหาให้คนรู้จัก', 'Rent/buy for yourself or someone you know');
  String get requirementRoleAgent =>
      t('นายหน้ากำลังหาให้ลูกค้า', 'Broker finding for client');
  String get requirementRoleAgentHint =>
      t('นายหน้าหาทรัพย์ให้ลูกค้า · ต้องการโคทรัพย์', 'Broker finding for your client · co-listing');
  String get requirementFieldProjectBuilding => t('โครงการ / อาคาร *', 'Project / building *');
  String get requirementFieldProjectBuildingHint => t(
        'กรอกชื่อโครงการ หรือทำเลที่กำลังหา — เลือกจากคำแนะนำหรือบันทึกค่าที่พิมพ์เอง',
        'Enter project name or area — pick a suggestion or save your own text',
      );
  String get requirementFieldProjectBuildingPlaceholder =>
      t('เช่น ทองหล่อ, The Line, อโศก', 'e.g. Thong Lo, The Line, Asok');
  String requirementAddCustomLocationNamed(String name) =>
      t('บันทึก "$name"', 'Save "$name"');
  String get requirementAddCustomLocation => t('เพิ่มที่พิมพ์', 'Add typed text');
  String get requirementPropertyOthers => t('อื่นๆ', 'Others');
  String get requirementPropertyTypeRequired => t(
        'กรุณาเลือกอย่างน้อย 1 ประเภททรัพย์',
        'Select at least one property type',
      );
  String get requirementZoneRequired => t(
        'กรุณาเพิ่มอย่างน้อย 1 โครงการ / ทำเล',
        'Add at least one project or area',
      );
  String get requirementFieldBudgetRangeRent => t('งบประมาณ (ต่อเดือน)', 'Budget (per month)');
  String get requirementFieldBudgetRangeSale => t('งบประมาณ (ซื้อ)', 'Budget (purchase)');
  String get requirementFieldMinArea => t('ขนาดขั้นต่ำ (พื้นที่ใช้สอย)', 'Min usable area');
  String get requirementFieldMinAreaHint => t('เช่น 40', 'e.g. 40');
  String get requirementFieldFurnishing => t('การตกแต่ง', 'Furnishing');
  String get requirementFurnishingEmpty => t('ห้องเปล่า', 'Unfurnished');
  String get requirementFurnishingFull => t('พร้อมเฟอร์', 'Furnished');
  String get requirementFurnishingAny => t('ไม่จำกัด', 'Any');
  String get requirementFieldContractStart => t('แพลนเริ่มสัญญา (ไม่เกินวันที่)', 'Lease start (no later than)');
  String get requirementFieldContractStartHint => t('เลือกวันที่', 'Pick a date');
  String get requirementFieldDecision => t('ระยะเวลาการตัดสินใจ', 'Decision timeline');
  String get requirementFieldDecisionShort =>
      t('เมื่อไหร่จะตัดสินใจ', 'When will you decide?');
  String get requirementFieldMinAreaShort =>
      t('พื้นที่ใช้สอยขั้นต่ำ', 'Min usable area');
  String get requirementFieldContactName => t('ชื่อ *', 'Name *');
  String get requirementFieldContactNameHint => t('ชื่อที่ใช้ติดต่อ', 'Your name');
  String get requirementFieldContactPhone => t('เบอร์โทรติดต่อ *', 'Phone *');
  String get requirementFieldContactPhoneHint => t('08x-xxx-xxxx', '08x-xxx-xxxx');
  String get requirementFieldLineId =>
      t('Line ID (ไม่บังคับ)', 'Line ID (optional)');
  String get requirementFieldWhatsApp =>
      t('WhatsApp (ไม่บังคับ)', 'WhatsApp (optional)');
  String get requirementContactNameRequired =>
      t('กรุณากรอกชื่อ', 'Please enter your name');
  String get requirementContactPhoneRequired =>
      t('กรุณากรอกเบอร์โทรติดต่อ', 'Please enter your phone number');
  String get requirementSectionContact => t('ข้อมูลติดต่อ', 'Contact info');
  String get requirementSectionDetails => t('รายละเอียดเพิ่ม', 'More details');
  String get requirementFieldPreferredProject => t('โครงการที่สนใจโดยเฉพาะ', 'Preferred project');
  String get requirementFieldBuyPayment => t('ประเภทการซื้อ', 'Payment type');
  String get requirementFieldBuyPurpose => t('วัตถุประสงค์การซื้อ', 'Buying purpose');
  String get requirementBuyPaymentCash => t('เงินสด', 'Cash');
  String get requirementBuyPaymentLoan => t('ขอสินเชื่อ', 'Mortgage / loan');
  String get requirementBuyWithTenant => t('ซื้อพร้อมผู้เช่า', 'With tenant');
  String get requirementBuyVacant => t('ซื้อห้องเปล่า', 'Vacant unit');
  String get requirementBuyInvestment => t('ซื้อเพื่อลงทุน (yield)', 'Investment (yield)');
  String get requirementBuyOwnStay => t('ซื้ออยู่เอง', 'Own stay');
  String get requirementBuyNoTenant => t('ซื้อห้องไม่ติดผู้เช่า', 'No tenant obligation');
  String get requirementDecisionBookNow =>
      t('พร้อมจองทันทีถ้าถูกใจ', 'Ready to book if it fits');
  String get requirementDecisionCompare =>
      t('ยังขอดูเปรียบเทียบเรื่อยๆ', 'Still comparing options');
  String get requirementDecision1Week => t('ตัดสินใจภายใน 1 สัปดาห์', 'Decide within 1 week');
  String get requirementDecision2Weeks => t('ตัดสินใจภายใน 2 สัปดาห์', 'Decide within 2 weeks');
  String get requirementDecision1Month => t('ตัดสินใจภายใน 1 เดือน', 'Decide within 1 month');
  String get requirementDecisionFlexible => t('ยืดหยุ่น / ยังไม่เร่ง', 'Flexible / not urgent');
  String get requirementFieldNotes => t('รายละเอียดเพิ่มเติม', 'Additional details');
  String get requirementFieldNotesHint => t(
        'ระบุความต้องการโดยละเอียดที่สุด เช่น ชั้นที่ต้องการ วิว สัตว์เลี้ยง ที่จอดรถ ฯลฯ',
        'Describe every detail: floor, view, pets, parking, etc.',
      );
  String get requirementSubmitCta => t('ส่งให้ทีมงาน', 'Send to team');
  String get requirementConfirmTitle =>
      t('ตรวจสอบก่อนส่ง', 'Review before sending');
  String get requirementConfirmIntro => t(
        'ตรวจสอบความถูกต้อง — กด「แก้ไข」เพื่อกลับไปแก้ หรือ「ยืนยันส่ง」เพื่อส่งให้ทีมงาน',
        'Check details — tap Edit to go back, or Confirm to send to our team',
      );
  String get requirementConfirmEdit => t('แก้ไข', 'Edit');
  String get requirementConfirmSubmit => t('ยืนยันส่ง', 'Confirm & send');
  String get requirementSubmitFailed => t(
        'ส่งไม่สำเร็จ กรุณาลองใหม่',
        'Could not submit — please try again',
      );
  String requirementDecisionLabel(String key) {
    switch (key) {
      case 'book_now':
        return requirementDecisionBookNow;
      case 'still_comparing':
        return requirementDecisionCompare;
      case 'within_1_week':
        return requirementDecision1Week;
      case 'within_2_weeks':
        return requirementDecision2Weeks;
      case 'within_1_month':
        return requirementDecision1Month;
      default:
        return requirementDecisionFlexible;
    }
  }
  String get requirementSubmitSuccessTitle => t('รับความต้องการแล้ว', 'Requirement received');
  String get requirementSubmitSuccessBodySaved => t(
        'ทีมงานจะตรวจสอบและนำไปประกาศบนบอร์ด「ประกาศหาทรัพย์」เพื่อให้เจ้าของและนายหน้าเสนอทรัพย์ที่ตรงเงื่อนไข',
        'Our team will review and publish on the board for owners and brokers to submit matches',
      );
  String get requirementSubmitSuccessBodyLocal => t(
        'บันทึกความต้องการแล้ว — ทีมงานจะติดต่อกลับเมื่อพร้อมเผยแพร่บนบอร์ด',
        'Saved — our team will contact you when ready to publish on the board',
      );

  // Phase 14 — LI-inspired (no credits)
  String get compareTitle => t('เปรียบเทียบ', 'Compare');
  String get compareClear => t('ล้าง', 'Clear');
  String get compareEmpty => t(
        'กดไอคอนเปรียบเทียบที่การ์ดทรัพย์ (สูงสุด 4 รายการ)',
        'Tap compare on listing cards (max 4)',
      );
  String get compareAdded => t('เพิ่มในรายการเปรียบเทียบ', 'Added to compare');
  String get compareFull => t('เปรียบเทียบได้สูงสุด 4 รายการ', 'Compare list full (max 4)');
  String get savedSearchTitle => t('แจ้งเตือนค้นหา', 'Search alerts');
  String get savedSearchSaveCurrent => t('บันทึก', 'Save');
  String get savedSearchIntro => t(
        'Notify Me ฟรี — บันทึกตัวกรองแล้วแจ้งเตือนเมื่อมีทรัพย์ใหม่ตรงเงื่อนไข',
        'Free Notify Me — save filters and get alerts for new matches',
      );
  String get savedSearchEmpty => t('ยังไม่มีการค้นหาที่บันทึก', 'No saved searches yet');
  String get savedSearchCreated => t('บันทึกการค้นหาแล้ว', 'Search saved');
  String savedSearchAlert(int n) =>
      t('พบทรัพย์ใหม่ $n รายการตรงการค้นหาที่บันทึก', '$n new listings match your saved search');
  String get nearMeChip => t('ใกล้ฉัน', 'Near me');
  String get sectionRecentlyViewed => t('ดูล่าสุด', 'Recently viewed');
  String get sectionNearMe => t('ใกล้ฉัน', 'Near you');
  String get sectionPreferredStock => t('สต็อกที่เก็บไว้', 'Preferred stock');
  String get sectionOwnerStockNew => t('สต็อก Owner ใหม่', 'New owner stock');
  String get lookingToMatch => t('Looking to Match', 'Looking to Match');
  String matchCount(int n) => t('จับคู่ได้ $n รายการ', '$n matches');
  String get listingAnalytics => t('สถิติประกาศ', 'Listing stats');
  String listingViews(int n) => t('เข้าชม $n ครั้ง', '$n views');
  String get preferredStockSaved => t('เก็บในสต็อกแล้ว', 'Saved to preferred stock');
  String get chatQuickReply => t('ตอบด่วน', 'Quick reply');
  String get chatTranslate => t('แปล EN', 'Translate EN');
  String get agentTools => t('เครื่องมือนายหน้า', 'Broker tools');
  String get monthlyRentLabel => t('ค่าเช่ารายเดือน (ถ้ามี)', 'Monthly rent (optional)');
  String get videoUrlLabel => t('ลิงก์วิดีโอ YouTube', 'YouTube video URL');
  String get listingTemplate => t('ใช้เทมเพลตคำอธิบาย', 'Use description template');
  String get myNoteLabel => t('My Note (ส่วนตัว)', 'My Note (private)');
  String get myNoteHint => t(
        'โน้ตส่วนตัว — เฉพาะคุณเห็น ไม่แสดงในประกาศ',
        'Private note — only you see this, not shown on the listing',
      );
  String createListingDescriptionTemplate(
    String? projectName, {
    String lang = 'th',
  }) {
    final place = projectName != null && projectName.isNotEmpty ? ' · $projectName' : '';
    switch (lang) {
      case 'en':
        return 'Property$place\n'
            '· Great location near transit\n'
            '· Ready to view / move in\n'
            'Contact and viewing via PROPPITER only';
      case 'zh':
        return '房源$place\n'
            '· 交通便利\n'
            '· 可预约看房 / 可入住\n'
            '请通过 PROPPITER 联系与预约看房';
      default:
        return 'ทรัพย์$place\n'
            '· ทำเลดี ใกล้รถไฟฟ้า\n'
            '· พร้อมเข้าอยู่ / นัดชมได้\n'
            'ติดต่อและนัดชมผ่าน PROPPITER เท่านั้น';
    }
  }

  String get createListingDescLangTh => t('ไทย', 'Thai');
  String get createListingDescLangEn => t('English', 'English');
  String get createListingDescLangZh => t('中文', 'Chinese');
  String get createListingListingLangTitle =>
      t('ภาษาประกาศ', 'Listing languages');
  String get createListingListingLangHint => t(
        'เลือกภาษาเพิ่ม แล้วกด「แปลจากภาษาไทย」เพื่อเติมร่าง (แก้ได้ก่อนส่ง)',
        'Add languages, then tap Translate from Thai to fill drafts (editable)',
      );
  String get createListingAutoTranslate =>
      t('แปลจากภาษาไทย', 'Translate from Thai');
  String get createListingTitleEnLabel =>
      t('หัวข้อ (English)', 'Title (English)');
  String get createListingDescEnLabel =>
      t('รายละเอียด (English)', 'Description (English)');
  String get createListingTitleZhLabel => t('หัวข้อ (中文)', 'Title (Chinese)');
  String get createListingDescZhLabel =>
      t('รายละเอียด (中文)', 'Description (Chinese)');
  String get createListingLineIdLabel =>
      t('ไอดีไลน์ (ถ้ามี)', 'Line ID (optional)');
  String get createListingSalePriceLabel => t('ราคาขาย *', 'Sale price *');
  String get createListingRentPriceLabel =>
      t('ค่าเช่า / เดือน *', 'Rent / month *');
  String get createListingPriceHint => t(
        'ราคาที่แสดงในประกาศ — รวมค่าคอมมิชชันแล้ว',
        'Listed price — commission included',
      );
  String get createListingTranslateNeedThai => t(
        'กรอกหัวข้อและรายละเอียดภาษาไทยก่อน',
        'Enter Thai title and description first',
      );
  String get createListingPublishPrivacyNotice => t(
        'ประกาศของคุณจะแสดงต่อผู้ใช้ทั่วไป — ข้อมูลติดต่อส่วนตัว (เช่น เบอร์โทร ไอดีไลน์) '
        'จะไม่ปรากฏในประกาศสาธารณะ มีเฉพาะทีมงาน PROPPITER ที่ดูแลข้อมูลของคุณและติดต่อคุณเมื่อมีผู้สนใจ',
        'Your listing is visible to other users — private contact details (phone, Line ID, etc.) '
        'are not shown publicly. Only the PROPPITER team manages your data and contacts you when there is interest.',
      );
  String get createListingPublishTermsPrefix =>
      t('ฉันยอมรับ ', 'I agree to the ');
  String get createListingPublishTermsMiddle => t(
        ' และ ',
        ' and ',
      );
  String get createListingPublishTermsSuffix => t(
        ' รวมถึงยืนยันว่าเนื้อหาประกาศเป็นจริง ไม่ลงข้อมูลติดต่อในส่วนที่ผู้ชมเห็น '
        'และยินยอมให้ทีมงานตรวจสอบก่อนเผยแพร่',
        ', confirm the listing is accurate, will not expose contact info in the public view, '
        'and consent to team review before publishing',
      );
  String get createListingPublishTermsRequired => t(
        'กรุณายอมรับเงื่อนไขและนโยบายก่อนส่งประกาศ',
        'Please accept the terms and privacy policy before submitting',
      );
  String get legalReadFull => t('อ่านฉบับเต็ม', 'Read full policy');

  // Exclusive listings
  String get ownerExclusiveTitle =>
      t('ฝาก Exclusive กับ PROPPITER', 'Exclusive mandate with PROPPITER');
  String ownerExclusivePitchFor(bool isSale, int contractDays) {
    if (isEnglish) {
      final period = isSale
          ? '${_saleMonthsLabelEn(contractDays)}only'
          : '$contractDays days only';
      return 'Initial contract $period · Marketing & auto boosts · Free';
    }
    final period = isSale
        ? '${_saleMonthsLabelTh(contractDays)}เท่านั้น'
        : '$contractDays วันเท่านั้น';
    return 'ระยะเวลาสัญญาเริ่มต้นเพียง $period · ทำการตลาด ดันประกาศอัตโนมัติ ฟรีทุกค่าใช้จ่าย';
  }

  String _saleMonthsLabelTh(int days) {
    switch (days) {
      case 180:
        return '6 เดือน';
      case 365:
        return '12 เดือน';
      default:
        return '3 เดือน';
    }
  }

  String _saleMonthsLabelEn(int days) {
    switch (days) {
      case 180:
        return '6 months ';
      case 365:
        return '12 months ';
      default:
        return '3 months ';
    }
  }
  String get ownerExclusiveToggle =>
      t('สนใจฝาก Exclusive', 'Interested in Exclusive mandate');
  String get ownerExclusiveToggleHint =>
      t('แตะเพื่อเลือกระยะสัญญา', 'Tap to choose contract length');
  String get ownerExclusiveContractLabel =>
      t('ระยะเวลาสัญญาเริ่มต้น', 'Initial contract period');
  String get ownerExclusiveTermsTitle =>
      t('เงื่อนไขเบื้องต้น', 'Preliminary terms');
  String get ownerExclusiveTermsIntro => t(
        'ทีมจะติดต่อทางแชทเพื่อเอกสารและเซ็นสัญญา',
        'Our team will contact you via chat for documents and signing',
      );
  String ownerExclusiveTermsContract(String period, bool isSale) => isSale
      ? t(
          'ฝากขายกับเรา $period ขึ้นไป — ไม่ฝากนายหน้าอื่นในช่วงนี้',
          'Sale mandate with us for $period — no other brokers during this period',
        )
      : t(
          'ฝากเช่ากับเรา $period — ไม่ฝากนายหน้าอื่นในช่วงนี้',
          'Rental mandate with us for $period — no other brokers during this period',
        );
  String get ownerExclusiveTermsExclusiveOnly => t(
        'ฝากกับ PROPPITER เท่านั้น',
        'Exclusive to PROPPITER only',
      );
  String get ownerExclusiveTermsMarketing => t(
        'ฟรีดันประกาศและทำการตลาด',
        'Free listing boosts and marketing',
      );
  String ownerExclusiveTermsAutoBump(String interval) => t(
        'ดันประกาศอัตโนมัติ $interval',
        'Auto listing boost $interval',
      );
  String get ownerExclusiveTermsFollowUp => t(
        'เงื่อนไขจริงจะยืนยันอีกครั้งก่อนเริ่มสัญญา',
        'Final terms confirmed before the contract starts',
      );
  String get ownerExclusiveTermsConfirm =>
      t('ยืนยัน', 'Confirm');
  String ownerExclusiveBumpEveryHours(int h) =>
      t('ทุก $h ชั่วโมง', 'every $h hours');
  String ownerExclusiveBumpEveryDays(int d) =>
      t('ทุก $d วัน', 'every $d day(s)');
  String get ownerExclusiveSubmitted => t(
        'บันทึกความสนใจฝาก Exclusive แล้ว — ทีมงานจะติดต่อทางแชท',
        'Exclusive interest saved — our team will contact you via chat',
      );
  String get agentExclusiveTitle =>
      t('ทรัพย์ Exclusive (นายหน้า)', 'Broker exclusive listing');
  String get agentExclusiveSubtitle => t(
        'มีแค่คุณที่ถือทรัพย์นี้ — ดันประกาศขึ้นฟีดมากขึ้น',
        'Only you hold this listing — stronger feed placement',
      );
  String get agentExclusiveToggle =>
      t('ทรัพย์นี้มีแค่ฉัน (Exclusive)', 'Only I have this listing');
  String get listingExclusiveBadge =>
      t('Exclusive', 'Exclusive');
  String get adminExclusiveSettingsTitle =>
      t('ตั้งค่า Exclusive & ดันฟีด', 'Exclusive & feed boost settings');
  String get adminExclusiveSettingsHint => t(
        'ช่วงดันฟีดอัตโนมัติสำหรับฝากเจ้าของ — เรียก Cron `process_exclusive_auto_bumps`',
        'Auto-bump interval for owner mandates — schedule `process_exclusive_auto_bumps` cron',
      );
  String get adminExclusiveRentBumpHours =>
      t('เช่า: ดันฟีดทุก (ชม.)', 'Rent: bump every (hours)');
  String get adminExclusiveSaleBumpHours =>
      t('ขาย: ดันฟีดทุก (ชม.)', 'Sale: bump every (hours)');
  String get adminExclusiveOwnerFeedBoost =>
      t('คะแนนฟีด ฝากเจ้าของ', 'Feed score: owner mandate');
  String get adminExclusiveAgentFeedBoost =>
      t('คะแนนฟีด นายหน้า Exclusive', 'Feed score: broker exclusive');
  String get adminExclusiveSettingsSaved =>
      t('บันทึกตั้งค่า Exclusive แล้ว', 'Exclusive settings saved');
  String get adminExclusiveSettingsInvalid =>
      t('กรอกตัวเลขให้ครบ', 'Enter valid numbers');

  // Viewing access (create listing)
  String get viewingAccessSectionTitle =>
      t('การนัดดูในอนาคต (ไม่บังคับ)', 'Future viewings (optional)');
  String get viewingAccessSectionIntro => t(
        'ช่วยให้ทีม PROPPITER ประสานงานเมื่อมีลูกค้าขอนัดชม — ไม่ต้องใส่รายละเอียดครบทุกช่อง',
        'Helps our team coordinate when a customer requests a viewing — no need to fill everything now',
      );
  String get viewingAccessFollowUpHint => t(
        'ถ้ายังไม่แน่ใจ ให้ติ๊ก「สอบถามภายหลัง」ไว้ก่อน — เราจะถามเพิ่มเมื่อมีคำขอนัดดูจริง',
        'Not sure yet? Keep「Ask me later」checked — we will follow up when a viewing is requested',
      );
  String get viewingAccessFollowUpToggle =>
      t('สอบถามรายละเอียดภายหลังเมื่อมีนัดดู', 'Follow up when a viewing is requested');
  String get viewingAccessFollowUpSubtitle => t(
        'แนะนำสำหรับประกาศใหม่ — ทีมจะแชท/โทรสอบถามเพิ่ม',
        'Recommended for new listings — our team will ask for details later',
      );
  String get viewingAccessModesQuestion =>
      t('ตอนนี้เปิดห้องนัดดูได้แบบไหน?', 'How can the unit be opened for viewings?');
  String get viewingAccessModesOptional =>
      t('เลือกได้หลายข้อ (ไม่บังคับ)', 'Select all that apply (optional)');
  String get viewingAccessModeOwnerOpen => t(
        'เจ้าของ/ผู้ดูแลมาเปิดเอง — ต้องแจ้งล่วงหน้า',
        'Owner/caretaker opens — advance notice required',
      );
  String get viewingAccessNotice1Day => t('1 วัน', '1 day');
  String get viewingAccessNotice2Days => t('2 วัน', '2 days');
  String get viewingAccessModeJuristic =>
      t('เบิกคีย์การ์ด / กุญแจกับนิติบุคคล', 'Key card / keys from juristic office');
  String get viewingAccessModeJuristicHint => t(
        'อาคารคอนโด/นิติมีระบบเบิกกุญแจ',
        'Condo or building with juristic key handout',
      );
  String get viewingAccessModeMailbox => t(
        'ฝากกุญแจ / คีย์การ์ด (ตู้จดหมาย / จุดรับกุญแจ)',
        'Key deposit (mailbox / key pickup point)',
      );
  String get viewingAccessModeMailboxHint => t(
        'มีจุดฝากหรือตู้ที่เจ้าหน้าที่/นิติจัดไว้',
        'Mailbox or designated key pickup',
      );
  String get viewingAccessNoteLabel =>
      t('หมายเหตุเพิ่มเติม (ไม่บังคับ)', 'Extra note (optional)');
  String get viewingAccessNoteHint => t(
        'เช่น ติดต่อนิติก่อน 9:00, วันหยุดไม่เปิด',
        'e.g. call juristic before 9:00, closed on holidays',
      );
  String get viewingAccessSummaryFollowUp => t(
        'นัดดู: สอบถามรายละเอียดเมื่อมีลูกค้าสนใจ',
        'Viewing: details TBD when customer requests',
      );
  String viewingAccessSummaryOwnerOpen(int days) => t(
        'เจ้าของมาเปิด (แจ้งล่วงหน้า $days วัน)',
        'Owner opens (notify $days day(s) ahead)',
      );
  String get viewingAccessSummaryJuristic =>
      t('เบิกกุญแจนิติ', 'Juristic key pickup');
  String get viewingAccessSummaryMailbox =>
      t('ฝากกุญแจ/ตู้', 'Key deposit');
  String get viewingAccessSummaryMayFollowUp =>
      t('อาจสอบถามเพิ่ม', 'may follow up');

  // Occupancy status (create listing)
  String get occupancySectionTitle => t('สถานะทรัพย์', 'Property status');
  String get occupancySectionHint => t(
        'ช่วยทีมนัดดูและทำการตลาด — เลือกตามความจริง',
        'Helps viewing coordination and marketing',
      );
  String occupancyReadyLabel(String propertySlug) {
    switch (propertySlug) {
      case 'house':
      case 'townhome':
      case 'home_office':
        return t('บ้านว่างพร้อมอยู่', 'Vacant — move-in ready');
      case 'land':
        return t('ที่ดินพร้อมโอน', 'Land — ready to transfer');
      case 'office':
      case 'commercial':
      case 'warehouse':
      case 'factory':
        return t('พื้นที่ว่างพร้อมใช้งาน', 'Vacant — ready to use');
      case 'apartment':
        return t('ห้องว่างพร้อมอยู่', 'Vacant — move-in ready');
      default:
        return t('ห้องว่างพร้อมอยู่', 'Vacant — move-in ready');
    }
  }

  String get occupancyRenovating =>
      t('อยู่ระหว่างรีโนเวท', 'Under renovation');
  String get occupancyTenanted =>
      t('มีผู้เช่าอยู่', 'Currently tenanted');
  String get occupancySaleWithTenant =>
      t('ขายพร้อมผู้เช่า', 'Sale with tenant in place');
  String get occupancyPickReadyDate =>
      t('เลือกวันที่จะพร้อม', 'Pick ready date');
  String occupancyReadyOnDate(String date) =>
      t('จะพร้อมวันที่ $date', 'Ready on $date');
  String occupancyCurrentRent(String amount) =>
      t('ค่าเช่าปัจจุบัน ~$amount บาท/เดือน', 'Current rent ~$amount THB/mo');
  String get occupancyTenantRentLabel =>
      t('ค่าเช่าปัจจุบัน (บาท/เดือน) *', 'Current rent (THB/month) *');
  String occupancyYieldPreview(String pct) =>
      t('Yield โดยประมาณ ~$pct%', 'Est. yield ~$pct%');
  String get occupancyYieldAfterPrice => t(
        'ระบุราคาขายในขั้นถัดไปเพื่อคำนวณ Yield',
        'Enter sale price next step to calculate yield',
      );
  String get occupancyViewingDuring =>
      t('นัดดูระหว่างนี้ได้', 'Viewings allowed in the meantime');
  String get occupancyDateRequired =>
      t('เลือกวันที่จะพร้อม', 'Select when the property will be ready');
  String get occupancyRentRequired =>
      t('ระบุค่าเช่าปัจจุบัน', 'Enter current monthly rent');
  String get createListingPromoPreviewTitle => t('ตัวอย่างบนประกาศ', 'Listing preview');
  String get createListingOpenMapLink => t('เปิดแผนที่', 'Open map');
  String get createListingEditMapLink => t('แก้ลิงก์แผนที่', 'Edit map link');
  String get createListingMapLinkInvalid => t(
        'ลิงก์ไม่ถูกต้อง — ใช้ Google Maps หรือ Apple Maps',
        'Invalid link — use Google Maps or Apple Maps',
      );
  String get adminTrialListingApproved => t(
        'อนุมัติแล้ว (โหมดทดลอง) — ดูที่ประกาศของเจ้าของ',
        'Approved (trial) — check owner My listings',
      );
  String get adminTrialListingRejected => t(
        'ส่งกลับเป็นร่าง (โหมดทดลอง)',
        'Sent back to draft (trial)',
      );
  String get adminTrialListingActionFailed => t(
        'ไม่พบประกาศนี้ในโหมดทดลอง',
        'Listing not found in trial mode',
      );

  // Promo banner
  String get promoTitle => t('ลงประกาศฟรี', 'List your property free');
  String get promoBody => t(
        'เช่า / ขายได้ทันที · ไม่มีค่าสมาชิก',
        'Rent or sell · No membership fee',
      );
  String get promoCta => t('ลงประกาศเลย', 'Post now');

  // Tabs / categories
  String get rent => t('เช่า', 'Rent');
  String get sale => t('ซื้อ', 'Buy');
  String get allCategories => t('ทั้งหมด', 'All');
  String get mapSearchLabel => t('ค้นหาด้วยแผนที่', 'Map search');
  String get mapSearchShort => t('แผนที่', 'Map');

  String get homeLookingTitle => t('กำลังหาอะไรอยู่...', "I'm looking for...");
  String get homeLookingSubtitle =>
      t('ค้นหาทำเล · โครงการ · งบประมาณ', 'Search area, project & budget');
  String get homePropertyOthers => t('อื่นๆ', 'Others');
  String get propertyTypeSheetTitle => t('ประเภทอสังหา', 'Property types');
  String get homeQuickHelperTitle => t('ช่วยหาทรัพย์ฟรี', 'Free property match');
  String get homeQuickHelperBody => t(
        'บอกความต้องการ เราหาให้ฟรี',
        'Tell us your needs — we find matches free',
      );
  String get homeQuickOwnerTitle => t('ลงประกาศฟรี', 'List for free');
  String get homeQuickOwnerBody => t(
        'ลงประกาศได้ไม่จำกัด ไม่มีค่าใช้จ่าย',
        'Unlimited listings, free of charge',
      );
  String get homeQuickBoardTitle => t('บอร์ดหาทรัพย์', 'Demand board');
  String get homeQuickBoardBody => t(
        'แหล่งรวมคนหาทรัพย์ เสนอทรัพย์ที่คุณมีได้เลย',
        'Seekers post here — offer what you have',
      );
  String get homeQuickManageTitle => t('จัดการประกาศของคุณ', 'Manage your listings');
  String get homeQuickManageBody => t(
        'แก้ไข อัปเดต ปักหมุด — ควบคุมประกาศได้ครบ',
        'Edit, refresh & pin — full control',
      );
  String get homeBadgeNew => t('ใหม่', 'New');
  String get homeTabPopularAreas => t('ทำเลยอดฮิต', 'Hot areas');
  String get homeTabTransitLines => t('เส้นรถไฟฟ้า', 'Transit lines');

  String perspectiveFeedDescription(AppPerspectiveKey key) {
    switch (key) {
      case AppPerspectiveKey.customer:
        return t(
          'คุณจะเห็นข้อมูลประกาศทั้งหมด',
          'You will see all listings',
        );
      case AppPerspectiveKey.agent:
        return t(
          'คุณจะเห็นเฉพาะทรัพย์ที่เปิดรับโคนายหน้า',
          'You will see only co-broker eligible listings',
        );
      case AppPerspectiveKey.owner:
        return t(
          'คุณจะเห็นข้อมูลประกาศทั้งหมด',
          'You will see all listings',
        );
    }
  }

  String get requirementTellTitle => t('บอกความต้องการ', 'Tell us what you need');
  String get requirementTellBody => t(
        'เราจะจัดหาทรัพย์ที่ตรงกับความต้องการของคุณมาให้',
        'We will find properties that match your needs',
      );
  String get promoBodyShort => t(
        'ลงประกาศได้ไม่จำกัด ไม่มีค่าใช้จ่าย',
        'Unlimited listings, free of charge',
      );

  String perspectiveChipShort(AppPerspectiveKey key) {
    switch (key) {
      case AppPerspectiveKey.customer:
        return t('หาซื้อ/เช่า', 'Rent/Buy');
      case AppPerspectiveKey.agent:
        return t('นายหน้า', 'Broker');
      case AppPerspectiveKey.owner:
        return t('เจ้าของ', 'Owner');
    }
  }

  String get aiGuideHint => t(
        'บอกทำเล · โครงการ · งบประมาณ — AI ช่วยคัดทรัพย์ให้',
        'Tell area, project & budget — AI finds matches',
      );
  String get aiGuideExample => t(
        'ตัวอย่าง: 「หาคอนโดเช่า ทองหล่อ งบ 18,000」',
        'e.g. "Condo rent Thonglor budget 18,000"',
      );
  String get appointmentsTitle => t('นัดหมาย', 'Appointments');
  String get myRequestsSection => t('นัดชม & คำขอของฉัน', 'My viewings & requests');

  // Chat tab
  String get messagesTitle => t('แชท/นัดหมาย', 'Chat & appointments');
  String get chatSectionTitle => t('แชท', 'Chat');
  String get chatWithAi => chatDiscovery;

  String get chatDiscovery =>
      t('ค้นหา/แนะนำทรัพย์', 'Search & recommend properties');
  String get chatWithStaff => t('คุยกับเจ้าหน้าที่', 'Chat with staff');
  String get chatHistory => t('ประวัติห้องแชท', 'Chat history');
  String get chatEmptyHint => t(
        'กดปุ่มด้านบนเพื่อเริ่มคุย หรือแชทจากหน้ารายการทรัพย์',
        'Start a chat above or from a listing',
      );

  // Profile
  String get profile => t('โปรไฟล์', 'Profile');
  String get displayLanguage => t('ภาษาแสดงผล', 'Display language');
  String get languageTh => t('ไทย', 'Thai');
  String get languageEn => t('English', 'English');

  String perspectiveShort(String th, String en) => t(th, en);

  String perspectiveLabelFull(AppPerspectiveKey key) {
    switch (key) {
      case AppPerspectiveKey.customer:
        return t(
          'กำลังหาซื้อ / หาเช่าอยู่ด้วยตัวเอง',
          'Looking to buy or rent',
        );
      case AppPerspectiveKey.agent:
        return t('นายหน้า กำลังหาทรัพย์ให้ลูกค้า', 'Broker seeking for clients');
      case AppPerspectiveKey.owner:
        return t('เจ้าของทรัพย์ · ลงประกาศ', 'Owner · post listings');
    }
  }

  // ── Common actions ──
  String get ok => t('ตกลง', 'OK');
  String get cancel => t('ยกเลิก', 'Cancel');
  String get save => t('บันทึก', 'Save');
  String get edit => t('แก้ไข', 'Edit');
  String get back => t('กลับ', 'Back');
  String get clear => t('ล้าง', 'Clear');
  String get apply => t('ใช้ตัวกรอง', 'Apply filters');
  String get open => t('เปิด', 'Open');
  String get share => t('แชร์', 'Share');
  String get refresh => t('รีเฟรช', 'Refresh');
  String get submit => t('ส่ง', 'Submit');
  String get publish => t('เผยแพร่', 'Publish');
  String get draft => t('บันทึกแบบร่าง', 'Save draft');
  String get filters => t('ตัวกรอง', 'Filters');
  String get enter => t('เข้าใช้', 'Sign in');

  // ── Errors / not found ──
  String get notFoundListing => t('ไม่พบทรัพย์', 'Listing not found');
  String get notFoundSection => t('ไม่พบรายการ', 'Section not found');
  String get notFoundLead => t('ไม่พบ Lead', 'Lead not found');
  String get notFoundChat => t('ไม่พบแชท', 'Chat not found');
  String get notFoundPost => t('ไม่พบประกาศ', 'Post not found');

  // ── Listing card meta ──
  String bedsShort(int n) => t('$n นอน', '$n bed');
  String sqmShort(int n) => t('$n ตร.ม.', '$n sqm');
  String get perMonth => t('/เดือน', '/mo');
  String get listingTypeRent => t('เช่า', 'Rent');
  String get listingTypeSale => t('ขาย', 'Sale');
  String get listingTypeSaleInstallment => t('ขายฝาก', 'Installment sale');

  /// ป้ายประเภทประกาศ — ไม่มี เซ้ง / ขายดาวน์
  String listingTransactionLabel(String? type) {
    switch (type) {
      case 'rent':
        return listingTypeRent;
      case 'sale':
        return listingTypeSale;
      case 'sale_installment':
        return listingTypeSaleInstallment;
      default:
        return type?.isNotEmpty == true ? type! : listingTypeSale;
    }
  }
  String get coAgentBadge => t('รับโค', 'Co-broker');
  String get coAgentEligible => t('รับโคนายหน้า', 'Co-broker eligible');
  String get coAgentOpen => t('เปิดรับโคนายหน้า', 'Open for co-broker');

  // ── Filters ──
  String get filterTitle => t('ตัวกรองการค้นหา', 'Search filters');
  String get filterTransactionType => t('ประเภทธุรกรรม', 'Transaction type');
  String get filterRentSeek => t('หาเช่า', 'For rent');
  String get filterBuySeek => t('หาซื้อ', 'For sale');
  String get filterPropertyType => t('ประเภททรัพย์', 'Property type');
  String get filterBedrooms => t('ห้องนอน', 'Bedrooms');
  String get filterStudio => t('สตูดิโอ', 'Studio');
  String bedCount(int n) => t('$n ห้องนอน', '$n bed');
  String get filterBed3Plus => t('3+', '3+');
  String salePriceRange(String min, String max) =>
      t('ราคาขาย: $min – $max', 'Sale price: $min – $max');
  String rentPriceRange(String min, String max) =>
      t('ราคาเช่า/เดือน: $min – $max', 'Rent/month: $min – $max');
  String get filterPriceHintSale => t(
        'ช่วง 0–20 ล้าน เลื่อนละเอียด · 20–300 ล้าน ช่วงสั้น',
        '0–20M fine steps · 20–300M coarse range',
      );
  String get filterPetAllowed => t('เลี้ยงสัตว์ได้', 'Pet-friendly');
  String get filterInvestor => t('การลงทุน / ซื้อ', 'Investment / buy');
  String get filterWithTenant => t('ซื้อพร้อมผู้เช่า', 'Buy with tenant');
  String get filterBmv => t('BMV', 'BMV');
  String minYieldLabel(String value) =>
      t('Yield ขั้นต่ำ: $value', 'Min yield: $value');
  String get filterNoYield => t('ไม่กรอง', 'No filter');
  String get clearFilters => t('ล้างตัวกรอง', 'Clear filters');
  String get useFilters => t('ใช้ตัวกรอง', 'Apply filters');
  String get useParsedFilters => t('ใช้ตัวกรอง', 'Apply filters');

  // ── Brand ──
  String get brandName => LivingBkkBrand.name;
  String get brandTagline => t(LivingBkkBrand.taglineTh, LivingBkkBrand.taglineEn);

  // ── Auth / login ──
  String get authQuickEntry =>
      t('เข้าใช้งานทันที · ไม่ต้องรหัส', 'Continue · no password needed');
  String get authWelcome => t('ยินดีต้อนรับ', 'Welcome');
  String get authEmailOrUsername => t('ชื่อผู้ใช้ / อีเมล', 'Username / email');
  String get authPassword => t('รหัสผ่าน', 'Password');
  String get forgotPassword => t('ลืมรหัสผ่าน ?', 'Forgot password?');
  String get authOrLoginWith => t('หรือเข้าสู่ระบบด้วย', 'Or sign in with');
  String get authNoAccountYet => t('ยังไม่เคยสมัคร', 'Not registered yet?');
  String get authSignUpFree => t('สมัครสมาชิกฟรี', 'Sign up free');
  String get authHaveAccount => t('มีบัญชีแล้ว?', 'Already have an account?');
  String get authSignInLink => t('เข้าสู่ระบบ', 'Log in');
  String get resetPasswordSent => t(
        'ส่งลิงก์ตั้งรหัสผ่านใหม่ไปที่อีเมลแล้ว',
        'Password reset link sent to your email',
      );
  String get resetPasswordNeedEmail => t(
        'กรุณากรอกอีเมลที่ใช้สมัคร',
        'Enter the email you registered with',
      );
  String get oauthNotConfigured => t(
        'ยังไม่ได้ตั้งค่า Google/Facebook ใน Supabase',
        'Google/Facebook login is not configured in Supabase yet',
      );
  String get loginTitle => t('สมัคร / เข้าสู่ระบบ', 'Sign up / Log in');
  String get signUpTitle => t('สมัครสมาชิก', 'Sign up');
  String get signInTitle => t('เข้าสู่ระบบ', 'Log in');
  String get signUpPageTitle => t('สร้างบัญชี PROPPITER', 'Create PROPPITER account');
  String get signUpPageIntro => t(
        'เช่า ซื้อ ขายในกรุงเทพฯ — สมัครครั้งเดียวใช้ได้ทุกบทบาท',
        'Rent, buy & sell in Bangkok — one account for every role',
      );
  String get signUpPhoneHint => t('เบอร์โทรศัพท์', 'Phone number');
  String get signUpDisplayNameHint => t('ชื่อที่แสดง (ไม่บังคับ)', 'Display name (optional)');
  String get signUpCountryCode => '+66';
  String get signUpAcceptTermsRequired => t(
        'กรุณายอมรับเงื่อนไขการใช้บริการ',
        'Please accept the terms of service',
      );
  String get signUpFieldsRequired => t(
        'กรุณากรอกอีเมลและรหัสผ่าน',
        'Email and password are required',
      );
  String get signUpAvatarLaterHint => t(
        'รูปโปรไฟล์จะอัปโหลดได้ที่หน้าโปรไฟล์ภายหลัง',
        'You can upload your profile photo later in Profile',
      );
  String get signUpTermsPrefix => t('ฉันยอมรับ ', 'I agree to the ');
  String get signUpTermsLink => t('เงื่อนไขการใช้บริการ', 'Terms of Service');
  String get signUpTermsAnd => t(' และ ', ' and ');
  String get signUpPrivacyLink => t('นโยบายความเป็นส่วนตัว', 'Privacy Policy');
  String get loginSubtitleTrial => t(
        'กรุงเทพฯ + ปริมณฑล · สมัครครั้งเดียว · สลับ「คุณคือ」ที่หน้าแรก',
        'Bangkok metro · One account · switch role on home',
      );
  String get loginSubtitleProd => t(
        'กรุงเทพฯ + ปริมณฑล · เช่า ซื้อ ขาย · สมัครด้วยอีเมล + รหัสผ่าน',
        'Bangkok metro · Rent · Buy · Sell · Email + password sign-up',
      );
  String get trialPeriodTitle => t('ช่วงทดลอง', 'Trial period');
  String get trialPeriodBody => t(
        'บัญชีเดียว — ไม่ต้องเลือกบทบาทตอนสมัคร\n'
        'หลังเข้าแล้วไปหน้าแรก → 「คุณคือ」',
        'One account — no role at sign-up\n'
        'After login go to home → switch「You are」',
      );
  String get enterTrial => t('เข้าทดลอง (ไม่ต้องรหัส)', 'Try demo (no password)');
  String get realAuthSection => t('สมัคร / ล็อกอินจริง', 'Real sign-up / log in');
  String get skipBrowse => t('ดูก่อนไม่ต้องเข้าสู่ระบบ', 'Browse without signing in');
  String get configureSupabase => t(
        'ตั้งค่า Supabase ใน mobile/assets/env',
        'Configure Supabase in mobile/assets/env',
      );
  String get configureSupabaseFirst => t(
        'ตั้งค่า Supabase ใน mobile/assets/env ก่อน',
        'Configure Supabase in mobile/assets/env first',
      );
  String get emailLabel => t('อีเมล', 'Email');
  String get passwordLabel => t('รหัสผ่าน (ตั้งเอง)', 'Password');
  String get phoneLabel => t('เบอร์โทร (+66...)', 'Phone (+66...)');
  String get phoneHint => t('+66812345678', '+66812345678');
  String get phoneHelper => t(
        'ใช้ยืนยัน OTP — รองรับเบอร์ต่างประเทศ',
        'For OTP verification — international numbers OK',
      );
  String get sendOtp => t('ส่ง OTP ยืนยันเบอร์', 'Send OTP');
  String get resendOtp => t('ส่ง OTP อีกครั้ง', 'Resend OTP');
  String get signUpHint => t(
        'ไม่ต้องยืนยันอีเมล · ยืนยัน OTP เบอร์โทร\n'
        'ชาวต่างชาติ: ใช้เบอร์ประเทศตัวเอง (+1, +44...) หรือเลือกยืนยันทางอีเมลภายหลัง',
        'No email confirm · verify phone OTP\n'
        'International: use your country code (+1, +44...) or verify email later',
      );
  String get signInHint => t(
        'เข้าด้วยอีเมล + รหัสผ่านที่ตั้งไว้',
        'Log in with email and password',
      );
  String get haveAccount => t('มีบัญชีแล้ว? เข้าสู่ระบบ', 'Have an account? Log in');
  String get noAccount => t('ยังไม่มีบัญชี? สมัคร', 'No account? Sign up');
  String get trialEntered => t(
        'เข้าทดลองแล้ว — สลับ「คุณคือ」ที่หน้าแรกได้',
        'Trial started — switch role on home',
      );
  String get phoneRequired => t(
        'กรุณากรอกเบอร์โทร (รูปแบบ +66...)',
        'Enter phone number (+66... format)',
      );
  String get otpSent => t(
        'ส่ง OTP แล้ว (ถ้าระบบ SMS พร้อมใช้งาน)',
        'OTP sent (if SMS is configured)',
      );

  // ── Profile ──
  String get testUser => t('ผู้ใช้ทดสอบ', 'Test user');
  String get trialModeStatus => t('โหมดทดลอง', 'Trial mode');
  String get demoModeStatus => t('โหมด Demo ข้อมูล', 'Demo data mode');
  String get configuredNotLoggedIn => t('ตั้งค่าแล้ว — ยังไม่ล็อกอิน', 'Configured — not logged in');
  String get configuredLoginOrTrial =>
      t('ตั้งค่าแล้ว — เข้าสู่ระบบหรือทดลอง', 'Configured — log in or try demo');
  String get singleAccountSwitchHome =>
      t('บัญชีเดียว · สลับมุมมองที่หน้าแรก', 'One account · switch view on home');
  String statusTrial(String name) => t('โหมดทดลอง · $name', 'Trial · $name');
  String get loginOrSignUp => t('เข้าสู่ระบบ / สมัคร', 'Log in / Sign up');
  String get loginOrTrial => t('เข้าสู่ระบบ / ทดลอง', 'Log in / Try demo');
  String get signedOutTrial => t('ออกจากโหมดทดลองแล้ว', 'Left trial mode');
  String get signedOut => t('ออกจากระบบแล้ว', 'Signed out');
  String get exitTrial => t('ออกจากโหมดทดลอง', 'Exit trial');
  String get signOut => t('ออกจากระบบ', 'Sign out');
  String get perspectiveSwitchHint => t(
        'สลับได้ที่หัวหน้าแรก (ข้างโลโก้) — 「คุณคือ」\n'
        'นายหน้า = เห็นเฉพาะทรัพย์รับโค · เจ้าของ = ลงประกาศได้',
        'Switch on home header — 「You are」\n'
        'Broker = co-broker listings only · Owner = can post',
      );
  String get adminCenter => t('ศูนย์ Admin (ทีมงาน)', 'Admin center (team)');
  String get checkingRole => t('กำลังตรวจสอบสิทธิ์…', 'Checking permissions…');
  String get adminHintDemo =>
      t('โหมด Demo — ทดสอบแชท/Lead/รายงานได้ทันที', 'Demo — test chat/leads/reports');
  String get adminHintTrial => t(
        'โหมดทดลอง — เปิดศูนย์ Admin ด้วยข้อมูลตัวอย่าง',
        'Trial — open Admin with sample data',
      );
  String get adminHintReal =>
      t('บัญชีแอดมิน — จัดการแชท Lead และรายงาน', 'Admin — manage chat, leads & reports');
  String get adminHintNeedLogin => t(
        'ล็อกอินด้วยบัญชี admin ใน Supabase เพื่อใช้งานจริง',
        'Log in with Supabase admin account for production',
      );
  String get postListingProperty => t('ลงประกาศทรัพย์', 'Post listing');
  String get myListingsConfirm =>
      t('ประกาศของฉัน · ยืนยันว่าง', 'My listings · mark available');
  String get notifications => t('การแจ้งเตือน', 'Notifications');
  String get notificationsRealtimeFcm => t(
        'Realtime + FCM เปิดแล้ว (Lead/นัดชม)',
        'Realtime + FCM enabled (leads/viewings)',
      );
  String get notificationsPartial => t(
        'ในแอป: Realtime · นอกแอป: ใส่ FIREBASE_* ตาม mobile/docs/FCM_SETUP.md',
        'In-app: Realtime · Push: set FIREBASE_* per mobile/docs/FCM_SETUP.md',
      );
  String get notificationsDemo =>
      t('โหมด Demo — SnackBar เมื่อมี Lead (จำลอง)', 'Demo — SnackBar on lead (simulated)');
  String get useOnMobile => t('ใช้บนมือถือจริง', 'Use on mobile device');
  String get pwaHint => t(
        'iPhone: Safari → แชร์ → เพิ่มไปที่หน้าจอโฮม\n'
        'Android: Chrome → เมนู → เพิ่มไปหน้าจอหลัก',
        'iPhone: Safari → Share → Add to Home Screen\n'
        'Android: Chrome → Menu → Add to Home Screen',
      );
  String get contactChat => t('ติดต่อ / แชท', 'Contact / Chat');
  String get setupGuide => t('คู่มือตั้งค่า', 'Setup guide');
  String get setupGuidePaths => t('docs/SETUP.md · docs/โหมดทดลอง.md', 'docs/SETUP.md · docs/trial-mode.md');

  // ── Perspective dropdown ──
  String get whoAreYou => t('คุณเป็นใคร', 'Who are you');
  String get agentCoOnlyHint =>
      t('แสดงเฉพาะทรัพย์รับโคนายหน้า', 'Co-broker listings only');

  // ── Trial banner ──
  String get trialBannerText => t(
        'โหมดทดลอง — เข้าสู่ระบบแล้วสลับมุมมองที่หน้าแรก',
        'Trial mode — log in then switch view on home',
      );

  // ── Listing detail ──
  String get downloadAllPhotos => t('ดาวน์โหลดรูปทั้งหมด', 'Download all photos');
  String showAllPhotos(int n) => t('แสดงรูปทั้งหมด\n($n)', 'All photos\n($n)');
  String pricePerSqm(String formatted) =>
      t('($formatted บ./ตร.ม.)', '($formatted /sqm)');
  String peopleViewingNow(int n) =>
      t('มี $n คนกำลังดูประกาศนี้', '$n people viewing this listing now');
  String get detailBookPropertyCta => t('สนใจจอง', 'Interested to book');
  String get detailContactCta => t('สอบถามข้อมูล', 'Ask for info');
  String get detailAskInfoCta => detailContactCta;
  String get detailScheduleCta => t('นัดชม', 'Book viewing');
  String get listingLastUpdated => t('อัปเดตล่าสุด', 'Last updated');
  String listingUpdatedAgo(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return t('เมื่อสักครู่', 'Just now');
    if (diff.inHours < 1) {
      return t('${diff.inMinutes} นาทีที่แล้ว', '${diff.inMinutes} min ago');
    }
    if (diff.inHours < 24 && at.day == DateTime.now().day) {
      return t('${diff.inHours} ชั่วโมงที่แล้ว', '${diff.inHours} hours ago');
    }
    if (diff.inDays == 0) return t('วันนี้', 'Today');
    if (diff.inDays == 1) return t('เมื่อวาน', 'Yesterday');
    return t('${diff.inDays} วันที่แล้ว', '${diff.inDays} days ago');
  }
  String get bookingInterestIntent =>
      t('สนใจจองทรัพย์นี้ — รอแอดมินติดต่อกลับ', 'Interested to book — awaiting admin');
  String get bookingInterestReceived => t(
        'เราได้รับความสนใจจองของคุณแล้ว\nทีมงานจะติดต่อกลับโดยเร็วที่สุด',
        'We received your booking interest.\nOur team will contact you ASAP.',
      );
  String get bookingInterestAdminAlert => t(
        '🔥 ลูกค้าสนใจจอง — ตอบทันที (ความสำคัญสูงสุด)',
        '🔥 Customer wants to book — reply immediately (top priority)',
      );
  String get adminInboxBookingInterest => t('สนใจจองด่วน', 'Urgent booking');
  String get searchDiscoveryHint =>
      t('ทำเล | โครงการ | คำอื่นๆ', 'Area | Project | Keywords');
  String get searchHistoryTitle => t('ประวัติและเทรนด์การค้นหา', 'History & trends');
  String get searchClearAll => t('ล้างทั้งหมด', 'Clear all');
  String get searchTrendsTitle => t('เทรนด์การค้นหา', 'Search trends');
  String get searchResultsTitle => t('ผลการค้นหา', 'Search results');
  String get searchByCategoryTitle => t('ค้นหาจากหมวดหมู่', 'Search by category');
  String get searchNearByTitle => t('Near By หาอสังหาฯ ใกล้ตัวคุณ', 'Near By — find nearby');
  String get searchNearBySubtitle => t('หาจากปักหมุดบนแผนที่', 'Search from map pin');
  String get searchTabLocation => t('ทำเล', 'Location');
  String get searchTabTransit => t('การเดินทาง', 'Transit');
  String get searchTabProject => t('โครงการ', 'Projects');
  String get searchPopularAreasTitle => t('ทำเลที่ถูกค้นหามากที่สุด', 'Most searched areas');
  String get searchProjectHint => t('พิมพ์ชื่อโครงการในช่องค้นหาด้านบน', 'Type a project name above');
  String get listingSubmitReceivedTitle => t('เราได้รับข้อมูลของคุณแล้ว', 'We received your listing');
  String get listingSubmitReceivedBody => t(
        'หลังจากตรวจสอบแล้ว เราจะแจ้งผลให้คุณทราบโดยเร็วที่สุด',
        'After review, we will notify you as soon as possible.',
      );
  String get detailOfferCta => t('เสนอ โคนายหน้า', 'Co-broker offer');
  String get listingStockOwnerDirect =>
      t('เจ้าของโพสต์', 'Owner listing');
  String get listingStockCoAgent => t('โคนายหน้า 50/50', 'Co-broker 50/50');
  String propertyTypeChip(String type) {
    switch (type) {
      case 'condo':
        return t('คอนโด', 'Condo');
      case 'house':
        return t('บ้าน', 'House');
      case 'townhouse':
        return t('ทาวน์เฮ้าส์', 'Townhome');
      case 'apartment':
        return t('อพาร์ทเมนต์', 'Apartment');
      default:
        return t('ทรัพย์', 'Property');
    }
  }
  String get inquireOrViewing =>
      t('สอบถามรายละเอียด / นัดดูห้อง', 'Inquire / book viewing');
  String get requestCoAgent => t('ขอโคนายหน้า', 'Request co-broker');

  // ── My listings ──
  String get myListingsTitle => t('ประกาศของฉัน', 'My listings');
  String get noListingsYet => t('ยังไม่มีประกาศ', 'No listings yet');
  String get confirmAvailable => t('ยืนยันว่าง', 'Mark available');
  String get confirmedAvailableBump => t(
        'ยืนยันว่างแล้ว — ดันประกาศ (Bump)',
        'Marked available — listing bumped',
      );
  String listingBumpReminder(int daysLeft) => t(
        '⏰ กรุณายืนยันว่าง — เหลือ $daysLeft วันก่อนเก็บประกาศอัตโนมัติ',
        '⏰ Please confirm available — $daysLeft days until auto-archive',
      );
  String listingDaysUntilArchive(int daysLeft) => t(
        'เก็บอัตโนมัติใน $daysLeft วัน หากไม่ยืนยันว่าง',
        'Auto-archive in $daysLeft days without confirmation',
      );
  String get listingStatusPublished => t('เผยแพร่', 'Published');
  String get listingStatusArchived => t('เก็บแล้ว', 'Archived');
  String get listingStatusHidden => t('ซ่อน', 'Hidden');
  String get listingStatusDraft => t('แบบร่าง', 'Draft');
  String get listingSectionActive => t('ประกาศที่ใช้งาน', 'Active listings');
  String get listingSectionArchived => t('เก็บในคลัง', 'Archived');
  String get listingSectionOther => t('อื่นๆ', 'Other');
  String get closeListingAction => t('ปิดการขาย/เช่า', 'Close listing');
  String get closeListingConfirm => t('ยืนยันปิดประกาศ', 'Confirm close');
  String get closeListingRentTitle => t('ปิดประกาศเช่า', 'Close rental listing');
  String get closeListingRentHint => t(
        'ระบุวันที่ห้องว่างอีกครั้ง — ประกาศจะถูกเก็บในคลัง (ไม่แสดงต่อสาธารณะ)',
        'When will it be available again? Listing will be archived (hidden from public).',
      );
  String get closeListingSaleTitle => t('ปิดการขายแล้ว', 'Mark as sold');
  String get closeListingSaleHint => t(
        'ทรัพย์นี้จะถูกเก็บในคลังและไม่นำกลับมาใช้งานเป็นประกาศเดิมอีก '
        '(ข้อมูลยังอยู่ในระบบเพื่อบันทึกของแพลตฟอร์ม)',
        'This listing will be archived and cannot be republished as the same unit. '
        'Data is kept for platform records.',
      );
  String get listingClosedArchived => t(
        'เก็บประกาศแล้ว — ไม่แสดงต่อสาธารณะ',
        'Listing archived — no longer public',
      );
  String get listingSaleArchivedNote => t(
        'ขาย/ปิดแล้ว — ไม่นำกลับมาใช้เป็นประกาศเดิม',
        'Sold/closed — cannot republish as same listing',
      );
  String listingRentAvailableAgain(String date) =>
      t('ว่างอีกครั้งประมาณ: $date', 'Available again around: $date');
  String get deleteListingTitle => t('ลบจากรายการของฉัน', 'Remove from my list');
  String get deleteListingHint => t(
        'ลบจากมุมมองของคุณเท่านั้น — ข้อมูลยังอยู่ในฐานข้อมูลของ PROPPITER',
        'Removes from your view only — data stays in PROPPITER database',
      );
  String get deleteListingConfirm => t('ลบถาวรจากรายการ', 'Remove permanently');
  String get listingDeletedFromView => t(
        'ลบจากรายการของคุณแล้ว',
        'Removed from your list',
      );
  String get listingLifecyclePolicy => t(
        'แจ้งเตือนทุก 7 วันให้กด「ยืนยันว่าง」· ครบ 30 วันไม่ยืนยัน → เก็บประกาศอัตโนมัติ · '
        'Push นอกแอป (เหมือน LINE) บน iOS/Android เมื่อตั้ง Firebase — ดู mobile/docs/FCM_SETUP.md',
        'Reminder every 7 days to confirm available · 30 days without confirm → auto-archive · '
        'Out-of-app push on iOS/Android with Firebase — see mobile/docs/FCM_SETUP.md',
      );
  String listingBumpBannerTitle(int count) => t(
        'มี $count ประกาศรอยืนยันว่าง',
        '$count listing(s) need availability confirm',
      );
  String get pushListingArchivedTitle =>
      t('PROPPITER — เก็บประกาศแล้ว', 'PROPPITER — Listing archived');
  String pushListingArchivedBody(String code, String title) => t(
        '$code · $title\nเก็บอัตโนมัติ — ไม่ได้ยืนยันว่างครบ 30 วัน',
        '$code · $title\nAuto-archived — no confirm for 30 days',
      );

  // ── Create listing ──
  String get createListingTitle => t('สร้างประกาศ', 'Create listing');
  String get createListingSaveDraft => t('บันทึกร่าง', 'Save draft');
  String get createListingNext => t('ถัดไป', 'Next');
  String get createListingBack => t('ย้อนกลับ', 'Back');
  String get createListingPosterLabel => t('สถานะผู้ประกาศ *', 'Poster status *');
  String get createListingPosterOwner => t('เจ้าของ', 'Owner');
  String get createListingPosterAgent => t('นายหน้า', 'Broker');
  String get createListingPosterOwnerHint => t(
        'เลือกสถานะตามความจริง — หากมีรายงานว่าไม่ใช่เจ้าของ ประกาศจะถูกระงับเพื่อตรวจสอบ',
        'Select your role honestly — false owner claims may suspend your listing',
      );
  String get createListingPosterAgentHint => t(
        'ประกาศในนามนายหน้า — ทีมจะตรวจสอบสิทธิ์ก่อนเผยแพร่',
        'Posting as broker — our team will verify before publishing',
      );
  String get createListingIntentLabel => t('ต้องการลงประกาศ *', 'Listing intent *');
  String get createListingNoProject => t('ไม่ระบุโครงการ', 'No project specified');
  String get createListingNoProjectHint => t(
        'บ้านนอกโครงการ / ทำเลเอง — ต้องใส่ลิงก์แผนที่',
        'Standalone property — map link required',
      );
  String get createListingLocationLinkLabel => t('ลิงก์โลเคชัน *', 'Location link *');
  String get createListingLocationLinkHint => t(
        'Google Maps / Apple Maps URL',
        'Google Maps / Apple Maps URL',
      );
  String get createListingLocationLinkRequired => t(
        'บ้านนอกโครงการ — กรุณาใส่ลิงก์แผนที่ (Google Maps)',
        'Standalone listing — paste a map link (Google Maps)',
      );
  String get createListingLocationLinkInvalid => t(
        'ลิงก์ไม่ถูกต้อง — ใช้ลิงก์แผนที่ที่ขึ้นต้นด้วย https://',
        'Invalid link — use an https:// map URL',
      );
  String get createListingCatalogNoLink => t(
        'โครงการในระบบ — ไม่ต้องใส่ลิงก์แผนที่ (ปักหมุดตามโครงการ)',
        'Registered project — no map link needed (pinned to project)',
      );
  String get createListingMatterportLabel => t('ลิงก์ Matterport (ถ้ามี)', 'Matterport link (optional)');
  String get createListingTiktokLabel => t('ลิงก์ TikTok (ถ้ามี)', 'TikTok link (optional)');
  String get createListingAcceptAgent => t('เปิดรับนายหน้า', 'Accept brokers');
  String get createListingAcceptAgentHint => t(
        'อนุญาตให้นายหน้าช่วยทำการตลาดผ่าน PROPPITER',
        'Allow brokers to market via PROPPITER',
      );
  String get createListingCommissionPercent => t('ค่าคอมมิชชัน (%)', 'Commission (%)');
  String get createListingCommissionTitle =>
      t('ค่าคอมมิชชัน / นายหน้า *', 'Commission / broker fee *');
  String get createListingCommissionPolicyOwner => t(
        'มาตรฐานไทย: ขาย/ขายฝาก ~3% จากราคาขาย · เช่า ~1 เดือนต่อสัญญา 12 เดือน (ปรับตามสัญญา)',
        'Thailand norm: sale ~3% of price · rent ~1 month per 12-month lease',
      );
  String get createListingCommissionPolicyAgent => t(
        'โคนายหน้า: แบ่ง 50/50 จากอัตรามาตรฐาน — ขายเริ่ม 1.5% · เช่าเริ่ม 0.5 เดือน',
        'Co-broker: 50/50 split — sale from 1.5% · rent from 0.5 month',
      );
  String get createListingNetReceiveLabel =>
      t('ต้องการรับสุทธิ (บาท) *', 'Target net amount (THB) *');
  String get createListingNetReceiveRequired =>
      t('ระบุยอดสุทธิที่ต้องการรับ', 'Enter your target net amount');
  String get createListingNetSelfAddHint => t(
        'ระบุยอดสุทธิที่ต้องการรับ และ % ที่ให้นายหน้าบวกเพิ่ม — ระบบคำนวณราคาประกาศให้',
        'Enter net to owner and broker commission % — we calculate the listing price',
      );
  String get createListingBrokerCommissionLabel =>
      t('Commission ที่นายหน้าบวก (%) *', 'Broker commission (%) *');
  String get createListingBrokerCommissionRequired =>
      t('ระบุ Commission % ที่นายหน้าจะบวกเพิ่ม', 'Enter broker commission %');
  String createListingListedPriceFromNet(String amount) => t(
        'ราคาประกาศโดยประมาณ ~$amount บาท',
        'Est. listing price ~$amount THB',
      );
  String get createListingLeaseMonthsLabel =>
      t('ระยะสัญญาเช่า (เดือน)', 'Lease term (months)');
  String createListingCommissionEstimate(String amount) => t(
        'ประมาณค่าคอม ~$amount บาท',
        'Est. commission ~$amount THB',
      );
  String get createListingVideoSectionHint => t(
        'วิดีโอ (ถ้ามี) — ใส่ได้เฉพาะ YouTube หรือ TikTok',
        'Video (optional) — YouTube or TikTok only',
      );
  String get createListingSaleInstallmentCommissionNote => t(
        'ขายฝาก — ใช้โครงสร้างค่าคอมแบบขาย',
        'Installment sale — same commission as sale',
      );
  String get listingStatusPendingReview => t('รอตรวจสอบ', 'Pending review');
  String get listingSectionPendingReview => t('รอทีมตรวจสอบ', 'Pending review');
  String get listingPendingReviewHint => t(
        'ทีม PROPPITER กำลังตรวจสอบ — จะแจ้งเมื่อขึ้นประกาศแล้ว',
        'PROPPITER team is reviewing — we will notify you when live',
      );
  String get homeSaleIncludesInstallment => t(
        'ซื้อ (รวมขายฝาก)',
        'Buy (incl. installment sale)',
      );
  String get createListingSubmittedTitle => t('ส่งประกาศแล้ว', 'Listing submitted');
  String get createListingSubmittedBody => t(
        'บันทึกไปที่「ประกาศของฉัน」แล้ว — ทีมงานจะตรวจสอบก่อนเผยแพร่',
        'Saved under My listings — our team will review before publishing',
      );
  String get createListingGoToMine => t('ไปจัดการประกาศ', 'Manage listings');
  String get createListingConfirmTitle => t('ยืนยันส่งประกาศ', 'Confirm submit');
  String get createListingConfirmIntro => t(
        'ตรวจสอบข้อมูลก่อนส่งให้ทีมตรวจ — หลังอนุมัติจึงขึ้นประกาศสาธารณะ',
        'Review before sending to our team — goes public after approval',
      );
  String get createListingConfirmEdit => requirementConfirmEdit;
  String get createListingConfirmSubmit => requirementConfirmSubmit;
  String get createListingHashtagsTitle => t('ติดแฮชแท็ก', 'Add hashtags');
  String get createListingHashtagsHint => t(
        'เลือกอย่างน้อย 1 แท็กที่ตรงความจริง',
        'Pick at least one tag that matches the property',
      );
  String get createListingFacilitiesTitle => t('ส่วนกลาง', 'Common facilities');
  String get adminListingsPendingReview => t('ประกาศรอตรวจ', 'Listings pending review');
  String get adminApproveListing => t('อนุมัติเผยแพร่', 'Approve & publish');
  String get adminRejectListing => t('ส่งกลับแก้ไข', 'Send back to draft');

  // ── Saved listings ──
  String get savedListingsTitle => t('บันทึกไว้', 'Saved');

  // ── Share actions ──
  String get noPhotosToShare => t('ยังไม่มีรูปสำหรับทรัพย์นี้', 'No photos for this listing');
  String preparingPhotos(int n) =>
      t('กำลังเตรียมรูป $n ภาพ...', 'Preparing $n photos...');
  String savePhotosFailed(String e) =>
      t('ไม่สามารถบันทึกรูปได้: $e', 'Could not save photos: $e');
  String get linkCopied => t('คัดลอกลิงก์แล้ว', 'Link copied');

  // ── Maps / location ──
  String get enableLocationServices =>
      t('เปิด Location Services ใน Settings', 'Enable Location Services in Settings');
  String get locationDenied =>
      t('ไม่ได้รับอนุญาตใช้ตำแหน่ง', 'Location permission denied');

  // ── Board / offers ──
  String get submitOfferTitle => t('เสนอทรัพย์', 'Submit listing');
  String get offerOwner100 => t('เจ้าของทรัพย์', 'Property owner');
  String get offerCoAgent5050 => t('โคนายหน้า', 'Co-broker');
  String get offerReferrer15 => t(
        'คนแนะนำ (รับค่าแนะนำ 15% ของค่าคอมมิชชั่น)',
        'Referrer (15% of commission)',
      );
  String get offerListingAgent =>
      t('นายหน้าฝั่งประกาศ (รอตรวจ)', 'Listing broker (pending review)');
  String offererCapacityLabel(String code) {
    switch (code) {
      case 'owner_direct_100':
        return offerOwner100;
      case 'co_agent_50_50':
        return offerCoAgent5050;
      case 'referrer_15':
        return offerReferrer15;
      case 'listing_agent':
        return offerListingAgent;
      default:
        return code;
    }
  }

  String get propertyPhotos => t('รูปทรัพย์', 'Property photos');
  String pickPhotos(int n) => t('เลือกรูป ($n)', 'Pick photos ($n)');
  String get submitOffer => t('ส่งข้อเสนอ', 'Submit offer');
  String get offerSubmittedTitle =>
      t('บันทึกข้อเสนอแล้ว', 'Offer saved');
  String get offerSubmittedBody => t(
        'ทีม PROPPITER จะตรวจสอบข้อเสนอและติดต่อกลับในแชท',
        'PROPPITER team will review your offer and follow up in chat',
      );
  String get offerSubmittedSummaryTitle => t('สรุปที่ส่ง', 'Submitted summary');
  String get offerSubmittedChatNote => t(
        'บันทึกลงประวัติแชทหมวด「เสนอทรัพย์」แล้ว — ดูได้ที่แท็บแชท',
        'Saved to chat history under Submit listing — see Messages tab',
      );
  String get offerSubmitted => offerSubmittedBody;

  // ── Work / leads ──
  String get acceptCase => t('รับเคส / ให้นัดดูได้', 'Accept case / allow viewing');
  String get propertyUnavailable => t('ทรัพย์ไม่ว่างแล้ว', 'Property no longer available');
  String get caseAccepted => t('รับเคสแล้ว — เริ่มประสานงานได้', 'Case accepted — coordinate now');
  String get unavailableSaved =>
      t('บันทึกสถานะทรัพย์ไม่ว่างแล้ว', 'Unavailable status saved');
  String get eContractAcceptCommission =>
      t('ยอมรับโครงสร้างค่าคอมมิชชัน', 'Accept commission structure');
  String get eContractConfirm => t('รับเคส / ยืนยัน E-Contract', 'Accept / confirm E-Contract');
  String contractUntil(String date) =>
      t('สัญญา/ไม่ว่างถึง: $date', 'Contract/unavailable until: $date');
  String availableAgain(String date) =>
      t('ว่างอีกครั้งประมาณ: $date', 'Available again around: $date');

  // ── Book viewing ──
  String get bookViewingTitle => t('นัดชมทรัพย์', 'Book viewing');
  String get customerRole => t('ลูกค้า (หาเช่า/หาซื้อด้วยตัวเอง)', 'Customer (rent/buy)');
  String get coAgentRole => t('โคนายหน้า (ต้องการขอโคทรัพย์)', 'Co-broker (request co-listing)');
  String get genderMale => t('ชาย', 'Male');
  String get genderFemale => t('หญิง', 'Female');
  String get genderPreferNot => t('ไม่ระบุ', 'Prefer not to say');
  String viewingDateLabel(String date) => t('วันที่นัดดู: $date', 'Viewing date: $date');
  String viewingTimeLabel(String time) => t('เวลานัดดู: $time', 'Viewing time: $time');
  String get hasCarYes => t('มี', 'Yes');
  String get hasCarNo => t('ไม่มี', 'No');
  String get smokeNo => t('ไม่สูบ', 'Non-smoker');
  String get smokeYes => t('สูบ', 'Smoker');
  String get petNone => t('ไม่มี', 'None');
  String get petCat => t('แมว', 'Cat');
  String get petDog => t('สุนัข', 'Dog');
  String get petOther => t('อื่นๆ', 'Other');
  String get submitViewingRequest => t('ส่งคำขอนัดดู', 'Submit viewing request');

  // ── Admin ──
  String get adminTitle => t('Admin', 'Admin');
  String get adminLivingBkk => t('PROPPITER Admin', 'PROPPITER Admin');
  String get adminLink => t('ลิงก์', 'Link');
  String get adminDetails => t('รายละเอียด', 'Details');
  String get adminConfirmRole => t('ยืนยันสิทธิ์', 'Confirm role');
  String get adminStatsMakecom =>
      t('สถิติวันล่าสุด (สำหรับ Make.com)', 'Latest stats (for Make.com)');
  String get adminChatTitle => t('แชท', 'Chat');
  String get adminReplyCustomer => t('ตอบแชทลูกค้า', 'Reply to customer');
  String get adminCloseCase => t('ปิดเคส', 'Close case');
  String get adminMarkedReplied => t('ทำเครื่องหมายว่าตอบแล้ว', 'Marked as replied');
  String get adminSaveViewing => t('บันทึกนัดชม', 'Save viewing appointment');
  String get adminViewingMap => t('แผนที่โซนนัดชม', 'Viewing zone map');
  String get adminNoCoords => t('ไม่มีพิกัดทรัพย์', 'No property coordinates');
  String get adminCoordinateViewing =>
      t('ประสานงาน / ยืนยันนัดดู', 'Coordinate / confirm viewing');
  String get adminPublishBoard => t('เผยแพร่บอร์ด', 'Publish to board');
  String get adminCopyTsv => t('คัดลอกส่ง Google Sheets', 'Copy for Google Sheets');
  String get adminTsvCopied => t(
        'คัดลอก TSV แล้ว — วางใน Google Sheets ได้',
        'TSV copied — paste into Google Sheets',
      );
  String get adminNoStats => t(
        'ยังไม่มีข้อมูล — ส่ง Lead หรือนัดชมเพื่อสะสมสถิติ',
        'No data yet — submit leads or viewings to collect stats',
      );
  String get adminLifecycleTitle =>
      t('Listing lifecycle', 'Listing lifecycle');
  String get adminRunNow => t('รันตอนี้', 'Run now');
  String get adminNoPhotosPending =>
      t('ไม่มีรูปรออนุมัติ', 'No photos pending approval');
  String get adminNoFlags => t('ไม่มี flag ค้าง', 'No pending flags');

  // ── Profile extras ──
  String get demoModeEditEnv => t(
        'โหมด Demo ข้อมูล — แก้ mobile/assets/env',
        'Demo data mode — edit mobile/assets/env',
      );

  // ── Create listing form ──
  String get createListingNetHint => createListingPriceHint;
  String get listingTitleRequired => t('หัวข้อ *', 'Title *');
  String get districtLabel => t('เขต/ย่าน', 'District / area');
  String get priceNetRequired => createListingSalePriceLabel;
  String get areaSqmLabel => t('ตร.ม.', 'sqm');
  String get descriptionLabel => t('คำอธิบาย', 'Description');
  String get listingTypeLabel => t('ประเภท', 'Type');
  String get coAgentOptional => t('โคนายหน้า (ถ้ามี)', 'Co-broker (optional)');
  String get coAgentNone => t('—', '—');
  String get coAgentDirect => t('Owner Direct', 'Owner Direct');
  String get coAgent5050 => t('โคนายหน้า 50/50', 'Co-broker 50/50');
  String get titlePriceRequired => t(
        'กรอกชื่อและราคา Net (รวมคอมแล้ว)',
        'Enter title and net price (incl. commission)',
      );
  String get listingPublished => t('เผยแพร่ประกาศแล้ว', 'Listing published');
  String get listingDraftSaved => t('บันทึกแบบร่างแล้ว', 'Draft saved');
  String get projectPickerLabel => t('โครงการ / อาคาร *', 'Project / building *');
  String get projectPickerHint => t(
        'เลือกจากระบบเพื่อชื่อมาตรฐานและปักหมุดถูกต้อง (แก้จุดอ่อน LI: ไม่ใช้ GPS มือถือ)',
        'Pick from registry for standard name and map pin (fixes LI GPS issue)',
      );
  String get projectSearchPlaceholder => t('พิมพ์ชื่อโครงการ...', 'Search project name...');
  String projectCatalogLoaded(int n) =>
      t('โหลดสมุดโครงการ $n รายการ', 'Loaded $n projects');
  String get projectSearchNoResults =>
      t('ไม่พบชื่อนี้ — ลองคำอื่น หรือกด「ไม่พบในระบบ」', 'No match — try another name or tap「Not listed」');
  String get projectSearchLoading =>
      t('กำลังค้นหา…', 'Searching…');
  String get projectNotInList => t('ไม่พบในระบบ — กรอกทำเลเอง', 'Not listed — enter location manually');
  String get projectCustomMode => t('กรอกทำเลเอง (ยังไม่อยู่ในระบบ)', 'Custom location (not in registry)');
  String get projectCustomHint => t(
        'กรอกเขต/ย่านด้านล่าง · ทีมจะเพิ่มโครงการในระบบภายหลัง',
        'Fill district below · team will add project to registry later',
      );
  String get projectPinFromCatalog => t('ปักหมุดตามโครงการ', 'Pinned to project');
  String get projectRequired => t('เลือกโครงการ หรือกด「ไม่พบในระบบ」', 'Select a project or tap「Not listed」');
  String get propertyTypeLabel => t('ประเภททรัพย์', 'Property type');
  String get bedroomsFieldLabel => t('ห้องนอน', 'Bedrooms');

  // ── Saved listings ──
  String get savedListingsEmpty => t('ยังไม่มีทรัพย์ที่บันทึก', 'No saved listings yet');
  String get savedListingsHint => t(
        'กดไอคอนหัวใจที่การ์ดทรัพย์เพื่อเก็บไว้ดูภายหลัง',
        'Tap the heart on listing cards to save for later',
      );

  // ── Listing detail extras ──
  String get coAgentRequestSent => t(
        'ส่งคำขอโคนายหน้าแล้ว รอทีมตรวจสอบ',
        'Co-broker request sent — pending review',
      );
  String shareCount(int n) => t('แชร์ $n', '$n shares');
  String get listingDetailsSection => t('รายละเอียดทรัพย์', 'Property details');
  String get projectDetailsSection => t('รายละเอียดโครงการ', 'Project details');
  String get mapApproxHint => t(
        'แผนที่โซนโดยประมาณ\n(ไม่แสดงเลขห้อง)',
        'Approximate area map\n(unit number not shown)',
      );
  String get yearBuiltLabel => t('ปีที่สร้าง', 'Year built');
  String get locationLabel => t('ทำเล', 'Location');
  String get districtField => t('เขต', 'District');
  String get floorLabel => t('ชั้น', 'Floor');
  String get commonFacilities => t('ส่วนกลาง', 'Common facilities');
  String get chatAiHint => t(
        'AI ช่วยตอบเบื้องต้นในแชท — กดขอนัดดูเมื่อพร้อมส่งข้อมูล',
        'AI answers in chat — request viewing when ready',
      );

  // ── Board / offer form ──
  String get offerAsLabel => t('คุณเสนอในฐานะ *', 'You are offering as *');
  String get offerPrivateNote => t(
        'ข้อมูลนี้ไม่แสดงต่อผู้ใช้รายอื่น — ทีม PROPPITER ตรวจสอบเท่านั้น',
        'Not visible to other users — PROPPITER team only',
      );
  String get offerTransactionLabel => t('ประเภทข้อเสนอ *', 'Offer type *');
  String get offerSale => t('ขาย', 'Sale');
  String get offerRent => t('ปล่อยเช่า', 'Rent');
  String get offerPostLinkLabel =>
      t('ลิงก์โพสต์ (ถ้ามี)', 'Post link (optional)');
  String get offerPostLinkHint => t(
        'Facebook / LivingInsider / อื่นๆ',
        'Facebook / LivingInsider / etc.',
      );
  String get offerPropertyNameField =>
      t('ชื่อทรัพย์ / ชื่อโครงการ *', 'Property / project name *');
  String get offerDetailsField =>
      t('รายละเอียดทรัพย์', 'Property details');
  String get offerPriceAskingField =>
      t('ราคาตั้ง (รวมคอมแล้ว) *', 'Asking price (incl. commission) *');
  String get offerPriceMaxField => t(
        'ราคาลดได้สูงสุด (รวมคอมแล้ว) *',
        'Max discounted price (incl. commission) *',
      );
  String get offerPriceCommissionNote => t(
        'ราคาที่ระบุควรสอดคล้องกับค่าคอมที่คุณเลือกด้านล่าง',
        'Prices should align with the commission option you select below',
      );
  String get offerCommissionLabel =>
      t('ค่าคอมมิชชั่นที่จะให้ *', 'Commission you will offer *');
  String get offerCommissionRent1Yr => t(
        'ค่าเช่า 1 เดือน ต่อสัญญาเช่า 1 ปี',
        '1 month rent per 1-year lease',
      );
  String get offerCommissionRent2Yr => t(
        'ค่าเช่า 1 เดือน ต่อสัญญาเช่า 2 ปี',
        '1 month rent per 2-year lease',
      );
  String get offerCommissionOwnerSale3 =>
      t('3% ของราคาขาย', '3% of sale price');
  String get offerCommissionOwnerSale4 =>
      t('4% ของราคาขาย', '4% of sale price');
  String get offerCommissionOwnerSale5 =>
      t('5% ของราคาขาย', '5% of sale price');
  String get offerCommissionOwnerSaleNetSelfAdd => t(
        'ต้องการรับสุทธิ — นายหน้าบวก Commission (%)',
        'Net to owner — broker adds commission (%)',
      );
  String get offerCommissionCoSale1_5 =>
      t('1.5% ของราคาขาย', '1.5% of sale price');
  String get offerCommissionCoSale2 =>
      t('2% ของราคาขาย', '2% of sale price');
  String get offerCommissionCoSaleNetSelfAdd => t(
        'ราคาสุทธิที่เจ้าของต้องการรับ — บวกค่าคอมเอง',
        'Owner net price — add commission on top',
      );
  String get offerCommissionCoRent5050 => t(
        'แบ่ง 50/50 — ค่าเช่า 0.5 เดือน ต่อสัญญาเช่า 1 ปี',
        '50/50 split — 0.5 month rent per 1-year lease',
      );
  String get offerCommissionCoRent70 => t(
        'ค่าคอม 70% ของค่าเช่า 1 เดือน (สัญญา 1 ปี)',
        '70% of 1 month rent (1-year lease)',
      );
  String get offerCommissionCoRent100 => t(
        'ค่าคอม 100% ของค่าเช่า 1 เดือน (สัญญา 1 ปี)',
        '100% of 1 month rent (1-year lease)',
      );
  String get offerCommissionSale3 => offerCommissionOwnerSale3;
  String get offerCommissionSale2 => offerCommissionCoSale2;
  String get offerCommissionOther => t('อื่นๆ (ระบุ)', 'Other (specify)');
  String get offerCommissionOtherHint =>
      t('ระบุค่าคอมมิชชั่นที่จะให้', 'Describe the commission you will offer');
  String get offerContactNameField =>
      t('ชื่อผู้ติดต่อ *', 'Contact name *');
  String get offerContactPhoneField =>
      t('เบอร์โทรติดต่อ *', 'Contact phone *');
  String get offerValidationContactName =>
      t('กรุณากรอกชื่อผู้ติดต่อ', 'Enter contact name');
  String get offerValidationContactPhone =>
      t('กรุณากรอกเบอร์โทรติดต่อ', 'Enter contact phone');
  String get offerValidationCommission =>
      t('กรุณาเลือกค่าคอมมิชชั่น', 'Select a commission option');
  String get offerValidationCommissionOther =>
      t('กรุณาระบุค่าคอมมิชชั่น', 'Enter commission details');
  String offerCommissionSchemeLabel(String scheme) {
    switch (scheme) {
      case 'rent_1mo_per_1yr':
        return offerCommissionRent1Yr;
      case 'rent_1mo_per_2yr':
        return offerCommissionRent2Yr;
      case 'sale_3pct':
        return offerCommissionOwnerSale3;
      case 'sale_4pct':
        return offerCommissionOwnerSale4;
      case 'sale_5pct':
        return offerCommissionOwnerSale5;
      case 'sale_net_self_add':
        return offerCommissionOwnerSaleNetSelfAdd;
      case 'sale_2pct':
        return offerCommissionCoSale2;
      case 'co_sale_1_5pct':
        return offerCommissionCoSale1_5;
      case 'co_sale_2pct':
        return offerCommissionCoSale2;
      case 'co_sale_net_self_add':
        return offerCommissionCoSaleNetSelfAdd;
      case 'co_rent_half_mo_1yr':
        return offerCommissionCoRent5050;
      case 'co_rent_70pct':
        return offerCommissionCoRent70;
      case 'co_rent_100pct':
        return offerCommissionCoRent100;
      case 'custom':
        return offerCommissionOther;
      default:
        return scheme;
    }
  }

  String get offerConfirmTitle =>
      t('ตรวจสอบข้อเสนอ', 'Review your offer');
  String get offerConfirmIntro => t(
        'ตรวจสอบความถูกต้อง — กด「แก้ไข」เพื่อกลับไปแก้ หรือ「ยืนยันส่ง」เพื่อส่งให้ทีมงาน',
        'Check everything — tap Edit to go back or Confirm to send to the team',
      );
  String get offerConfirmEdit => requirementConfirmEdit;
  String get offerConfirmSubmit => requirementConfirmSubmit;
  String get offerSentOpenChat => t(
        'ส่งข้อเสนอแล้ว — เปิดแชทหมวดเสนอทรัพย์',
        'Offer sent — opening Submit listing chat',
      );
  String get offerTransferLabel =>
      t('เงื่อนไขการโอน *', 'Transfer conditions *');
  String get offerTransferSellerAll => t(
        'ผู้ขายออกค่าโอนทั้งหมด',
        'Seller pays all transfer fees',
      );
  String get offerTransferSplit => t(
        'หารค่าใช้จ่ายการโอนคนละครึ่งกับผู้ซื้อ',
        'Split transfer costs 50/50 with buyer',
      );
  String get offerTransferBuyerAll => t(
        'ผู้ซื้อออกค่าโอนทั้งหมด',
        'Buyer pays all transfer fees',
      );
  String get offerTransferOther => t('อื่นๆ (ระบุ)', 'Other (specify)');
  String get offerTransferOtherHint =>
      t('ระบุเงื่อนไขการโอน', 'Describe transfer terms');
  String get offerValidationName =>
      t('กรุณากรอกชื่อทรัพย์ / โครงการ', 'Enter property / project name');
  String get offerValidationPrice =>
      t('กรุณากรอกราคาตั้งและราคาลดได้สูงสุด', 'Enter asking and max prices');
  String get offerValidationPriceOrder => t(
        'ราคาลดได้สูงสุดต้องไม่เกินราคาตั้ง',
        'Max price must not exceed asking price',
      );
  String get offerValidationTransfer =>
      t('กรุณาเลือกเงื่อนไขการโอน', 'Select transfer conditions');
  String get offerTitleField => offerPropertyNameField;
  String get offerPriceNetField => offerPriceAskingField;
  String get offerLinkLabel => offerPostLinkLabel;
  String get notesLabel => t('หมายเหตุ', 'Notes');

  // ── Demand post detail ──
  String get demandZoneMap => t('แผนที่โซนความต้องการ', 'Requirement zone map');
  String budgetMax(String price) => t('งบไม่เกิน $price', 'Budget max $price');
  String areaMin(int sqm) => t('ขนาด ≥ $sqm ตร.ม.', 'Size ≥ $sqm sqm');
  String get offersPrivateAdmin => t(
        'ข้อเสนอของผู้อื่นไม่แสดงต่อสาธารณะ — เฉพาะทีม PROPPITER ตรวจสอบ',
        'Other offers are private — PROPPITER team reviews only',
      );

  // ── Viewing submitted dialog ──
  String get viewingRequestReceived => t('ระบบได้รับคำขอของคุณแล้ว', 'Your request was received');
  String get viewingFollowUpNote => t(
        'ทีมงานจะติดต่อกลับหาคุณโดยเร็วที่สุด '
        'บางกรณีอาจเป็นการโทรติดต่อกลับ',
        'Our team will contact you soon — sometimes by phone',
      );
  String get viewingSavedChatOnly => t(
        'บันทึกในแชทแล้ว — ยังไม่เข้าระบบ Lead บนเซิร์ฟเวอร์ '
        '(รัน Supabase migration ตาราง leads ก่อน)',
        'Saved in chat — not yet in server Lead table (run Supabase leads migration first)',
      );
  String get viewingDuplicatePhone => t(
        'พบ 4 ตัวท้ายเบอร์ลูกค้าซ้ำในระบบ — ทีมงานได้รับแจ้งเตือนแล้ว',
        'Duplicate customer phone suffix detected — team notified',
      );
  String get viewingSummaryTitle => t('สรุปที่ส่งในแชท', 'Summary sent in chat');

  // ── Book viewing form ──
  String get requestViewingTitle => t('ขอนัดดูห้อง', 'Request viewing');
  String get selectDate => t('เลือกวันที่', 'Select date');
  String get selectViewingTime => t('เลือกเวลานัดดู', 'Select viewing time');
  String get contractStartNotLater => t(
        'ต้องการเริ่มสัญญาไม่เกินวันที่ที่เลือก',
        'Contract start no later than selected date',
      );
  String get viewingRequired => t('ต้องการนัดดูทรัพย์ *', 'Viewing appointment *');
  String get nicknameRequired => t('ชื่อเล่น *', 'Nickname *');
  String get phoneRequiredField => t('เบอร์โทร *', 'Phone *');
  String get customerPhoneLast4 => t('4 ตัวท้ายเบอร์ลูกค้า *', 'Customer phone last 4 digits *');
  String get customerPhoneLast4Hint => t('เช่น 5725', 'e.g. 5725');
  String get customerPhoneLast4Helper => t(
        'ใช้ตรวจสอบว่าลูกค้าซ้ำในระบบหรือไม่',
        'Used to check duplicate customers',
      );
  String get occupantsRequired => t('จำนวนผู้เข้าพัก *', 'Occupants *');
  String get genderLabel => t('เพศ', 'Gender');
  String get genderLgbtq => t('LGBTQ+', 'LGBTQ+');
  String get occupationRequired => t('อาชีพ *', 'Occupation *');
  String get occupationHint => t(
        'เช่น นักเรียน/นักศึกษา, เจ้าของธุรกิจ, พนักงานบริษัท',
        'e.g. student, business owner, employee',
      );
  String get workplaceLabel => t('สถานที่ทำงาน', 'Workplace');
  String get contractDurationRequired => t('ระยะสัญญา *', 'Contract duration *');
  String get contractStartLabel => t('วันที่ต้องการเริ่มสัญญา', 'Desired contract start');
  String get contract6Months => t('6 เดือน', '6 months');
  String get contract1Year => t('1 ปี', '1 year');
  String get contract2Years => t('2 ปี', '2 years');
  String get hasCarLabel => t('มีรถยนต์', 'Has car');
  String get smokingLabel => t('สูบบุหรี่', 'Smoking');
  String get petsLabel => t('สัตว์เลี้ยง', 'Pets');
  String get whoAreYouRequired => t('คุณเป็น *', 'You are *');
  String submitFailedWith(String e) => t('ส่งไม่สำเร็จ: $e', 'Submit failed: $e');
  String get errSelectApplicantType => t(
        'กรุณาเลือกว่าคุณเป็นลูกค้าหรือโคนายหน้า',
        'Please select customer or co-broker',
      );
  String get errNicknamePhone => t(
        'กรุณากรอกชื่อเล่นและเบอร์โทร (อย่างน้อย 9 หลัก)',
        'Enter nickname and phone (min 9 digits)',
      );
  String get errRequiredFields => t(
        'กรุณากรอกข้อมูลที่จำเป็น และเลือกวัน/เวลานัดดูให้ครบ',
        'Fill required fields and select viewing date/time',
      );
  String get errCoAgentLast4 => t(
        'โคนายหน้า: กรอก 4 ตัวท้ายของเบอร์ลูกค้า (ตัวเลข 4 หลัก)',
        'Co-broker: enter last 4 digits of customer phone',
      );
  String contractStartNotLaterThan(String date) =>
      t('เริ่มสัญญาไม่เกิน $date', 'Contract start no later than $date');
  String contractStartOn(String date) => t('ต้องการเริ่มสัญญา $date', 'Contract start $date');
  String get summaryWhoAreYou => t('คุณเป็น', 'You are');
  String get summaryNickname => t('ชื่อเล่น', 'Nickname');
  String get summaryPhone => t('เบอร์โทร', 'Phone');
  String get summaryCustomerLast4 => t('4 ตัวท้ายเบอร์ลูกค้า', 'Customer phone last 4');
  String get summaryOccupants => t('จำนวนผู้เข้าพัก', 'Occupants');
  String get summaryGender => t('เพศ', 'Gender');
  String get summaryOccupation => t('อาชีพ', 'Occupation');
  String get summaryWorkplace => t('สถานที่ทำงาน', 'Workplace');
  String get summaryContract => t('ระยะสัญญา', 'Contract');
  String get summaryBudget => t('งบประมาณ', 'Budget');
  String get summaryContractStart => t('วันที่ต้องการเริ่มสัญญา', 'Desired contract start');
  String get summaryHasCar => t('มีรถยนต์', 'Has car');
  String get summarySmoking => t('สูบบุหรี่', 'Smoking');
  String get summaryPets => t('สัตว์เลี้ยง', 'Pets');
  String get summaryViewing => t('นัดดูทรัพย์', 'Viewing');

  // ── Lead inbox ──
  String get leadDefaultName => t('ลูกค้า', 'Customer');
  String get phoneHidden => t('เบอร์ปิด', 'Phone hidden');
  String get statusLabel => t('สถานะ', 'Status');
  String get occupantsLabel => t('ผู้เข้าพัก', 'Occupants');
  String occupantsCount(int n) => t('$n คน', '$n people');
  String get occupationLabel => t('อาชีพ', 'Occupation');
  String get workplaceField => t('ที่ทำงาน', 'Workplace');
  String get movePlanLabel => t('แพลนย้าย', 'Move plan');
  String get contractFieldLabel => t('สัญญา', 'Contract');
  String get budgetLabel => t('งบ', 'Budget');
  String get carLabel => t('รถ', 'Car');
  String get smokingField => t('สูบ', 'Smoking');
  String get petsField => t('สัตว์เลี้ยง', 'Pets');
  String get typeFieldLabel => t('ประเภท', 'Type');
  String get typeSeeker => t('ลูกค้าหาเช่า/ซื้อ', 'Customer rent/buy');
  String get typeCoAgentRequest => t('โคนายหน้าขอโคทรัพย์', 'Co-broker request');
  String get viewingFieldLabel => t('นัดดู', 'Viewing');
  String get caseProcessed => t('เคสนี้ดำเนินการแล้ว', 'Case already processed');

  // ── E-contract ──
  String get eContractTitle => t(
        'ข้อตกลงค่าคอมมิชชัน (E-Contract)',
        'Commission agreement (E-Contract)',
      );
  String listingCodeLabel(String code) => t('ประกาศ $code', 'Listing $code');
  String get propertyCodeLabel => t('รหัสทรัพย์', 'Property');
  String get transactionRefLabel => t('เลขอ้างอิง', 'Ref');
  String referenceCopied(String code) =>
      t('คัดลอก $code แล้ว', 'Copied $code');
  String get viewingRefHint => t(
        'เก็บเลขอ้างอิงไว้ — แจ้งเจ้าหน้าที่เมื่อติดตาม',
        'Save this reference — quote it when following up',
      );
  String viewingRefNote(String chatRef, String? leadRef) {
    if (leadRef != null && leadRef.isNotEmpty) {
      return t(
        'อ้างอิงแชท: $chatRef · Lead: $leadRef',
        'Chat ref: $chatRef · Lead: $leadRef',
      );
    }
    return t('อ้างอิงแชท: $chatRef', 'Chat ref: $chatRef');
  }
  String get eContractPolicy => t(
        'การกดยอมรับถือว่าคุณตกลงโครงสร้างค่าคอมก่อนเริ่มประสานงานลูกค้า '
        'ตามนโยบาย PROPPITER (ตัวกลาง 100%)',
        'Accepting means you agree to the commission structure before coordinating, '
        'per PROPPITER policy (100% intermediary)',
      );

  // ── Lead unavailable ──
  String get unavailableDatesHint => t(
        'ระบุวันที่สัญญาถึงหรือว่างอีกครั้งเมื่อไหร่',
        'Set contract end or when available again',
      );

  // ── Agent tools ──
  String get transferCostTitle => t(
        'คำนวณค่าใช้จ่าย ณ วันโอน (ประมาณการ)',
        'Transfer-day cost estimate',
      );
  String get purchasePriceLabel => t('ราคาซื้อขาย (บาท)', 'Sale price (THB)');
  String get mortgageAmountLabel => t('วงเงินกู้ (บาท)', 'Loan amount (THB)');
  String get transferFeePctLabel => t('ค่าโอน (% ของราคา)', 'Transfer fee (% of price)');
  String get stampPctLabel => t('อากรแสตมป์ (% )', 'Stamp duty (% )');
  String get transferFeeLine => t('ค่าโอน', 'Transfer fee');
  String get stampDutyLine => t('อากรแสตมป์', 'Stamp duty');
  String get mortgageRegApprox => t('ค่าจดจำนอง (ประมาณ)', 'Mortgage reg. (approx.)');
  String get otherFeesApprox => t('ค่าอื่นๆ (ประมาณ)', 'Other fees (approx.)');
  String get totalApprox => t('รวมประมาณ', 'Total approx.');
  String downPaymentApprox(String amount) => t('เงินดาวน์ ≈ $amount', 'Down payment ≈ $amount');
  String get agentToolsDisclaimer => t(
        'หมายเหตุ: ตัวเลขเป็นการประมาณการเท่านั้น ไม่ใช่คำแนะนำทางกฎหมาย/ภาษี',
        'Note: estimates only — not legal/tax advice',
      );

  // ── Share extras ──
  String get downloadPhotosFailed => t('ดาวน์โหลดรูปไม่สำเร็จ', 'Photo download failed');
  String sharePhotosText(String code) => t('รูปทรัพย์ $code — PROPPITER', 'Photos $code — PROPPITER');

  // ── Maps extras ──
  String mapListingsCount(int n) => t('$n ทรัพย์', '$n listings');
  String get mapTapToZoom => t('แตะเพื่อซูมเข้า', 'Tap to zoom in');
  String get osmMapFreeNote => t(
        'แผนที่ OpenStreetMap (ไม่ต้องใช้ Google key)',
        'OpenStreetMap (no Google key needed)',
      );

  // ── Search bar / map search ──
  String get searchHintProjects => t(
        'ทำเล | โครงการ | คำอื่นๆ',
        'Area | Project | Keywords',
      );
  String get detectedFilters => t('ตัวกรองที่ตรวจจับได้', 'Detected filters');
  String mapListingCount(int n) => t('แผนที่ · $n ทรัพย์', 'Map · $n listings');

  // ── Compare column ──
  String get compareTypeLabel => t('ประเภท', 'Type');
  String get compareSizeLabel => t('ขนาด', 'Size');
  String get compareBedroomsLabel => t('ห้องนอน', 'Bedrooms');
  String get compareLocationLabel => t('ทำเล', 'Location');
  String get compareViewsLabel => t('เข้าชม', 'Views');
  String get yesShort => t('ได้', 'Yes');

  // ── Admin chat ──
  List<String> get adminQuickReplies => isEnglish
      ? [
          'Hello — PROPPITER team has received your request and will reply here.',
          'Viewing confirmed — staff will call again before the appointment.',
          'Price/owner matters need direct coordination — please share a contact number.',
          'Thank you — ask any follow-up questions in this chat.',
        ]
      : [
          'สวัสดีครับ ทีม PROPPITER รับเรื่องแล้ว จะติดต่อกลับในแชทนี้ครับ',
          'ยืนยันนัดดูแล้วครับ เจ้าหน้าที่จะโทรยืนยันอีกครั้งก่อนถึงวันนัด',
          'เรื่องราคา/เจ้าของ ต้องให้เจ้าหน้าที่ประสานงานโดยตรง — ขอเบอร์ติดต่อที่สะดวกได้ครับ',
          'ขอบคุณครับ หากมีคำถามเพิ่มเติม แจ้งในแชทนี้ได้เลยครับ',
        ];

  String get adminReplyHint => t('พิมพ์คำตอบให้ลูกค้า...', 'Type a reply to the customer...');
  String get adminPendingMeta =>
      t('รอทีมงานตอบ — ลูกค้าเห็นคำตอบในแชทเดิม', 'Awaiting team reply — customer sees replies here');
  String get adminResolvedMeta => t('ตอบแล้ว / ปิดเคส', 'Replied / case closed');
  String get adminViewingFormChip => t('มีฟอร์มนัดดู', 'Viewing form sent');
  String get adminStaffChatChip => t('แชทเจ้าหน้าที่', 'Staff chat');
  String listingCodeShort(String code) => t('รหัส $code', 'Code $code');
  String get chatRoleCustomer => t('ลูกค้า', 'Customer');
  String get chatRoleSystem => t('ระบบ', 'System');
  String get chatRoleTeam => t('ทีมงาน', 'Team');
  String get adminInboxIntro => t(
        '1) กด「รับงาน」ก่อนตอบ · 2) มอบหมายได้ถ้าไม่ว่าง · 3) ปิดเคสเมื่อจบ\n'
        'Bot กรอง FAQ ให้แล้ว — เหลือเฉพาะนัดดู · sensitive · ขอเจ้าหน้าที่ · ถามซ้ำ 2 ครั้ง',
        '1) Claim before replying · 2) Reassign if busy · 3) Close when done\n'
        'FAQ bot filters first — only viewings · sensitive · staff · 2 unclear tries remain',
      );
  String get adminFaqTitle => t('ตั้งค่า FAQ อัตโนมัติ', 'Auto-reply FAQ');
  String get adminFaqIntro => t(
        'แก้ข้อความตอบอัตโนมัติได้ทันที — ไม่ต้อง deploy\n'
        'ปิด switch เพื่อปิด rule ชั่วคราว',
        'Edit auto-replies instantly — no deploy needed\n'
        'Toggle off to disable a rule temporarily',
      );
  String get adminFaqEmpty => t('ยังไม่มี FAQ — รัน migration บน Supabase', 'No FAQ rules yet');
  String get adminFaqEditTitle => t('แก้คำตอบ', 'Edit reply');
  String get adminFaqReplyLabel => t('ข้อความตอบ', 'Reply text');
  String get adminFaqSettings => t('ตั้งค่า FAQ', 'FAQ settings');
  String get adminConsoleTitle =>
      t('ศูนย์แชทแอดมิน (คอม)', 'Admin chat console (desktop)');
  String get adminConsolePickChat => t(
        'เลือกแชทจากรายการซ้ายเพื่อตอบลูกค้า\nEnter ส่งข้อความ · ปุ่มด้านบนปิดเคส',
        'Pick a chat from the inbox to reply\nEnter to send · use Close case when done',
      );
  String get adminOpenConsole =>
      t('เปิดโหมดคอม', 'Open desktop console');
  String get adminTabDashboard => t('แดชบอร์ด', 'Dashboard');
  String get adminDashboardBarTitle =>
      t('ภาพรวมแพลตฟอร์ม', 'Platform overview');
  String get adminViewConsumerApp =>
      t('ดูแอpลูกค้า', 'View consumer app');
  String get adminPreviewBanner =>
      t('โหมดดูแอpลูกค้า (แอดมิน)', 'Consumer preview (admin)');
  String get adminBackToConsole => t('กลับหลังบ้าน', 'Back to admin');
  String get adminDashProjects => t('โครงการ', 'Projects');
  String get adminDashListings => t('ประกาศเผยแพร่', 'Published');
  String adminDashListingsSub(int total) =>
      t('ทั้งหมด $total', 'Total $total');
  String get adminDashLeads => t('Lead ใหม่', 'New leads');
  String adminDashLeadsSub(int total) => t('รวม $total', 'Total $total');
  String get adminDashChat => t('แชทรอตอบ', 'Pending chat');
  String get adminDashAppointments => t('นัดชม', 'Viewings');
  String get adminDashOffers => t('ข้อเสนอรอ', 'Pending offers');
  String get adminDashModeration => t('Moderation', 'Moderation');
  String adminDashModerationSub(int images, int flags) =>
      t('รูป $images · flag $flags', 'Photos $images · flags $flags');
  String get adminDashImports => t('นำเข้ารอ', 'Pending imports');
  String adminDashNeedsAction(int n) => t('ต้องทำ $n', '$n need action');
  String get adminDashSectionOps => t('งานประจำวัน', 'Daily operations');
  String get adminDashSectionCatalog => t('ข้อมูลหลัก', 'Catalog');
  String get adminDashSectionTrust => t('ความน่าเชื่อถือ', 'Trust & safety');
  String get adminDashSectionTrend => t('แนวโน้ม 7 วัน', '7-day trend');
  String get adminDashDemandPosts => t('บอร์ดเปิด', 'Open board posts');
  String get adminDashModImages => t('รูปรอตรวจ', 'Photos pending');
  String get adminDashModFlags => t('Flags เปิด', 'Open flags');
  String get adminDashUsers => t('ผู้ใช้ทั้งหมด', 'All users');
  String get adminDashOpenTab => t('เปิดแท็บ →', 'Open tab →');
  String adminDashUpdated(String time) => t('อัปเดต $time', 'Updated $time');
  String adminDashTrendLine(String date, int leads, int appts) =>
      t('$date · Lead $leads · นัด $appts', '$date · leads $leads · viewings $appts');
  String get adminConsoleInboxHint => t(
        'Inbox — เฉพาะเคสที่ต้องคน',
        'Inbox — human-needed cases only',
      );
  String get adminSendReply => t('ส่ง', 'Send');
  String get adminImportTitle => t('นำเข้าทรัพย์ LI', 'Import LI listings');
  String get adminTabImport => t('นำเข้า', 'Import');
  String get adminTabInventory => t('ทะเบียนทรัพย์', 'Inventory');
  String get adminTabProjects => t('โครงการ', 'Projects');
  String get adminProjectsIntro => t(
        'สมุดชื่อโครงการ — ดึงจาก Property Hub เว็บเดียว (ชื่อ · เขต · แผนที่ · BTS · สิ่งอำนวยความสะดวก)\n'
        'ใช้ตอนลงประกาศให้พิมพ์ชื่อแล้วเจอ',
        'Project registry — Property Hub only (name, district, map, BTS, facilities)\n'
        'Used when posting listings',
      );
  String get adminProjectsNeedSupabase => t(
        'บันทึกลง Cloud ต้องเชื่อม Supabase แล้วรัน deploy project-import-propertyhub',
        'Saving to cloud requires Supabase + project-import-propertyhub deployed',
      );
  String get adminProjectsImportTitle =>
      t('ดึงโครงการทีละลิงก์ (Property Hub)', 'Import one Property Hub link');
  String get adminProjectsImportUrlLabel =>
      t('ลิงก์หน้าโครงการ Property Hub', 'Property Hub project URL');
  String get adminProjectsImportUrlHintAny => t(
        'https://propertyhub.in.th/projects/ชื่อโครงการ',
        'https://propertyhub.in.th/projects/project-slug',
      );
  String get adminProjectsPropertyHubOnly => t(
        'รองรับเฉพาะลิงก์ propertyhub.in.th/projects/...',
        'Only propertyhub.in.th/projects/... links are supported',
      );
  String get adminProjectsBulkTitle =>
      t('เติมสมุดโครงการจาก Property Hub', 'Fill catalog from Property Hub');
  String get adminProjectsBulkHint => t(
        'กดปุ่มใหญ่ — ดึงรายละเอียดทีละชุด (รอจนจบ)\n'
        'สำหรับหลายพันโครงการ: รัน scripts/sync-propertyhub-cloud.sh บน Mac (ค้นหาชื่อแบบเต็ม)',
        'Main button imports in batches. For thousands of projects, run scripts/sync-propertyhub-cloud.sh on Mac',
      );
  String get adminProjectsSyncAllBtn =>
      t('ดึงทั้งหมดจาก Property Hub', 'Sync all from Property Hub');
  String get adminProjectsDiscoverBtn => t('ค้นหารายชื่ออย่างเดียว', 'Find names only');
  String get adminProjectsBulkImportBtn =>
      t('ดึงรายละเอียด (หลังค้นหาแล้ว)', 'Import details (after find)');
  String get adminProjectsDiscoverFirst => t('กด「ค้นหารายชื่อ」ก่อน', 'Tap “Find names” first');
  String get adminProjectsDiscovering => t('กำลังค้นหารายชื่อจาก Property Hub…', 'Finding names on Property Hub…');
  String adminProjectsDiscovered(int n) =>
      t('พบ $n โครงการ — กด「ดึงรายละเอียด」หรือ「ดึงทั้งหมด」', 'Found $n — tap import or sync all');
  String get adminProjectsImportingBatch => t('กำลังดึงและบันทึก…', 'Importing and saving…');
  String adminProjectsBatchProgress(int done, int total, int ok, int fail) =>
      t('ดึงแล้ว $done/$total · สำเร็จ $ok · ล้มเหลว $fail', 'Imported $done/$total · ok $ok · fail $fail');
  String adminProjectsBatchDone(int ok, int fail) =>
      t('เสร็จแล้ว — สำเร็จ $ok · ล้มเหลว $fail', 'Done — ok $ok · fail $fail');
  String get adminProjectsImportUrlHint => t(
        'https://propertyhub.in.th/projects/...',
        'https://propertyhub.in.th/projects/...',
      );
  String get adminProjectsImportBtn => t('ดึงและบันทึกโครงการ', 'Fetch & save project');
  String get adminProjectsNeedUrl => t('ใส่ลิงก์ก่อน', 'Enter a URL first');
  String adminProjectsImportCreated(String name) =>
      t('เพิ่มโครงการ: $name', 'Added project: $name');
  String adminProjectsImportUpdated(String name) =>
      t('อัปเดตโครงการ: $name', 'Updated project: $name');
  String get adminProjectsSearchHint => t('ค้นหาชื่อ / เขต / slug', 'Search name / district / slug');
  String get adminProjectsShowInactive => t('รวมปิดใช้', 'Include inactive');
  String adminProjectsCount(int shown, int total) =>
      t('แสดง $shown จาก $total โครงการ', 'Showing $shown of $total projects');
  String get adminProjectsEmpty => t('ยังไม่มีโครงการ', 'No projects yet');
  String get adminProjectsAdd => t('เพิ่มโครงการ', 'Add project');
  String get adminProjectsEdit => t('แก้ไขโครงการ', 'Edit project');
  String get adminProjectsSaved => t('บันทึกโครงการแล้ว', 'Project saved');
  String get adminProjectsNameRequired => t('กรอกชื่อไทยและอังกฤษ', 'Enter Thai and English names');
  String get adminProjectsCoordsInvalid => t('พิกัด Lat/Lng ไม่ถูกต้อง', 'Invalid Lat/Lng');
  String get adminProjectsNameTh => t('ชื่อโครงการ (ไทย)', 'Project name (Thai)');
  String get adminProjectsNameEn => t('ชื่อโครงการ (EN)', 'Project name (EN)');
  String get adminProjectsSlug => t('Slug (URL)', 'Slug (URL id)');
  String get adminProjectsSlugHint => t('ว่างไว้ = สร้างอัตโนมัติ', 'Leave blank to auto-generate');
  String get adminProjectsBts => t('BTS / MRT ใกล้เคียง', 'Nearby BTS / MRT');
  String get adminProjectsAliases => t('ชื่ออื่น (คั่นด้วย ,)', 'Aliases (comma-separated)');
  String get adminProjectsDesc => t('รายละเอียดโครงการ', 'Project description');
  String get adminProjectsActivate => t('เปิดใช้', 'Activate');
  String get adminProjectsDeactivate => t('ปิดใช้', 'Deactivate');
  String get adminImportIntro => t(
        'วางลิงก์ Living Insider → ระบบดึงข้อมูล + รูป → สร้าง draft\n'
        'Admin ตรวจแล้วกดอนุมัติ — เบอร์/Line ถูกตัดออกอัตโนมัติ',
        'Paste Living Insider links → auto-fetch data + photos → draft\n'
        'Review and approve — phone/Line stripped automatically',
      );
  String get adminImportPaste => t('วางจากคลิปบอร์ด', 'Paste clipboard');
  String get adminImportFetchAll => t('ดึงข้อมูลทั้งหมด', 'Fetch all');
  String get adminImportNeedUrl => t('ใส่ลิงก์อย่างน้อย 1 รายการ', 'Add at least one link');
  String adminImportBatchDone(int ok, int fail) => t(
        'ดึงสำเร็จ $ok · ล้มเหลว $fail',
        'Fetched $ok · failed $fail',
      );
  String get adminImportSlotsTitle => t('ช่องวางลิงก์', 'Link slots');
  String adminImportUrlHint(int n) => t('ลิงก์ LI #$n', 'LI link #$n');
  String get adminImportBulkLabel => t('วางหลายลิงก์ (บรรทัดละ 1)', 'Bulk paste (one per line)');
  String get adminImportBulkHint =>
      t('https://www.livinginsider.com/istockdetail/...', 'https://www.livinginsider.com/istockdetail/...');
  String adminImportQueueTitle(int n) => t('คิวนำเข้า ($n)', 'Import queue ($n)');
  String get adminImportShowArchived => t('แสดงจัดเก็บ', 'Show archived');
  String get adminImportEmpty => t(
        'ยังไม่มีรายการ — วางลิงก์ด้านบนแล้วกดดึงข้อมูล',
        'No imports yet — paste links above and fetch',
      );
  String get adminImportApprove => t('อนุมัติเผยแพร่', 'Approve & publish');
  String get adminImportRetry => t('ลองใหม่', 'Retry');
  String get adminImportArchive => t('จัดเก็บ', 'Archive');
  String get adminImportApproved => t('อนุมัติและเผยแพร่แล้ว', 'Approved and published');
  String adminImportImages(int n) => t('$n รูป', '$n photos');
  String adminImportStatus(String status) {
    switch (status) {
      case 'queued':
        return t('รอคิว', 'Queued');
      case 'fetching':
        return t('กำลังดึง', 'Fetching');
      case 'draft_ready':
        return t('รออนุมัติ', 'Ready');
      case 'needs_fix':
        return t('ต้องตรวจ', 'Needs review');
      case 'approved':
        return t('เผยแพร่แล้ว', 'Published');
      case 'archived':
        return t('จัดเก็บ', 'Archived');
      case 'failed':
        return t('ล้มเหลว', 'Failed');
      default:
        return status;
    }
  }
  String adminPendingCount(int n) => t('รอตอบ ($n)', 'Pending ($n)');
  String get adminInboxEmpty => t(
        'ไม่มีแชทรอตอบ — ลูกค้าพิมพ์คำถามละเอียดหรือกด「คุยกับเจ้าหน้าที่」จะขึ้นที่นี่',
        'No pending chats — detailed questions or「Chat with staff」appear here',
      );
  String get adminResolvedSection => t('ตอบแล้ว / ปิดแล้ว', 'Replied / closed');
  String get adminInboxViewing => t('นัดดูห้อง', 'Viewing request');
  String get adminInboxNeedsStaff => t('ต้องเจ้าหน้าที่', 'Needs staff');
  String get adminInboxPropertyChat => t('แชททรัพย์', 'Property chat');
  String get adminInboxDemandOffer => t('เสนอทรัพย์', 'Submit listing');
  String get adminPriorityHigh => t('ด่วน', 'Urgent');
  String get adminViewingFormSubmitted => t('ส่งฟอร์มนัดแล้ว', 'Viewing form sent');
  String get adminAwaitingReply => t('รอตอบ', 'Pending');
  String adminInboxTabUnclaimed(int n) => t('รอรับงาน ($n)', 'Unclaimed ($n)');
  String adminInboxTabMine(int n) => t('งานของฉัน ($n)', 'Mine ($n)');
  String adminInboxTabResolved(int n) => t('ปิดแล้ว ($n)', 'Closed ($n)');
  String get adminInboxEmptyUnclaimed => t(
        'ไม่มีแชทรอรับงาน — เคสใหม่จะแจ้ง「แชทรอรับงาน」',
        'No unclaimed chats — new cases notify as「Chat awaiting claim」',
      );
  String get adminInboxEmptyMine => t(
        'ยังไม่มีงานของคุณ — กด「รับงาน」จากแท็บรอรับงาน',
        'Nothing assigned to you — claim from the Unclaimed tab',
      );
  String get adminInboxEmptyResolved => t(
        'ยังไม่มีเคสปิด — กด「ปิดเคส」หลังตอบลูกค้า',
        'No closed cases yet — tap「Close case」after replying',
      );
  String get adminClaimWork => t('รับงาน', 'Claim');
  String get adminAssignWork => t('มอบหมาย', 'Assign');
  String get adminAssignTo => t('มอบหมายให้', 'Assign to');
  String adminClaimedBy(String name) => t('ดูแล: $name', 'Owner: $name');
  String get adminNeedsClaim => t('ยังไม่รับ', 'Unclaimed');
  String get adminMustClaimFirst => t(
        'กด「รับงาน」ก่อนตอบลูกค้า',
        'Tap「Claim」before replying',
      );
  String get adminClaimedByOther => t(
        'มีคนรับงานแล้ว — ใช้「มอบหมาย」ถ้าต้องส่งต่อ',
        'Already claimed — use「Assign」to hand off',
      );
  String get adminClaimSuccess => t('รับงานแล้ว', 'Claimed');
  String get adminAssignSuccess => t('มอบหมายแล้ว', 'Assigned');
  String notifyChatUnclaimed(String code) =>
      t('แชทรอรับงาน — $code', 'Chat awaiting claim — $code');
  String notifyChatMine(String code) =>
      t('งานของคุณ — $code', 'Your assignment — $code');
  String notifyChatClaimed(String name, String code) =>
      t('$name รับงาน $code แล้ว', '$name claimed $code');
  String notifyChatSlaUnclaimed(String code, int minutes) =>
      t('⚠️ ยังไม่มีคนรับ — $code · รอ $minutes นาที', '⚠️ Unclaimed — $code · $minutes min');
  String notifyChatSlaOverdue(String code, int minutes, String who) =>
      t('⚠️ แชทค้าง — $code · $minutes นาที · $who', '⚠️ Overdue — $code · $minutes min · $who');
  String adminLifecycleResult(String result) => t('Lifecycle: $result', 'Lifecycle: $result');
  String get adminLifecycleSubtitle => t(
        'หมดอายุ / ซ่อนประกาศที่ไม่ bump 30 วัน — ตั้ง Cron เรียก listing-lifecycle-cron รายวัน',
        'Expire / hide listings not bumped in 30 days — schedule listing-lifecycle-cron daily',
      );
  String adminPhotosPending(int n) => t('รูปรอตรวจ ($n)', 'Photos pending ($n)');
  String adminFlagsSection(int n) => t('Flags ($n)', 'Flags ($n)');
  String get adminResolveFlag => t('ปิด flag', 'Resolve flag');
  String get adminHideListing => t('ซ่อนประกาศ', 'Hide listing');
  String get adminDefaultProperty => t('ทรัพย์', 'Property');
  String get adminConfirmViewingTitle => t('ยืนยันนัดดูทรัพย์', 'Confirm property viewing');
  String get adminTimeSlotLabel => t('ช่วงเวลา', 'Time slot');
  String get adminNotesLabel => t('หมายเหตุแอดมิน', 'Admin notes');
  String get adminViewingSavedSnack =>
      t('บันทึกนัดชมแล้ว — ดูในแท็บนัดชม', 'Viewing saved — see Appointments tab');
  String get adminViewingRequestField => t('คำขอนัดดู', 'Viewing request');
  String get adminApproxZone => t('โซนทรัพย์ (โดยประมาณ)', 'Property zone (approx.)');
  List<String> get adminTimeSlots => isEnglish
      ? ['09:00 – 12:00', '12:00 – 15:00', '15:00 – 18:00', '18:00 – 20:00']
      : ['09:00 – 12:00 น.', '12:00 – 15:00 น.', '15:00 – 18:00 น.', '18:00 – 20:00 น.'];
  String get adminManageAppointments => t('จัดการนัดชม', 'Manage viewings');
  String get adminHideMap => t('ซ่อนแผนที่', 'Hide map');
  String get adminShowMap => t('แสดงแผนที่', 'Show map');
  String get adminAppointmentsEmpty => t(
        'ยังไม่มีนัดชม — เปิด Lead แล้วกด「ประสานงาน / ยืนยันนัดดู」',
        'No viewings yet — open a Lead and tap「Coordinate / confirm viewing」',
      );
  String get adminConfirmAppointment => t('ยืนยัน', 'Confirm');
  String get adminCompleteAppointment => t('เสร็จสิ้น', 'Complete');
  String get adminNeedRole => t(
        'ต้องมี role = admin ใน Supabase profiles\n(ตั้งใน Table Editor หรือ SQL)',
        'Requires role = admin in Supabase profiles\n(Set in Table Editor or SQL)',
      );
  String get adminTabChat => t('แชท', 'Chat');
  String get adminTabOffers => t('ข้อเสนอ', 'Offers');
  String get adminTabLeads => t('Leads', 'Leads');
  String get adminTabAppointments => t('นัดชม', 'Viewings');
  String get adminTabReports => t('รายงาน', 'Reports');
  String get adminTabModeration => t('Moderation', 'Moderation');
  String get adminTabCreateBoard => t('สร้างบอร์ด', 'Create board');
  String get adminTrialBannerConfigured => t(
        'โหมดทดลอง — แชท/Lead ตัวอย่าง · ตั้ง TRIAL_MODE=false เมื่อเปิดใช้จริง',
        'Trial — sample chat/leads · set TRIAL_MODE=false for production',
      );
  String get adminNoOffers => t('ยังไม่มีข้อเสนอ', 'No offers yet');
  String get adminNoLeads => t('ยังไม่มี Lead', 'No leads yet');
  String get adminMustLoginReal => t(
        'ต้องล็อกอินจริง (อีเมล+รหัส) — โหมดทดลองไม่ sync กับมือถือ',
        'Log in with email/password — trial mode does not sync across devices',
      );
  String get adminRecentLeadsTitle =>
      t('Lead / นัดดู ล่าสุด', 'Recent leads / viewings');
  String get adminViewAllLeads => t('ดูทั้งหมด', 'View all');
  String get adminReject => t('ปฏิเสธ', 'Reject');
  String adminViewingPrefix(String v) => t('นัด: $v', 'Viewing: $v');
  String adminLeadStatsLine(int leads, int accepted) =>
      t('Leads: $leads · รับแล้ว: $accepted', 'Leads: $leads · accepted: $accepted');
  String get adminCreateBoardIntro => t(
        'บอร์ดประกาศจาก PROPPITER\n(ผู้ใช้จะไม่เห็นข้อเสนอของกัน)',
        'PROPPITER board posts\n(Users cannot see each other\'s offers)',
      );
  String get adminMaxPriceLabel => t('งบสูงสุด (บาท)', 'Max budget (THB)');
  String get adminMinAreaLabel => t('ตร.ม. ขั้นต่ำ', 'Min sqm');
  String get adminBtsDistanceLabel => t('ห่าง BTS (กม.)', 'Distance to BTS (km)');
  String get adminCreateBoardHint =>
      t('หาคอนโดย่านทองหล่อ BTS ≤1.5km ...', 'Condo Thonglor BTS ≤1.5km ...');
  String get adminBoardCreated => t('สร้างประกาศบอร์ดแล้ว', 'Board post created');
  String get adminReportsTitle => t('รายงาน & Make.com', 'Reports & Make.com');
  String get adminReportsConfigured =>
      t('ดึงจาก view platform_stats_daily (ไม่มีเบอร์โทร)', 'From platform_stats_daily view (no phone numbers)');
  String get adminReportsDemo => t('โหมด Demo — ตัวเลขตัวอย่าง', 'Demo mode — sample numbers');
  String get adminDailyStats => t('สถิติรายวัน', 'Daily stats');
  String get adminMakecomSetup => t('ตั้งค่า Make.com', 'Make.com setup');
  String get adminMakecomInstructions => t(
        '1. Schedule ทุก 1 ชม.\n'
        '2. HTTP → Supabase REST\n'
        '   /rest/v1/platform_stats_daily?order=stat_date.desc&limit=7\n'
        '3. Google Sheets → Append row\n\n'
        'Webhook (ทางเลือก): ตั้ง MAKECOM_WEBHOOK_URL ใน Edge Functions\n'
        '→ รับ event lead_routed / appointment_scheduled\n\n'
        'ดู docs/MAKECOM.md และ docs/phase-7-reporting-push.md',
        '1. Schedule every hour\n'
        '2. HTTP → Supabase REST\n'
        '   /rest/v1/platform_stats_daily?order=stat_date.desc&limit=7\n'
        '3. Google Sheets → Append row\n\n'
        'Webhook (optional): set MAKECOM_WEBHOOK_URL in Edge Functions\n'
        '→ receives lead_routed / appointment_scheduled\n\n'
        'See docs/MAKECOM.md and docs/phase-7-reporting-push.md',
      );
  String adminStatRowSubtitle(int leads, int accepted, int appts, int confirmed) => t(
        'Lead $leads (รับ $accepted) · นัดชม $appts (ยืนยัน $confirmed)',
        'Leads $leads (accepted $accepted) · viewings $appts (confirmed $confirmed)',
      );

  // ── Property chat ──
  List<String> get propertyChatQuickReplies => isEnglish
      ? [
          'Interested — please share more details',
          'When can I view the unit?',
          'Does the price include common fees?',
          'Is parking available?',
        ]
      : [
          'สนใจทรัพย์นี้ ขอรายละเอียดเพิ่ม',
          'ขอดูห้องได้เมื่อไหร่',
          'ราคานี้รวมค่าส่วนกลางแล้วหรือยัง',
          'มีที่จอดรถไหม',
        ];

  String get chatStaffTitle => t('เจ้าหน้าที่', 'Staff');
  String get chatDiscoveryTitle => t('ค้นหาทรัพย์', 'Find properties');
  String get chatPropertyTitle => t('PROPPITER', 'PROPPITER');
  String get chatAiTitle => chatPropertyTitle;

  String get adminInboxDiscovery => t('ค้นหาทรัพย์', 'Discovery');
  String get chatStaffEscalated => t(
        'ทีมงานได้รับแจ้งแล้ว — จะตอบในแชทนี้โดยเร็วที่สุด',
        'Team notified — will reply in this chat ASAP',
      );
  String get chatHintThai => t('พิมพ์คำถาม...', 'Type your question...');
  String get chatHintEnglish => t('Type in English...', 'Type in English...');
  String get chatViewingSubmitted => t('ส่งคำขอนัดดูแล้ว', 'Viewing request sent');
  String get chatTeamLivingBkk => t('ทีมงาน PROPPITER', 'PROPPITER team');
  String get chatSelectListingFirst => t(
        'เลือกทรัพย์จากหน้าค้นหาก่อน แล้วกดสอบถาม / แชท AI',
        'Pick a listing from search first, then tap inquire / AI chat',
      );
  String get viewingSubmittedBadge => t('นัดดูแล้ว', 'Viewing sent');

  // ── Work page ──
  String get workDemoMode => t('โหมด Demo', 'Demo mode');
  String get workDemoHint => t(
        'สลับโปรไฟล์เป็น เจ้าของ/นายหน้า แล้วเปิด Lead ในกล่องมอบหมาย',
        'Switch profile to owner/broker and open leads in the assigned inbox',
      );
  String get workLeadInbox => t('กล่อง Lead (มอบหมาย)', 'Lead inbox (assigned)');
  String get workNoLeadsInbox => t(
        'ยังไม่มี Lead — ลูกค้าส่งคำขอจากแชท/นัดดูจะปรากฏที่นี่',
        'No leads yet — customer chat/viewing requests appear here',
      );
  String get workNoRequests => t('ยังไม่มีคำขอที่ส่ง', 'No submitted requests yet');
  String get workCoAgentRequests => t('คำขอโคนายหน้า', 'Co-broker requests');
  String get workNoCoAgentRequests => t('ยังไม่มีคำขอโคนายหน้า', 'No co-broker requests yet');
  String get workBoardOffers => t('ข้อเสนอบอร์ด', 'Board offers');
  String get workNoBoardOffers => t('ยังไม่มีข้อเสนอบนบอร์ด', 'No board offers yet');
  String statusPrefix(String status) => t('สถานะ: $status', 'Status: $status');
  String get reloadTooltip => t('โหลดใหม่', 'Reload');
  String get budgetRangeLabelMonthly => t('งบประมาณ (บาท/เดือน)', 'Budget (THB/month)');
  String get priceSuffixRentShort => t('/ด', '/mo');

  // ── Filter preview labels (NLP) ──
  String get filterLabelProject => t('โครงการ', 'Project');
  String get filterLabelInvestor => t('นักลงทุน', 'Investor');
  String get filterLabelYield => t('Yield', 'Yield');
  String get filterLabelCoAgent => t('โคนายหน้า', 'Co-broker');
  String get filterLabelPetsAllowed => t('อนุญาต', 'Allowed');

  String filterPreviewLabel(String label) {
    switch (label) {
      case 'ทำเล':
      case 'Location':
        return locationLabel;
      case 'งบ':
      case 'Budget':
        return budgetLabel;
      case 'สัตว์เลี้ยง':
      case 'Pets':
        return petsLabel;
      case 'โครงการ':
      case 'Project':
        return filterLabelProject;
      case 'โคนายหน้า':
      case 'Co-broker':
        return filterLabelCoAgent;
      case 'นักลงทุน':
      case 'Investor':
        return filterLabelInvestor;
      case 'Yield':
        return filterLabelYield;
      default:
        return label;
    }
  }

  String filtersSummary(SearchFilters f) {
    final parts = <String>[];
    if (f.listingType == 'rent') parts.add(rent);
    if (f.listingType == 'sale') parts.add(sale);
    if (f.listingType == 'sale_installment') parts.add(listingTypeSaleInstallment);
    if (f.propertyType != null) parts.add(f.propertyType!);
    if (f.maxPrice != null) parts.add('≤${f.maxPrice!.toInt()}');
    if (f.geoZoneSlugs != null && f.geoZoneSlugs!.isNotEmpty) {
      parts.add(f.geoZoneSlugs!.join(', '));
    }
    if (f.coAgentEligibleOnly == true) parts.add(filterLabelCoAgent);
    return parts.isEmpty ? allCategories : parts.join(' · ');
  }

  // ── Chat AI / system copy ──
  String get chatAiDisclaimer => t(
        'AI เป็นตัวช่วยแนะนำโครงการและทรัพย์เบื้องต้นเท่านั้น '
        'หากต้องการรายละเอียดที่ครบถ้วน กรุณาติดต่อเจ้าหน้าที่โดยตรง',
        'AI suggests projects and listings only. '
        'For full details please contact our staff directly.',
      );

  String get chatDiscoveryRoomTitle =>
      t('PROPPITER — ค้นหาทรัพย์', 'PROPPITER — Property search');

  String get chatStaffRoomTitle =>
      t('เจ้าหน้าที่ PROPPITER', 'PROPPITER staff');

  String get chatDemandOfferRoomTitle => t('เสนอทรัพย์', 'Submit listing');
  String get chatDemandOfferWelcome => t(
        'แชทหมวด「เสนอทรัพย์」 — ส่งข้อเสนอตรงความต้องการบนบอร์ดได้ที่นี่\n'
        'ทีม PROPPITER จะตรวจสอบและติดต่อกลับในแชทนี้',
        'Submit listing chat — send offers matching board requests here.\n'
        'PROPPITER team will review and follow up in this chat.',
      );
  String chatDemandOfferUserSent(String postCode) =>
      t('ส่งข้อเสนอทรัพย์ ($postCode)', 'Submitted listing offer ($postCode)');
  String get chatDemandOfferStaffAck => t(
        'เจ้าหน้าที่จะตรวจสอบข้อเสนอและแจ้งผลในแชทนี้ครับ',
        'Our team will review your offer and reply in this chat.',
      );

  String get chatRequirementRoomTitle =>
      t('ความต้องการหาทรัพย์', 'Property search request');
  String get chatRequirementWelcome => t(
        'แชทส่งความต้องการหาทรัพย์ — ทีม PROPPITER จะช่วยหาทรัพย์ที่ตรงเงื่อนไข\n'
        'และติดต่อกลับในแชทนี้',
        'Property need chat — PROPPITER team will find matches\n'
        'and follow up in this chat.',
      );
  String chatRequirementUserSent(String title) =>
      t('ส่งความต้องการ: $title', 'Submitted need: $title');
  String get chatRequirementReceived => t(
        'รับความต้องการแล้ว — ทีมงานกำลังตรวจสอบ',
        'Requirement received — our team is reviewing it.',
      );
  String get chatRequirementSummaryHeader =>
      t('สรุปความต้องการ', 'Requirement summary');
  String get chatRequirementStaffAck => t(
        'ทีมงานจะช่วยหาทรัพย์ที่ตรงเงื่อนไขและตอบกลับในแชทนี้ครับ',
        'Our team will find matching listings and reply in this chat.',
      );

  String chatDiscoveryWelcome() => t(
        'สวัสดีครับ ผมผู้ช่วย PROPPITER\n'
        '$chatAiDisclaimer\n\n'
        'บอกทำเล · โครงการ · งบประมาณ — ผมช่วยคัดทรัพย์ในระบบให้\n'
        'ตัวอย่าง: 「หาคอนโดเช่า ทองหล่อ งบ 18,000」',
        'Hello, I\'m the PROPPITER assistant.\n'
        '$chatAiDisclaimer\n\n'
        'Tell me area, project & budget — I\'ll match listings for you.\n'
        'e.g. "Condo rent Thonglor budget 18,000"',
      );

  String chatStaffWelcome() => t(
        'สวัสดีครับ ทีม PROPPITER พร้อมช่วยเหลือ\n'
        'พิมพ์คำถามได้เลย เราจะตอบกลับในแชทนี้โดยเร็วที่สุด',
        'Hello, the PROPPITER team is here to help.\n'
        'Type your question — we\'ll reply in this chat ASAP.',
      );

  String chatPropertyWelcome(String listingTitle, {required bool allowViewing}) =>
      allowViewing
          ? t(
              'สวัสดีครับ ผมผู้ช่วย PROPPITER สำหรับ $listingTitle\n'
              '$chatAiDisclaimer\n\n'
              'ถามรายละเอียดทรัพย์นี้ได้เลย — ถามหาทรัพย์อื่น/ทำเล/งบก็ได้ในแชทนี้\n'
              'หากต้องการนัดดูห้อง กด「ขอนัดดูห้อง」ด้านล่างเมื่อพร้อมครับ',
              'Hello, PROPPITER assistant for $listingTitle.\n'
              '$chatAiDisclaimer\n\n'
              'Ask about this listing — or other areas/budgets in this chat.\n'
              'Tap「Request viewing」below when ready to book a visit.',
            )
          : t(
              'สวัสดีครับ ผมผู้ช่วย PROPPITER สำหรับ $listingTitle\n'
              '$chatAiDisclaimer\n\n'
              'ถามเรื่องทำเล ราคา เงื่อนไข หรือให้แนะนำทรัพย์อื่นในระบบได้เลยครับ',
              'Hello, PROPPITER assistant for $listingTitle.\n'
              '$chatAiDisclaimer\n\n'
              'Ask about location, price, terms, or other listings in our system.',
            );

  String get chatEscalateToStaff => t(
        'คำถามนี้ต้องให้เจ้าหน้าที่ตอบโดยตรง — เราแจ้งทีมแล้ว และจะติดต่อกลับในแชทนี้โดยเร็วที่สุด',
        'This needs a staff reply — we\'ve notified the team and will follow up here ASAP.',
      );

  String get chatStaffAck => t(
        'รับข้อความแล้วครับ ทีมงานจะตอบกลับในแชทนี้โดยเร็วที่สุด',
        'Message received — our team will reply in this chat ASAP.',
      );

  String get chatViewingReceived => t(
        'ระบบได้รับคำขอของคุณแล้ว\n'
        'ทีมงานจะติดต่อกลับหาคุณโดยเร็วที่สุด บางกรณีอาจเป็นการโทรติดต่อกลับ',
        'Your request was received.\n'
        'Our team will contact you soon — sometimes by phone.',
      );

  String get chatDuplicatePhoneAlert => t(
        '⚠️ แจ้งทีมงาน: พบ 4 ตัวท้ายเบอร์ลูกค้าซ้ำในระบบ — รอตรวจสอบ',
        '⚠️ Team alert: duplicate customer phone suffix — pending review',
      );

  String get chatCustomerSummaryHeader =>
      t('สรุปโปรไฟล์ลูกค้า', 'Customer profile summary');

  String chatViewingDetailAck(String viewing) => t(
        'รายละเอียดนัดดู: $viewing\n'
        'เจ้าหน้าที่จะยืนยันนัดและประสานงานให้ครับ',
        'Viewing details: $viewing\n'
        'Staff will confirm and coordinate the appointment.',
      );

  String get chatNoMatches => t(
        'ยังไม่พบทรัพย์ที่ตรงบรีฟชัดเจนครับ '
        'ลองระบุทำเล โครงการ หรืองบประมาณเพิ่มเติม\n'
        'หรือกด「คุยกับเจ้าหน้าที่」เพื่อให้ทีมช่วยคัดให้',
        'No clear matches yet. Try adding area, project, or budget.\n'
        'Or tap「Chat with staff」for a curated shortlist.',
      );

  String chatMatchesFound(String names) => t(
        'พบทรัพย์ที่ใกล้เคียงบรีฟของคุณ:\n$names\n'
        'กดลิงก์ด้านล่างเพื่อดูประกาศ หรือห้องอื่นในโครงการ',
        'Listings matching your brief:\n$names\n'
        'Tap links below for details or other units in the project.',
      );

  String chatAiPriceReply(String listingCode) => t(
        'ราคาที่แสดงเป็นราคา Net สำหรับผู้เช่า/ผู้ซื้อแล้วครับ '
        'สำหรับ $listingCode หากต้องการรายละเอียดครบถ้วน '
        'กรุณาติดต่อเจ้าหน้าที่โดยตรง',
        'The price shown is net for tenants/buyers. '
        'For $listingCode, contact staff for full details.',
      );

  String get chatAiPetReply => t(
        'เงื่อนไขสัตว์เลี้ยงขึ้นกับแต่ละห้องครับ เจ้าหน้าที่จะยืนยันให้เมื่อติดต่อกลับ',
        'Pet policy varies by unit — staff will confirm when they follow up.',
      );

  String get chatAiParkingReply => t(
        'ที่จอดรถและค่าใช้จ่ายเพิ่มเติม เจ้าหน้าที่จะยืนยันให้เมื่อติดต่อกลับครับ',
        'Parking and extra fees — staff will confirm when they follow up.',
      );

  String get chatAiLocationReply => t(
        'ทำเลแสดงแบบโซนโดยประมาณบนแผนที่ (ไม่เปิดเผยเลขห้อง) '
        'หากต้องการรายละเอียดเพิ่ม ติดต่อเจ้าหน้าที่ได้ครับ',
        'Location is shown as an approximate zone on the map (no unit number). '
        'Contact staff for more detail.',
      );

  String get chatAiGenericAck => t(
        'รับทราบครับ',
        'Noted.',
      );

  String chatAiGenericFallback() => t(
        'รับทราบครับ $chatAiDisclaimer '
        'หากต้องการให้เจ้าหน้าที่ช่วยเพิ่มเติม แจ้งในแชทได้เลยครับ',
        'Noted. $chatAiDisclaimer '
        'Ask here if you need staff to help further.',
      );

  String priceLabelChat(ListingPublic l) {
    if (l.listingType == 'rent') {
      final k = (l.priceNet / 1000).toStringAsFixed(0);
      return isEnglish ? '$k,000/mo' : '$k,000/เดือน';
    }
    if (l.priceNet >= 1000000) {
      final m = (l.priceNet / 1000000).toStringAsFixed(1);
      return isEnglish ? '$m M THB' : '$m ล้าน';
    }
    return isEnglish ? '${l.priceNet.toInt()} THB' : '${l.priceNet.toInt()} บาท';
  }

  String leadStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return t('รอดำเนินการ', 'Pending');
      case 'accepted':
        return t('รับแล้ว', 'Accepted');
      case 'closed':
        return t('ปิดแล้ว', 'Closed');
      case 'confirmed':
        return t('ยืนยันแล้ว', 'Confirmed');
      case 'completed':
        return t('เสร็จสิ้น', 'Completed');
      case 'cancelled':
        return t('ยกเลิก', 'Cancelled');
      case 'waiting_admin':
        return t('รอทีมงาน', 'Awaiting staff');
      case 'open':
        return t('เปิดรับ', 'Open');
      default:
        return status;
    }
  }

  List<String> get facilityLabelsEn => const [
        'Swimming pool',
        'Fitness',
        'Parking',
        '24h security',
        'Lobby',
      ];

  List<String> localizedFacilities(List<String> thFacilities) {
    if (!isEnglish) return thFacilities;
    const map = {
      'สระว่ายน้ำ': 'Swimming pool',
      'ฟิตเนส': 'Fitness',
      'ที่จอดรถ': 'Parking',
      'รปภ. 24 ชม.': '24h security',
      'Lobby': 'Lobby',
      'Sky Lounge': 'Sky Lounge',
      'Co-working': 'Co-working',
      'Sky garden': 'Sky garden',
    };
    return thFacilities.map((f) => map[f] ?? f).toList();
  }
}

enum AppPerspectiveKey { customer, agent, owner }

/// Shorthand: `context.s.navHome`
extension AppStringsContext on BuildContext {
  AppStrings get s => AppStrings.of(this);
}

class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.localeController,
    required super.child,
  });

  final LocaleController localeController;

  AppStrings get strings => AppStrings(localeController.isEnglish);

  @override
  bool updateShouldNotify(AppStringsScope old) =>
      localeController.locale != old.localeController.locale;
}
