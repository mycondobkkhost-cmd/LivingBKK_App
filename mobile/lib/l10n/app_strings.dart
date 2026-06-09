import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/demand_offer_acceptance.dart';
import '../models/listing_public.dart';
import '../models/search_filters.dart';
import '../models/viewing_report.dart';
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
  /// แท็บล่าง — จัดการประกาศ (ไม่ซ้ำแท็บบอร์ด「ประกาศ」)
  String get navMyListings => t('ของฉัน', 'Mine');
  String get createListingFree => t('สร้างประกาศฟรี', 'Create listing free');
  String get authRequiredBeforePost => t(
        'กรุณาเข้าสู่ระบบหรือลงทะเบียนก่อนลงประกาศ',
        'Please log in or register before posting',
      );
  String get postDemandWantedButton =>
      t('ลงประกาศหาทรัพย์', 'Post property wanted');
  String get createListingLoginRequired => t(
        'เข้าสู่ระบบหรือสมัครสมาชิกก่อนสร้างประกาศ',
        'Log in or sign up to create a listing',
      );
  String get myListingsHubEmpty => t(
        'ยังไม่มีประกาศ — กดปุ่มด้านบนเพื่อสร้างประกาศแรกฟรี',
        'No listings yet — tap above to create your first one free',
      );
  String get mineTabSignInTitle => t(
        'เข้าสู่ระบบเพื่อจัดการทรัพย์',
        'Sign in to manage properties',
      );
  String get mineTabSignInBody => t(
        'ทรัพย์ที่แอดมินมอบให้และประกาศของคุณจะแสดงที่นี่\n'
        'ไม่ใช่แค่สลับมุมมอง「เจ้าของ」บนหน้าแรก — ต้องล็อกอินบัญชีเจ้าของ',
        'Assigned properties and your listings appear here.\n'
        'Switching to Owner view on home is not enough — sign in as owner.',
      );
  String get mineTabOwnerTrialButton => t(
        'เข้าเป็นเจ้าของทดลอง · ไม่ต้องรหัส',
        'Enter as trial owner · no password',
      );
  String get mineTabGoLoginButton => t('ไปหน้าเข้าสู่ระบบ', 'Go to login');
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
  String get adminViewportSetting => t('มุมมองการแสดงผล', 'Display view');
  String get adminViewportDesktop => t('เมนูซ้าย (คอม)', 'Sidebar (desktop)');
  String get adminViewportMobile => t('เมนูบน (แอป)', 'Top menu (app)');
  String get adminViewportDesktopHint => t(
        'กำลังใช้: เมนูซ้ายตลอด — เหมาะกับจอคอม',
        'Active: persistent sidebar — for desktop',
      );
  String get adminViewportMobileHint => t(
        'กำลังใช้: เมนู ☰ ด้านบน — เหมือนแอปมือถือ',
        'Active: top ☰ menu — like the phone app',
      );
  String get adminViewportToggleToDesktop =>
      t('สลับเป็นเมนูซ้าย (คอม)', 'Switch to sidebar (desktop)');
  String get adminViewportToggleToMobile =>
      t('สลับเป็นเมนูบน (แอป)', 'Switch to top menu (app)');
  String get adminViewportWebOnlyNote => t(
        'ไอคอนแสดงโหมดที่ใช้อยู่ — แตะเพื่อสลับ',
        'Icon shows the active mode — tap to switch',
      );
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
  String get demandBoardCollectionTitle => t(
        'แหล่งรวบรวมความต้องการหาทรัพย์',
        'Property needs hub',
      );
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
        return t('ลูกค้า RealXtate', 'RealXtate customer');
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
  String get savedDemandBoardManage => t('จัดการ', 'Manage');
  String savedDemandBoardDeleteSelected(int n) =>
      t('ลบที่เลือก ($n)', 'Delete selected ($n)');
  String get savedDemandBoardRemoved =>
      t('ลบออกจากรายการบันทึกแล้ว', 'Removed from saved');
  String savedDemandBoardDeleteConfirm(int n) => t(
        'ลบประกาศที่เลือก $n รายการออกจากรายการบันทึก?',
        'Remove $n saved board posts?',
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
        'สวัสดีครับ ผมช่วยคัดโครงการและทรัพย์ใน RealXtate ให้ได้\n\n'
        'ลองพิมพ์ เช่น:\n'
        '• ช่วยหาห้อง The Line งบ 25,000\n'
        '• คอนโดใกล้ BTS อ่อนนุช\n'
        '• ก้อปปี้รหัสทรัพย์ RENT-CD-…\n\n'
        'หากต้องการคุยแอดมินโดยตรง พิมพ์「ขอคุยกับแอดมิน」'
        ' — อาจรอตามคิวเนื่องจากมีผู้ติดต่อจำนวนมาก',
        'Hi — I can match projects and listings in RealXtate.\n\n'
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
        'สรุปเงื่อนไขที่คุณต้องการ — ทีม RealXtate จะตรวจสอบแล้วนำไปประกาศบนบอร์ด「ประกาศหาทรัพย์」เพื่อให้เจ้าของและนายหน้าเข้ามาเสนอทรัพย์ที่ตรงความต้องการ',
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
  String get requirementSeriousUseTitle =>
      t('ข้อควรทราบก่อนส่งความต้องการ', 'Please read before submitting');
  String get requirementSeriousUseBody => t(
        'RealXtate ช่วยหาทรัพย์ให้คุณโดยไม่คิดค่าบริการ แต่เบื้องหลังทีมงานต้องลงทุนเวลาและทรัพยากรจริงในการคัดหาและประสานงาน '
        'กรุณาส่งเฉพาะเมื่อคุณมีความต้องการหาทรัพย์จริง และให้ข้อมูลตรงตามความเป็นจริง '
        'หากส่งแบบเล่นๆ ไม่มีความต้องการจริง ให้ข้อมูลคลาดเคลื่อน หรือปิดบังเงื่อนไขสำคัญในภายหลัง '
        'เราขอสงวนสิทธิ์ในการระงับการใช้บริการนี้หรือบัญชีของคุณตามนโยบายของแพลตฟอร์ม',
        'RealXtate finds properties for you at no charge, but our team invests real time and resources to search and coordinate. '
        'Please submit only if you genuinely need a property and provide accurate information. '
        'Casual or playful use, misleading details, or withholding important conditions later may result in suspension of this service or your account under our policies.',
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
            'Contact and viewing via RealXtate only';
      case 'zh':
        return '房源$place\n'
            '· 交通便利\n'
            '· 可预约看房 / 可入住\n'
            '请通过 RealXtate 联系与预约看房';
      default:
        return 'ทรัพย์$place\n'
            '· ทำเลดี ใกล้รถไฟฟ้า\n'
            '· พร้อมเข้าอยู่ / นัดชมได้\n'
            'ติดต่อและนัดชมผ่าน RealXtate เท่านั้น';
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
        'จะไม่ปรากฏในประกาศสาธารณะ มีเฉพาะทีมงาน RealXtate ที่ดูแลข้อมูลของคุณและติดต่อคุณเมื่อมีผู้สนใจ',
        'Your listing is visible to other users — private contact details (phone, Line ID, etc.) '
        'are not shown publicly. Only the RealXtate team manages your data and contacts you when there is interest.',
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
      t('ฝาก Exclusive กับ RealXtate', 'Exclusive mandate with RealXtate');
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
        'ฝากกับ RealXtate เท่านั้น',
        'Exclusive to RealXtate only',
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
  String get listingOnlyHereRibbon =>
      t('เฉพาะที่นี่', 'Only Here');
  String get listingExclusiveRibbon =>
      t('EXCLUSIVE', 'EXCLUSIVE');
  String get listingHotLabel => 'HOT';
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
  String get adminHotBadgeSectionTitle =>
      t('ป้าย HOT บนการ์ด', 'HOT badge on cards');
  String get adminHotBadgeSectionHint => t(
        'แสดงป้าย HOT เมื่อประกาศมีผู้ดูเกินเกณฑ์ใน 1 ชั่วโมง',
        'Show HOT when listing views in the last hour exceed the threshold',
      );
  String get adminHotBadgeEnabled =>
      t('เปิดป้าย HOT', 'Enable HOT badge');
  String get adminHotBadgeEnabledHint => t(
        'ปิดเพื่อซ่อนป้าย HOT ทั้งระบบ',
        'Turn off to hide HOT badges app-wide',
      );
  String get adminHotBadgeThreshold =>
      t('เกณฑ์วิว/ชม. (ขั้นต่ำ)', 'Views per hour (min)');

  // Viewing access (create listing)
  String get viewingAccessSectionTitle =>
      t('การนัดดูในอนาคต (ไม่บังคับ)', 'Future viewings (optional)');
  String get viewingAccessSectionIntro => t(
        'ช่วยให้ทีม RealXtate ประสานงานเมื่อมีลูกค้าขอนัดชม — ไม่ต้องใส่รายละเอียดครบทุกช่อง',
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
      case 'showroom':
      case 'business':
      case 'co_working':
      case 'warehouse':
      case 'factory':
        return t('พื้นที่ว่างพร้อมใช้งาน', 'Vacant — ready to use');
      case 'pool_villa':
        return t('บ้านว่างพร้อมอยู่', 'Vacant — move-in ready');
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
  String get petPolicySectionTitle =>
      t('นโยบายเลี้ยงสัตว์', 'Pet policy');
  String get petPolicySectionHint => t(
        'ช่วยลูกค้าที่มีสัตว์เลี้ยงตัดสินใจได้เร็วขึ้น',
        'Helps pet owners decide faster',
      );
  String get petPolicyNotAllowed =>
      t('ไม่อนุญาตเลี้ยงสัตว์', 'No pets allowed');
  String get petPolicyAllowed => t('เลี้ยงสัตว์ได้', 'Pets allowed');
  String get petPolicyTypesQuestion =>
      t('อนุญาตสัตว์ประเภทใด', 'Which pets are allowed');
  String get petPolicyDogs => t('สุนัข', 'Dogs');
  String get petPolicyCats => t('แมว', 'Cats');
  String get petPolicyMaxWeightLabel =>
      t('น้ำหนักไม่เกิน (กก./ตัว)', 'Max weight (kg per pet)');
  String get petPolicyMaxCountLabel =>
      t('จำนวนสูงสุด', 'Maximum number of pets');
  String get petPolicyOptionalHint =>
      t('ไม่บังคับ', 'Optional');
  String get petPolicyOptionalNote => t(
        'เว้นว่าง = ไม่ระบุจำกัดในระบบ (ทีมอาจสอบถามเพิ่ม)',
        'Leave blank = no limit shown (team may follow up)',
      );
  String petPolicyMaxWeight(String kg) =>
      t('ไม่เกิน $kg กก./ตัว', 'Up to $kg kg each');
  String petPolicyMaxCount(int n) => t('ไม่เกิน $n ตัว', 'Up to $n pets');
  String get petPolicyWeightUnlimited =>
      t('ไม่ระบุจำกัดน้ำหนัก', 'No weight limit specified');
  String get petPolicyCountUnlimited =>
      t('ไม่ระบุจำกัดจำนวน', 'No count limit specified');
  String get petPolicyTypeRequired => t(
        'เลือกอย่างน้อย สุนัข หรือ แมว',
        'Select at least dogs or cats',
      );
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
  String get homeHeaderWelcome =>
      t('ยินดีต้อนรับสู่ RealXtate', 'Welcome to RealXtate');
  String get homeHeaderSlogan => t(
        'ประกาศฟรี ปิดไว ไม่ต้องหาลูกค้าเอง',
        'Free listings · close fast · we bring the buyers',
      );
  String get homeAreaPill =>
      t('กรุงเทพฯและปริมณฑล', 'Bangkok & metro area');
  String get homeHeroCta => t('ค้นหาทรัพย์เลย', 'Search properties');
  String get homeServiceMapTitle => t('ค้นหาแผนที่', 'Map search');
  String get homeQuickServiceMapLine1 => t('ค้นหา', 'Search');
  String get homeQuickServiceMapLine2 => t('ใกล้ฉัน', 'Near me');
  String get homeQuickServiceMatchLine1 => t('สร้างประกาศ', 'Create post');
  String get homeQuickServiceMatchLine2 => t('หาซื้อ / หาเช่า', 'Buy / Rent');
  String get homeQuickServiceMatchLine3 => t('เราหาให้ฟรี', 'We find for free');
  String get homeQuickServiceBoardLine1 => t('รวมประกาศ', 'All posts');
  String get homeQuickServiceBoardLine2 => t('หาซื้อ / หาเช่า', 'Buy / Rent');
  String get homeQuickServiceBoardLine3 => t('เสนอทรัพย์ด่วน', 'Quick offer');
  String get homeServiceMapSubtitle =>
      t('ดูทรัพย์รอบคุณบนแผนที่', 'Browse listings on the map');
  String get homeServiceMapPromo => t('แม่นยำ', 'Verified');
  String get homeServiceFreePromo => t('ฟรี', 'Free');
  String get homeServiceSavedSubtitle =>
      t('ทรัพย์ที่บันทึกไว้', 'Your saved listings');
  String get notifMarkAllRead => t('อ่านทั้งหมด', 'Mark all read');
  String get notifEmpty =>
      t('ยังไม่มีการแจ้งเตือน', 'No notifications yet');
  String get notifFilterAll => t('ทั้งหมด', 'All');
  String get notifFilterChat => t('แชท', 'Chat');
  String get notifFilterAppointment => t('นัด', 'Appointments');
  String get notifFilterListing => t('ประกาศ', 'Listings');
  String get notifFilterSystem => t('ระบบ', 'System');
  String get promoContactTeam => t('ติดต่อทีมงาน', 'Contact our team');
  String get promoContactTeamHint => t(
        'ไปที่แท็บข้อความ — ทีมงานจะตอบกลับโดยเร็ว',
        'Open Messages tab — our team will reply shortly',
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
  String get delete => t('ลบ', 'Delete');
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
  String get notFoundLead => t('ไม่พบเคสลูกค้า', 'Lead not found');
  String get notFoundChat => t('ไม่พบแชท', 'Chat not found');
  String get notFoundPost => t('ไม่พบประกาศ', 'Post not found');

  // ── Listing card meta ──
  String bedsShort(int n) => t('$n นอน', '$n bed');
  String get studioCardLabel => t('สตูดิโอ', 'Studio');
  String bedroomCardLabel(int n) =>
      n == 0 ? studioCardLabel : t('$n ห้องนอน', '$n bed');
  String bathroomCardLabel(int n) => t('$n ห้องน้ำ', '$n bath');
  String areaCardLabel(num sqm) =>
      t('${sqm.round()} ตร.ม.', '${sqm.round()} sqm');
  String sqmShort(int n) => t('$n ตร.ม.', '$n sqm');
  String get perMonth => t('/เดือน', '/mo');
  String get listingTypeRent => t('เช่า', 'Rent');
  String get listingTypeSale => t('ขาย', 'Sale');
  String get listingTypeSaleInstallment => t('ขายฝาก', 'Installment sale');
  String get listingTypeRentAndSale => t('ขาย + ให้เช่า', 'Sale + rent');

  /// ป้ายประเภทประกาศ — ไม่มี เซ้ง / ขายดาวน์
  String listingTransactionLabel(String? type) {
    switch (type) {
      case 'rent':
        return listingTypeRent;
      case 'sale':
        return listingTypeSale;
      case 'sale_installment':
        return listingTypeSaleInstallment;
      case 'rent_and_sale':
        return listingTypeRentAndSale;
      default:
        return type?.isNotEmpty == true ? type! : listingTypeSale;
    }
  }

  /// ป้ายสั้นบนรูป (แนวนอน) — เช่า / ขาย / ขาย+เช่า
  String listingTransactionRibbonLabel(String? type) {
    switch (type) {
      case 'rent':
        return listingTypeRent;
      case 'sale':
        return listingTypeSale;
      case 'sale_installment':
        return listingTypeSaleInstallment;
      case 'rent_and_sale':
        return t('ขาย/เช่า', 'Sale/Rent');
      default:
        return listingTypeSale;
    }
  }

  String get createListingRentAndSaleHint => t(
        'ประกาศนี้จะแสดงทั้งแท็บเช่าและซื้อ — กรอกราคาเช่าและราคาขายแยกกัน',
        'This listing appears in both Rent and Buy — enter rent and sale prices separately',
      );
  String get createListingDualPriceSummary => t('ราคาเช่า + ขาย', 'Rent + sale prices');
  String get careOwnerDataSalePriceRequired =>
      t('กรอกราคาขาย', 'Enter sale price');
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
  String get filterWithTenant => filterSaleWithTenant;
  String get filterSaleWithTenant =>
      t('ขายพร้อมผู้เช่า', 'Sale with tenant in place');
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
  String get authQuickEntryAdmin => t(
        'เข้าหลังบ้านทดลอง · ไม่ต้องรหัส',
        'Open admin demo · no password',
      );
  String get authQuickEntryFront => t(
        'เข้าหน้าบ้านทดลอง · ไม่ต้องรหัส',
        'Open app demo · no password',
      );
  String get authQuickEntryOwner => t(
        'เข้าเป็นเจ้าของทดลอง · ไม่ต้องรหัส',
        'Open as demo owner · no password',
      );
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
  String get signUpPageTitle => t('สร้างบัญชี RealXtate', 'Create RealXtate account');
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
  String get profileAvatarUpdated =>
      t('อัปเดตรูปโปรไฟล์แล้ว', 'Profile photo updated');
  String get profileAvatarNeedLogin => t(
        'ล็อกอินก่อนอัปโหลดรูปโปรไฟล์',
        'Sign in to upload a profile photo',
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
  String get profileGuestWelcome => t('ยินดีต้อนรับ', 'Welcome');
  String get profileGuestSubtitle => t(
        'เข้าสู่ระบบเพื่อบันทึกทรัพย์และจัดการประกาศ',
        'Sign in to save listings and manage your posts',
      );
  String get profileGuestCta => t('เข้าสู่ระบบ / สมัคร', 'Log in / Sign up');
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
  String get deleteAccount => t('ลบบัญชี', 'Delete account');
  String get deleteAccountTitle => t('ลบบัญชีถาวร?', 'Delete account permanently?');
  String get deleteAccountHint => t(
        'ข้อมูลโปรไฟล์ ประกาศ และแชทที่เชื่อมกับบัญชีนี้จะถูกลบและไม่สามารถกู้คืนได้',
        'Your profile, listings, and linked chats will be permanently deleted and cannot be recovered',
      );
  String get deleteAccountConfirm => t('ลบบัญชีถาวร', 'Delete permanently');
  String get deleteAccountDone => t('ลบบัญชีแล้ว', 'Account deleted');
  String get deleteAccountCancel => t('ยกเลิก', 'Cancel');
  String get perspectiveSwitchHint => t(
        'สลับได้ที่หัวหน้าแรก (ข้างโลโก้) — 「คุณคือ」\n'
        'นายหน้า = เห็นเฉพาะทรัพย์รับโค · เจ้าของ = ลงประกาศได้',
        'Switch on home header — 「You are」\n'
        'Broker = co-broker listings only · Owner = can post',
      );
  String get adminCenter => t('ศูนย์หลังบ้าน (ทีมงาน)', 'Admin center (team)');
  String get checkingRole => t('กำลังตรวจสอบสิทธิ์…', 'Checking permissions…');
  String get adminHintDemo =>
      t('โหมดทดลอง — ทดสอบแชท เคสลูกค้า และรายงานได้ทันที', 'Demo — test chat/leads/reports');
  String get adminHintTrial => t(
        'โหมดทดลอง — เปิดศูนย์หลังบ้านด้วยข้อมูลตัวอย่าง',
        'Trial — open Admin with sample data',
      );
  String get adminHintReal =>
      t('บัญชีผู้ดูแล — จัดการแชท เคสลูกค้า และรายงาน', 'Admin — manage chat, leads & reports');
  String get adminHintNeedLogin => t(
        'ล็อกอินด้วยบัญชีผู้ดูแลในระบบเพื่อใช้งานจริง',
        'Log in with Supabase admin account for production',
      );
  String get postListingProperty => t('ลงประกาศทรัพย์', 'Post listing');
  String get myListingsConfirm =>
      t('ประกาศของฉัน · ยืนยันว่าง', 'My listings · mark available');
  String get notifications => t('การแจ้งเตือน', 'Notifications');
  String get notificationsRealtimeFcm => t(
        'แจ้งเตือนทันทีเปิดแล้ว (เคสลูกค้า/นัดชม)',
        'Realtime + FCM enabled (leads/viewings)',
      );
  String get notificationsPartial => t(
        'ในแอป: Realtime · นอกแอป: ใส่ FIREBASE_* ตาม mobile/docs/FCM_SETUP.md',
        'In-app: Realtime · Push: set FIREBASE_* per mobile/docs/FCM_SETUP.md',
      );
  String get notificationsDemo =>
      t('โหมดทดลอง — แจ้งเตือนเมื่อมีเคสใหม่ (จำลอง)', 'Demo — SnackBar on lead (simulated)');
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
  String get listingBumpedLabel => t('เลื่อนประกาศ', 'Listing bump');
  String listingUpdatedAgo(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return t('เมื่อสักครู่', 'Just now');
    if (diff.inMinutes < 60) {
      return t('${diff.inMinutes} นาทีก่อน', '${diff.inMinutes} min ago');
    }
    if (diff.inHours < 24) {
      return t('${diff.inHours} ชั่วโมงก่อน', '${diff.inHours} hr ago');
    }
    return t('${diff.inDays} วันก่อน', '${diff.inDays} days ago');
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
      t('พิมพ์ย่าน สถานี โครงการ…', 'Type area, station, project…');
  String get searchDiscoveryTypewriterHint => t(
        'ลองค้นหา โครงการ, ย่าน, ทำเล, สถานีรถไฟฟ้า',
        'Try projects, areas, locations, BTS/MRT stations',
      );
  String get searchZoneTagAddTitle =>
      t('เพิ่มแท็กค้นหา', 'Add search tags');
  String get searchZonePopularTitle =>
      t('แนะนำ', 'Suggested');
  String get searchHistoryTitle => t('ประวัติและเทรนด์การค้นหา', 'History & trends');
  String get searchYourHistoryTitle =>
      t('ประวัติการค้นหาของคุณ', 'Your search history');
  String get searchHistoryEmpty => t(
        'ยังไม่มีประวัติ — ลองค้นหาโครงการหรือทำเลด้านบน',
        'No history yet — search for a project or area above',
      );
  String get searchClearAll => t('ล้างทั้งหมด', 'Clear all');
  String get searchTrendsTitle => t('เทรนด์การค้นหา', 'Search trends');
  String get searchResultsTitle => t('ผลการค้นหา', 'Search results');
  String get searchByCategoryTitle => t('ค้นหาจากหมวดหมู่', 'Search by category');
  String get searchNearByTitle => t('Near By หาอสังหาฯ ใกล้ตัวคุณ', 'Near By — find nearby');
  String get searchNearBySubtitle => t('หาจากปักหมุดบนแผนที่', 'Search from map pin');
  String get searchTabLocation => t('ทำเล', 'Location');
  String get searchTabTransit => t('การเดินทาง', 'Transit');
  String get searchTabProject => t('โครงการ', 'Projects');
  String get searchTabEducation => t('สถานศึกษา', 'Education');
  String get searchZoneTagHint =>
      t('พิมพ์ชื่อย่าน/ทำเล…', 'Type neighborhood or area…');
  String get searchZoneTagHintLocation =>
      t('พิมพ์ชื่อย่าน เช่น ทองหล่อ เอกมัย', 'Type area e.g. Thong Lo, Ekkamai');
  String get searchZoneTagHintTransit =>
      t('พิมพ์ชื่อสถานี BTS/MRT', 'Type BTS/MRT station name');
  String get searchZoneTagHintProject =>
      t('พิมพ์ชื่อโครงการ', 'Type project name');
  String get searchZoneTagHintEducation =>
      t('พิมพ์ชื่อสถานศึกษา', 'Type school or university');
  String get mapPinPlace => t('ปักหมุด', 'Drop pin');
  String get mapPinTapHint => t('แตะแผนที่เพื่อปักหมุด', 'Tap map to drop pin');
  String get mapPinClear => t('ลบหมุด', 'Clear pin');
  String get mapPinRadiusLabel => t('รัศมี', 'Radius');
  String mapPinRadiusKm(double km) => mapPinRadiusDisplay(km);
  String mapPinRadiusDisplay(double km) {
    if (km < 1) {
      final m = (km * 1000).round();
      return t('$m ม.', '$m m');
    }
    final v = km == km.roundToDouble()
        ? '${km.toInt()}'
        : km.toStringAsFixed(1);
    return t('$v กม.', '$v km');
  }

  String mapPinActive(double km) => t(
        'กำลังค้นหาในรัศมี ${mapPinRadiusDisplay(km)} จากหมุด',
        'Searching within ${mapPinRadiusDisplay(km)} of pin',
      );
  String searchApplyZoneFilters(int count) =>
      t('ดูทั้งหมด ($count)', 'View all ($count)');
  String get searchProjectsSection => t('โครงการ', 'Projects');
  String searchSeeAllForQuery(String query) => t(
        'ดูผลลัพธ์ทั้งหมดสำหรับ \'$query\'',
        'See all results for \'$query\'',
      );
  String projectStatRentFrom(String price) =>
      t('เช่าเริ่มต้น $price', 'Rent from $price');
  String projectStatSaleFrom(String price) =>
      t('ขายเริ่มต้น $price', 'Sale from $price');
  String get projectNearbyTitle => t('โครงการใกล้เคียง', 'Nearby projects');
  String projectNearbyDistanceKm(double km) {
    final v = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return t('$v กม.', '$v km');
  }
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
  String get confirmAvailableBump => t(
        'ยืนยันว่าง / ดันประกาศ',
        'Confirm vacant / Bump',
      );
  String get confirmedAvailableBump => t(
        'ยืนยันว่างแล้ว — ดันประกาศ (Bump)',
        'Marked available — listing bumped',
      );
  String get listingBumpFailed => t(
        'ดันประกาศไม่สำเร็จ — ลองรีเฟรชหน้า',
        'Could not bump — try refreshing',
      );
  String listingExpiresBumpHint(int daysLeft) => t(
        'ประกาศจะหมดอายุในอีก $daysLeft วัน (ยืนยันว่าง / ดันประกาศ)',
        'Listing expires in $daysLeft days (confirm vacant / bump)',
      );
  String listingBumpCooldownHint(int hours, int minutes) => t(
        'กดได้อีกใน $hours ชม. $minutes นาที',
        'Available again in ${hours}h ${minutes}m',
      );
  String get listingViewStats => t('ดูสถิติ', 'View stats');
  String get listingEditAction => t('แก้ไข', 'Edit');
  String get listingCloseShort => t('ปิดประกาศ…', 'Close…');
  String get listingTapForDetails => t('แตะเพื่อดูรายละเอียด', 'Tap for details');
  String get listingEditComingSoon => t(
        'ฟอร์มแก้ไขเต็มจะมาในเฟสถัดไป — ใช้ปิด/ดันประกาศก่อน',
        'Full edit form coming soon — use bump or close for now',
      );
  String get listingStatsSheetHint => t(
        'สถิติอัปเดตเมื่อมีผู้เข้าชมหรือเริ่มแชทจากประกาศนี้',
        'Stats update when viewers browse or start a chat from this listing',
      );
  String get listingInsightShares => t('แชร์', 'Shares');
  String listingStatsOneLiner(int views, int shares, int chats) => t(
        'เข้าชม $views · แชร์ $shares · แชท $chats',
        '$views views · $shares shares · $chats chats',
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
        'เลือกแบบปิดประกาศ — ประกาศจะถูกเก็บในคลัง (ไม่แสดงต่อสาธารณะ)',
        'Choose how to close — listing will be archived (hidden from public).',
      );
  String get closeListingModePermanent =>
      t('ลบประกาศถาวร', 'Close listing permanently');
  String get closeListingModePermanentHint => t(
        'เลือกเหตุผลด้านล่าง แล้วกดยืนยัน',
        'Pick a reason below, then confirm',
      );
  String get closeListingModeTenanted =>
      t('มีผู้เช่าแล้ว', 'Already tenanted');
  String get closeListingModeTenantedHint => t(
        'ระบุวันที่ทรัพย์จะว่างอีกครั้ง',
        'Set when the unit will be available again',
      );
  String get closeListingTenantedDateSection =>
      t('วันที่ว่างอีกครั้ง', 'Available again on');
  String get closeListingTenantedDateHint => t(
        'ระบบจะแจ้งเตือนก่อนถึงวัน (เช่น 30 และ 15 วันล่วงหน้า)',
        'We will remind you before that date (e.g. 30 and 15 days ahead)',
      );
  String get closeListingTenantedReminderNote => t(
        'ก่อนวันว่าง คุณเลือกได้: เผยแพร่ล่วงหน้า · ยังไม่แน่ใจ (เตือนอีกครั้ง) · เปลี่ยนวัน · ปิดถาวร',
        'Before vacancy you can: republish early · not sure (remind again) · change date · close permanently',
      );
  String get closeListingTenantedConfirm =>
      t('ยืนยันปิดประกาศชั่วคราว', 'Confirm temporary close');
  String get closeListingPermanentDeleteConfirm =>
      t('ยืนยันลบประกาศถาวร', 'Confirm permanent close');
  String get closeListingRentPermanentSection =>
      t('เลือกเหตุผลปิดถาวร', 'Pick a permanent reason');
  String get closeRentReasonSold =>
      t('ทรัพย์ขายไปแล้ว', 'Property sold');
  String get closeRentReasonSoldHint => t(
        'ไม่นำประกาศเช่านี้กลับมาใช้ใหม่',
        'This rental listing cannot be republished',
      );
  String get closeRentReasonStopRent =>
      t('ไม่ต้องการปล่อยเช่าแล้ว', 'No longer renting out');
  String get closeRentReasonStopRentHint => t(
        'หยุดปล่อยเช่า — ปิดถาวร',
        'Stop renting — permanent close',
      );
  String get closeRentReasonUnavailable =>
      t('ทรัพย์ไม่พร้อมอีกต่อไป', 'Property no longer available');
  String get closeRentReasonUnavailableHint => t(
        'ไม่สามารถให้เช่าได้อีก',
        'Cannot be rented anymore',
      );
  String get closeListingRentTemporarySection =>
      t('ว่างอีกครั้งในภายหลัง', 'Available again later');
  String get closeListingRentTemporaryTitle =>
      t('จะว่างอีกครั้ง — ระบุวันที่', 'Will be available — pick a date');
  String get closeListingRentTemporaryHint => t(
        'เก็บประกาศชั่วคราว นำกลับมาได้เมื่อถึงวัน',
        'Temporarily archived — can return when date arrives',
      );
  String get closeListingPermanentConfirm =>
      t('ยืนยันปิดถาวร', 'Confirm permanent close');
  String closeRentArchivedReason(String key) {
    switch (key) {
      case 'sold':
        return closeRentReasonSold;
      case 'stop_rent':
        return closeRentReasonStopRent;
      case 'unavailable':
        return closeRentReasonUnavailable;
      default:
        return listingSaleArchivedNote;
    }
  }
  String get closeSaleReasonStopSale =>
      t('ไม่ต้องการขายแล้ว', 'No longer selling');
  String get closeSaleReasonStopSaleHint => t(
        'หยุดขาย — ปิดถาวร',
        'Stop selling — permanent close',
      );
  String get listingClosePickReason => t(
        'กดเพื่อเลือก: มีผู้เช่าแล้ว หรือ ปิดถาวร',
        'Tap: already tenanted or permanent close',
      );
  String get listingPreviewOnline => t('พรีวิวออนไลน์', 'Preview live');
  String get listingPreviewNotOnline => t(
        'ประกาศนี้ยังไม่ออนไลน์ — รอทีมตรวจสอบหรือยังไม่เผยแพร่',
        'Not live yet — pending review or unpublished',
      );
  String get listingCoverPreviewHint => t(
        'แตะรูปเพื่อพรีวิว',
        'Tap photo to preview',
      );
  String get closeListingSaleTitle => t('ปิดประกาศขาย', 'Close sale listing');
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
        'ลบจากมุมมองของคุณเท่านั้น — ข้อมูลยังอยู่ในฐานข้อมูลของ RealXtate',
        'Removes from your view only — data stays in RealXtate database',
      );
  String get deleteListingConfirm => t('ลบถาวรจากรายการ', 'Remove permanently');
  String get hideListingFromMine => t('ซ่อนจากรายการของฉัน', 'Hide from my list');
  String listingAvailabilityReminderTitle(int days) => t(
        'ประกาศจะว่างในอีก $days วัน',
        'Listing available in $days days',
      );
  String listingAvailabilityReminderBody(String title, String date) => t(
        '「$title」กำหนดว่างอีกครั้ง $date — เลือกดำเนินการ',
        '「$title」scheduled available $date — choose next step',
      );
  String get listingAvailabilityRepublishEarly =>
      t('นำประกาศเผยแพร่อีกครั้ง (หาผู้เช่าล่วงหน้า)', 'Republish early (pre-marketing)');
  String get listingAvailabilityRepublishEarlyHint => t(
        'แสดงประกาศอีกครั้งก่อนวันว่างจริง',
        'Show listing again before actual vacancy',
      );
  String get listingAvailabilityRemindLater =>
      t('ยังไม่แน่ใจ — เตือนอีกครั้ง', 'Not sure — remind me again');
  String get listingAvailabilityRemindLaterHint => t(
        'ระบบจะแจ้งอีกครั้ง 15 วันก่อนวันเดิม',
        'We will notify again 15 days before the original date',
      );
  String get listingAvailabilityUpdateDate =>
      t('เปลี่ยนวันว่างจริง', 'Update available date');
  String get listingAvailabilityUpdateDateHint => t(
        'ระบุวันที่ทรัพย์จะว่างจริง',
        'Set the actual vacancy date',
      );
  String get listingAvailabilityPermanentClose =>
      t('ไม่พร้อมให้เช่าอีกต่อไป', 'No longer available for rent');
  String get listingAvailabilityPermanentCloseHint => t(
        'ขายแล้ว / ไม่เช่า / ไม่พร้อม — ปิดถาวร',
        'Sold / stop rent / unavailable — permanent close',
      );
  String get listingAvailabilityManageAction =>
      t('จัดการวันว่าง', 'Manage vacancy');
  String listingArchivedAvailableLine(String date, int days) => t(
        'ว่างอีกครั้ง $date (อีก $days วัน)',
        'Available again $date (in $days days)',
      );
  String get listingRepublishedEarly => t(
        'เผยแพร่ประกาศอีกครั้ง — หาผู้เช่าล่วงหน้า',
        'Listing republished — pre-marketing',
      );
  String get listingAvailabilityDateUpdated => t(
        'อัปเดตวันว่างแล้ว',
        'Available date updated',
      );
  String get listingAvailabilityRemindScheduled => t(
        'จะแจ้งเตือนอีกครั้ง 15 วันก่อนวันเดิม',
        'Reminder scheduled 15 days before original date',
      );
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
      t('RealXtate — เก็บประกาศแล้ว', 'RealXtate — Listing archived');
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
        'อนุญาตให้นายหน้าช่วยทำการตลาดผ่าน RealXtate',
        'Allow brokers to market via RealXtate',
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
        'ทีม RealXtate กำลังตรวจสอบ — จะแจ้งเมื่อขึ้นประกาศแล้ว',
        'RealXtate team is reviewing — we will notify you when live',
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
  String get createListingHashtagsTitle => t('จุดเด่นทรัพย์', 'Property highlights');
  String get createListingHashtagsHint => t(
        'เลือกจุดเด่นที่ตรงความจริงอย่างน้อย 1 รายการ — ด้านล่างเป็นตัวแนะนำ',
        'Pick at least one accurate highlight — suggestions shown first',
      );
  String createListingHashtagsShowMore(int count) => t(
        'ดูจุดเด่นเพิ่มเติม ($count)',
        'More highlights ($count)',
      );
  String get createListingHashtagsShowLess =>
      t('ซ่อนจุดเด่นเพิ่มเติม', 'Show fewer highlights');
  String createListingHashtagsExtraSelected(int count) => t(
        'เลือกจากรายการเพิ่มเติมแล้ว $count รายการ',
        '$count extra highlight(s) selected',
      );
  String get createListingFacilitiesTitle => t('ส่วนกลาง', 'Common facilities');
  String get adminListingsPendingReview => t('ประกาศรอตรวจ', 'Listings pending review');
  String get adminApproveListing => t('อนุมัติเผยแพร่', 'Approve & publish');
  String get adminPublishedWithWatermark => t(
        'เผยแพร่แล้ว — ยูสเห็นรูปมีลายน้ำ · ต้นฉบับเก็บในหลังบ้าน',
        'Published — users see watermarked photos · originals kept in backend',
      );
  String get adminListingPreview => t('พรีวิวหน้าบ้าน', 'Public preview');
  String get adminListingPreviewTitle =>
      t('พรีวิวประกาศบนเว็บ', 'Listing public preview');
  String get adminListingPreviewBanner => t(
        'ตัวอย่างหน้าบ้าน — รูปที่แสดงคือเวอร์ชันมีลายน้ำ (public_url)',
        'Public preview — photos shown are watermarked (public_url)',
      );
  String get adminListingPreviewWatermarkNote => t(
        'แอดมินดาวน์โหลดต้นฉบับไม่มีลายน้ำได้จากปุ่มด้านบน',
        'Admins can download originals without watermark using the button above',
      );
  String get adminDownloadOriginalPhotos =>
      t('ดาวน์โหลดรูปต้นฉบับ', 'Download originals');
  String get adminDownloadOriginalsPreparing =>
      t('กำลังเตรียมรูปต้นฉบับ…', 'Preparing original photos…');
  String adminDownloadOriginalsShareText(String code) =>
      t('รูปต้นฉบับ $code (ไม่มีลายน้ำ)', 'Original photos $code (no watermark)');
  String get adminListingPreviewFeedTab => t('การ์ดฟีด', 'Feed card');
  String get adminListingPreviewDetailTab => t('หน้ารายละเอียด', 'Detail page');
  String get adminListingPreviewNotFound => t(
        'ไม่พบประกาศสำหรับพรีวิว',
        'No listing found for preview',
      );
  String get adminTabWatermark => t('ลายน้ำ', 'Watermark');
  String get adminWatermarkTitle => t('ตั้งค่าลายน้ำรูปประกาศ', 'Listing photo watermark');
  String get adminWatermarkHint => t(
        'อัปโหลด PNG โปร่งใส (โลโก้เล็ก) — ใช้หลังอนุมัติเผยแพร่ มุมล่างขวา กึ่งโปร่งแสง',
        'Upload transparent PNG — applied on publish, bottom-right, semi-transparent',
      );
  String get adminWatermarkPreview => t('ตัวอย่างบนรูป', 'Preview on photo');
  String get adminWatermarkUsingCustom => t('ใช้รูปที่อัปโหลดแล้ว', 'Using uploaded image');
  String get adminWatermarkUsingDefault => t('ใช้โลโก้เริ่มต้นในระบบ', 'Using built-in default logo');
  String get adminWatermarkUpload => t('อัปโหลดรูปลายน้ำ', 'Upload watermark image');
  String get adminWatermarkUploaded => t('อัปโหลดลายน้ำแล้ว', 'Watermark uploaded');
  String get adminWatermarkUseDefault => t('กลับไปใช้โลโก้เริ่มต้น', 'Use default logo');
  String get adminWatermarkTuning => t('ปรับความเบา/ขนาด', 'Opacity & size');
  String get adminWatermarkEnabled => t('เปิดใช้ลายน้ำ', 'Watermark enabled');
  String get adminWatermarkEnabledHint => t(
        'ปิดชั่วคราวได้ — รูปใหม่ที่เผยแพร่จะไม่ฝังลายน้ำ',
        'Turn off to skip watermarking new publishes',
      );
  String adminWatermarkOpacityLabel(int v) =>
      t('ความเข้ม (โปร่งแสง) · $v', 'Opacity · $v');
  String adminWatermarkSizeLabel(int pct) =>
      t('ขนาด · $pct% ของความกว้างรูป', 'Size · $pct% of image width');
  String get adminWatermarkSaveTuning => t('บันทึกการปรับ', 'Save settings');
  String get adminWatermarkSaved => t('บันทึกการตั้งค่าแล้ว', 'Settings saved');
  String get adminWatermarkNote => t(
        'รูปต้นฉบับเก็บใน Storage — ยูสเห็น/ดาวน์โหลดเวอร์ชันมีลายน้ำ · เปลี่ยนโลโก้มีผลประกาศเผยแพร่ใหม่',
        'Originals kept in Storage — users see/download watermarked copies · logo changes apply to new publishes',
      );
  String get adminWatermarkClearTitle => t('ลบรูปลายน้ำที่อัปโหลด?', 'Remove uploaded watermark?');
  String get adminWatermarkClearBody => t(
        'จะกลับไปใช้โลโก้เริ่มต้นในระบบ',
        'Will revert to the built-in default logo',
      );
  String get adminWatermarkClearConfirm => t('ลบ', 'Remove');
  String get adminWatermarkCleared => t('กลับไปใช้โลโก้เริ่มต้นแล้ว', 'Reverted to default logo');
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
        'ทีม RealXtate จะตรวจสอบข้อเสนอและติดต่อกลับในแชท',
        'RealXtate team will review your offer and follow up in chat',
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
  String get adminTitle => t('หลังบ้าน', 'Admin');
  String get adminLivingBkk => t('RealXtate หลังบ้าน', 'RealXtate Admin');
  String get adminLink => t('ลิงก์', 'Link');
  String get adminDetails => t('รายละเอียด', 'Details');
  String get adminConfirmRole => t('ยืนยันสิทธิ์', 'Confirm role');
  String get adminStatsMakecom =>
      t('สถิติวันล่าสุด (ส่งต่อระบบอัตโนมัติ)', 'Latest stats (for Make.com)');
  String get adminChatTitle => t('แชท', 'Chat');
  String get adminReplyCustomer => t('ตอบแชทลูกค้า', 'Reply to customer');
  String get adminCloseCase => t('ปิดเคส', 'Close case');
  String get adminMarkedReplied => t('ทำเครื่องหมายว่าตอบแล้ว', 'Marked as replied');
  String get adminSaveViewing => t('บันทึกนัดชม', 'Save viewing appointment');
  String get adminViewingMap => t('แผนที่โซนนัดชม', 'Viewing zone map');
  String get adminNoCoords => t('ไม่มีพิกัดทรัพย์', 'No property coordinates');
  String get adminListingNotFound =>
      t('ไม่พบทรัพย์ในระบบ', 'Listing not found');
  String get adminOpenListing => t('เปิดหน้าทรัพย์', 'Open listing');
  String get adminConfirmViewingInChat =>
      t('ยืนยันนัดดู', 'Confirm viewing');
  String get adminSeniorOwnerCallBtn =>
      t('ขอแอดมินโทรเจ้าของ', 'Senior call owner');
  String get adminSeniorOwnerCallTitle =>
      t('ขอแอดมินระดับสูงโทรเจ้าของ', 'Request senior admin to call owner');
  String get adminSeniorOwnerCallHint => t(
        'ระบุประเด็นที่ต้องคุยกับเจ้าของก่อนยืนยันนัด',
        'What should be discussed with the owner before confirming',
      );
  String get adminSeniorOwnerCallSubmit =>
      t('ส่งคำขอ', 'Submit request');
  String get adminSeniorOwnerCallSent => t(
        'ส่งคำขอให้แอดมินระดับสูงแล้ว',
        'Senior admin request sent',
      );
  String get adminSendOwnerProfileBtn =>
      t('ส่งโปรไฟล์ให้เจ้าของ', 'Send profile to owner');
  String get adminSendOwnerProfileTitle =>
      t('ส่งโปรไฟล์ลูกค้าให้เจ้าของ', 'Send customer profile to owner');
  String get adminSendOwnerProfileBody => t(
        'ระบบจะตัดเบอร์โทรและ Line ID ออกก่อนส่ง — เจ้าของจะเห็นในแชทและกล่องงาน',
        'Phone and Line ID will be removed before sending. The owner will see this in chat and work inbox.',
      );
  String get adminSendOwnerProfileConfirm =>
      t('ส่งเลย', 'Send now');
  String get adminSendOwnerProfileDone => t(
        'ส่งโปรไฟล์ให้เจ้าของแล้ว (ไม่มีเบอร์/ไลน์เต็ม)',
        'Profile sent to owner (contact details censored)',
      );
  String get adminOwnerNotFound =>
      t('ไม่พบเจ้าของประกาศในระบบ', 'Listing owner not found');
  String get adminConfirmViewingChatOnly => t(
        'ยืนยันนัดดูได้ในแชทหลังรับงานและคุยกับลูกค้าแล้ว',
        'Confirm viewing in chat after claiming and talking to the customer',
      );
  String get adminLeadPropertyCard => t('ทรัพย์ที่ลูกค้าสนใจ', 'Property of interest');
  String get adminOpenLinkedChat =>
      t('เปิดแชทกับลูกค้า', 'Open customer chat');
  String get adminOpenOwnerChat =>
      t('เปิดแชทกับเจ้าของทรัพย์', 'Open owner chat');
  String get adminLeadViewingAccessTitle =>
      t('วิธีเปิดทรัพย์ (นัดชม)', 'Property access (viewing)');
  String adminLeadViewingAccessLinkedHint(String code) => t(
        'บันทึกแล้วอัปเดตที่ทรัพย์ $code และโน้ตนัดชมที่เชื่อมเคสนี้',
        'Saved to listing $code and linked viewing notes for this lead',
      );
  String get adminLeadViewingAccessNoListing => t(
        'ยังไม่มีรหัสทรัพย์ — ผูกประกาศก่อนจึงบันทึกวิธีเปิดได้',
        'No listing code — link a listing before saving access details',
      );
  String get adminLeadViewingAccessSave =>
      t('บันทึกวิธีเปิดทรัพย์', 'Save access details');
  String get adminLeadViewingAccessSaved => t(
        'บันทึกวิธีเปิดทรัพย์แล้ว',
        'Property access details saved',
      );
  String get adminLeadViewingAccessSavedLinked => t(
        'บันทึกแล้ว — อัปเดตทรัพย์และโน้ตนัดชมที่เชื่อมเคส',
        'Saved — listing and linked appointment notes updated',
      );
  String get adminLeadViewingAccessApptNote =>
      t('โน้ตนัดชม (เชื่อมเคส)', 'Linked viewing note');
  String adminLeadViewingAccessLinkedNote(String code, String summary) => t(
        '[$code] วิธีเปิดทรัพย์: $summary',
        '[$code] Access: $summary',
      );
  String get adminChatBeforeConfirmHint => t(
        'คุยกับลูกค้าในแชทก่อน แล้วค่อยกด「ยืนยันนัดดู」เมื่อตกลงรายละเอียดแล้ว',
        'Chat with the customer first, then confirm the viewing once agreed.',
      );
  String get adminLeadChatRef => t('เลขแชท', 'Chat ref');
  String get adminCoordinateViewing =>
      t('ประสานงาน / ยืนยันนัดดู', 'Coordinate / confirm viewing');
  String get adminPublishBoard => t('เผยแพร่บอร์ด', 'Publish to board');
  String get adminCopyTsv => t('คัดลอกส่งสเปรดชีต', 'Copy for Google Sheets');
  String get adminTsvCopied => t(
        'คัดลอกตารางแล้ว — วางในสเปรดชีตได้',
        'TSV copied — paste into Google Sheets',
      );
  String get adminNoStats => t(
        'ยังไม่มีข้อมูล — รอเคสลูกค้าหรือนัดชมเพื่อสะสมสถิติ',
        'No data yet — submit leads or viewings to collect stats',
      );
  String get adminLifecycleTitle =>
      t('วงจรประกาศ', 'Listing lifecycle');
  String get adminRunNow => t('รันตอนี้', 'Run now');
  String get adminNoPhotosPending =>
      t('ไม่มีรูปรออนุมัติ', 'No photos pending approval');
  String get adminNoFlags => t('ไม่มีรายการแจ้งผิดปกติค้าง', 'No pending flags');

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
  String get createListingLocationSearchHint => t(
        'ค้นหาโครงการ ทำเล หรือ BTS/MRT — เหมือนช่องค้นหาหน้าแรก',
        'Search projects, areas, or BTS/MRT — same as the home search bar',
      );
  String get createListingLocationManualEntry => t(
        'อยู่นอกโครงการ / ไม่พบในระบบ — กรอกทำเลเอง',
        'Outside a project / not listed — enter manually',
      );
  String get createListingLocationManualTitle =>
      t('กรอกทำเลเอง', 'Enter location manually');
  String get createListingLocationManualHint => t(
        'ระบุชื่อโครงการหรือทำเล และเขต/ย่านด้านล่าง',
        'Enter project or area name and district below',
      );
  String get createListingStandaloneToggle =>
      t('ไม่ระบุชื่อโครงการ (บ้าน/ทาวน์เฮาส์นอกโครงการ)', 'No project name (standalone house/townhouse)');
  String get createListingPhotoPolicy => t(
        'ใช้รูปถ่ายจริงของทรัพย์เท่านั้น — ห้ามลายน้ำ/โลโก้จากเว็บหรือนายหน้าอื่น · หลังอนุมัติเผยแพร่ ระบบจะฝังลายน้ำ RealXtate ในไฟล์รูปอัตโนมัติ',
        'Actual property photos only — no third-party watermarks/logos · after approval RealXtate watermark is burned into image files automatically.',
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
  String get projectRequired => t(
        'เลือกโครงการจากการค้นหา หรือกด「กรอกทำเลเอง」',
        'Pick a project from search or tap「Enter manually」',
      );
  String get propertyTypeLabel => t('ประเภททรัพย์', 'Property type');
  String get bedroomsFieldLabel => t('ห้องนอน', 'Bedrooms');

  // ── Saved listings ──
  String get savedListingsEmpty => t('ยังไม่มีทรัพย์ที่บันทึก', 'No saved listings yet');
  String get savedListingsHint => t(
        'กดไอคอนหัวใจที่การ์ดทรัพย์เพื่อเก็บไว้ดูภายหลัง',
        'Tap the heart on listing cards to save for later',
      );
  String get savedListingsManage => t('จัดการ', 'Manage');
  String get savedListingsSortRecent =>
      t('บันทึกล่าสุด', 'Recently saved');
  String savedListingsDeleteSelected(int n) =>
      t('ลบที่เลือก ($n)', 'Delete selected ($n)');
  String get savedListingsSelectAll => t('เลือกทั้งหมด', 'Select all');
  String get savedListingsDeselectAll => t('ยกเลิกเลือก', 'Deselect all');
  String get savedListingsRemoved =>
      t('ลบออกจากรายการบันทึกแล้ว', 'Removed from saved');
  String savedListingsDeleteConfirm(int n) => t(
        'ลบทรัพย์ที่เลือก $n รายการออกจากรายการบันทึก?',
        'Remove $n saved listings?',
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
        'ข้อมูลนี้ไม่แสดงต่อผู้ใช้รายอื่น — ทีม RealXtate ตรวจสอบเท่านั้น',
        'Not visible to other users — RealXtate team only',
      );
  String get offerVacancyWarningTitle => t(
        'ข้อควรทราบก่อนส่งข้อเสนอ',
        'Before you submit an offer',
      );
  String get offerVacancyWarningBody => t(
        'กรุณาตรวจสอบว่าทรัพย์ของท่านยังว่างและพร้อมให้เช่าหรือขายตามที่ระบุไว้ '
        'หากในขณะนี้ยังไม่ว่าง โปรดระบุในช่องรายละเอียดให้ชัดเจน '
        'เช่น วันที่ว่าง เงื่อนไขการส่งมอบ และช่วงเวลาที่ผู้สนใจสามารถเข้าอยู่ได้',
        'Please confirm your property is vacant and available as described. '
        'If it is not available yet, kindly note this in the details — '
        'available date, handover terms, and when the tenant or buyer may move in.',
      );
  String get offerMisuseWarning => t(
        'เพื่อคุณภาพของการให้บริการ โปรดส่งข้อเสนอที่สอดคล้องกับความต้องการของประกาศเท่านั้น '
        'หากพบข้อเสนอที่ไม่ตรงหรือไม่ใกล้เคียงซ้ำ ๆ ทีมงานอาจพิจารณาจำกัดสิทธิ์การเสนอทรัพย์บนบอร์ดเป็นการชั่วคราว',
        'To maintain service quality, please submit offers that genuinely match the post. '
        'Repeated offers that are irrelevant or far from requirements may result in '
        'temporary limits on board offer access.',
      );
  String get propertyHonestyWarningTitle => t(
        'กรุณาตรวจสอบความพร้อมและความถูกต้องของข้อมูล',
        'Please verify availability and listing accuracy',
      );
  String get propertyHonestyWarningVacancy => t(
        'โปรดยืนยันว่าทรัพย์อยู่ในสภาพพร้อมให้เช่าหรือขายตามที่ระบุ '
        'หากยังไม่ว่าง กรุณาระบุใน「สถานะทรัพย์」หรือหมายเหตุให้ชัดเจน '
        'เช่น วันที่ว่าง เงื่อนไขการส่งมอบ และช่วงเวลาที่ผู้สนใจเข้าอยู่ได้',
        'Please confirm the property is available as stated. '
        'If not yet vacant, specify under Property status or in notes — '
        'available date, handover terms, and expected move-in timing.',
      );
  String get propertyHonestyWarningMisuse => t(
        'ข้อมูลที่ไม่ถูกต้อง ไม่ครบถ้วน หรือไม่สอดคล้องกับความเป็นจริง '
        'อาจส่งผลให้ไม่ได้รับสิทธิ์ co-agent ค่าคอมมิชชันไม่เป็นไปตามเกณฑ์มาตรฐาน '
        'และระบบอาจพิจารณาจำกัดการลงประกาศหรือการเสนอทรัพย์',
        'Inaccurate, incomplete, or misleading information may affect co-agent eligibility, '
        'standard commission terms, and may result in limited access to posting or offering.',
      );
  String get offerDetailsVacancyHint => t(
        'ระบุสภาพทรัพย์ วันที่ว่าง และเงื่อนไขการส่งมอบ (โดยเฉพาะหากยังไม่ว่างทันที)',
        'Property condition, available date, and handover terms (if not vacant yet)',
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
  String get offerCustomerPhoneLast4Label => t(
        'เลข 4 ตัวท้ายเบอร์ลูกค้า *',
        'Customer phone — last 4 digits *',
      );
  String get offerCustomerPhoneLast4Hint => t(
        'ใช้รีเช็คข้อมูลซ้ำในระบบ (โคเอเจนหาให้ลูกค้า)',
        'For duplicate check (co-agent customer lead)',
      );
  String get offerCustomerPhoneLast4Invalid => t(
        'กรุณากรอกเลข 4 ตัวท้ายเบอร์ลูกค้าให้ครบ',
        'Enter the last 4 digits of the customer phone',
      );
  String get offerCustomerPhoneLast4Mismatch => t(
        'เลข 4 ตัวท้ายไม่ตรงกับข้อมูลลูกค้าของประกาศนี้',
        'Last 4 digits do not match this post’s customer record',
      );
  String get offerCustomerPhoneLast4Duplicate => t(
        'พบข้อมูลที่อาจซ้ำในระบบ — โปรดตรวจสอบก่อนส่งข้อเสนอ',
        'Possible duplicate found — please verify before submitting',
      );
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
        'ข้อเสนอของผู้อื่นไม่แสดงต่อสาธารณะ — เฉพาะทีม RealXtate ตรวจสอบ',
        'Other offers are private — RealXtate team reviews only',
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
        'ตามนโยบาย RealXtate (ตัวกลาง 100%)',
        'Accepting means you agree to the commission structure before coordinating, '
        'per RealXtate policy (100% intermediary)',
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
  String sharePhotosText(String code) => t('รูปทรัพย์ $code — RealXtate', 'Photos $code — RealXtate');

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
          'Hello — RealXtate team has received your request and will reply here.',
          'Viewing confirmed — staff will call again before the appointment.',
          'Price/owner matters need direct coordination — please share a contact number.',
          'Thank you — ask any follow-up questions in this chat.',
        ]
      : [
          'สวัสดีครับ ทีม RealXtate รับเรื่องแล้ว จะติดต่อกลับในแชทนี้ครับ',
          'ยืนยันนัดดูแล้วครับ เจ้าหน้าที่จะโทรยืนยันอีกครั้งก่อนถึงวันนัด',
          'เรื่องราคา/เจ้าของ ต้องให้เจ้าหน้าที่ประสานงานโดยตรง — ขอเบอร์ติดต่อที่สะดวกได้ครับ',
          'ขอบคุณครับ หากมีคำถามเพิ่มเติม แจ้งในแชทนี้ได้เลยครับ',
        ];

  String get adminReplyHint => t('พิมพ์คำตอบให้ลูกค้า...', 'Type a reply to the customer...');
  String get adminPendingMeta =>
      t('รอทีมงานตอบ — ลูกค้าเห็นคำตอบในแชทเดิม', 'Awaiting team reply — customer sees replies here');
  String get adminActiveMeta =>
      t('กำลังดูแล — ปิดเคสเมื่อจบงาน', 'In progress — close case when done');
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
  String get adminFaqTitle => t('ตั้งค่าตอบอัตโนมัติ', 'Auto-reply FAQ');
  String get adminFaqIntro => t(
        'แก้ข้อความตอบอัตโนมัติได้ทันที — ไม่ต้อง deploy\n'
        'ปิด switch เพื่อปิด rule ชั่วคราว',
        'Edit auto-replies instantly — no deploy needed\n'
        'Toggle off to disable a rule temporarily',
      );
  String get adminFaqEmpty => t('ยังไม่มีคำถามพบบ่อย — ต้องตั้งค่าฐานข้อมูลก่อน', 'No FAQ rules yet');
  String get adminFaqEditTitle => t('แก้คำตอบ', 'Edit reply');
  String get adminFaqReplyLabel => t('ข้อความตอบ', 'Reply text');
  String get adminFaqSettings => t('ตั้งค่าคำถามพบบ่อย', 'FAQ settings');
  String get adminConsoleTitle =>
      t('ศูนย์แชทหลังบ้าน (จอคอม)', 'Admin chat console (desktop)');
  String get adminConsolePickChat => t(
        'เลือกแชทจากรายการซ้ายเพื่อตอบลูกค้า\nEnter ส่งข้อความ · ปุ่มด้านบนปิดเคส',
        'Pick a chat from the inbox to reply\nEnter to send · use Close case when done',
      );
  String get adminOpenConsole =>
      t('เปิดโหมดคอม', 'Open desktop console');
  String get adminTabDashboard => t('ภาพรวมแพลตฟอร์ม', 'Platform overview');
  String get adminErpCommandCenter =>
      t('ศูนย์บัญชาการ', 'Command center');
  String get adminErpComms => t('สื่อสาร', 'Communications');
  String get adminErpCustomers => t('ลูกค้า', 'Customers');
  String get adminErpProperty => t('ทรัพย์สิน', 'Property');
  String get adminErpGovernance => t('ธรรมาภิบาล', 'Governance');
  String get adminErpMoreMenu => t('เพิ่มเติม', 'More');
  String get adminErpViewCalendar => t('ปฏิทิน', 'Calendar');
  String get adminErpViewList => t('รายการ', 'List');
  String get adminErpViewMap => t('แผนที่', 'Map');
  String get adminDashboardBarTitle =>
      t('ภาพรวมแพลตฟอร์ม', 'Platform overview');
  String get adminViewConsumerApp =>
      t('ดูแอปลูกค้า', 'View consumer app');
  String get adminMoreActions => t('เมนูเพิ่มเติม', 'More actions');
  String get adminRefresh => t('รีเฟรช', 'Refresh');
  String get adminPreviewBanner =>
      t('โหมดดูแอปลูกค้า (หลังบ้าน)', 'Consumer preview (admin)');
  String get adminBackToConsole => t('กลับหลังบ้าน', 'Back to admin');
  String get adminDashProjects => t('โครงการ', 'Projects');
  String get adminDashListings => t('ประกาศเผยแพร่', 'Published');
  String adminDashListingsSub(int total) =>
      t('ทั้งหมด $total', 'Total $total');
  String get adminDashLeads => t('เคสใหม่', 'New leads');
  String adminDashLeadsSub(int total) => t('รวม $total', 'Total $total');
  String get adminDashChat => t('แชทรอตอบ', 'Pending chat');
  String get adminDashAppointments => t('ปฏิทินนัดชม', 'Viewing calendar');
  String get adminTabAppointmentsList =>
      t('รายการนัด + แผนที่', 'List & map');
  String get adminDashOffers => t('ข้อเสนอรอ', 'Pending offers');
  String get adminDashModeration => t('ตรวจสอบ', 'Moderation');
  String adminDashModerationSub(int images, int flags) =>
      t('รูป $images · แจ้ง $flags', 'Photos $images · flags $flags');
  String get adminDashImports => t('นำเข้ารอ', 'Pending imports');
  String adminDashNeedsAction(int n) => t('ต้องทำ $n', '$n need action');
  String get adminDashSectionOps => t('งานประจำวัน', 'Daily operations');
  String get adminDashSectionCatalog => t('ข้อมูลหลัก', 'Catalog');
  String get adminDashSectionTrust => t('ความน่าเชื่อถือ', 'Trust & safety');
  String get adminDashSectionTrend => t('แนวโน้ม 7 วัน', '7-day trend');
  String get adminDashDemandPosts => t('บอร์ดเปิด', 'Open board posts');
  String get adminDashModImages => t('รูปรอตรวจ', 'Photos pending');
  String get adminDashModFlags => t('แจ้งผิดปกติ', 'Open flags');
  String get adminDashUsers => t('ผู้ใช้ทั้งหมด', 'All users');
  String get adminDashOpenTab => t('เปิดแท็บ →', 'Open tab →');
  String adminDashUpdated(String time) => t('อัปเดต $time', 'Updated $time');
  String adminDashTrendLine(String date, int leads, int appts) =>
      t('$date · เคส $leads · นัด $appts', '$date · leads $leads · viewings $appts');
  String get adminConsoleInboxHint => t(
        'กล่องรับงาน — เฉพาะเคสที่ต้องมีคนดูแล',
        'Inbox — human-needed cases only',
      );
  String get adminSendReply => t('ส่ง', 'Send');
  String get adminImportTitle => t('นำเข้าทรัพย์จากเว็บนอก', 'Import LI listings');
  String get adminTabImport => t('นำเข้า', 'Import');
  String get adminTabInventory => t('ทะเบียนทรัพย์', 'Inventory');
  String get adminTabProjects => t('โครงการ', 'Projects');
  String get adminTabPromos => t('โฆษณา', 'Promos');
  String get adminPromosSpecTitle => t('ขนาดรูปโฆษณา (ตามกรอบหน้าแรก)', 'Promo image size (home frame)');
  String adminPromosSpecBody(int w, int h) => t(
        'อัตราส่วน 21:9 · แนะนำ ${w}×${h} px · PNG/WebP/JPEG/GIF · ไม่เกิน 512 KB\n'
        'รูปจะถูก crop แบบ cover ในกรอบสูงสุด 124pt · GIF แสดงแอนิเมชันได้',
        'Aspect ratio 21:9 · recommended ${w}×${h} px · PNG/WebP/JPEG/GIF · max 512 KB\n'
        'Image is cover-cropped in a max 124pt-tall frame · GIFs animate',
      );
  String adminPromosActiveCount(int active, int max) =>
      t('เปิดใช้งาน $active / $max รายการ', '$active / $max active');
  String get adminPromosEmpty =>
      t('ยังไม่มีโฆษณา — กดเพิ่มด้านล่าง', 'No promos yet — tap Add below');
  String get adminPromosInactive => t('ปิด', 'Off');
  String get adminPromosMoveUp => t('เลื่อนขึ้น', 'Move up');
  String get adminPromosMoveDown => t('เลื่อนลง', 'Move down');
  String get adminPromosAdd => t('เพิ่มโฆษณา', 'Add promo');
  String get adminPromosEdit => t('แก้ไขโฆษณา', 'Edit promo');
  String get adminPromosMaxActive =>
      t('เปิดใช้งานได้สูงสุด 10 โฆษณา', 'Maximum 10 active promos');
  String get adminPromosDeleteTitle => t('ลบโฆษณา', 'Delete promo');
  String adminPromosDeleteBody(String title) =>
      t('ลบ "$title" ถาวร?', 'Permanently delete "$title"?');
  String get adminPromosNeedTitleOrImage => t(
        'กรอกหัวข้อหรืออัปโหลดรูปอย่างน้อยหนึ่งอย่าง',
        'Enter a title or upload an image',
      );
  String get adminPromosPreviewHome => t('บนหน้าแรก (carousel)', 'On home (carousel)');
  String get adminPromosPreviewHomeHint => t(
        'แสดงเฉพาะรูปในแถบเลื่อน — ไม่มีข้อความทับ',
        'Image only in the scroll strip — no text overlay',
      );
  String get adminPromosPreviewDetail => t('เมื่อผู้ใช้แตะการ์ด', 'When user taps the card');
  String get adminPromosSlugAuto => t('รหัส (สร้างอัตโนมัติ)', 'ID (auto-generated)');
  String get adminPromosSlugEdit => t('แก้รหัส', 'Edit ID');
  String get adminPromosSectionOptional => t('เพิ่มเติม (ไม่บังคับ)', 'Optional details');
  String get adminPromosSectionAdvanced => t('ตั้งค่าขั้นสูง', 'Advanced');
  String get adminPromosTitleThRequired => t('หัวข้อ (ไทย) *', 'Title (Thai) *');
  String get adminPromosSubtitleThOptional =>
      t('คำบรรยายสั้น (ไทย)', 'Short subtitle (Thai)');
  String get adminPromosDefaultTitle => t('โปรโมชั่น', 'Promotion');
  String get adminPromosPickCancelled => t('ยกเลิกเลือกรูป', 'Image pick cancelled');
  String get adminPromosUploadDone => t('อัปโหลดรูปแล้ว', 'Image uploaded');
  String get adminPromosUploadFailed => t('อัปโหลดไม่สำเร็จ — ตรวจ Supabase / bucket home-promo', 'Upload failed — check Supabase / home-promo bucket');
  String get adminPromosDetailPreviewHint =>
      t('(ยังไม่มีรายละเอียด)', '(No detail yet)');
  String get adminPromosUploadImage => t('อัปโหลดรูป', 'Upload image');
  String get adminPromosUploadHint => t(
        'ใช้รูป 21:9 ตามขนาดด้านบน — รองรับ GIF แอนิเมชัน · ถ้ายังไม่อัปโหลดจะใช้รูปในแอป (ถ้ามี)',
        'Use 21:9 image per spec above — animated GIF supported · bundled asset used if no upload',
      );
  String get adminPromosSlug => t('Slug (รหัส)', 'Slug (id)');
  String get adminPromosSort => t('ลำดับ (1–10)', 'Sort order (1–10)');
  String get adminPromosActive => t('เปิดใช้งาน', 'Active');
  String get adminPromosTitleTh => t('หัวข้อ (ไทย)', 'Title (Thai)');
  String get adminPromosTitleEn => t('หัวข้อ (อังกฤษ)', 'Title (English)');
  String get adminPromosSubtitleTh => t('คำบรรยายย่อ (ไทย)', 'Subtitle (Thai)');
  String get adminPromosSubtitleEn => t('คำบรรยายย่อ (อังกฤษ)', 'Subtitle (English)');
  String get adminPromosDetailTh => t('รายละเอียด (ไทย)', 'Detail (Thai)');
  String get adminPromosDetailEn => t('รายละเอียด (อังกฤษ)', 'Detail (English)');
  String get adminPromosBulletsTh => t('จุดเด่น (ไทย, บรรทัดละข้อ)', 'Bullets (Thai, one per line)');
  String get adminPromosBulletsEn => t('จุดเด่น (อังกฤษ)', 'Bullets (English)');
  String get adminPromosBulletsHint =>
      t('หนึ่งบรรทัดต่อหนึ่งข้อ', 'One bullet per line');
  String get adminPromosGradientStart => t('สีไล่เริ่ม (#hex)', 'Gradient start (#hex)');
  String get adminPromosGradientEnd => t('สีไล่จบ (#hex)', 'Gradient end (#hex)');
  String get adminPromosAccent => t('สีเน้น (#hex)', 'Accent (#hex)');
  String get adminProjectsIntro => t(
        'สมุดชื่อโครงการ — เพิ่มเองหรือดึงจากลิงก์ Property Hub / LI',
        'Project registry — add manually or import from Property Hub / LI',
      );
  String get adminProjectsManualTitle => t('เพิ่มโครงการด้วยมือ', 'Add project manually');
  String get adminProjectsManualHint => t(
        'กรอกชื่อ · เขต · พิกัด · BTS — ไม่ต้องมีลิงก์ภายนอก',
        'Enter name, district, coordinates, BTS — no external link required',
      );
  String get adminProjectsManualBtn => t('เปิดฟอร์มกรอกเอง', 'Open manual form');
  String get adminProjectsFormSectionBasic => t('ข้อมูลหลัก', 'Basic info');
  String get adminProjectsFormSectionLocation => t('ที่ตั้งและพิกัด', 'Location');
  String get adminProjectsFormSectionExtra => t('รายละเอียดเพิ่ม', 'Extra details');
  String get adminProjectsSourceUrl => t('ลิงก์อ้างอิง (ไม่บังคับ)', 'Reference URL (optional)');
  String get adminProjectsSourceUrlHint => t(
        'Property Hub หรือ Living Insider — กดดึงมาเติมฟอร์ม',
        'Property Hub or LI — tap fetch to prefill',
      );
  String get adminProjectsPrefillBtn => t('ดึงมาเติมฟอร์ม', 'Fetch to prefill form');
  String get adminProjectsPrefillDone => t('เติมข้อมูลจากลิงก์แล้ว — ตรวจก่อนบันทึก', 'Prefilled from link — review before save');
  String get adminProjectsImportUnsupported => t(
        'ลิงก์ไม่รองรับ — ใช้ propertyhub.in.th/projects/... หรือ livinginsider.com\n'
        'หรือกด「เพิ่มด้วยมือ」',
        'Unsupported link — use Property Hub or Living Insider, or add manually',
      );
  String get adminProjectsNeedSupabase => t(
        'บันทึกลงคลาวด์ไม่ได้ — ตรวจการเชื่อมระบบและล็อกอินบัญชีหลังบ้าน',
        'Cannot save to cloud — check connection and admin login',
      );
  String get adminProjectsImportTitle =>
      t('ดึงโครงการจากลิงก์', 'Import project from link');
  String get adminProjectsImportUrlLabel =>
      t('ลิงก์หน้าโครงการ', 'Project page URL');
  String get adminProjectsImportUrlHintAny => t(
        'Property Hub: propertyhub.in.th/projects/...\n'
        'Living Insider: livinginsider.com/...',
        'Property Hub or Living Insider project URL',
      );
  String get adminProjectsPropertyHubOnly => adminProjectsImportUnsupported;
  String get adminProjectsBulkTitle =>
      t('เติมสมุดโครงการจาก Property Hub', 'Fill catalog from Property Hub');
  String get adminProjectsBulkHint => t(
        'ค้นหารายชื่อแล้วดึงรายละเอียดทีละชุด — ใช้เวลาสักพัก',
        'Find project names then import details in batches',
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
  String get adminProjectsEnrichTagsTitle =>
      t('อัปเดตแท็กค้นหามาตรฐาน', 'Refresh standard search tags');
  String get adminProjectsEnrichTagsHint => t(
        'คำนวณจากพิกัดโครงการ (BTS/โซน/มหาลัย/landmark) — ไม่ใช้ AI · รายการที่ขัดกันจะเป็น needs_review',
        'Computed from project coordinates (transit/zone/POI) — no AI · mismatches marked needs_review',
      );
  String get adminProjectsEnrichTagsBtn =>
      t('อัปเดตแท็กทุกโครงการ', 'Enrich tags for all projects');
  String get adminProjectsEnrichTagsBody => t(
        'ระบบจะคำนวณแท็กมาตรฐานให้โครงการทุกรายการจากพิกัดและชื่อ\n'
        'โครงการที่พิกัดผิดหรือข้อมูลขัดกันจะถูกทำเครื่องหมาย needs_review',
        'Standard tags will be computed for every project from coordinates and names.\n'
        'Projects with bad coords or conflicts will be marked needs_review.',
      );
  String get adminProjectsEnrichTagsConfirm => t('เริ่มอัปเดต', 'Start update');
  String adminProjectsEnrichTagsDone(int updated, int needsReview) => t(
        'อัปเดตแท็กแล้ว $updated โครงการ · ต้องตรวจ $needsReview',
        'Updated $updated projects · $needsReview need review',
      );
  String adminProjectsTagCount(int n) =>
      t('แท็กค้นหา $n รายการ', '$n search tags');

  String get adminProjectsResetTitle => t('รีเซ็ตสมุดโครงการ', 'Reset project catalog');
  String get adminProjectsResetHint => t(
        'ลบสมุดโครงการทั้งหมดในระบบ — เฉพาะ CEO',
        'Delete the entire project catalog — CEO only',
      );
  String get adminProjectsResetBtn => t('ลบสมุดโครงการทั้งหมด', 'Delete entire catalog');
  String get adminProjectsResetConfirmTitle => t('ยืนยันรีเซ็ตสมุดโครงการ?', 'Reset entire catalog?');
  String get adminProjectsResetConfirmBody => t(
        'จะลบโครงการทุกรายการในระบบ (ประกาศที่ผูกโครงการจะถูกถอดลิงก์ ไม่ลบประกาศ)\n'
        'หลังลบให้เพิ่มโครงการทีละรายการหรือนำเข้าจากลิงก์',
        'All projects will be deleted (listings unlinked, not deleted). '
        'Add projects again one by one or import from URLs.',
      );
  String get adminProjectsResetConfirmBtn => t('ลบทั้งหมด', 'Delete all');
  String get adminProjectsResetCeoOnly =>
      t('รีเซ็ตสมุดโครงการ — เฉพาะ CEO', 'Reset catalog — CEO only');
  String get adminProjectsResetCancel => t('ยกเลิก', 'Cancel');
  String adminProjectsResetDone(int deleted, int unlinked) => t(
        'ลบโครงการ $deleted รายการ · ถอดลิงก์ประกาศ $unlinked รายการ',
        'Deleted $deleted projects · unlinked $unlinked listings',
      );
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
  String get adminProjectsCoordsInvalid => t('พิกัดละติจูด/ลองจิจูดไม่ถูกต้อง', 'Invalid Lat/Lng');
  String get adminProjectsNameTh => t('ชื่อโครงการ (ไทย)', 'Project name (Thai)');
  String get adminProjectsNameEn => t('ชื่อโครงการ (EN)', 'Project name (EN)');
  String get adminProjectsSlug => t('รหัสลิงก์ (ย่อ)', 'Slug (URL id)');
  String get adminProjectsSlugHint => t('ว่างไว้ = สร้างอัตโนมัติ', 'Leave blank to auto-generate');
  String get adminProjectsBts => t('BTS / MRT ใกล้เคียง', 'Nearby BTS / MRT');
  String get adminProjectsBtsHint => t(
        'ว่างไว้ = ระบบหาจากพิกัดอัตโนมัติ',
        'Leave blank to auto-detect from coordinates',
      );
  String get adminProjectsNearbyTransitHint => t(
        'สถานีด้านบนคำนวณจากพิกัด + รายละเอียด (ระยะเดินโดยประมาณ ≤ 1 กม.)',
        'Stations from coords + description (walk ~≤1 km)',
      );
  String get adminProjectsRefreshTransit => t('หาสถานีจากพิกัด', 'Detect stations from coords');
  String get adminProjectsTagsSelected => t('แท็กที่เลือก (แตะ ✕ เพื่อลบ)', 'Selected tags (tap ✕ to remove)');
  String get adminProjectsTagsSuggest => t('แนะนำเพิ่ม (แตะเพื่อเลือก)', 'Suggested (tap to add)');
  String get adminProjectsTagsEmpty => t('ยังไม่มีแท็ก — กดหาสถานีจากพิกัด', 'No tags yet — detect from coords');
  String get adminProjectsAliases => t('ชื่ออื่น (คั่นด้วย ,)', 'Aliases (comma-separated)');
  String get adminProjectsDesc => t('รายละเอียดโครงการ', 'Project description');
  String get adminProjectsActivate => t('เปิดใช้', 'Activate');
  String get adminProjectsDeactivate => t('ปิดใช้', 'Deactivate');
  String get adminImportIntro => t(
        'วางลิงก์สาธารณะทีละ 1 รายการ (LI / Facebook / เว็บอื่น) → ดึงข้อมูล + รูป → ตรวจแก้ → เผยแพร่\n'
        'เบอร์/Line ถูกตัดออกอัตโนมัติ · บางลิงก์ (เช่น FB) อาจดึงไม่ครบ — แก้มือก่อนอนุมัติ',
        'One public link at a time (LI / Facebook / other sites) → fetch → review & edit → publish\n'
        'Phone/Line stripped · Some links (e.g. FB) may be partial — edit before approve',
      );
  String get adminImportPaste => t('วางจากคลิปบอร์ด', 'Paste clipboard');
  String get adminImportFetchAll => t('ดึงข้อมูลทั้งหมด', 'Fetch all');
  String get adminImportFetchOne => t('ดึงข้อมูล', 'Fetch');
  String get adminImportSingleUrlLabel =>
      t('ลิงก์อ้างอิง (ทีละ 1 รายการ)', 'Reference link (one at a time)');
  String get adminImportUnsupportedUrl => t(
        'ลิงก์ไม่ถูกต้อง — ใช้ http(s):// ที่เข้าถึงสาธารณะได้',
        'Invalid link — use a public http(s):// URL',
      );
  String adminImportFetchedFor(String source) => t(
        'ดึงจาก $source แล้ว — ตรวจสอบก่อนเผยแพร่',
        'Fetched from $source — review before publishing',
      );
  String adminImportSourceLabel(String platform) {
    switch (platform) {
      case 'livinginsider':
        return t('Living Insider', 'Living Insider');
      case 'facebook':
        return t('Facebook', 'Facebook');
      default:
        return t('เว็บทั่วไป', 'Generic web');
    }
  }

  String adminImportParseWarnings(List<String> flags) {
    final parts = <String>[];
    if (flags.contains('facebook_login_wall')) {
      parts.add(t(
        'Facebook อาจต้อง login — กรอก/แก้ข้อมูลมือ',
        'Facebook may require login — fill in manually',
      ));
    }
    if (flags.contains('missing_price')) {
      parts.add(t('ไม่พบราคา — ใส่ราคาก่อนเผยแพร่', 'Price missing — set before publish'));
    }
    if (flags.contains('missing_images')) {
      parts.add(t('ไม่พบรูป — อัปโหลดหรือลองดึงใหม่', 'No images — upload or retry fetch'));
    }
    if (flags.contains('project_not_in_registry')) {
      parts.add(t(
        'ไม่พบโครงการในฐานข้อมูล — วางลิงก์แชร์แผนที่เพื่อปักพิกัด',
        'Project not in registry — paste a map share link to set coordinates',
      ));
    }
    if (flags.contains('missing_project') || flags.contains('missing_coords')) {
      parts.add(t(
        'ยังไม่ปักโครงการ/พิกัด — เพิ่มโครงการก่อนเผยแพร่',
        'Project or pin missing — add project before publish',
      ));
    }
    if (flags.contains('duplicate_import')) {
      parts.add(t(
        'ซ้ำกับรายการที่นำเข้าแล้ว — เปิดรายการเดิมหรือล้างรายการนี้',
        'Duplicate of an existing import — open original or discard this row',
      ));
    }
    if (flags.contains('facebook_source')) {
      parts.add(t(
        'ดึงจาก Facebook — ตรวจข้อความโพสต์/รูป/ลิงก์ในโพสต์',
        'Fetched from Facebook — verify post text, photos, and links',
      ));
    }
    if (flags.contains('generic_og_parse') || flags.contains('needs_admin_review')) {
      parts.add(t(
        'ดึงจาก Open Graph — ตรวจหัวข้อ/รายละเอียด/ราคาให้ครบ',
        'Parsed via Open Graph — verify title, details, price',
      ));
    }
    if (parts.isEmpty) {
      return t('ตรวจสอบข้อมูลก่อนเผยแพร่', 'Review all fields before publishing');
    }
    return parts.join(' · ');
  }
  String get adminImportReviewTitle =>
      t('ตรวจสอบก่อนเผยแพร่', 'Review before publish');
  String get adminImportReviewHint => t(
        'แก้ไขข้อมูลได้ก่อนกดอนุมัติ — รูปถูกดึงจากลิงก์ต้นทางแล้ว',
        'Edit fields before approve — photos already imported from source link',
      );
  String get adminImportSaveDraft => t('บันทึก draft', 'Save draft');
  String get adminImportDraftSaved => t('บันทึก draft แล้ว', 'Draft saved');
  String get adminImportRefetched => t('ดึงข้อมูลใหม่แล้ว', 'Re-fetched from LI');
  String get adminImportNoDraft =>
      t('ยังไม่มี draft — กดดึงข้อมูลก่อน', 'No draft yet — fetch first');
  String get adminImportPriceRequired =>
      t('ใส่ราคาที่ถูกต้องก่อนเผยแพร่', 'Enter a valid price before publishing');
  String get adminImportReviewOpen => t('ตรวจสอบ / แก้ไข', 'Review / edit');
  String get adminImportView => t('ดูรายละเอียด', 'View details');
  String get adminImportBedrooms => t('ห้องนอน', 'Bedrooms');
  String get adminImportProjectName => t('ชื่อโครงการ', 'Project name');
  String get adminImportProjectNotFound =>
      t('ไม่พบโครงการในฐานข้อมูล', 'Project not found in registry');
  String get adminImportProjectNotFoundHint => t(
        'ชื่อโครงการดึงจาก LI แล้ว — เปิด Google Maps ค้นหาพิกัดจริง แชร์ลิงก์มาวาง แล้วตรวจก่อนยืนยัน',
        'Project name from LI — find the pin in Google Maps, paste the share link, review, then confirm',
      );
  String get adminImportAddProjectFromMaps =>
      t('เพิ่มโครงการ (วางลิงก์แผนที่)', 'Add project (paste map link)');
  String get adminImportAddProjectTitle =>
      t('เพิ่มโครงการ — วางลิงก์แชร์แผนที่', 'Add project — paste map share link');
  String get adminImportAddProjectHint => t(
        'ลิงก์แผนที่เติมเฉพาะพิกัด — ชื่อและเขตจาก LI ให้ตรวจก่อนกดยืนยัน',
        'Map link fills coordinates only — review LI name and district before confirming',
      );
  String get adminImportMapsShareLink =>
      t('ลิงก์แชร์ Google Maps', 'Google Maps share link');
  String get adminImportMapsShareLinkHint => t(
        'https://maps.app.goo.gl/... หรือ google.com/maps/...',
        'https://maps.app.goo.gl/... or google.com/maps/...',
      );
  String get adminImportApplyMapsLink =>
      t('ดึงพิกัดจากลิงก์', 'Apply coordinates from link');
  String get adminImportMapsShareSteps => t(
        '1) เปิด Google Maps ค้นหาโครงการ · 2) กดแชร์ → คัดลอกลิงก์ · 3) วางด้านบนแล้วกดดึงพิกัด',
        '1) Open Google Maps and find the project · 2) Share → copy link · 3) Paste above and apply coordinates',
      );
  String get adminImportMapsLinkInvalid => t(
        'ลิงก์ไม่ใช่ Google Maps — ใช้ลิงก์จากปุ่มแชร์ในแอปแผนที่',
        'Not a Google Maps link — use the share link from the Maps app',
      );
  String get adminImportMapsLinkNoCoords => t(
        'ไม่พบพิกัดในลิงก์ — ลองแชร์จากหมุดบนแผนที่ (ไม่ใช่แค่ชื่อสถานที่)',
        'No coordinates in link — share from the map pin, not just a place name',
      );
  String get adminImportMapsCoordsApplied => t(
        'ปักพิกัดจากลิงก์แล้ว — ตรวจชื่อโครงการก่อนยืนยัน',
        'Coordinates applied from link — review project name before confirming',
      );
  String get adminImportMapsLinkResolveFailed => t(
        'เปิดลิงก์สั้นไม่ได้ — ลองคัดลอกลิงก์เต็มจาก Google Maps',
        'Could not resolve short link — try the full Google Maps URL',
      );
  String get adminImportCoordsFromLinkOnly => t(
        'พิกัดจากลิงก์แผนที่ — ชื่อโครงการไม่ถูกเปลี่ยนอัตโนมัติ',
        'Coordinates from map link — project name was not auto-changed',
      );
  String get adminImportProjectNameTh => t('ชื่อโครงการ (ไทย)', 'Project name (TH)');
  String get adminImportProjectNameEn => t('ชื่อโครงการ (อังกฤษ)', 'Project name (EN)');
  String get adminImportOpenGoogleMaps =>
      t('เปิดใน Google Maps', 'Open in Google Maps');
  String get adminImportConfirmAddProject =>
      t('ยืนยันเพิ่มโครงการ', 'Confirm add project');
  String get adminImportProjectLinked =>
      t('เพิ่มโครงการและผูกกับประกาศแล้ว', 'Project added and linked to listing');
  String get adminImportProjectNameRequired =>
      t('ใส่ชื่อโครงการ', 'Enter project name');
  String get adminImportCoordsRequired =>
      t('ใส่พิกัด Lat/Lng ให้ถูกต้อง', 'Enter valid Lat/Lng');
  String get adminImportFetchedProjectMissing => t(
        'ดึงประกาศแล้ว — ไม่พบโครงการในฐานข้อมูล กดเพิ่มโครงการในหน้าตรวจสอบ',
        'Listing fetched — project not in registry. Add it on the review screen.',
      );
  String get adminImportDistrict => t('เขต / ทำเล', 'District / area');
  String get adminImportTxnType => t('ประเภทธุรกรรม', 'Transaction type');
  String get adminImportPropertyType => t('ประเภททรัพย์', 'Property type');
  String get adminImportNeedUrl => t('ใส่ลิงก์ LI', 'Paste an LI link');
  String adminImportBatchDone(int ok, int fail) => t(
        'ดึงสำเร็จ $ok · ล้มเหลว $fail',
        'Fetched $ok · failed $fail',
      );
  String get adminImportSlotsTitle => t('ช่องวางลิงก์', 'Link slots');
  String adminImportUrlHint(int n) => t('ลิงก์ LI #$n', 'LI link #$n');
  String get adminImportBulkLabel => t('วางหลายลิงก์ (บรรทัดละ 1)', 'Bulk paste (one per line)');
  String get adminImportBulkHint => t(
        'https://www.livinginsider.com/istockdetail/...\n'
        'https://www.facebook.com/groups/.../posts/...',
        'https://www.livinginsider.com/istockdetail/...\n'
        'https://www.facebook.com/groups/.../posts/...',
      );
  String adminImportQueueTitle(int n) => t('คิวนำเข้า ($n)', 'Import queue ($n)');
  String get adminImportShowArchived => t('แสดงจัดเก็บ', 'Show archived');
  String get adminImportEmpty => t(
        'ยังไม่มีรายการ — วางลิงก์ด้านบนแล้วกดดึงข้อมูล (ทีละ 1 ลิงก์)',
        'No imports yet — paste one link above and fetch',
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
  String get adminImportDuplicateTitle =>
      t('ซ้ำกับรายการที่นำเข้าแล้ว', 'Duplicate of existing import');
  String get adminImportDuplicateHint => t(
        'ระบบพบลิงก์หรือรหัส LI เดิม — เปิดรายการเดิมเพื่อเผยแพร่ต่อ หรือล้างรายการซ้ำนี้',
        'Same link or LI id already imported — open the original to publish, or discard this duplicate',
      );
  String get adminImportContinuePublish =>
      t('เผยแพร่ต่อ (รายการเดิม)', 'Continue publish (original)');
  String get adminImportOpenOriginal =>
      t('เปิดรายการเดิม', 'Open original import');
  String get adminImportOpenInStock =>
      t('เปิดในคลังทรัพย์', 'Open in listings');
  String get adminImportOpenSourceLink =>
      t('เปิดลิงก์ต้นทาง', 'Open source link');
  String get adminImportDiscardDuplicate =>
      t('ยกเลิกและล้างข้อมูล', 'Discard & purge');
  String get adminImportDiscardConfirm => t(
        'ล้างรายการนำเข้านี้และ draft ที่สร้างจากการดึงซ้ำ?',
        'Discard this import row and purge its draft listing?',
      );
  String get adminImportDiscarded =>
      t('ล้างรายการซ้ำแล้ว', 'Duplicate import discarded');
  String adminImportDuplicateOf(String label) =>
      t('ซ้ำกับ: $label', 'Duplicate of: $label');
  String get adminImportFacebookSection =>
      t('ข้อมูลจาก Facebook', 'Facebook post data');
  String get adminImportSourceMetaSection =>
      t('ข้อมูลจากลิงก์ต้นทาง', 'Source link data');
  String get adminImportFacebookPoster =>
      t('ผู้โพสต์', 'Posted by');
  String get adminImportFacebookPost =>
      t('ข้อความในโพสต์', 'Post text');
  String get adminImportFacebookLinks =>
      t('ลิงก์ในโพสต์', 'Links in post');
  String get adminImportOpenPostLink =>
      t('เปิดลิงก์โพสต์', 'Open post link');
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
  String get adminInboxRequirement =>
      t('ความต้องการหาทรัพย์', 'Property need');
  String get adminSendRequirementFormBtn =>
      t('ส่งฟอร์มหาทรัพย์', 'Send need form');
  String get adminSendViewingFormBtn =>
      t('ส่งฟอร์มนัดดู', 'Send viewing form');
  String get adminSendRequirementFormMessage => t(
        'รบกวนกรอกความต้องการหาทรัพย์ด้านล่างครับ ทีมจะช่วยหาเพิ่มให้ตรงเงื่อนไข',
        'Please fill in your property needs below — we will find more matches for you.',
      );
  String get adminSendViewingFormMessage => t(
        'รบกวนกรอกแบบฟอร์มนัดดูด้านล่างครับ ทีมจะประสานนัดให้',
        'Please complete the viewing request form below — we will arrange a visit.',
      );
  String get adminSendListingCardsTitle =>
      t('ส่งการ์ดทรัพย์ในแชท', 'Send listing cards');
  String get adminSendListingCardsHint =>
      t('ค้นหารหัส PIR / ชื่อ / โครงการ', 'Search PIR code / title / project');
  String adminSendListingCardsConfirm(int n) =>
      t('ส่ง $n การ์ด', 'Send $n cards');
  String get chatDiscoveryEntryHint => t(
        'บอกทำเล งบ โครงการ — ทีมช่วยคัดทรัพย์ให้',
        'Tell area, budget & project — we match listings for you',
      );
  String get chatLinkViewListing => t('ดูรายละเอียด', 'View details');
  String get chatLinkAskListing => t('ถามห้องนี้', 'Ask about this room');
  String get chatLinkFillRequirement =>
      t('กรอกความต้องการหาทรัพย์', 'Fill property need form');
  String get chatLinkBookViewing =>
      t('กรอกแบบฟอร์มนัดดู', 'Fill viewing request form');
  String get chatLinkViewingLocation =>
      t('เปิดพิกัดจุดนัดชม', 'Open viewing location');
  String get chatLinkViewingLocationOpenFailed =>
      t('เปิดแผนที่ไม่สำเร็จ', 'Could not open map');
  String get chatLinkViewingAppointment =>
      t('บันทึกการนัดชม', 'Viewing appointment record');
  String chatLinkViewingAppointmentNotFound(String id) =>
      t('ไม่พบบันทึกนัดชม $id', 'Viewing record $id not found');
  String get chatLinkViewingAppointmentDetailTitle =>
      t('รายละเอียดนัดชม', 'Viewing appointment details');
  String get chatLinkViewingAppointmentGuide =>
      t('เอเจ้นพาดู', 'Guide');
  String chatLinkTagNotFound(String code) =>
      t('ไม่พบแท็ก $code', 'Tag $code not found');
  String chatLinkViewingNotFound(String code) =>
      t('ไม่พบคำขอ $code', 'Request $code not found');
  String get chatLinkTagDetailTitle =>
      t('รายละเอียดแท็กโปรไฟล์', 'Profile tag details');
  String get chatLinkViewingDetailTitle =>
      t('รายละเอียดคำขอนัดดู', 'Viewing request details');
  String get chatLinkTagRole => t('ประเภทแท็ก', 'Tag type');
  String get chatLinkTagSubject => t('ชื่อในคำขอ', 'Subject name');
  String get chatLinkTagVersion => t('เวอร์ชัน', 'Version');
  String get chatLinkTagCreated => t('สร้างเมื่อ', 'Created');
  String get chatLinkTagSnapshot => t('ข้อมูลในแท็ก', 'Tag snapshot');
  String get chatLinkViewingListing => t('ทรัพย์', 'Listing');
  String get chatLinkViewingPlace => t('จุดนัดชม', 'Meeting point');
  String get chatLinkViewingProject => t('โครงการ', 'Project');
  String get chatLinkViewingSchedule => t('วันเวลานัด', 'Scheduled');
  String get chatLinkViewingStatus => t('สถานะ', 'Status');
  String get chatLinkFieldNickname => t('ชื่อเล่น', 'Nickname');
  String get chatLinkFieldPhone => t('เบอร์โทร', 'Phone');
  String get chatLinkFieldOccupants => t('จำนวนผู้เข้าพัก', 'Occupants');
  String get chatLinkFieldOccupation => t('อาชีพ', 'Occupation');
  String get chatLinkFieldContract => t('สัญญา', 'Contract');
  String get chatLinkFieldBudget => t('งบประมาณ', 'Budget');
  String get chatLinkFieldWorkplace => t('ที่ทำงาน', 'Workplace');
  String get chatLinkFieldDisplayName => t('ชื่อแสดง', 'Display name');
  String get chatLinkFieldAgency => t('สังกัด', 'Agency');
  String get chatLinkFieldLicense => t('เลขใบอนุญาต', 'License no.');
  String get chatLinkTapToOpen => t('แตะเพื่อดูรายละเอียด', 'Tap to view details');
  String get requirementOpenChat =>
      t('เปิดแชทเคสนี้', 'Open case chat');
  String get adminPromoteOfferToListing =>
      t('สร้างประกาศ PIR จากข้อเสนอ', 'Create PIR listing from offer');
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
  String adminInboxCheckMine(int n) => t(
        'มีงานของคุณ $n เคส — ดูแท็บ「งานของฉัน」',
        'You have $n assigned chat(s) — check the Mine tab',
      );
  String chatUnreadCount(int n) => t('$n ข้อความใหม่', '$n new');
  String get chatTeamReplyWaiting => t(
        'ทีมงานตอบกลับแล้ว — แตะเพื่ออ่าน',
        'Team replied — tap to read',
      );
  String get adminInboxEmptyMine => t(
        'ยังไม่มีงานของคุณ — กด「รับงาน」จากแท็บรอรับงาน',
        'Nothing assigned to you — claim from the Unclaimed tab',
      );
  String get adminInboxEmptyResolved => t(
        'ยังไม่มีเคสปิด — กด「ปิดเคส」หลังตอบลูกค้า',
        'No closed cases yet — tap「Close case」after replying',
      );
  String get adminInboxRoleDirect => t('ลูกค้าตรง', 'Direct customer');
  String get adminInboxRoleAgent => t('เอเจนต์', 'Agent');
  String get adminInboxIntentViewing =>
      t('สนใจนัดดูทรัพย์', 'Interested in viewing');
  String get adminInboxIntentProperty =>
      t('สนใจทรัพย์', 'Interested in listing');
  String get adminInboxIntentDiscovery =>
      t('ค้นหา/สอบถามทรัพย์', 'Property search');
  String get adminInboxIntentGeneral =>
      t('สอบถามข้อมูลทั่วไป', 'General inquiry');
  String get adminInboxIntentBooking =>
      t('สนใจจองด่วน', 'Urgent booking');
  String get adminInboxIntentOffer => t('เสนอทรัพย์', 'Listing offer');
  String get adminInboxIntentRequirement =>
      t('ฝากความต้องการ', 'Requirement post');
  String get adminInboxIntentEscalation =>
      t('ขอคุยกับทีมงาน', 'Needs staff');
  String get adminInboxIntentAgentInterest =>
      t('เอเจนต์สนใจโครงการ', 'Agent project interest');
  String get adminInboxNoPreview =>
      t('ยังไม่มีข้อความจากลูกค้า', 'No customer message yet');
  String get adminInboxPreviewViewingSubmitted => t(
        'ส่งคำขอนัดดูแล้ว — รอทีมงานตอบ',
        'Viewing request sent — awaiting reply',
      );
  String get adminInboxSortRecentFirst => t('ล่าสุดบน', 'Newest on top');
  String get adminInboxSortOldestWaiting =>
      t('รอนานสุดบน', 'Longest wait on top');
  String get adminInboxFilterAll => t('ทั้งหมด', 'All');
  String get adminInboxFilterAgent => t('AGENT', 'AGENT');
  String get adminInboxFilterDirect => t('DIRECT', 'DIRECT');
  String get adminInboxFilterCoAgent =>
      t('ลูกค้าโคเอเจนซี่', 'Co-agency customer');
  String get adminInboxRoleCoAgencyCustomer =>
      t('ลูกค้าของโคเอเจนซี่', 'Co-agency customer');
  String get adminInboxFilterViewing => t('นัดดู', 'Viewing');
  String get adminInboxFilterProperty => t('สนใจทรัพย์', 'Property');
  String get adminInboxFilterGeneral => t('สอบถามทั่วไป', 'General');
  String get adminInboxFilterUrgent => t('ด่วน', 'Urgent');
  String get adminInboxFilterHint =>
      t('กรองก่อนรับงาน', 'Filter before claim');
  String adminInboxEmptyFiltered(int n) => t(
        'ไม่มีแชทตรงตัวกรอง — ทั้งหมด $n เคส',
        'No chats match filter — $n total',
      );
  String get adminChatRenameTitle => t('ตั้งชื่อแชท', 'Rename chat');
  String get adminChatRenameHint => t(
        'ชื่อนี้แสดงเฉพาะทีมแอดมิน — ลูกค้าไม่เห็น',
        'Visible to admins only — customers do not see this',
      );
  String get adminChatRenameLabel => t('ชื่อแชท', 'Chat name');
  String get adminChatRenamePlaceholder =>
      t('เช่น Mint Patcha — ลูกค้า VIP', 'e.g. Mint Patcha — VIP');
  String get adminChatRenameClear => t('ล้างชื่อ', 'Clear name');
  String get adminChatSearchTitle => t('ค้นหาข้อความในแชท', 'Search chat messages');
  String get adminChatSearchHint =>
      t('พิมพ์คำค้น (อย่างน้อย 2 ตัวอักษร)', 'Type to search (min 2 chars)');
  String get adminChatSearchMinChars => t(
        'พิมพ์อย่างน้อย 2 ตัวอักษร',
        'Enter at least 2 characters',
      );
  String get adminChatSearchEmpty =>
      t('ไม่พบข้อความที่ตรงกัน', 'No matching messages');
  String get adminClaimWork => t('รับงาน', 'Claim');
  String get adminAssignWork => t('มอบหมาย', 'Assign');
  String get adminAssignTo => t('มอบหมายให้', 'Assign to');
  String adminClaimedBy(String name) => t('ดูแล: $name', 'Owner: $name');
  String get adminNeedsClaim => t('ยังไม่รับ', 'Unclaimed');
  String get adminMustClaimFirst => t(
        'กด「รับงาน」ก่อนตอบลูกค้า',
        'Tap「Claim」before replying',
      );
  String get adminReturningCustomerTitle =>
      t('ลูกค้ารายเดิม', 'Returning customer');
  String adminReturningCustomerBanner(String adminName, String roomTitle) => t(
        'ลูกค้ารายนี้กำลังคุยกับ $adminName อยู่ที่「$roomTitle」— แนะนำให้ $adminName รับเคสนี้ต่อ',
        'This customer is with $adminName in「$roomTitle」— let $adminName continue',
      );
  String adminReturningCustomerBannerSelf(String roomTitle) => t(
        'คุณกำลังดูแลลูกค้ารายนี้ใน「$roomTitle」อยู่ — แนะนำให้รับเคสนี้ต่อเอง',
        'You are handling this customer in「$roomTitle」— claim this case yourself',
      );
  String adminReturningCustomerClaimPrompt(String adminName, String roomTitle) =>
      t(
        'ลูกค้ารายนี้มีเคสค้างกับ $adminName ที่「$roomTitle」\nยืนยันรับงานห้องนี้?',
        'This customer has an open case with $adminName in「$roomTitle」\nClaim this room anyway?',
      );
  String adminReturningCustomerClaimPromptSelf(String roomTitle) => t(
        'คุณกำลังดูแลลูกค้ารายนี้ใน「$roomTitle」อยู่\nรับเคสห้องนี้ต่อเลย?',
        'You are already handling this customer in「$roomTitle」\nClaim this room too?',
      );
  String adminReturningCustomerChip(String adminName) =>
      t('ลูกค้าเดิม · $adminName', 'Returning · $adminName');
  String get adminReturningCustomerOpenOther =>
      t('เปิดแชทเดิม', 'Open prior chat');
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
  String adminLifecycleResult(String result) => t('ผลวงจรประกาศ: $result', 'Lifecycle: $result');
  String get adminLifecycleSubtitle => t(
        'หมดอายุ / ซ่อนประกาศที่ไม่อัปเดตสถานะ 30 วัน — ตั้งงานอัตโนมัติรายวัน',
        'Expire / hide listings not bumped in 30 days — schedule listing-lifecycle-cron daily',
      );
  String adminPhotosPending(int n) => t('รูปรอตรวจ ($n)', 'Photos pending ($n)');
  String adminFlagsSection(int n) => t('แจ้งผิดปกติ ($n)', 'Flags ($n)');
  String get adminResolveFlag => t('ปิดเรื่องแจ้ง', 'Resolve flag');
  String get adminHideListing => t('ซ่อนประกาศ', 'Hide listing');
  String get adminDefaultProperty => t('ทรัพย์', 'Property');
  String get adminConfirmViewingTitle => t('ยืนยันนัดดูทรัพย์', 'Confirm property viewing');
  String get adminTimeSlotLabel => t('ช่วงเวลา', 'Time slot');
  String get adminNotesLabel => t('หมายเหตุทีมงาน', 'Admin notes');
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
        'ยังไม่มีนัดชม — เปิดเคสลูกค้าแล้วกด「ประสานงาน / ยืนยันนัดดู」',
        'No viewings yet — open a Lead and tap「Coordinate / confirm viewing」',
      );
  String get adminConfirmAppointment => t('ยืนยัน', 'Confirm');
  String get adminConfirmGuideAppointment =>
      t('ยืนยันเอเจ้นพาดู', 'Confirm guide');
  String get adminCompleteAppointment => t('เสร็จสิ้น', 'Complete');
  String get adminNeedRole => t(
        'ต้องเป็นผู้ดูแลระบบในฐานข้อมูล\n(ตั้งสิทธิ์ในหน้าจัดการผู้ใช้)',
        'Requires role = admin in Supabase profiles\n(Set in Table Editor or SQL)',
      );
  String get adminTabChat => t('แชท', 'Chat');
  String get adminTabOffers => t('ข้อเสนอ', 'Offers');
  String get adminTabLeads => t('เคสลูกค้า', 'Leads');
  String get adminTabAppointments => t('นัดชม', 'Viewings');
  String get adminNavViewingCalendar => t('ปฏิทินนัดชม', 'Viewing calendar');
  String get adminCalendarTitle => t('ปฏิทินนัดชม', 'Viewing calendar');
  String get adminCalendarSubtitle => t(
        'ภาพรวมคำขอนัดดู · วันเวลา · เจ้าหน้าที่พาดู',
        'Overview of viewing requests · date & time · assigned guide',
      );
  String adminCalendarTodayCount(int n) =>
      t('วันนี้ $n นัด', 'Today: $n viewing${n == 1 ? '' : 's'}');
  String adminCalendarPendingCount(int n) =>
      t('รอยืนยัน $n', '$n pending');
  String adminCalendarWeekCount(int n) =>
      t('สัปดาห์นี้ $n นัด', 'This week: $n');
  String adminCalendarUnassignedCount(int n) =>
      t('ยังไม่ระบุคน $n', '$n unassigned');
  String get adminCalendarTodaySchedule =>
      t('ตารางวันนี้', 'Today\'s schedule');
  String adminCalendarMoreSlots(int n) => t('+$n', '+$n');
  String adminCalendarDayDetail(String date, int n) => t(
        'นัดวันที่ $date · $n รายการ',
        '$date · $n appointment${n == 1 ? '' : 's'}',
      );
  String adminCalendarDayOverview(String date) => t(
        'ภาพรวมวันที่ $date',
        'Overview · $date',
      );
  String adminCalendarDayCaseCount(int n) => t(
        '$n เคส',
        '$n case${n == 1 ? '' : 's'}',
      );
  String adminCalendarCellApptCount(int n) => t('$n นัด', '$n');
  String adminCalendarDayConfirmedCount(int n) =>
      t('ยืนยัน $n', '$n confirmed');
  String adminCalendarDayPendingCount(int n) =>
      t('รอ $n', '$n pending');
  String adminCalendarDayUnassignedCount(int n) =>
      t('ยังไม่ระบุคน $n', '$n unassigned');
  String get adminCalendarDayTimelineTitle =>
      t('ตารางเวลา', 'Timeline');
  String get adminCalendarAiDraftBadge =>
      t('ร่าง AI', 'AI draft');
  String get adminCalendarAiDraftHint => t(
        'AI สร้างร่างให้แล้ว — แก้ไขได้ทุกฟิลด์ ระบบจะไม่ให้ AI ทับส่วนที่คุณแก้',
        'AI prepared this draft — edit freely; locked fields won’t be overwritten',
      );
  String get adminCalendarConfirmAiDraft =>
      t('ยืนยันร่าง', 'Confirm draft');
  String get adminCalendarConfirmAiDraftDone =>
      t('ยืนยันกิจกรรมแล้ว — sync ปฏิทินภายนอก (ถ้าตั้งค่า)', 'Event confirmed — external sync queued');
  String get adminCalendarEventSaved =>
      t('บันทึกกิจกรรมแล้ว', 'Event saved');
  String get adminCalendarEventEditTitle =>
      t('แก้ไขกิจกรรม', 'Edit event');
  String get adminCalendarEventTitleLabel =>
      t('หัวข้อ', 'Title');
  String get adminCalendarEventLocationLabel =>
      t('สถานที่', 'Location');
  String get adminCalendarEventDescriptionLabel =>
      t('รายละเอียด / เช็กลิสต์ลูกค้า', 'Details / client checklist');
  String get adminCalendarEventTimeLabel =>
      t('เวลา', 'Time');
  String get adminCalendarRefreshAi =>
      t('รีเฟรช AI', 'Refresh AI');
  String get adminCalendarVersionConflict => t(
        'มีคนแก้ไขไปแล้ว — โหลดใหม่แล้วลองอีกครั้ง',
        'Someone else edited this — reload and try again',
      );
  String adminCalendarHumanLockedCount(int n) => t(
        'มนุษย์แก้แล้ว $n ฟิลด์ (AI จะไม่ทับ)',
        '$n human-locked fields (AI won’t overwrite)',
      );
  String get adminCareGrantTitle =>
      t('มอบสิทธิ์ดูแลทรัพย์', 'Grant property care access');
  String get adminCareGrantHint => t(
        'มอบให้คนดูแลในแอป — ไม่จำเป็นต้องเป็นเจ้าของกฎหมาย',
        'Assign in-app caretaker — not necessarily legal owner',
      );
  String get adminCareCurrentList =>
      t('ผู้ดูแลปัจจุบัน', 'Current caretakers');
  String get adminCareUserIdLabel =>
      t('รหัสผู้ใช้ในแอป (UUID)', 'App user ID (UUID)');
  String get adminCareUserIdHint => t(
        'เจ้าของ/โคเอ/ลูกค้าแจ้งหลังสมัคร — วางจากโปรไฟล์',
        'Paste from profile after signup',
      );
  String get adminCareRoleLabel => t('บทบาทดูแล', 'Care role');
  String get adminCareStatusLabel => t('สถานะสิทธิ์', 'Access status');
  String get adminCarePrimaryToggle =>
      t('ตั้งเป็นผู้ดูแลหลัก', 'Set as primary caretaker');
  String get adminCarePrimaryHint => t(
        'ผู้ดูแลหลักรับแจ้งเตือนและลำดับงานก่อน',
        'Primary caretaker gets alerts and priority routing',
      );
  String get adminCareNotesLabel => t('หมายเหตุ', 'Notes');
  String get adminCareGrantButton =>
      t('มอบสิทธิ์ดูแล', 'Grant care access');
  String get adminCareGrantDone =>
      t('มอบสิทธิ์ดูแลแล้ว', 'Care access granted');
  String get adminOwnerDataStatusComplete =>
      t('เจ้าของกรอกข้อมูลครบแล้ว', 'Owner data complete');
  String get adminOwnerDataStatusPending =>
      t('รอเจ้าของกรอกข้อมูล', 'Awaiting owner data');
  String adminOwnerDataOccupancyLine(String status) => t(
        'สถานะทรัพย์จากเจ้าของ: $status',
        'Owner occupancy: $status',
      );
  String adminOwnerDataDescriptionPreview(String text) {
    final preview = text.length > 120 ? '${text.substring(0, 120)}…' : text;
    return t('รายละเอียดจากเจ้าของ: $preview', 'Owner description: $preview');
  }

  String get adminCareOpenGrantSheet =>
      t('มอบสิทธิ์ดูแลทรัพย์', 'Grant property care');
  String get adminCareRevokeButton =>
      t('ถอนสิทธิ์', 'Revoke access');
  String get adminCareRevokeDone =>
      t('ถอนสิทธิ์ดูแลแล้ว', 'Care access revoked');
  String get myCaredPropertiesTitle =>
      t('ทรัพย์ที่ฉันดูแล', 'Properties I manage');
  String get myCaredPropertiesMenu =>
      t('ทรัพย์ที่ฉันดูแล', 'My managed properties');
  String get myCaredPropertiesEmpty => t(
        'ยังไม่มีทรัพย์ที่มอบให้คุณ\nแอดมินมอบสิทธิ์หลังทราบ UUID ของคุณ',
        'No properties assigned yet\nAdmin grants access after you sign up',
      );
  String get careAcceptButton =>
      t('รับสิทธิ์ดูแลทรัพย์', 'Accept care access');
  String get careAcceptDone =>
      t('รับสิทธิ์แล้ว — ดูทรัพย์ในรายการนี้', 'Access accepted');
  String get careOwnerDataPending =>
      t('รอเติมข้อมูล', 'Data pending');
  String get careCompleteDataButton =>
      t('เติมข้อมูลทรัพย์ให้ครบ', 'Complete property data');
  String get careManageListingsSection =>
      t('ประกาศในทรัพย์นี้ — จัดการได้', 'Listings you can manage');
  String careMineDataHint(int n) => t(
        'มี $n ประกาศรอเติมข้อมูล — ขยายการ์ดด้านล่างเพื่อบันทึก',
        '$n listing(s) need data — expand a card below to mark complete',
      );
  String get careManageListingsEmpty => t(
        'ยังไม่มีประกาศเชื่อมกับทะเบียนนี้',
        'No listings linked to this registry yet',
      );
  String get careCompleteListingButton =>
      t('กรอกข้อมูลให้ครบ', 'Complete required data');
  String careCompleteListingDone(String code) => t(
        'บันทึกข้อมูลประกาศ $code ครบแล้ว',
        'Listing $code marked complete',
      );
  String get careCompleteDataTitle =>
      t('เติมข้อมูลทรัพย์', 'Complete property info');
  String careCompleteDataIntro(String code, int pending) => t(
        'ทะเบียน $code — มี $pending ประกาศที่รอข้อมูลจากคุณ\n'
        'สถานะเผยแพร่บนหน้าบ้านไม่เปลี่ยน',
        'Registry $code — $pending listing(s) need your data\n'
        'Published status on the app stays the same',
      );
  String get careCompleteDataNote => t(
        'กรอกรายละเอียด ราคา สถานะทรัพย์ และการนัดดูให้ครบ — จึงจะบันทึกได้',
        'Complete description, price, occupancy, and viewing access before saving',
      );
  String get careOwnerDataFormTitle =>
      t('เติมข้อมูลประกาศให้ครบ', 'Complete listing details');
  String get careOwnerDataFormEditTitle =>
      t('แก้ไขข้อมูลประกาศ', 'Edit listing details');
  String get careOwnerDataFormSaveEdit =>
      t('บันทึกการแก้ไข', 'Save changes');
  String get careOwnerDataStepOverview =>
      t('ภาพรวม', 'Overview');
  String get careOwnerDataStepDetails =>
      t('รายละเอียด', 'Details');
  String get careOwnerDataStepConfirm =>
      t('ราคา', 'Price');
  String get careOwnerDataStepPreview =>
      t('พรีวิว', 'Preview');
  String get careOwnerDataPreviewTitle =>
      t('พรีวิวประกาศ', 'Listing preview');
  String get careOwnerDataPreviewIntro => t(
        'ตรวจสอบก่อนบันทึก — ตัวอย่างตามข้อมูลที่กรอก (หัวข้อ/รายละเอียด/ราคา)',
        'Review before saving — preview reflects your title, details, and price',
      );
  String get careOwnerDataPreviewListingTypeLabel =>
      t('ประเภทประกาศ', 'Listing type');
  String get careOwnerDataPreviewPublicTab =>
      t('หน้าบ้าน (ลูกค้า)', 'Public view');
  String get careOwnerDataPreviewOwnerTab =>
      t('ฉบับเจ้าของ', 'Owner copy');
  String get careOwnerDataPreviewPublicBanner => t(
        'ตัวอย่างหน้าบ้าน',
        'Public preview',
      );
  String get careOwnerDataPreviewPublicNote => t(
        'บันทึกแล้วลูกค้าเห็นตามนี้ — ยกเว้นหัวข้อที่เปลี่ยน ต้องรอทีมตรวจก่อนเผยแพร่',
        'Customers see this after save — except a changed title, which needs team review',
      );
  String get careOwnerDataPreviewOwnerBanner => t(
        'ข้อมูลที่จะบันทึก',
        'Data to be saved',
      );
  String get careOwnerDataPreviewOwnerNote => t(
        'เบอร์/ไลน์ในข้อความจะไม่แสดงหน้าบ้านอัตโนมัติ',
        'Phone/LINE in text will not appear on the public page automatically',
      );
  String get createListingPreviewAction =>
      t('พรีวิวหน้าบ้าน', 'Preview listing');
  String get careOwnerDataAdminBlockTitle =>
      t('ข้อมูลเริ่มต้นจากทีม', 'Starting point from team');
  String get careOwnerDataAdminBlockHint => t(
        'อ้างอิงหัวข้อ/รูป/ทำเลที่ทีมเตรียมไว้ — ขั้นถัดไปแก้ไขได้ทุกฟิลด์เหมือนลงประกาศใหม่',
        'Reference title, photos, and location from the team — next steps let you edit everything like a new listing',
      );
  String get careOwnerDataOverviewHint => t(
        'กด「ถัดไป」เพื่อแก้ไขประเภทประกาศ รายละเอียด ราคา และสถานะทรัพย์ได้ตามต้องการ',
        'Tap Next to edit listing type, details, price, and occupancy like a new listing',
      );
  String get careOwnerDataOwnerBlockTitle =>
      t('ข้อมูลประกาศ', 'Listing details');
  String get careOwnerDataTitleLabel =>
      t('หัวข้อประกาศ *', 'Listing title *');
  String get careOwnerDataTitleOwnerLabel => careOwnerDataTitleLabel;
  String get careOwnerDataTitleReviewWarning => t(
        'เปลี่ยนหัวข้อแล้ว — หลังบันทึกระบบจะส่งให้ทีมตรวจสอบอีกครั้งก่อนเผยแพร่',
        'Title changed — after saving, the listing will be sent for team review before going live',
      );
  String get careOwnerDataTitleReviewSaved => t(
        'บันทึกแล้ว — ส่งหัวข้อใหม่ให้ทีมตรวจสอบ (สถานะรอตรวจ)',
        'Saved — new title sent for team review (pending)',
      );
  String get careOwnerDataTitleTooShort => t(
        'หัวข้อสั้นเกินไป — อย่างน้อย 5 ตัวอักษร',
        'Title too short — at least 5 characters',
      );
  String get careOwnerDataSpecsRequired => t(
        'กรุณาระบุห้องนอน ห้องน้ำ และพื้นที่ (ตร.ม.)',
        'Enter bedrooms, bathrooms, and area (sqm)',
      );
  String get careOwnerDataPetTypesRequired => t(
        'เลือกประเภทสัตว์ที่อนุญาต หรือปิดการเลี้ยงสัตว์',
        'Select allowed pet types or disable pets',
      );
  String get careOwnerDataContactLeakWarning => t(
        'พบเบอร์หรือไลน์ในข้อความ — ระบบจะเก็บไว้หลังบ้านเท่านั้น ไม่แสดงหน้าบ้านจนกว่าทีมจะ sync',
        'Phone or LINE detected — stored in back-office only until the team syncs public copy',
      );
  String get careOwnerDataEditIntro => t(
        'แก้ไขได้ทุกส่วน — ข้อมูลเริ่มจากที่ทีมเตรียมไว้ · เปลี่ยนหัวข้อแล้วต้องรอทีมตรวจอีกครั้ง',
        'Edit anything — pre-filled from the team · changing the title sends it for review again',
      );
  String get careOwnerDataFirstIntro => t(
        'กรอก/ปรับข้อมูลให้ครบเหมือนลงประกาศใหม่ — เปลี่ยนหัวข้อแล้วต้องรอทีมตรวจ',
        'Complete or adjust all fields like a new listing — title changes need team review',
      );
  String get careOwnerDataPromoPriceLabel =>
      t('ราคาโปรโมชั่น (ถ้ามี)', 'Promo price (optional)');
  String get createListingRentPriceSection => t('ราคาเช่า', 'Rent price');
  String get createListingSalePriceSection => t('ราคาขาย', 'Sale price');
  String get createListingFullPriceLabel =>
      t('ราคาเต็ม', 'Full price');
  String get createListingPromoPriceLabel =>
      t('ราคาลดโปรโมชั่น *', 'Promo price *');
  String get createListingPromoToggle =>
      t('ตั้งราคาโปรโมชั่น', 'Set promotion price');
  String get createListingPromoMustBeLower =>
      t('ราคาโปรโมชั่นต้องต่ำกว่าราคาเต็ม', 'Promo must be below full price');
  String get bahtUnit => t('บาท', 'THB');
  String get careOwnerDataFloorLabel => t('ชั้น', 'Floor');
  String careOwnerDataFormIntro(String code) => t(
        'ประกาศ $code — กรอกข้อมูลที่จำเป็นก่อนเผยแพร่เต็มรูปแบบ',
        'Listing $code — required fields before full publish',
      );
  String get careOwnerDataFormSubmit =>
      t('บันทึกข้อมูลครบแล้ว', 'Save completed data');
  String get careOwnerDataValidationError => t(
        'กรอกหัวข้อ รายละเอียด สเปก ราคา สถานะทรัพย์ และการนัดดูให้ครบ',
        'Complete title, description, specs, price, occupancy, and viewing access',
      );
  String get careOwnerDataRequiredBeforeBump => t(
        'กรอกข้อมูลให้ครบก่อนดันประกาศ',
        'Complete data before bumping',
      );
  String get careOwnerDataRequiredHint => t(
        'ต้องกรอกรายละเอียด ราคา และสถานะทรัพย์ก่อน — จึงจะดันประกาศได้',
        'Fill description, price, and occupancy first — then you can bump',
      );
  String careOwnerDataDescCounter(int n) => t(
        'อย่างน้อย 20 ตัวอักษร ($n/20)',
        'At least 20 characters ($n/20)',
      );
  String get careOwnerDataDescTooShort => t(
        'รายละเอียดสั้นเกินไป — กรุณากรอกอย่างน้อย 20 ตัวอักษร',
        'Description too short — enter at least 20 characters',
      );
  String get careOwnerDataPriceRequired =>
      t('กรุณาระบุราคา', 'Enter a price');
  String get careOwnerDataOccupancyDateRequired => t(
        'กรุณาระบุวันที่ว่าง/พร้อมเข้าอยู่ตามสถานะทรัพย์',
        'Set available date for the selected occupancy status',
      );
  String get careOwnerDataInventoryMissing => t(
        'ไม่พบทะเบียนทรัพย์ — ลองรีเฟรชหน้า',
        'Registry not found — try refreshing',
      );
  String get careOwnerDataListingRefMissing => t(
        'ไม่พบรหัสประกาศ — ปิดแล้วเปิดฟอร์มใหม่ หรือรีเฟรชหน้า',
        'Listing reference missing — reopen the form or refresh',
      );
  String get careCompleteDataConfirm =>
      t('บันทึกว่าเติมข้อมูลครบแล้ว', 'Mark all as complete');
  String get careCompleteDataAllDone => t(
        'ครบทุกประกาศแล้ว — ใช้ปุ่มด้านล่างการ์ดเพื่อดัน/ปิดประกาศ',
        'All listings complete — use card actions to bump or close',
      );
  String careCompleteDataDone(int n) => t(
        'บันทึกครบแล้ว $n ประกาศ',
        'Marked $n listing(s) complete',
      );
  String careBannerClaim(int n) => t(
        'มีทรัพย์ $n รายการรอรับสิทธิ์ — แตะเพื่อรับ',
        '$n propert(ies) waiting — tap to accept',
      );
  String careBannerData(int n) => t(
        'มีทรัพย์ $n รายการรอเติมข้อมูล — แตะเพื่อเปิด',
        '$n propert(ies) need data — tap to open',
      );
  String get careMineTabTitle => t(
        'ทรัพย์ที่แอดมินมอบให้ดูแล',
        'Properties assigned by admin',
      );
  String careMineTabBody(int claim, int data) => t(
        claim > 0
            ? 'มี $claim ทรัพย์รอคุณกดรับสิทธิ์'
                '${data > 0 ? ' · อีก $data รายการรอเติมข้อมูล' : ''}\n'
                'ไม่ใช่ประกาศที่คุณลงเอง — อยู่ในเมนู「ทรัพย์ที่ฉันดูแล」'
            : 'มี $data ทรัพย์รอเติมข้อมูลให้ครบ\n'
                'สถานะเผยแพร่บนหน้าบ้านไม่เปลี่ยน',
        claim > 0
            ? '$claim propert(ies) waiting for you to accept'
                '${data > 0 ? ' · $data need data' : ''}\n'
                'Not your self-posted listings — see「Properties I manage」'
            : '$data propert(ies) need your data\n'
                'Public listing status stays the same',
      );
  String get careMineTabOpenButton =>
      t('เปิดทรัพย์ที่ฉันดูแล', 'Open managed properties');
  String get careNotifTitle =>
      t('มอบสิทธิ์ดูแลทรัพย์แล้ว', 'Property care access granted');
  String careNotifBody(String code) => t(
        'ทะเบียน $code รอคุณกดรับ — เปิดหน้าของฉันเพื่อดูทรัพย์',
        'Registry $code awaits your acceptance — open My tab to view',
      );
  String careNotifToast(String code) => t(
        'ได้รับมอบสิทธิ์ดูแล $code แล้ว',
        'You received care access for $code',
      );
  String get careNotifCta =>
      t('เปิดหน้าของฉัน', 'Open My tab');
  String get careMineSectionTitle =>
      t('ทรัพย์ที่มอบให้ดูแล', 'Assigned properties');
  String get careAssignedListingTag =>
      t('ทรัพย์ที่ได้รับมอบดูแล', 'Care-assigned property');
  String adminCalendarAiDraftCount(int n) =>
      t('ร่าง AI $n', '$n AI drafts');
  String get adminCalendarDayListTitle =>
      t('รายการนัดทั้งหมด', 'All appointments');
  String adminCalendarCompactLine({
    required String guide,
    required String place,
  }) =>
      t(
        '$guide พาลูกค้านัดชม $place',
        '$guide · customer viewing · $place',
      );
  String get adminCalendarGuideUnset =>
      t('ยังไม่ระบุคนพา', 'Guide not assigned');
  String get adminCalendarRowGuide =>
      t('เอเจ้นที่ได้รับมอบหมาย', 'Assigned guide');
  String get adminCalendarRowDirectChannel =>
      t('ลูกค้าตรง', 'Direct customer');
  String get adminCalendarRowCoAgencyChannel =>
      t('ลูกค้าตรง, โคเอเจนซี่', 'Direct / co-agency');
  String get adminCalendarRowProject =>
      t('สนใจนัดดูโครงการ', 'Viewing project');
  String get adminCalendarRowViewingProfile =>
      t('โปรไฟล์สำหรับนัดดู', 'Viewing profile');
  String get adminCalendarRowCoAgencyClient =>
      t('โปรไฟล์ของลูกค้าโคเอเจนซี่', 'Co-agency client profile');
  String get adminCalendarRowContactAdmin =>
      t('แอดมินที่เป็นคนติดต่อ', 'Contact admin');
  String get adminCalendarContactAdminUnset =>
      t('ยังไม่มีคนรับแชท', 'Chat not claimed yet');
  String get adminCalendarBtnViewChat =>
      t('ดูแชท', 'View chat');
  String get adminCalendarBtnOwnerChat =>
      t('แชทเจ้าของ', 'Owner chat');
  String get adminCalendarBtnAdminOwnerChat =>
      t('แอดมินคุยกับเจ้าของ', 'Admin–owner chat');
  String adminBackToPage(String page) =>
      t('กลับ$page', 'Back to $page');
  String get adminCalendarTapForDetail =>
      t('แตะรายการเพื่อดูรายละเอียด', 'Tap a row for full details');
  String get adminCalendarDetailTitle =>
      t('รายละเอียดนัดชม', 'Viewing details');
  String get adminCalendarDayEmpty =>
      t('ไม่มีนัดในวันนี้', 'No viewings on this day');
  String adminCalendarStatusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return t('ยืนยันแล้ว', 'Confirmed');
      case 'completed':
        return t('เสร็จสิ้น', 'Completed');
      case 'cancelled':
        return t('ยกเลิก', 'Cancelled');
      default:
        return t('รอยืนยัน', 'Pending');
    }
  }

  String adminCalendarStaffGuide(String name) =>
      t('เจ้าหน้าที่พาดู: $name', 'Guide: $name');
  String adminCalendarChatAdminLine(String name) =>
      t('แอดมินคุย: $name', 'Chat admin: $name');
  String get adminCalendarChatAdminUnset => t(
        'แอดมินคุย: ยังไม่มีคนรับแชท',
        'Chat admin: not claimed yet',
      );
  String get adminCompCardIntro => t(
        'คอมพ์การ์ด = โปรไฟล์ย่อยของทีมงาน แต่ละคนมีแท็ก PR ผูกไว้ '
        'ส่งให้ลูกค้าในแชทได้ — ลูกค้ากดแท็กเพื่อดูข้อมูลสาธารณะ',
        'Comp cards are staff sub-profiles with linked PR tags '
        'you can send in chat — customers tap the tag to view public info',
      );
  String adminCompCardListTitle(int n) =>
      t('คอมพ์การ์ดทีมงาน ($n)', 'Team comp cards ($n)');
  String get adminCompCardEmpty =>
      t('ยังไม่มีคอมพ์การ์ด', 'No comp cards yet');
  String get adminCompCardEditTitle =>
      t('แก้ไขคอมพ์การ์ด', 'Edit comp card');
  String adminCompCardEditHint(String tag) => t(
        'แท็กที่ผูก: $tag — บันทึกแล้วสร้างเวอร์ชันแท็กใหม่',
        'Linked tag: $tag — save creates a new tag version',
      );
  String get adminCompCardSendTag =>
      t('ส่งแท็กในแชท', 'Send tag in chat');
  String adminCompCardSendTagMessage(String name) => t(
        'ข้อมูลผู้ดูแลจากทีมงาน — $name',
        'Your contact from our team — $name',
      );
  String get adminCompCardSendTagDone =>
      t('ส่งแท็กในแชทแล้ว', 'Tag sent in chat');
  String get adminCompCardTab => t('คอมพ์การ์ด', 'Comp cards');
  String get adminCalendarAssignStaff => t('ระบุคนพา', 'Assign guide');
  String adminCalendarStaffAssigned(String name) =>
      t('ระบุคนพาแล้ว: $name', 'Guide assigned: $name');
  String get adminCalendarStaffNotifySent => t(
        'แจ้งลูกค้าในแชทแล้ว — ยืนยันนัดพร้อมชื่อเอเจ้นต์',
        'Customer notified in chat with guide details',
      );
  String get adminCalendarStaffNotifyMissingChat => t(
        'ระบุคนพาแล้ว — ยังหาแชทลูกค้าไม่เจอ',
        'Guide saved — customer chat thread not found',
      );
  String get adminOpenCustomerChat => t('เปิดแชทลูกค้า', 'Open customer chat');
  String get adminCalendarAssignConfirmed => t(
        'มอบหมายเอเจ้นและยืนยันนัดแล้ว — แจ้งลูกค้าในแชทแล้ว',
        'Guide assigned & viewing confirmed — customer notified',
      );
  String get adminCalendarStaffAssignNeedConfirm => t(
        'ระบุคนพาแล้ว — กด「ยืนยันนัด」เพื่อแจ้งลูกค้าในแชท',
        'Guide saved — tap Confirm viewing to notify customer in chat',
      );
  String get adminCalendarConfirmNeedStaff => t(
        'กรุณาระบุคนพาก่อนยืนยันนัด',
        'Assign a guide before confirming the viewing',
      );
  String adminCalendarAlertOverview({
    required int unassigned,
    required int awaitingConfirm,
    required int newCases,
    required int postViewing,
  }) {
    final parts = <String>[];
    if (unassigned > 0) {
      parts.add(t('$unassigned นัดยังไม่ระบุคนพา', '$unassigned need guide'));
    }
    if (awaitingConfirm > 0) {
      parts.add(t('$awaitingConfirm นัดรอยืนยัน', '$awaitingConfirm awaiting confirm'));
    }
    if (newCases > 0) {
      parts.add(t('$newCases เคสใหม่', '$newCases new'));
    }
    if (postViewing > 0) {
      parts.add(t('$postViewing อัปเดทหลังนัดดู', '$postViewing post-viewing'));
    }
    final body = parts.join(' · ');
    return t('ปฏิทินนัดชม: $body', 'Viewing calendar: $body');
  }
  String get adminCalendarAlertBannerTitle =>
      t('งานปฏิทินที่ต้องดูแล', 'Calendar tasks');
  String adminViewingGuideAssignedCustomerNotice({
    required String dateLine,
    required String timeSlot,
    required String place,
    required String guideName,
    required String guidePhone,
  }) =>
      t(
        '✅ ยืนยันนัดชมทรัพย์แล้ว\n'
        '📅 $dateLine · $timeSlot\n'
        '📍 $place\n'
        '👤 เอเจ้นต์พาชมทรัพย์: $guideName\n'
        '📞 ติดต่อ $guidePhone (วันนัดชม)\n'
        'หากต้องการเลื่อนนัด กรุณาแจ้งล่วงหน้าอย่างน้อย 3 ชั่วโมง\n'
        '\n'
        '⏰ ก่อนถึงเวลานัด 1 ชั่วโมง ระบบจะส่งการแจ้งเตือนให้กดยืนยันนัดครั้งสุดท้าย\n'
        'กรุณากดยืนยันนัดเมื่อได้รับแจ้งเตือน',
        '✅ Your viewing is confirmed\n'
        '📅 $dateLine · $timeSlot\n'
        '📍 $place\n'
        '👤 Viewing guide: $guideName\n'
        '📞 $guidePhone (on viewing day)\n'
        'To reschedule, please notify us at least 3 hours in advance.\n'
        '\n'
        '⏰ 1 hour before your slot we will send a final confirmation reminder.\n'
        'Please confirm when notified.',
      );
  String viewingFinalConfirmReminderPush({
    required String time,
    required String place,
  }) =>
      t(
        'ใกล้ถึงเวลานัดชมแล้ว ($time) — กรุณากดยืนยันนัดครั้งสุดท้ายที่ $place',
        'Viewing soon ($time) — please confirm your appointment at $place',
      );
  String viewingFinalConfirmReminderChatMessage({
    required String time,
    required String place,
  }) =>
      t(
        '🔔 ใกล้ถึงเวลานัดชมแล้ว ($time)\n'
        '📍 $place\n'
        'กรุณากด「ยืนยันนัด」ครั้งสุดท้าย เพื่อให้เอเจ้นท์ RealXtate ไปแสตนบายรอเปิดทรัพย์ให้\n'
        '(แจ้งเตือนนี้ส่งก่อนเวลานัด 1 ชั่วโมง)',
        '🔔 Your viewing is coming up ($time)\n'
        '📍 $place\n'
        'Please tap「Confirm appointment」so your RealXtate guide can be on-site to open the property.\n'
        '(Sent 1 hour before your scheduled time)',
      );
  String get adminCalendarClearStaff => t('ล้างการระบุ', 'Clear assignment');
  String get adminCalendarNoShowBadge =>
      t('ลูกค้าไม่มาตามนัด', 'Customer no-show');
  String get adminCalendarOpenFromDashboard =>
      t('เปิดปฏิทินนัดชม', 'Open viewing calendar');
  String adminCalendarDashboardHint(int pending) => pending > 0
      ? t(
          'มีคำขอนัด $pending รายการ — ดูวันเวลาและเจ้าหน้าที่พาดู',
          '$pending viewing request${pending == 1 ? '' : 's'} — see schedule & guides',
        )
      : t(
          'ดูภาพรวมนัดชมทั้งเดือน · วันนี้กี่โมง · ใครพาดู',
          'Monthly overview · today\'s slots · assigned guides',
        );
  String get adminCalendarListMapLink =>
      t('รายการนัด + แผนที่', 'List & map view');

  String get adminViewingReportTitle =>
      t('บันทึกผลหลังพาชม', 'Post-viewing report');
  String get adminViewingReportIntro => t(
        'ผู้พาชมต้องบันทึกทุกครั้งหลังพาดู — โน้ตนี้เห็นเฉพาะทีมแอดมิน',
        'Guides must log after every viewing — admin-only notes',
      );
  String get adminViewingFollowUpContinue =>
      t('ติดตามต่อ', 'Follow up');
  String get adminViewingFollowUpClose =>
      t('ไม่ต้องติดตามแล้ว', 'Close follow-up');
  String get adminViewingFollowUpIntentConsider =>
      t('พิจารณาทรัพย์นี้ก่อน', 'More time to decide');
  String get adminViewingFollowUpIntentFindMore =>
      t('ช่วยหาทรัพย์เพิ่ม', 'Find more options');
  String get adminViewingFollowUpIntentBoth =>
      t('พิจารณา + หาตัวเลือกเพิ่ม', 'Decide + more options');
  String get adminViewingReportOutcomeLabel =>
      t('ผลการพาชม', 'Viewing outcome');
  String get adminViewingReportOutcomeHint => t(
        'สรุปว่าพาชมเป็นอย่างไร — เข้าห้องได้ไหม ลูกค้าเห็นทรัพย์ครบไหม',
        'How did the viewing go — access, full tour, etc.',
      );
  String get adminViewingReportFeedbackLabel =>
      t('ฟีดแบ็กลูกค้า', 'Customer feedback');
  String get adminViewingReportFeedbackHint => t(
        'ลูกค้าพูดว่าอะไร — ชอบ/ไม่ชอบจุดไหน ข้อกังวล',
        'What the customer said — likes, concerns',
      );
  String get adminViewingReportWantsLabel =>
      t('ลูกค้าต้องการอะไรต่อ', 'What they want next');
  String get adminViewingReportWantsHint => t(
        'เช่น เปรียบเทียบกับทรัพย์อื่น ลดราคา ห้องใหญ่ขึ้น ย้ายเข้าเมื่อไหร่',
        'e.g. compare units, lower price, larger unit, move-in date',
      );
  String get adminViewingReportNotesLabel =>
      t('หมายเหตุทีมเพิ่มเติม', 'Extra team notes');
  String get adminViewingReportNotesHint => t(
        'รายละเอียดอื่นที่ทีมควรรู้ (ไม่ส่งลูกค้า)',
        'Other internal details (not sent to customer)',
      );
  String get adminViewingReportNextStepLabel =>
      t('ขั้นตอนถัดไป', 'Next step');
  String get adminViewingReportNeedOutcome =>
      t('กรุณาระบุผลการพาชม', 'Please describe the viewing outcome');
  String get adminViewingReportNeedFeedback =>
      t('กรุณาระบุฟีดแบ็กลูกค้า', 'Please enter customer feedback');
  String get adminViewingReportNeedWants =>
      t('กรุณาระบุว่าลูกค้าต้องการอะไรต่อ', 'Please enter what they want next');
  String get adminViewingReportNeedNoShowNote => t(
        'กรณีลูกค้าไม่มา — กรุณาระบุหมายเหตุ',
        'Customer no-show — please add a note',
      );
  String get adminViewingReportNoShowNotesHint => t(
        'เช่น รอ 30 นาที / โทรไม่รับ / แจ้งเลื่อนแล้วไม่มา',
        'e.g. waited 30 min / no answer / rescheduled but absent',
      );
  String viewingReportNoShowPreset(bool isEn) =>
      isEn ? 'Customer no-show' : 'ลูกค้าไม่มา';
  String get adminViewingReportChatHintContinue => t(
        'ถ้าเลือก「ติดตามต่อ」ระบบจะส่งข้อความยืนยันในแชทลูกค้า (ไม่รวมรายละเอียดภายใน)',
        'If you follow up, a short confirmation is posted to the customer chat (no internal details)',
      );
  String get adminViewingReportAdminOnlyHint => t(
        'บันทึกภายในเท่านั้น — ไม่ส่งข้อความหาลูกค้า',
        'Internal only — no message to the customer',
      );
  String get adminViewingReportSubmitContinue =>
      t('บันทึกและแจ้งลูกค้าในแชท', 'Save & notify customer');
  String get adminViewingReportSubmitClose =>
      t('บันทึก (โน้ตแอดมิน)', 'Save (admin note)');
  String get adminViewingReportSavedContinue => t(
        'บันทึกแล้ว — แจ้งลูกค้าในแชทแล้ว',
        'Saved — customer notified in chat',
      );
  String get adminViewingReportSavedClose => t(
        'บันทึกโน้ตแอดมินแล้ว',
        'Admin note saved',
      );
  String get adminViewingFollowUpAlreadyRecorded => t(
        'บันทึกผลหลังพาชมแล้ว',
        'Post-viewing report already recorded',
      );
  String get adminViewingFollowUpBtn =>
      t('บันทึกผลหลังพาชม', 'Log post-viewing');
  String get adminViewingReportViewDetail =>
      t('ดูบันทึกผลพาชม', 'View post-viewing log');
  String get adminViewingReportSavedChatPending => t(
        'บันทึกแล้ว — ยังหาแชทลูกค้าไม่เจอ เปิดจาก Lead หรือแชทคอนโซล',
        'Saved — customer chat not found; open from Lead or chat console',
      );
  List<String> get adminViewingReportOutcomePresets => isEnglish
      ? const [
          'Viewed successfully',
          'Partial tour only',
          'Customer no-show',
          'Owner/access issue',
        ]
      : const [
          'พาชมครบ',
          'ดูได้บางส่วน',
          'ลูกค้าไม่มา',
          'ปัญหาเข้าห้อง/เจ้าของ',
        ];

  String adminViewingFollowUpCustomerAck(ViewingFollowUpIntent intent) {
    return switch (intent) {
      ViewingFollowUpIntent.consider => t(
            'ได้ค่ะ ขอพิจารณาทรัพย์นี้เพิ่มเติมนะคะ รอทีมช่วยติดตามด้วยค่ะ',
            'Thanks — I\'d like more time to decide on this unit.',
          ),
      ViewingFollowUpIntent.findMore => t(
            'อยากให้ช่วยหาตัวเลือกทรัพย์เพิ่มด้วยค่ะ ขอบคุณค่ะ',
            'Please help me find more options too, thanks.',
          ),
      ViewingFollowUpIntent.both => t(
            'ขอพิจารณาทรัพย์นี้และอยากดูตัวเลือกอื่นเพิ่มด้วยค่ะ',
            'I\'d like to decide on this one and see more options.',
          ),
    };
  }

  String get adminViewingReportChatNotFound => t(
        'ไม่พบแชทลูกค้าที่ผูกกับเคสนี้ — เปิดแชทจากหน้า Lead หรือให้ลูกค้าส่งคำขอนัดดูก่อน',
        'No customer chat linked to this case — open from Lead or ask customer to request a viewing first',
      );

  /// โน้ตภายในแอดมินในแชท — ลูกค้าไม่เห็น
  String adminViewingReportChatInternalNote({
    required String outcome,
    required String feedback,
    required String wants,
    String? teamNotes,
    String? timeSlot,
    DateTime? viewedDate,
  }) {
    final y = viewedDate != null
        ? (isEnglish ? viewedDate.year : viewedDate.year + 543)
        : null;
    final when = viewedDate != null && timeSlot != null && timeSlot.isNotEmpty
        ? '${viewedDate.day}/${viewedDate.month}/$y · $timeSlot'
        : (timeSlot ?? '');
    final lines = <String>[
      t('[บันทึกผลหลังพาชม — ภายใน]', '[Post-viewing — internal]'),
      if (when.isNotEmpty) t('เมื่อ: $when', 'When: $when'),
      t('ผล: $outcome', 'Outcome: $outcome'),
      t('ฟีดแบ็ก: $feedback', 'Feedback: $feedback'),
      t('ต้องการ: $wants', 'Wants: $wants'),
      if (teamNotes != null && teamNotes.trim().isNotEmpty)
        t('โน้ตทีม: ${teamNotes.trim()}', 'Team notes: ${teamNotes.trim()}'),
    ];
    return lines.join('\n');
  }

  String adminViewingFollowUpChatContinue({
    required ViewingFollowUpIntent intent,
    String? listingCode,
  }) {
    final code = listingCode != null && listingCode.isNotEmpty
        ? ' ($listingCode)'
        : '';
    return switch (intent) {
      ViewingFollowUpIntent.consider => t(
            'ผลการนัดดูวันนี้$code — ทีมรับทราบว่าคุณต้องการพิจารณาทรัพย์นี้เพิ่มเติม เราจะติดตามและแจ้งอัปเดตในแชทนี้ครับ',
            'Post-viewing result today$code — we noted you\'d like more time to decide. We\'ll follow up here.',
          ),
      ViewingFollowUpIntent.findMore => t(
            'ผลการนัดดูวันนี้$code — ทีมรับทราบว่าคุณต้องการตัวเลือกทรัพย์เพิ่มเติม เราจะคัดเลือกที่เหมาะและส่งให้ต่อไปครับ',
            'Post-viewing result today$code — we\'ll find more matching options and share them here.',
          ),
      ViewingFollowUpIntent.both => t(
            'ผลการนัดดูวันนี้$code — ทีมรับทราบว่าคุณต้องการพิจารณาทรัพย์นี้พร้อมดูตัวเลือกอื่นเพิ่ม เราจะติดตามและแนะนำทรัพย์ที่เหมาะต่อไปครับ',
            'Post-viewing result today$code — we\'ll help you decide on this unit and share more options.',
          ),
    };
  }

  String adminViewingReportAdminNoteSummary({
    required String outcome,
    required String feedback,
    required String wants,
    required String decision,
  }) {
    final step = decision == 'continue'
        ? t('ติดตามต่อ', 'Follow up')
        : t('ไม่ต้องติดตามแล้ว', 'Closed');
    return t(
      '[ผลหลังพาชม] $step\n'
      'ผล: $outcome\n'
      'ฟีดแบ็ก: $feedback\n'
      'ต้องการ: $wants',
      '[Post-viewing] $step\n'
      'Outcome: $outcome\n'
      'Feedback: $feedback\n'
      'Wants: $wants',
    );
  }

  String adminViewingFollowUpBadge(String decision) {
    if (decision == 'continue') {
      return t('ติดตามต่อ', 'Following up');
    }
    return t('ปิดการติดตาม', 'Closed');
  }

  String get adminViewingHistoryTitle =>
      t('ประวัติพาชมทรัพย์', 'Viewing history');
  String get adminViewingHistorySubtitle => t(
        'เชื่อมเคสนี้และเบอร์ลูกค้าเดียวกัน — วัน เวลา ทรัพย์ ผลพาชม',
        'Linked to this case and same phone — date, time, property, outcomes',
      );
  String adminViewingHistoryCount(int n) =>
      t('$n ครั้ง', '$n visit${n == 1 ? '' : 's'}');
  String get adminViewingHistoryEmpty =>
      t('ยังไม่มีบันทึกผลหลังพาชม', 'No post-viewing reports yet');
  String adminViewingHistoryGuideLine(String name) =>
      t('ผู้พาชม: $name', 'Guide: $name');
  String get adminViewingReportOutcomeShort => t('ผล', 'Outcome');
  String get adminViewingReportFeedbackShort => t('ฟีดแบ็ก', 'Feedback');
  String get adminViewingReportWantsShort => t('ต้องการ', 'Wants');
  String get adminViewingReportNotesShort => t('โน้ต', 'Notes');
  String get adminTabReports => t('รายงาน', 'Reports');
  String get adminTabModeration => t('ตรวจสอบ', 'Moderation');
  String get adminTabCreateBoard => t('สร้างบอร์ด', 'Create board');
  String get adminNavPinned => t('เร่งด่วน', 'Urgent');
  String get adminNavMenu => t('เมนู', 'Menu');
  String get adminNavOpenMenu => t('เปิดเมนูนำทาง', 'Open navigation menu');
  String get adminNavGroupAssets => t('ทรัพย์ & โพสต์', 'Listings');
  String get adminNavGroupCustomers => t('ลูกค้า & เคส', 'Customers');
  String get adminNavGroupSystem => t('ระบบ & ตั้งค่า', 'System');
  String get adminNavGroupVault => t('คลังลับ', 'Vault');
  String get adminNavRequirements => t('ความต้องการลูกค้า', 'Requirements');
  String get adminRequirementsIntro => t(
        'ลูกค้าส่งความต้องการหาทรัพย์ — ทีมเลือกเคสแล้วสร้างประกาศบนบอร์ด',
        'Customers submit property needs — pick a case and publish on the demand board',
      );
  String get adminAccessRequestsIntro => t(
        'คำขอเข้าถึงข้อมูลลับ — อนุมัติโดย SUPER+',
        'Vault access requests — approved by SUPER+',
      );
  String get adminAccessRequestPending => t('รออนุมัติ', 'Pending');
  String get adminAccessRequestApproved => t('อนุมัติแล้ว', 'Approved');
  String get adminAccessRequestsEmpty => t(
        'ไม่มีคำขอรออนุมัติ',
        'No pending access requests',
      );
  String get adminDemoDataNote => t(
        'แสดงข้อมูลตัวอย่าง — โหมดทดลองหรือ DB ว่าง',
        'Showing sample data — trial mode or empty DB',
      );
  String get adminOrgIntro => t(
        'โครงสร้างทีมปฏิบัติการ (ตัวอย่าง)',
        'Operations team structure (sample)',
      );
  String get adminOrgLead => t('หัวหน้า', 'Lead');
  String get adminOrgMembers => t('คน', 'members');
  String get adminNavVault => t('ข้อมูลลับ', 'Confidential data');
  String get adminNavAssetRegistry => t('คลังทรัพย์', 'Asset registry');
  String get adminNavAvailabilityAlerts => t(
        'แจ้งเตือนกำลังจะว่าง',
        'Becoming available',
      );
  String get adminAvailabilityAlertsIntro => t(
        'เบอร์โทรอยู่ในคลังลับ — แอดมินระดับล่างกด「ขอสิทธิ์ติดต่อ」ให้ SUPER+ อนุมัติ · ตั้งเตือนซ้ำได้ถ้ายังติดต่อไม่ได้',
        'Phone numbers stay in the confidential vault — lower-tier admins request access from SUPER+ · set repeat reminders if unreachable',
      );
  String get adminAvailabilityAlertsEmpty => t(
        'ยังไม่มีประกาศที่จะว่างในช่วงที่เลือก — ระบุวันว่างตอนปิดประกาศหรือในรายละเอียดทรัพย์',
        'No listings becoming available in this window — set available date when closing or in listing details',
      );
  String get adminAvailabilityVaultPhoneHint => t(
        'เบอร์/Line ดูในคลังลับหลังได้รับสิทธิ์',
        'Phone/Line in confidential vault after access granted',
      );
  String get adminAvailabilityFilterDue =>
      t('ถึงกำหนดติดตาม', 'Due for follow-up');
  String get adminAvailabilityFilterSnoozed =>
      t('เลื่อนเตือนแล้ว', 'Snoozed');
  String get adminAvailabilityFilterMonth => t('ภายใน 30 วัน', 'Within 30 days');
  String get adminAvailabilityFilterWeek => t('ภายใน 7 วัน', 'Within 7 days');
  String get adminAvailabilityFilterAll => t('ภายใน 60 วัน', 'Within 60 days');
  String get adminAvailabilityDueNow =>
      t('ถึงกำหนดติดต่อเจ้าของ', 'Due to contact owner');
  String adminAvailabilityRemindOn(String date) =>
      t('เตือนอีกครั้ง: $date', 'Remind again: $date');
  String adminAvailabilityContactedOn(String date) =>
      t('ติดต่อแล้ว ($date)', 'Contacted ($date)');
  String get adminAvailabilityRequestContactTitle => t(
        'ขอสิทธิ์เบอร์/ติดต่อเจ้าของ',
        'Request phone / owner contact',
      );
  String get adminAvailabilityRequestContact => t(
        'ขอสิทธิ์ติดต่อ',
        'Request contact access',
      );
  String adminAvailabilityRequestDefaultReason(String code) => t(
        'แจ้งเตือนประกาศ $code กำลังจะว่าง — ขอเบอร์ติดต่อเจ้าของล่วงหน้า',
        'Listing $code becoming available — request owner phone for early outreach',
      );
  String get adminAvailabilityOpenRegistryFallback => t(
        'เปิดรายละเอียดจากข้อมูลทดลอง — ซิงค์คลังเพื่อดูข้อมูลจริง',
        'Opened demo detail — sync vault for live data',
      );
  String get adminAvailabilitySnoozeTitle =>
      t('ตั้งเตือนซ้ำ', 'Set repeat reminder');
  String get adminAvailabilitySnoozeHint => t(
        'ติดต่อเจ้าของไม่ได้ — เลือกว่าอีกกี่วันค่อยติดตามอีกครั้ง',
        'Could not reach owner — choose days until next follow-up',
      );
  String get adminAvailabilitySnoozeNote =>
      t('หมายเหตุ (ไม่บังคับ)', 'Note (optional)');
  String get adminAvailabilitySnoozeConfirm => t('บันทึก', 'Save');
  String get adminAvailabilitySnoozeBtn =>
      t('เตือนซ้ำ', 'Snooze');
  String adminAvailabilitySnoozeDays(int days) =>
      t('$days วัน', '$days days');
  String adminAvailabilitySnoozeSaved(int days) => t(
        'ตั้งเตือนซ้ำใน $days วันแล้ว',
        'Reminder set for $days days from now',
      );
  String get adminAvailabilityMarkContacted =>
      t('ติดต่อแล้ว', 'Contacted');
  String adminAvailabilityDaysLeft(int days) => t(
        days == 0 ? 'ว่างวันนี้' : 'ว่างในอีก $days วัน',
        days == 0 ? 'Available today' : 'Available in $days days',
      );
  String adminAvailabilityOnDate(String date) =>
      t('ว่างวันที่ $date', 'Available on $date');
  String adminAvailabilityOwner(String name) =>
      t('เจ้าของ/ผู้โพส: $name', 'Owner/poster: $name');
  String adminAvailabilityChatHint(String code) => t(
        'ยังไม่มีแชทเคส $code — เปิดศูนย์แชทแล้วค้นหาจากรหัส',
        'No chat thread for $code yet — open console and search by code',
      );
  String adminAvailabilityContactCount(int n) =>
      t('ติดต่อแล้ว $n ครั้ง', 'Contacted $n times');
  String get adminAvailabilityContactHistoryTitle =>
      t('ประวัติการติดต่อ', 'Contact history');
  String get adminAvailabilityContactHistoryEmpty =>
      t('ยังไม่มีบันทึกการติดต่อ', 'No contact records yet');
  String get adminAvailabilityContactChannelChat =>
      t('แชทในระบบ', 'In-app chat');
  String get adminAvailabilityContactChannelPhone =>
      t('โทรนอกระบบ', 'External call');
  String get adminAvailabilityContactChannelOther => t('อื่นๆ', 'Other');
  String get adminAvailabilityRecordCallTitle =>
      t('บันทึกโทรนอกระบบ', 'Log external call');
  String get adminAvailabilityRecordCallHint => t(
        'บันทึกวันเวลาอัตโนมัติ — ใส่หมายเหตุสั้นๆ ได้',
        'Timestamp saved automatically — optional note',
      );
  String get adminAvailabilityRecordCallNote => t('หมายเหตุ', 'Note');
  String get adminAvailabilityRecordCallSave => t('บันทึก', 'Save');
  String get adminAvailabilityStopFollowUpTitle =>
      t('ไม่ต้องติดตามเพิ่ม', 'Stop follow-up');
  String get adminAvailabilityStopFollowUpHint => t(
        'ทรัพย์จะถูกย้ายไปคลังซ่อน · ติดแท็กติดต่อเจ้าของไม่ได้ · ไม่แสดงในคลังหลัก',
        'Asset moves to hidden vault · tagged unreachable · removed from main registry',
      );
  String get adminAvailabilityStopFollowUpReason => t('สาเหตุ', 'Reason');
  String get adminAvailabilityStopFollowUpDefaultReason => t(
        'ไม่สามารถติดต่อเจ้าของได้แล้ว',
        'Cannot reach owner anymore',
      );
  String get adminAvailabilityStopFollowUpConfirm =>
      t('ยืนยันหยุดติดตาม', 'Confirm stop');
  String get adminAvailabilityStopFollowUpBtn =>
      t('หยุดติดตาม', 'Stop follow-up');
  String get adminAvailabilityEditListing =>
      t('แก้ไขทรัพย์', 'Edit listing');
  String get adminNavHiddenRegistry =>
      t('คลังซ่อน', 'Hidden vault');
  String get adminHiddenRegistryIntro => t(
        'ทรัพย์ที่ติดต่อเจ้าของไม่ได้ — ไม่แสดงในคลังหลัก แต่ค้นหาจากคลังหลักยังพบได้',
        'Unreachable owner assets — hidden from main registry but searchable',
      );
  String get adminHiddenRegistryEmpty =>
      t('ยังไม่มีทรัพย์ในคลังซ่อน', 'No hidden assets');
  String adminHiddenRegistryReason(String reason) =>
      t('สาเหตุ: $reason', 'Reason: $reason');
  String adminHiddenRegistryArchivedOn(String when) =>
      t('ย้ายเมื่อ $when', 'Archived $when');
  String get adminHiddenRegistryRestore =>
      t('นำกลับคลังหลัก', 'Restore to main');
  String get adminHiddenRegistryRestored =>
      t('นำกลับคลังหลักแล้ว', 'Restored to main registry');
  String get adminRegistryTagOwnerUnreachable => t(
        'ติดต่อเจ้าของไม่ได้',
        'Owner unreachable',
      );

  // —— Phase 27: Rental management + group chat ——
  String get rentalManagementTitle =>
      t('บริหารจัดการทรัพย์ให้เช่า', 'Rental management');
  String get rentalManagementIntro => t(
        'แชทกลุ่มสำหรับสัญญาเช่า active — ผู้เช่า · เจ้าของ · เอเจ้นท์ · แอดมิน',
        'Group chat for active leases — tenant · owner · agent · admin',
      );
  String get rentalManagementEmpty =>
      t('ยังไม่มีสัญญาเช่า active', 'No active leases yet');
  String get rentalGroupBlindHint => t(
        'แชทกลุ่มไม่แสดงเบอร์/Line/ข้อมูลหวงห้ามของกันและกัน — ติดต่อส่วนตัวผ่านระบบนอกกลุ่ม',
        'Group chat hides phones, Line and private contact info between members',
      );
  String get rentalGroupChatTitle => t('แชทกลุ่มเช่า', 'Lease group chat');
  String rentalGroupWelcome(String code) => t(
        'เปิดห้องกลุ่มสัญญา $code — สมาชิกเห็นเฉพาะชื่อและบทบาท',
        'Lease group $code opened — members see names and roles only',
      );
  String get rentalGroupPhaseNote => t(
        'Phase 27 — ข้อความ/ไฟล์/แจ้งเตือนชำระจะเปิดใช้ในเวอร์ชันถัดไป',
        'Phase 27 — messaging, files and payment reminders coming next',
      );
  String get rentalTabChat => t('แชท', 'Chat');
  String get rentalTabDocuments => t('เอกสาร', 'Documents');
  String get rentalTabAlbum => t('อัลบั้ม', 'Album');
  String get rentalTabPayments => t('ชำระค่าเช่า', 'Payments');
  String get rentalTabMaintenance => t('แจ้งซ่อม', 'Maintenance');
  String get rentalDocumentsHint => t(
        'อัปโหลดสัญญา · ใบเสร็จ · โน้ตต่อเอกสารในกลุ่ม',
        'Upload contracts, receipts and document notes in the group',
      );
  String get rentalAlbumHint => t(
        'อัลบั้มรูปสภาพห้องก่อนเข้าอยู่ · มิเตอร์ · โน้ตประกอบ',
        'Pre-move-in room condition album · meters · notes',
      );
  String get rentalAlbumNoteTitle => t('โน้ต', 'Note');
  String get rentalAlbumNoteEmpty =>
      t('ยังไม่มีโน้ต — แอดมินเขียนอธิบายสภาพห้องได้', 'No note yet — admin can write a long description');
  String get rentalAlbumNoteEdit => t('แก้ไขโน้ต', 'Edit note');
  String get rentalAlbumNoteEditTitle =>
      t('โน้ตสภาพห้องก่อนเข้าอยู่', 'Pre-move-in room note');
  String get rentalAlbumNoteEditHint => t(
        'เขียนข้อความยาวๆ อธิบายสภาพห้อง — แบบโน้ต LINE (ไม่ผูกกับรูปแต่ละใบ)',
        'Long-form room description — like a LINE note (not per photo)',
      );
  String get rentalAlbumNotePlaceholder => t(
        'อธิบายสภาพห้องก่อนเข้าอยู่…\n\n• ห้องนอน\n• ห้องน้ำ\n• มิเตอร์\n• ตำหนิเดิม',
        'Describe room condition before move-in…',
      );
  String get rentalAlbumNoteSave => t('บันทึกโน้ต', 'Save note');
  String get rentalAlbumNoteSaved => t('บันทึกโน้ตแล้ว', 'Note saved');
  String rentalAlbumNoteUpdated(String when, String who) =>
      t('แก้ไขล่าสุด $when · $who', 'Updated $when · $who');
  String get rentalAlbumAddPhotosBulk =>
      t('เพิ่มรูปหลายใบ', 'Add many photos');
  String get rentalAlbumBulkHint => t(
        'วางชื่อไฟล์ทีละบรรทัด — ไม่ต้องใส่คำอธิบายต่อรูป · อัปโหลดจริงใน 27b',
        'One filename per line — no caption per photo · real upload in 27b',
      );
  String get rentalAlbumBulkPlaceholder => t(
        'photo-001.jpg\nphoto-002.jpg\nphoto-003.jpg',
        'photo-001.jpg\nphoto-002.jpg',
      );
  String get rentalAlbumBulkAdd => t('เพิ่มเข้าอัลบั้ม', 'Add to album');
  String rentalAlbumBulkAdded(int n) =>
      t('เพิ่ม $n รูปเข้าอัลบั้มแล้ว', 'Added $n photo(s) to album');
  String rentalAlbumPhotosTitle(int n) =>
      t('อัลบั้มรูป ($n)', 'Photo album ($n)');
  String get rentalAlbumPhotosNoCaption => t(
        'รูปรวมในอัลบั้มเดียว — ไม่มีคำกำกับต่อรูป',
        'Single album — no caption per photo',
      );
  String get rentalAlbumPhotosEmpty =>
      t('ยังไม่มีรูป — กดเพิ่มรูปหลายใบ', 'No photos — tap add many photos');
  String get rentalMaintenanceHint => t(
        'เปิดเคสแจ้งซ่อมและติดตามสถานะในกลุ่ม',
        'Open maintenance tickets and track status in the group',
      );
  String get rentalChatInputHint =>
      t('พิมพ์ข้อความ…', 'Type a message…');
  String get rentalAttachDocument => t('แนบเอกสาร', 'Attach document');
  String get rentalFeatureComingSoon =>
      t('เปิดใช้ในเวอร์ชันถัดไป', 'Coming in a future release');
  String rentalRentAmount(int amount) {
    final fmt = NumberFormat.decimalPattern(isEnglish ? 'en' : 'th');
    final n = fmt.format(amount);
    return t('ค่าเช่า ฿$n / เดือน', 'Rent ฿$n / month');
  }
  String get rentalRentAmountLabel => t('ค่าเช่า', 'Rent');
  String rentalNextPayment(String date) =>
      t('ครบกำหนดชำระ $date', 'Payment due $date');
  String get rentalPaymentSchedule => t('รอบชำระ', 'Payment schedule');
  String rentalPaymentDay(int day) =>
      t('วันชำระทุกเดือน: วันที่ $day', 'Due day each month: day $day');
  String rentalBillingCycle(String label) =>
      t('รอบบิล: $label', 'Billing: $label');
  String get rentalBillingMonthly => t('รายเดือน', 'Monthly');
  String get rentalBillingCustom => t('กำหนดเอง', 'Custom');
  String get rentalBankAccountNote =>
      t('เลขที่บัญชี (โน้ตในกลุ่ม)', 'Bank account (group note)');
  String get rentalSendPaymentReminder =>
      t('ส่งแจ้งเตือนชำระ', 'Send payment reminder');
  String get adminNavGroupRentalManagement =>
      t('บริหารจัดการทรัพย์ให้เช่า', 'Rental management');
  String get adminNavRentalManagement =>
      t('สัญญาเช่า & แชทกลุ่ม', 'Leases & group chat');
  String get adminRentalManagementIntro => t(
        'จัดการสัญญาเช่า active · ดึงผู้เช่า/เอเจ้นท์/เจ้าของ/แอดมินเข้ากลุ่มเดียวกัน',
        'Manage active leases · add tenant, agent, owner and admin to one group',
      );
  String get adminRentalManagementEmpty =>
      t('ยังไม่มีสัญญาเช่า', 'No leases yet');
  String get adminRentalSearchHint => t(
        'ค้นหารหัส RXT / ชื่อทรัพย์…',
        'Search RXT code / property title…',
      );
  String get adminRentalStatusActive => t('active', 'Active');
  String get adminRentalStatusEnded => t('สิ้นสุด', 'Ended');
  String get adminRentalOpenGroupChat =>
      t('เปิดแชทกลุ่ม', 'Open group chat');
  String get adminRentalAddMember =>
      t('เพิ่มสมาชิก', 'Add member');
  String get rentalContractSignedLabel =>
      t('ทำสัญญา:', 'Contract signed:');
  String get rentalLeaseStartLabel =>
      t('เริ่มสัญญา:', 'Lease start:');
  String get rentalLeaseEndLabel =>
      t('สิ้นสุด:', 'Lease end:');
  String get adminRentalEditContract =>
      t('ตั้งค่าสัญญา', 'Contract settings');
  String get adminRentalLeaseSheetTitle =>
      t('ตั้งค่าสัญญาเช่า', 'Lease contract settings');
  String get adminRentalDatesSection =>
      t('วันที่สัญญา', 'Contract dates');
  String get adminRentalContractFilesSection =>
      t('ไฟล์สัญญา', 'Contract files');
  String get adminRentalSaveDates =>
      t('บันทึกวันที่', 'Save dates');
  String get adminRentalDatesSaved =>
      t('บันทึกวันที่สัญญาแล้ว', 'Contract dates saved');
  String get adminRentalNoEndDate =>
      t('ยังไม่กำหนด', 'Not set');
  String get adminRentalClearDate =>
      t('ล้างวันที่', 'Clear date');
  String get adminRentalAttachContract =>
      t('แนบไฟล์สัญญา', 'Attach contract file');
  String get adminRentalAttachContractHint => t(
        'ระบุชื่อไฟล์ (เช่น สัญญาเช่า.pdf) — อัปโหลด Storage จริงใน Phase 27b',
        'Enter file name (e.g. lease.pdf) — real upload in Phase 27b',
      );
  String get adminRentalAttachFileName =>
      t('ชื่อไฟล์', 'File name');
  String get adminRentalAttachNote =>
      t('หมายเหตุ', 'Note');
  String get adminRentalAttachSave => t('แนบ', 'Attach');
  String get adminRentalAttachDone =>
      t('แนบไฟล์สัญญาแล้ว', 'Contract file attached');
  String get adminRentalNoContractFiles =>
      t('ยังไม่มีไฟล์สัญญา', 'No contract files yet');
  String get adminRentalPreviewDates =>
      t('ตัวอย่างที่สมาชิกเห็น:', 'Preview for members:');
  String adminRentalContractFileCount(int n) =>
      t('ไฟล์สัญญา $n ฉบับ', '$n contract file(s)');
  String get rentalDocumentsEmpty =>
      t('ยังไม่มีเอกสารสัญญา', 'No contract documents yet');
  String get rentalDocumentsAdminOnly => t(
        'แอดมินแนบไฟล์สัญญาได้จากหน้าตั้งค่าสัญญา',
        'Admins attach contract files from contract settings',
      );
  String get rentalContractViewSoon =>
      t('เปิดดูไฟล์จริงใน Phase 27b', 'File preview in Phase 27b');

  // —— Rental payment policy & slips ——
  String get adminRentalPaymentSettings =>
      t('ตั้งค่าชำระค่าเช่า', 'Payment settings');
  String get adminRentalPaymentSettingsHint => t(
        'แจ้งเตือนผู้เช่าก่อนครบกำหนด · หยุดเมื่อได้รับสลิป · กำหนดค่าปรับล่าช้า',
        'Remind tenant before due · stop on slip · configure late penalties',
      );
  String get adminRentalPaymentRemindSection =>
      t('แจ้งเตือนผู้เช่า', 'Tenant reminders');
  String get adminRentalPaymentRemindDaysLabel => t(
        'ก่อนครบกำหนด (วัน) คั่นด้วยจุลภาค',
        'Days before due (comma-separated)',
      );
  String get adminRentalPaymentRemindHint => t(
        'เช่น 2, 1 = แจ้ง 2 วันก่อนและ 1 วันก่อน · หยุดเมื่อผู้เช่าส่งสลิป',
        'e.g. 2, 1 = remind 2 days and 1 day before · stops when slip uploaded',
      );
  String get adminRentalPaymentYearSection =>
      t('รอบชำระทั้งปี', 'Annual schedule');
  String get adminRentalPaymentYearLabel => t('ปี', 'Year');
  String get adminRentalPaymentInstallmentsLabel =>
      t('เก็บสลิปกี่ครั้ง/ปี', 'Slips per year');
  String get adminRentalPaymentLateSection =>
      t('ล่าช้า & ค่าปรับ', 'Late payment');
  String get adminRentalPaymentGraceLabel =>
      t('ล่าช้าได้ไม่เกิน (วัน)', 'Grace days');
  String get adminRentalPaymentPenaltyLabel =>
      t('ค่าปรับ/วัน หลัง grace (บาท)', 'Penalty/day after grace (THB)');
  String get adminRentalPaymentSavePolicy =>
      t('บันทึกนโยบาย', 'Save policy');
  String get adminRentalPaymentRegenerate =>
      t('สร้างรอบชำระใหม่ทั้งปี', 'Regenerate year schedule');
  String get adminRentalPaymentRunReminders =>
      t('ส่งแจ้งเตือนที่ครบกำหนดวันนี้', 'Send due reminders today');
  String get adminRentalPaymentSaved =>
      t('บันทึกตั้งค่าชำระค่าเช่าแล้ว', 'Payment settings saved');
  String get adminRentalPaymentRemindersRun =>
      t('ส่งแจ้งเตือนผู้เช่าแล้ว', 'Reminders sent to tenant');
  String get adminRentalPaymentRemindInvalid => t(
        'ระบุวันแจ้งเตือนก่อนครบกำหนด เช่น 2, 1',
        'Enter reminder days before due, e.g. 2, 1',
      );
  String get adminRentalPaymentSchedulePreview =>
      t('ตารางรอบชำระ', 'Payment schedule');
  String get rentalPaymentPolicyTitle =>
      t('นโยบายชำระค่าเช่า', 'Payment policy');
  String rentalPaymentRemindBefore(String days) =>
      t('แจ้งเตือนก่อนครบกำหนด: $days วัน', 'Remind before due: $days day(s)');
  String rentalPaymentInstallmentsCount(int n) =>
      t('เก็บสลิป $n ครั้ง/ปี', '$n slip(s) per year');
  String rentalPaymentGraceDays(int n) =>
      t('ล่าช้าได้ไม่เกิน $n วัน', 'Grace period: $n day(s)');
  String rentalPaymentPenaltyPerDay(int baht) =>
      t('ค่าปรับ $baht บาท/วัน หลัง grace', 'Penalty ฿$baht/day after grace');
  String rentalPaymentPolicyYear(int year) =>
      t('ปี $year', 'Year $year');
  String rentalPaymentRemindersDue(int n) =>
      t('มีแจ้งเตือนควรส่ง $n รายการวันนี้', '$n reminder(s) due today');
  String get rentalPaymentInstallmentsTitle =>
      t('รอบชำระค่าเช่า', 'Payment rounds');
  String get rentalPaymentNoInstallments =>
      t('ยังไม่มีตารางรอบชำระ — แอดมินสร้างจากตั้งค่า', 'No schedule yet — admin generates from settings');
  String get rentalPaymentSlipSection =>
      t('สลิปค่าเช่า', 'Rent payment slips');
  String get rentalPaymentSlipHint => t(
        'ผู้เช่าอัปโหลดสลิปในรอบที่ตรงกับวันครบกำหนด',
        'Tenant uploads slip for the matching due round',
      );
  String get rentalPaymentSlipStopsReminders => t(
        'ส่งสลิปแล้ว → หยุดแจ้งเตือนรอบนั้น',
        'Slip submitted → reminders stop for that round',
      );
  String rentalPaymentRound(int n) => t('รอบที่ $n', 'Round $n');
  String get rentalPaymentPending => t('รอชำระ', 'Pending');
  String get rentalPaymentSlipReceived =>
      t('ได้รับสลิปแล้ว', 'Slip received');
  String get rentalPaymentConfirmed => t('ยืนยันแล้ว', 'Confirmed');
  String get rentalPaymentRemindersPaused =>
      t('หยุดแจ้งเตือน', 'Reminders paused');
  String rentalPaymentReminded(String days) =>
      t('แจ้งเตือนแล้ว: ก่อน $days วัน', 'Reminded: $days day(s) before');
  String rentalPaymentLateDays(int days) =>
      t('ล่าช้า $days วัน', '$days day(s) late');
  String rentalPaymentPenaltyAmount(int baht) {
    final fmt = NumberFormat.decimalPattern(isEnglish ? 'en' : 'th');
    return t('ค่าปรับสะสม ฿${fmt.format(baht)}', 'Penalty due ฿${fmt.format(baht)}');
  }
  String rentalPaymentSendRemind(int days) =>
      t('แจ้ง $days วันก่อน', 'Remind $days d before');
  String rentalPaymentReminderSent(int days) =>
      t('ส่งแจ้งเตือน $days วันก่อนแล้ว', 'Sent $days-day reminder');
  String get rentalPaymentSelectRound =>
      t('เลือกรอบชำระ', 'Select payment round');
  String get rentalPaymentUploadSlip =>
      t('อัปโหลดสลิปค่าเช่า', 'Upload rent slip');
  String get rentalPaymentSubmitSlip => t('ส่งสลิป', 'Submit slip');
  String get rentalPaymentSlipSubmitted =>
      t('ส่งสลิปแล้ว — หยุดแจ้งเตือนรอบนี้', 'Slip submitted — reminders stopped');
  String get rentalPaymentAllSlipsReceived =>
      t('รับสลิปครบทุกรอบแล้ว', 'All slips received');
  String get rentalPaymentAdminConfirmBtn =>
      t('ยืนยันรับเงินแล้ว', 'Confirm payment received');
  String get rentalPaymentAdminConfirmTitle =>
      t('ยืนยันโอนค่าเช่าแล้ว', 'Confirm rent paid');
  String get rentalPaymentAdminConfirmHint => t(
        'กรณีผู้เช่าส่งสลิปในแอปไม่ได้ แต่เจ้าของได้รับเงินแล้ว — ปิดการเตือนรอบนี้',
        'Tenant could not upload slip but owner received payment — stop reminders',
      );
  String get rentalPaymentAdminConfirmNote => t('หมายเหตุ', 'Note');
  String get rentalPaymentAdminConfirmNoteHint => t(
        'เช่น โอนตรงเจ้าของแล้ว · รับเงินสด',
        'e.g. Paid owner directly · cash received',
      );
  String get rentalPaymentAdminConfirmSave =>
      t('ยืนยันและปิดการเตือน', 'Confirm and stop reminders');
  String get rentalPaymentAdminConfirmDone => t(
        'ยืนยันรับเงินแล้ว — ปิดการเตือนรอบนี้',
        'Payment confirmed — reminders stopped for this round',
      );
  String get rentalPaymentAdminConfirmed =>
      t('แอดมินยืนยันรับเงินแล้ว', 'Admin confirmed payment');
  String rentalPaymentAdminConfirmedBy(String who, String when) =>
      t('ยืนยันโดย $who · $when', 'Confirmed by $who · $when');
  String rentalPaymentAdminConfirmedOn(String when) =>
      t('ยืนยันรับเงินแล้ว · $when', 'Payment confirmed · $when');
  String get rentalPushReminderTitle =>
      t('RealXtate — ใกล้ครบชำระค่าเช่า', 'RealXtate — Rent due soon');
  String rentalPushReminderBody(
    String code,
    int round,
    int daysBefore,
    String dueDate,
  ) =>
      t(
        '$code · รอบที่ $round · อีก $daysBefore วัน · ครบ $dueDate',
        '$code · Round $round · $daysBefore day(s) left · Due $dueDate',
      );
  String get rentalPushAdminConfirmedTitle =>
      t('RealXtate — ยืนยันรับเงินแล้ว', 'RealXtate — Payment confirmed');
  String rentalPushAdminConfirmedBody(String code, int round, String dueDate) =>
      t(
        '$code · รอบที่ $round · แอดมินยืนยันรับเงินแล้ว ($dueDate)',
        '$code · Round $round · Admin confirmed payment ($dueDate)',
      );
  String get rentalPushSlipTitle =>
      t('RealXtate — ส่งสลิปค่าเช่าแล้ว', 'RealXtate — Rent slip submitted');
  String rentalPushSlipBody(String code, int round, String by) =>
      t(
        '$code · รอบที่ $round · $by',
        '$code · Round $round · $by',
      );
  String get rentalPaymentAdminConfirmedTenantBanner => t(
        'รอบนี้แอดมินยืนยันรับเงินแล้ว — ไม่ต้องส่งสลิปซ้ำ',
        'Admin confirmed payment for this round — no need to upload slip again',
      );
  String rentalPaymentHomeAdminConfirmed(int round) =>
      t('แอดมินยืนยันรับเงินแล้ว — รอบที่ $round', 'Admin confirmed — round $round');
  String rentalPaymentHomeSlipReceived(int round) =>
      t('ส่งสลิปแล้ว — รอบที่ $round', 'Slip received — round $round');
  String get adminCallOwner => t('โทร', 'Call');
  String get adminCopyPhone => t('คัดลอกเบอร์', 'Copy phone');
  String get adminPhoneCopied => t('คัดลอกเบอร์แล้ว', 'Phone copied');
  String get adminRegistryColSeq => t('ลำดับ', '#');
  String get adminRegistryColCode => t('รหัส', 'Code');
  String get adminRegistryColType => t('ประเภท', 'Type');
  String get adminRegistryColDate => t('วันที่เพิ่ม', 'Added');
  String get adminRegistryColLastEdit =>
      t('แก้ไขล่าสุด', 'Last edited');
  String get adminRegistryColSource => t('แหล่ง', 'Source');
  String get adminRegistryColTitle => t('หัวข้อ', 'Title');
  String get adminRegistrySearchHint => t(
        'ค้นหารหัส RXT / IMP / หัวข้อ / แหล่ง…',
        'Search RXT / IMP / title / source…',
      );
  String adminRegistryShowing(int shown, int total) => t(
        'แสดง $shown จาก $total รายการ',
        'Showing $shown of $total',
      );
  String get adminRegistryEmpty => t('ไม่มีรายการในคลัง', 'No registry rows');
  String get adminRegistryNoSearchResults => t(
        'ไม่พบรหัสที่ค้นหา — ลองรหัส RXT หรือ IMP',
        'No match — try RXT or IMP code',
      );
  String get adminRegistryDetailTitle => t('รายละเอียดทรัพย์', 'Asset details');
  String get adminRegistryCensoredHint => t(
        'มุมมองปฏิบัติการ — ไม่แสดงเบอร์/Line/ลิงก์ต้นทาง',
        'Ops view — phones, Line and source links hidden',
      );
  String get adminRegistryLockedFields => t(
        'ข้อมูลลับ (เบอร์ · Line · ลิงก์ต้นทาง · ข้อความโพสต์เต็ม) ต้องขอสิทธิ์จาก SUPER+ หรือเปิดจากคลังลับ',
        'Confidential fields require SUPER+ approval or vault access',
      );
  String get adminRegistryPublicBanner => t(
        'คลังทรัพย์ปฏิบัติการ — ตารางเดียวกับคลังลับ แต่ซ่อนข้อมูลสำคัญ · ค้นหารหัสแล้วกดแถวเพื่อดูรายละเอียด',
        'Ops asset registry — same table as vault, sensitive fields hidden · search code, tap row for details',
      );
  String get adminRegistryOpsTitle => t('จัดการทรัพย์', 'Manage asset');
  String get adminRegistryEdit => t('แก้ไข', 'Edit');
  String get adminRegistryBumpNow => t('ดันประกาศ (มือ)', 'Bump now');
  String get adminRegistryBumpDone => t('ดันประกาศแล้ว', 'Listing bumped');
  String get adminRegistryBumpFailed => t('ดันประกาศไม่สำเร็จ', 'Bump failed');
  String get adminRegistryBumpNeedListing =>
      t('ต้องมีประกาศเผยแพร่ก่อนจึงดันได้', 'Needs a published listing');
  String adminRegistryLastBump(String when) =>
      t('ดันล่าสุด: $when', 'Last bump: $when');
  String get adminRegistryTagsTitle => t('แท็กปฏิบัติการ', 'Ops tags');
  String get adminRegistryTagHot => t('ติดไฟฮอต', 'Hot');
  String get adminRegistryTagExclusive =>
      t('ฝากพิเศษ (ปฏิบัติการ)', 'Ops mandate');
  String get adminRegistryTagFeatured => t('แนะนำ', 'Featured');
  String get adminRegistryTagVerified => t('ยืนยันแล้ว', 'Verified');
  String get adminRegistryTagUrgent => t('เร่งด่วน', 'Urgent');
  String get adminRegistryOverlayTitle => t('ป้ายทับบนแผนที่/ฟีด', 'Map & feed overlay');
  String get adminRegistryOverlayNormal => t('ปกติ', 'Normal');
  String get adminRegistryOverlaySold => t('SOLD', 'SOLD');
  String get adminRegistryOverlayNotAvailable => t('NOT AVAILABLE', 'NOT AVAILABLE');
  String adminRegistryOverlayPreview(String label) =>
      t('แสดงป้ายทับ: $label', 'Overlay: $label');
  String get adminRegistryAutoBumpTitle => t('ดันประกาศอัตโนมัติ', 'Auto bump');
  String get adminRegistryAutoBumpHint => t(
        'ตั้งช่วงดันซ้ำ — ใช้กับ Exclusive / ฝากเจ้าของ (Cron process_exclusive_auto_bumps)',
        'Repeat bump interval — for Exclusive mandates (process_exclusive_auto_bumps cron)',
      );
  String get adminRegistryAutoBumpEnable => t('เปิดดันอัตโนมัติ', 'Enable auto bump');
  String adminRegistryAutoBumpEvery(int h) => t('ทุก $h ชม.', 'Every $h h');
  String get adminRegistryInternalLinks => t('ลิงก์ภายในระบบ', 'Internal links');
  String get adminRegistryAdminNote => t('โน้ตแอดมิน', 'Admin note');
  String get adminRegistryAdminNoteHint =>
      t('บันทึกภายใน — ไม่แสดงต่อผู้ใช้', 'Internal note — not shown to users');
  String get adminRegistryEditProfileSoon =>
      t('แก้ไขโปรไฟล์ — เปิดจากเมนูลูกค้าเร็วๆ นี้', 'Edit profile — coming via Customers menu');
  String get adminRegistryEditDemoImport => t(
        'ข้อมูลจำลอง — เปิดแท็บนำเข้าเพื่อแก้รายการจริง',
        'Demo data — open Import tab to edit real records',
      );
  String get adminRegistryImportNotFound => t(
        'ไม่พบรายการนำเข้า — อาจเป็น ID จำลองหรือถูกลบแล้ว',
        'Import not found — demo ID or deleted',
      );
  String get adminRegistryDetailSection =>
      t('ข้อมูลในคลัง', 'Registry record');
  String get adminRegistryRecordedBy =>
      t('ผู้บันทึก / ที่มา', 'Recorded by');
  String get adminRegistryRecordedByLabel =>
      t('บันทึกโดย', 'Recorded by');
  String get adminRegistryRecordedAt => t('วันที่บันทึก', 'Recorded at');
  String get adminRegistryOwnerName => t('เจ้าของทรัพย์', 'Owner');
  String get adminRegistryChatTag => t('แท็กแชท', 'Chat tag');
  String get adminRegistryEditHistory =>
      t('ประวัติการแก้ไข', 'Edit history');
  String get adminRegistryEditTitle =>
      t('แก้ไขข้อมูลในคลัง', 'Edit registry record');
  String get adminRegistryEditDescription =>
      t('คำอธิบายสาธารณะ', 'Public description');
  String get adminRegistrySave => t('บันทึก', 'Save');
  String get adminRegistryEditSaved =>
      t('บันทึกการแก้ไขแล้ว', 'Changes saved');
  String get adminRegistryChatOwner =>
      t('คุยกับเจ้าของ', 'Chat owner');
  String get adminRegistryChatOwnerRequest =>
      t('ขอสิทธิ์คุยเจ้าของ', 'Request owner chat');
  String get adminRegistryChatRequestPending =>
      t('รออนุมัติสิทธิ์แชท', 'Chat access pending');
  String get adminRegistryChatOwnerGate => t(
        'แอดมินระดับล่างต้องขอสิทธิ์จาก SUPER+ ก่อนคุยเจ้าของ',
        'Lower-tier admins must request SUPER+ approval before owner chat',
      );
  String get adminRegistryChatRequestTitle =>
      t('ขอสิทธิ์คุยเจ้าของทรัพย์', 'Request owner chat access');
  String get adminRegistryChatRequestHint => t(
        'ระบุเหตุผล — SUPER+ จะอนุมัติผ่านเมนูคำขอสิทธิ์',
        'State a reason — SUPER+ approves via Access requests',
      );
  String get adminRegistryChatRequestReason => t('เหตุผล', 'Reason');
  String get adminRegistryChatRequestSubmit => t('ส่งคำขอ', 'Submit');
  String get adminRegistryChatRequestNeedReason =>
      t('กรุณาระบุเหตุผล', 'Please enter a reason');
  String get adminRegistryChatRequestSent => t(
        'ส่งคำขอแล้ว — รอ SUPER+ อนุมัติ',
        'Request sent — awaiting SUPER+ approval',
      );
  String adminRegistryChatTagHint(String tag) => t(
        'เปิดคอนโซลแชท — ค้นหาด้วยรหัส $tag',
        'Chat console opened — search by code $tag',
      );
  // Phase 24–26 — Profile tags, hubs, viewing requests
  String get hubSeekerTitle => t('แชทกลางของฉัน', 'My hub');
  String get hubAgentTitle => t('แชทกลางงานโคเอ', 'Agent hub');
  String get hubEntryHint => t(
        'สรุปคำขอนัดดูและแท็กโปรไฟล์ — ไม่มีบอท',
        'Viewing requests & profile tags — no bot',
      );
  String hubViewingRecap({
    required String propertyLabel,
    required String schedule,
    required String clientCode,
    required String viewingCode,
    String? presenterCode,
  }) =>
      t(
        'คำขอนัดดู: $propertyLabel\nวันเวลา: $schedule\nลูกค้า: $clientCode'
        '${presenterCode != null ? '\nผู้พานัด: $presenterCode' : ''}\nรหัสคำขอ: $viewingCode',
        'Viewing: $propertyLabel\nWhen: $schedule\nClient: $clientCode'
        '${presenterCode != null ? '\nPresenter: $presenterCode' : ''}\nRequest: $viewingCode',
      );
  String viewingTagRecap({
    required String schedule,
    required String clientCode,
    required String viewingCode,
    String? presenterCode,
  }) =>
      t(
        'รับคำขอนัดดูแล้ว · $schedule\nโปรไฟล์: $clientCode'
        '${presenterCode != null ? ' · ผู้พานัด: $presenterCode' : ''}\nคำขอ: $viewingCode',
        'Viewing received · $schedule\nProfile: $clientCode'
        '${presenterCode != null ? ' · Presenter: $presenterCode' : ''}\nRequest: $viewingCode',
      );
  String viewingAppointmentRecordRecap({
    required String propertyLabel,
    required String schedule,
    required String place,
    required String clientCode,
    required String viewingCode,
    required String appointmentRef,
    String? guideName,
    String? presenterCode,
  }) =>
      t(
        '📋 บันทึกการนัดชม · $appointmentRef\n'
        'ทรัพย์: $propertyLabel\n'
        'วันเวลา: $schedule · $place\n'
        'แท็กลูกค้า: $clientCode'
        '${presenterCode != null ? ' · ผู้พานัด: $presenterCode' : ''}\n'
        'คำขอนัดดู: $viewingCode'
        '${guideName != null && guideName.isNotEmpty ? '\nเอเจ้นพาดู: $guideName' : ''}',
        '📋 Viewing record · $appointmentRef\n'
        'Property: $propertyLabel\n'
        'When: $schedule · $place\n'
        'Client tag: $clientCode'
        '${presenterCode != null ? ' · Presenter: $presenterCode' : ''}\n'
        'Viewing request: $viewingCode'
        '${guideName != null && guideName.isNotEmpty ? '\nGuide: $guideName' : ''}',
      );
  String get profileTagFormSeeker =>
      t('โปรไฟล์นัดดู (คุณ)', 'Your viewing profile');
  String get profileTagFormPresenter =>
      t('โปรไฟล์ผู้พานัด', 'Presenter profile');
  String get profileTagFormClient =>
      t('โปรไฟล์ลูกค้า', 'Client profile');
  String get profileTagRoleCoAgencyCustomer =>
      t('ลูกค้าของโคเอเจนซี่', 'Co-agency customer');
  String get profileTagEditCreatesNew => t(
        'แก้ไขจะสร้างแท็กเวอร์ชันใหม่ — แท็กเก่าไม่ถูกทับ',
        'Edits create a new tag version — old tags stay unchanged',
      );
  String get profileTagErrDisplayName =>
      t('กรุณาระบุชื่อผู้พานัด', 'Enter presenter name');
  String get profileTagSave => t('บันทึกแท็ก', 'Save tag');
  String get profileTagPickerHint => t(
        'เลือกแท็กเดิมหรือสร้างใหม่',
        'Use an existing tag or create a new one',
      );
  String get profileTagUse => t('ใช้แท็กนี้', 'Use tag');
  String get profileTagEditNewVersion => t('แก้ไข (แท็กใหม่)', 'Edit (new tag)');
  String get profileTagCreateNew => t('สร้างแท็กใหม่', 'Create new tag');
  String get profileTagPickerSeeker =>
      t('โปรไฟล์นัดดูของคุณ', 'Your viewing profile');
  String get profileTagPickerPresenter =>
      t('โปรไฟล์ผู้พานัด', 'Presenter profile');
  String get profileTagPickerClient => t('โปรไฟล์ลูกค้า', 'Client profile');
  String get profileTagPresenterLine => t('ผู้พานัด', 'Presenter');
  String get profileTagClientLine => t('แท็กลูกค้า', 'Client tag');
  String get viewingRequestCodeLine => t('รหัสคำขอ', 'Request code');
  String get viewingScheduleTitle =>
      t('วันและเวลานัดดู', 'Viewing date & time');
  String get viewingScheduleHint => t(
        'โปรไฟล์บันทึกแล้ว — ระบุเฉพาะวันเวลา',
        'Profile saved — enter date and time only',
      );
  String get viewingScheduleSubmit => t('ส่งคำขอนัดดู', 'Submit viewing request');
  String get adminNavParticipant360 =>
      t('ภาพรวมผู้ใช้', 'Participant 360°');
  String get adminParticipantTitle =>
      t('ภาพรวมผู้ใช้ (360°)', 'Participant 360°');
  String get adminParticipantSearchHint =>
      t('ค้นหา user / แท็ก / ข้อความ', 'Search user / tag / message');
  String get adminParticipantHub => t('แชทกลาง', 'Hub chat');
  String get adminParticipantThreads => t('แชทย่อย', 'Threads');
  String get adminParticipantTags => t('แท็กโปรไฟล์', 'Profile tags');
  String get adminParticipantViewings => t('คำขอนัดดู', 'Viewing requests');
  String get adminParticipantModeration => t('ตั้งค่าบัญชี', 'Account settings');
  String get adminParticipantMute => t('ปิดแจ้งเตือน', 'Mute notifications');
  String get adminParticipantFlag => t('ป้ายก่อกวน', 'Flag disruptive');
  String get adminParticipantSuspend => t('ระงับชั่วคราว', 'Suspend');
  String get adminParticipantMessageHub =>
      t('ทักแชทกลาง', 'Message hub');
  String get adminParticipantNoUser =>
      t('ค้นหาหรือเลือกผู้ใช้', 'Search or select a user');
  String get adminParticipantPickThread =>
      t('เลือกแชทกลางหรือแชทย่อยด้านซ้าย', 'Select hub or thread on the left');
  String get adminParticipantNoViewings =>
      t('ยังไม่มีคำขอนัดดู', 'No viewing requests yet');
  String get adminParticipantDemoUser => t('ผู้ใช้ทดลอง', 'Demo user');

  String get adminNavAccessRequests => t('คำขอสิทธิ์', 'Access requests');
  String get adminNavOrg => t('องค์กร', 'Organization');
  String get adminNavQueueTitle => t('รอรับงาน', 'Queue');
  String get adminNavQueueHint => t(
        'แชทที่ยังไม่มีแอดมินรับ — ต้องตอบก่อน',
        'Chats waiting for an admin to claim',
      );
  String get adminVaultPlaceholder => t(
        'คลังข้อมูลลับ — กำลังพัฒนาตาม Phase 23',
        'Confidential vault — Phase 23 in progress',
      );
  String get adminVaultPlaceholderHint => t(
        'เฉพาะ CEO / SUPER · ข้อมูลเบอร์ ลิงก์ต้นทาง ข้อความโพสต์เต็ม',
        'CEO / SUPER only · phones, source links, full post text',
      );
  String get adminVaultStorageTitle => t('วิธีจัดเก็บข้อมูลลับ', 'How confidential data is stored');
  String get adminVaultStorageBody => t(
        'ข้อมูลลับถูกคัดลอกจากต้นทาง → ตาราง vault_assets (JSON) · แอดมินปกติอ่านตรงไม่ได้ · เปิดดูบันทึก audit',
        'Secrets are copied from sources → vault_assets (JSON) · Standard admins cannot read directly · Views are audited',
      );
  String get adminVaultStorageTable => t('ข้อมูลลับรวมศูนย์ (PII, ลิงก์, ข้อความเต็ม)', 'Central confidential store');
  String get adminVaultStorageImportSource => t('ซิงค์จาก listing_imports (raw_payload + parsed)', 'Synced from listing_imports');
  String get adminVaultStorageProfileSource => t('เบอร์/Line จาก profiles + listings', 'Phone/Line from profiles + listings');
  String get adminVaultStorageAudit => t('บันทึกทุกครั้งที่เปิดดู (vault.view)', 'Logged on every view (vault.view)');
  String get adminVaultSync => t('ซิงค์เข้าคลัง', 'Sync to vault');
  String get adminVaultSynced => t('ซิงค์เข้าคลังแล้ว', 'Vault synced');
  String get adminVaultSyncHint => t(
        'กดซิงค์เพื่อดึงข้อมูลจากนำเข้า/ประกาศ/บัญชีเข้า vault_assets (ต้อง deploy migration + vault-browse)',
        'Tap sync to pull imports/listings/profiles into vault_assets (requires migration + vault-browse deploy)',
      );
  String get adminVaultEmpty => t('คลังว่าง — กดซิงค์เพื่อดึงข้อมูล', 'Vault empty — tap sync to import data');
  String get adminVaultFilterAll => t('ทั้งหมด', 'All');
  String get adminVaultFilterImport => t('นำเข้า', 'Imports');
  String get adminVaultFilterListing => t('ประกาศ', 'Listings');
  String get adminVaultFilterProfile => t('บัญชี', 'Profiles');
  String get adminVaultHasPhone => t('มีเบอร์', 'Has phone');
  String get adminVaultDetailTitle => t('รายละเอียดคลังลับ', 'Vault record');
  String get adminVaultPhones => t('เบอร์โทร', 'Phone numbers');
  String get adminVaultRawPayload => t('ข้อมูลดิบ (payload)', 'Raw payload');
  String get adminVaultEntityId => t('รหัส entity', 'Entity ID');
  String get adminVaultSyncedFrom => t('ซิงค์จาก', 'Synced from');
  String get adminVaultDemoBanner => t(
        'ข้อมูลจำลอง — หน้าตาเดียวกับ vault_assets จริง · deploy vault-browse แล้วกดซิงค์เพื่อข้อมูลจริง',
        'Simulated data — same layout as real vault_assets · deploy vault-browse and sync for live data',
      );
  String get adminVaultDemoSynced => t(
        'โหลดข้อมูลจำลอง 7 รายการแล้ว',
        'Loaded 7 simulated vault records',
      );
  String adminNavTierLabel(String tier) {
    switch (tier) {
      case 'ceo':
        return t('CEO', 'CEO');
      case 'super':
        return t('SUPER', 'SUPER');
      case 'lead':
        return t('LEAD', 'LEAD');
      default:
        return t('ADMIN', 'ADMIN');
    }
  }
  String get adminTrialBannerConfigured => t(
        'โหมดทดลอง — แชทและเคสตัวอย่าง · ปิดโหมดทดลองเมื่อเปิดใช้จริง',
        'Trial — sample chat/leads · set TRIAL_MODE=false for production',
      );
  String get adminUnifiedTrialBanner => t(
        'โหมดทดลองแยก — ข้อมูลจำลองทั้งหมด ไม่ผสม DB · ตั้ง ADMIN_DEMO_CASES=false ก่อนเปิดใช้จริง',
        'Isolated trial — simulated data only, no DB mixing · set ADMIN_DEMO_CASES=false for production',
      );
  String get adminResetTrialCases => t('เคลียร์เคสทดลอง', 'Reset trial cases');
  String get adminResetTrialCasesConfirm => t(
        'รีเซ็ตนัดชมและแชทจำลองทั้งหมดกลับค่าเริ่มต้น?\n'
        'เอเจ้นที่มอบหมายและสถานะยืนยันจะถูกล้าง',
        'Reset all demo appointments and chats to defaults?\n'
        'Assigned guides and confirmed statuses will be cleared.',
      );
  String get adminResetTrialCasesDone => t(
        'เคลียร์เคสทดลองแล้ว — ดูชิป「รอระบุคนพา」และนัดที่ขึ้น「ยังไม่ระบุ」',
        'Trial cases cleared — check the unassigned chip and「Unassigned」guides',
      );
  String get adminNoOffers => t('ยังไม่มีข้อเสนอ', 'No offers yet');
  String get adminNoLeads => t('ยังไม่มีเคสลูกค้า', 'No leads yet');
  String get adminMustLoginReal => t(
        'ต้องล็อกอินจริง (อีเมล+รหัส) — โหมดทดลองไม่ sync กับมือถือ',
        'Log in with email/password — trial mode does not sync across devices',
      );
  String get adminRecentLeadsTitle =>
      t('เคสลูกค้า / นัดดู ล่าสุด', 'Recent leads / viewings');
  String get adminViewAllLeads => t('ดูทั้งหมด', 'View all');
  String get adminReject => t('ปฏิเสธ', 'Reject');
  String get adminDemandPostFallback => t('ประกาศบอร์ด', 'Demand post');
  String get adminOfferVerifyLabel => t('ตรวจสิทธิ์', 'Verification');
  String get adminLeadFallbackTitle => t('เคสลูกค้า', 'Lead');
  String get adminNoPendingListings => t('ไม่มีประกาศรอตรวจ', 'No listings pending review');
  String get adminLatLabel => t('ละติจูด', 'Latitude');
  String get adminLngLabel => t('ลองจิจูด', 'Longitude');
  String adminViewingPrefix(String v) => t('นัด: $v', 'Viewing: $v');
  String adminLeadStatsLine(int leads, int accepted) =>
      t('เคส $leads · รับแล้ว $accepted', 'Leads: $leads · accepted: $accepted');
  String get adminCreateBoardIntro => t(
        'บอร์ดประกาศจาก RealXtate\n(ผู้ใช้จะไม่เห็นข้อเสนอของกัน)',
        'RealXtate board posts\n(Users cannot see each other\'s offers)',
      );
  String get adminBoardLeadsTitle =>
      t('คำขอจากหน้าหลัก', 'Requests from home');
  String get adminBoardLeadsHint => t(
        'ลูกค้าส่งจากเมนูหาทรัพย์ · เลือกรายการเพื่อตรวจสอบ แก้ไข และเผยแพร่บอร์ด',
        'Submitted from Find property · Select to review, edit, and publish to board',
      );
  String get adminBoardLeadsEmpty =>
      t('ไม่มีคำขอรอตรวจสอบ', 'No requests awaiting review');
  String get adminBoardFromLead =>
      t('มาจากคำขอหน้าหลัก', 'From home request');
  String get adminBoardEditAndPublish =>
      t('ตรวจสอบและเผยแพร่', 'Review & publish');
  String get adminBoardLeadPublished => t(
        'เผยแพร่บอร์ดแล้ว — คำขอนี้ปิดคิว',
        'Published to board — request cleared from queue',
      );
  String get adminBoardLeadClosed =>
      t('ปิดคำขอแล้ว (ไม่เผยแพร่)', 'Request closed (not published)');
  String get adminBoardCloseLead => t('ปิดคำขอ', 'Close request');
  String get adminBoardManualCreate =>
      t('สร้างบอร์ดด้วยตนเอง', 'Create board post manually');
  String get adminDashRequirements =>
      t('คำขอหาทรัพย์', 'Property requests');
  String get adminMaxPriceLabel => t('งบสูงสุด (บาท)', 'Max budget (THB)');
  String get adminMinAreaLabel => t('ตร.ม. ขั้นต่ำ', 'Min sqm');
  String get adminBtsDistanceLabel => t('ห่าง BTS (กม.)', 'Distance to BTS (km)');
  String get adminCreateBoardHint =>
      t('หาคอนโดย่านทองหล่อ BTS ≤1.5km ...', 'Condo Thonglor BTS ≤1.5km ...');
  String get adminBoardCreated => t('สร้างประกาศบอร์ดแล้ว', 'Board post created');
  String get adminReportsTitle => t('รายงานและส่งออกข้อมูล', 'Reports & Make.com');
  String get adminReportsConfigured =>
      t('ดึงจากสรุปรายวันในระบบ (ไม่มีเบอร์โทร)', 'From platform_stats_daily view (no phone numbers)');
  String get adminReportsDemo => t('โหมดทดลอง — ตัวเลขตัวอย่าง', 'Demo mode — sample numbers');
  String get adminDailyStats => t('สถิติรายวัน', 'Daily stats');
  String get adminMakecomSetup => t('เชื่อมส่งข้อมูลอัตโนมัติ', 'Make.com setup');
  String get adminMakecomInstructions => t(
        '1. ตั้งให้ดึงข้อมูลทุก 1 ชั่วโมง\n'
        '2. เรียกข้อมูลสรุปรายวันจากระบบ (7 วันล่าสุด)\n'
        '3. บันทึกลงสเปรดชีตทีละแถว\n\n'
        'ทางเลือก: แจ้งเตือนทันทีเมื่อมีเคสใหม่หรือนัดชม\n\n'
        'ดูคู่มือใน docs/MAKECOM.md',
        '1. Schedule every hour\n'
        '2. HTTP → Supabase REST\n'
        '   /rest/v1/platform_stats_daily?order=stat_date.desc&limit=7\n'
        '3. Google Sheets → Append row\n\n'
        'Webhook (optional): set MAKECOM_WEBHOOK_URL in Edge Functions\n'
        '→ receives lead_routed / appointment_scheduled\n\n'
        'See docs/MAKECOM.md and docs/phase-7-reporting-push.md',
      );
  String adminStatRowSubtitle(int leads, int accepted, int appts, int confirmed) => t(
        'เคส $leads (รับ $accepted) · นัดชม $appts (ยืนยัน $confirmed)',
        'Leads $leads (accepted $accepted) · viewings $appts (confirmed $confirmed)',
      );
  String get adminReportsCenterTitle =>
      t('ศูนย์รายงาน RealXtate', 'RealXtate Reports Center');
  String get adminReportDays7 => t('7 วัน', '7 days');
  String get adminReportDays14 => t('14 วัน', '14 days');
  String get adminReportDays30 => t('30 วัน', '30 days');
  String get adminReportTotalLeads => t('เคสลูกค้ารวม', 'Total leads');
  String get adminReportTotalAppts => t('นัดชมรวม', 'Total viewings');
  String get adminReportAcceptRate => t('อัตรารับเคส', 'Lead accept rate');
  String get adminReportConfirmRate => t('อัตรายืนยันนัด', 'Viewing confirm rate');
  String adminReportInDays(int n) => t('ใน $n วัน', 'Over $n days');
  String adminReportAcceptedCount(int n) => t('รับแล้ว $n', '$n accepted');
  String adminReportConfirmedCount(int n) => t('ยืนยัน $n', '$n confirmed');
  String adminReportCompletedCount(int n) => t('เสร็จสิ้น $n นัด', '$n completed');
  String adminReportRatePercent(int pct) => t('$pct%', '$pct%');
  String get adminReportFunnelTitle => t('ขั้นตอนปิดดีล', 'Deal funnel');
  String get adminReportFunnelLeads => t('เคสลูกค้า', 'Leads');
  String get adminReportFunnelAccepted => t('รับแล้ว', 'Accepted');
  String get adminReportFunnelAppts => t('นัดชม', 'Viewings');
  String get adminReportFunnelConfirmed => t('ยืนยัน', 'Confirmed');
  String get adminReportChartLeads => t('เคสรายวัน', 'Daily leads');
  String get adminReportChartAppts => t('นัดชมรายวัน', 'Daily viewings');
  String get adminOpenReportsCenter => t('เปิดศูนย์รายงาน →', 'Open reports center →');
  String get adminOverviewSectionUrgent => t('เร่งด่วน', 'Urgent');
  String get adminOverviewSectionPending =>
      t('ค้างดำเนินการ', 'Pending');
  String get adminOverviewSectionRisk =>
      t('ตรวจสอบ / ความเสี่ยง', 'Review & risk');
  String get adminOverviewSectionWait =>
      t('ระยะรอตอบ', 'Response wait');
  String get adminOverviewSectionUsage =>
      t('การใช้งานแอป 7 วัน', 'App usage (7d)');
  String get adminOverviewQueueUnclaimed =>
      t('รอรับงาน', 'Unclaimed queue');
  String get adminOverviewQueueMine => t('งานของฉัน', 'My queue');
  String get adminOverviewLongestWaitLabel =>
      t('รอนานสุด (รอรับงาน)', 'Longest wait (unclaimed)');
  String get adminOverviewNoWait => t('—', '—');
  String adminOverviewWaitMinutes(int m) =>
      t('$m นาที', '$m min');
  String adminOverviewWaitHours(int h, int m) =>
      t('$h ชม. $m นาที', '${h}h ${m}m');
  String adminOverviewWaitDays(int d, int h) =>
      t('$d วัน $h ชม.', '${d}d ${h}h');
  String adminOverviewWaitHint(int n) =>
      t('มี $n แชทรอรับงาน — กดเพื่อเปิดคิว', '$n unclaimed — tap to open queue');
  String adminOverviewAlertQueue(int queue, int attention) => t(
        'รอรับงาน $queue · ต้องทำ $attention',
        'Unclaimed $queue · $attention need action',
      );
  String get adminOverviewNewUsers7d =>
      t('ลีดใหม่ 7 วัน', 'New leads (7d)');
  String get adminDashActionHint =>
      t('แตะเพื่อไปคิวแชทหรือแท็บที่เกี่ยวข้อง', 'Tap to open chat queue or related tab');
  String listingShares(int n) => t('แชร์ $n', '$n shares');
  String listingChats(int n) => t('แชท $n', '$n chats');
  String get listingInsightsEmpty =>
      t('ยังไม่มีสถิติ — รอผู้สนใจเข้าชม', 'No stats yet — waiting for interest');
  String get listingPortfolioHint => t(
        'สถิติบนอุปกรณ์นี้ — ยังไม่รวมผู้ใช้คนอื่น',
        'Stats on this device — not aggregated across all users yet',
      );
  String get listingPortfolioActive => t('ประกาศเผยแพร่', 'Published');
  String get listingInsightViews => t('เข้าชม', 'Views');
  String get listingInsightChats => t('แชท', 'Chats');
  String get workLeadSummaryTitle => t('สรุปเคสลูกค้าของฉัน', 'My lead summary');
  String workLeadSummaryLine(int inbox, int accepted, int pending) => t(
        'กล่อง $inbox · รับแล้ว $accepted · รอดำเนินการ $pending',
        'Inbox $inbox · accepted $accepted · pending $pending',
      );
  String get adminAnalyticsTabOverview => t('ภาพรวม', 'Overview');
  String get adminAnalyticsTabFunnel => t('ขั้นปิดดีล', 'Funnel');
  String get adminAnalyticsTabGeo => t('เขต/โซน', 'Geography');
  String get adminAnalyticsTabChat => t('แชท/เวลาตอบ', 'Chat & SLA');
  String get adminAnalyticsTabListings => t('ทรัพย์ยอดนิยม', 'Top listings');
  String get adminAnalyticsTabExport => t('ส่งออก', 'Export');
  String get adminAnalyticsServerHint => t(
        'ดึงจากสรุปรายวันในระบบ — ออกแบบรองรับผู้ใช้หลายแสนคน',
        'From rollup tables (analytics_platform_daily) — built for 100k+ users',
      );
  String get adminAnalyticsRefreshRollup => t('รวมตัวเลขใหม่', 'Refresh rollups');
  String get adminAnalyticsRefreshRollupHint => t(
        'รวมการเข้าชม เคสลูกค้า นัดชม และสัญญาจากฐานข้อมูล — ระบบจะรันอัตโนมัติทุกชั่วโมง',
        'Merge events + leads/viewings/e-contracts — hourly cron in production',
      );
  String get adminAnalyticsRefreshed => t('รวมตัวเลขเรียบร้อยแล้ว', 'Rollups refreshed');
  String get adminAnalyticsCompareHint => t(
        'เทียบกับช่วงก่อนหน้า (ความยาวเท่ากัน)',
        'Compared to the previous period (same length)',
      );
  String adminAnalyticsDeltaPct(int pct) =>
      t('${pct >= 0 ? '+' : ''}$pct% เทียบช่วงก่อน', '${pct >= 0 ? '+' : ''}$pct% vs prior');
  String get adminAnalyticsDeltaNew => t('ใหม่', 'new');
  String get adminAnalyticsTotalViews => t('เข้าชมรวม', 'Total views');
  String get adminAnalyticsGmv => t('มูลค่าปิด (โดยประมาณ)', 'Est. closed GMV');
  String get adminAnalyticsNewUsersChart => t('ผู้ใช้ใหม่รายวัน', 'Daily new users');
  String get adminAnalyticsFullFunnel => t('ขั้นตอนปิดดีลครบวงจร', 'Full conversion funnel');
  String get adminAnalyticsFunnelViews => t('เข้าชม', 'Views');
  String get adminAnalyticsFunnelChats => t('เริ่มแชท', 'Chats');
  String get adminAnalyticsFunnelContract => t('สัญญาอิเล็กทรอนิกส์', 'E-Contract');
  String get adminAnalyticsFunnelClosed => t('ปิดดีล', 'Closed');
  String get adminAnalyticsGeoHint => t(
        'ความต้องการตามเขต — จากสรุปรายวันในระบบ',
        'Demand by district — from analytics_district_daily rollups',
      );
  String adminAnalyticsDistrictLine(int views, int leads, int appts) => t(
        'เข้าชม $views · เคส $leads · นัด $appts',
        'Views $views · leads $leads · viewings $appts',
      );
  String get adminAnalyticsChatVolume => t('แชทรวม', 'Total chats');
  String get adminAnalyticsSlaBreaches => t('เกินเวลาตอบ', 'SLA breaches');
  String adminAnalyticsChatCategory(String c) =>
      t('แชท: ${adminChatCategoryLabel(c)}', 'Chat: ${adminChatCategoryLabel(c)}');
  String adminAnalyticsChatLine(int vol, int claimed, int resolved, int sla, int? avgMin) => t(
        'เข้า $vol · รับ $claimed · ปิด $resolved · เกินเวลา $sla'
        '${avgMin != null ? ' · เฉลี่ย $avgMin นาที' : ''}',
        'In $vol · claimed $claimed · resolved $resolved · SLA $sla'
        '${avgMin != null ? ' · avg $avgMin min' : ''}',
      );
  String get adminAnalyticsTopListingsHint => t(
        'ประกาศที่มีความสนใจสูงสุดในช่วงที่เลือก',
        'Highest-engagement listings in the selected period',
      );
  String adminAnalyticsListingLine(int views, int chats, int leads) => t(
        'เข้าชม $views · แชท $chats · เคส $leads',
        'Views $views · chats $chats · leads $leads',
      );
  String get adminAnalyticsScaleNote => t(
        'ระบบรองรับผู้ใช้จำนวนมาก: บันทึกเหตุการณ์ → สรุปรายชั่วโมง → ส่งออกรายงาน\n'
        'ดู docs/phase-21-analytics-platform.md',
        'Scale path: analytics_events (append) → hourly rollup → Make.com/BigQuery.\n'
        'See docs/phase-21-analytics-platform.md',
      );
  String get adminAnalyticsPeriod12h => t('ทุก 12 ชม.', 'Every 12 hours');
  String get adminAnalyticsPeriod24h => t('ทุก 24 ชม.', 'Every 24 hours');
  String get adminAnalyticsPeriodDaily => t('รายวัน', 'Daily');
  String get adminAnalyticsPeriodHint => t(
        'เลือกความถี่รายงาน — 12/24 ชม. เหมาะดูแนวโน้มสั้น รายวันเหมาะดูย้อนหลัง',
        'Report granularity — 12/24h for short trends, daily for history',
      );
  String get adminAnalyticsTabApp => t('แอป', 'App');
  String get adminAnalyticsTabErrors => t('ข้อผิดพลาด', 'Errors');
  String get adminAnalyticsTabAudit => t('Audit log', 'Audit log');
  String get adminAuditLogEmpty =>
      t('ยังไม่มีบันทึก audit', 'No audit entries yet');
  String adminAuditLogEntity(String type, String id) =>
      t('entity: $type · $id', 'entity: $type · $id');
  String adminAuditLogActor(String name) =>
      t('โดย $name', 'by $name');
  String get adminAnalyticsAppInstalls => t('ติดตั้ง/ดาวน์โหลด', 'Installs');
  String get adminAnalyticsAppOpens => t('เปิดแอป', 'App opens');
  String get adminAnalyticsAppUninstalls => t('ถอนแอป (ประมาณ)', 'Uninstalls (est.)');
  String get adminAnalyticsAppHint => t(
        'เว็บ/PWA: นับ「ติดตั้ง」= เปิดครั้งแรกบนเครื่อง · ถอนแอปจริงบน iOS/Android ดูที่ App Store Connect / Play Console',
        'Web/PWA: install = first open on device · real uninstalls on stores: App Store Connect / Play Console',
      );
  String get adminAnalyticsErrorsHint => t(
        'รวบรวม error จากแอป — มีคำแปลไทยและแนวทางแก้',
        'Client errors with Thai guidance and fix steps',
      );
  String get adminAnalyticsErrorCount => t('ครั้ง', 'occurrences');
  String get adminAnalyticsErrorSessions => t('เซสชันที่กระทบ', 'Affected sessions');
  String get adminAnalyticsErrorFixTitle => t('แนวทางแก้ปัญหา', 'How to fix');
  String get adminAnalyticsErrorSeverityHigh => t('รุนแรง', 'High');
  String get adminAnalyticsErrorSeverityMedium => t('ปานกลาง', 'Medium');
  String get adminAnalyticsErrorSeverityLow => t('ต่ำ', 'Low');
  String get adminAnalyticsPeriodInstallChart => t('ติดตั้งตามช่วง', 'Installs by period');
  String get adminAnalyticsPeriodErrorChart => t('ข้อผิดพลาดตามช่วง', 'Errors by period');
  String get adminAnalyticsPeriodLeadsChart => t('เคสลูกค้าตามช่วง', 'Leads by period');

  /// แปลประเภทแชทในรายงานหลังบ้าน
  String adminChatCategoryLabel(String raw) {
    switch (raw) {
      case 'viewing_request':
        return 'ขอนัดดู';
      case 'booking_interest':
        return 'สนใจจอง';
      case 'discovery':
        return 'ค้นหาทรัพย์';
      case 'staff_support':
        return 'คุยกับเจ้าหน้าที่';
      case 'escalation':
        return 'ต้องคนดูแล';
      case 'demand_offer':
        return 'เสนอทรัพย์';
      case 'customer_requirement':
        return isEnglish ? 'Property need' : 'ความต้องการหาทรัพย์';
      case 'property_chat':
        return 'แชททรัพย์';
      case 'other':
        return 'อื่นๆ';
      default:
        return raw.replaceAll('_', ' ');
    }
  }
  String get listingPortfolioServerHint => t(
        'รวมจากเซิร์ฟเวอร์ (ทุกผู้ใช้)',
        'Aggregated from server (all users)',
      );

  // ── Property chat ──
  List<String> get discoveryChatQuickReplies => isEnglish
      ? [
          'Looking for a condo near BTS — budget around 15k',
          'Need a pet-friendly unit with parking',
          'Compare a few projects in Sukhumvit area',
          'Please recommend more options',
        ]
      : [
          'หาคอนโดใกล้ BTS งบประมาณ 15,000',
          'ต้องการห้องเลี้ยงสัตว์ได้ มีที่จอดรถ',
          'ช่วยเปรียบเทียบโครงการแถวสุขุมวิท',
          'ช่วยแนะนำทรัพย์เพิ่มให้หน่อย',
        ];

  List<String> get requirementChatQuickReplies => isEnglish
      ? [
          'Any updates on my search?',
          'Can you add more location options?',
          'Please publish on the board when ready',
        ]
      : [
          'มีความคืบหน้าเรื่องหาทรัพย์ไหมครับ',
          'ช่วยเพิ่มโซนที่สนใจได้ไหม',
          'พร้อมแล้วช่วยลงบอร์ดให้ด้วยครับ',
        ];

  String requirementSubmittedInThreadAck(String title) => t(
        'ส่งความต้องการแล้ว: $title — ทีมจะติดต่อในแชทเคสความต้องการ',
        'Requirement submitted: $title — our team will follow up in your need chat',
      );

  String requirementBoardCodeLabel(String code) =>
      t('บอร์ด: $code', 'Board: $code');

  String get adminBoardCloseLeadConfirm => t(
        'ปิดคำขอนี้โดยไม่เผยแพร่บนบอร์ด?',
        'Close this request without publishing to the board?',
      );

  String get adminBoardOpenChat => t('เปิดแชทเคส', 'Open case chat');

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
  String get chatPropertyTitle => t('RealXtate', 'RealXtate');
  String get chatAiTitle => chatPropertyTitle;

  String get adminInboxDiscovery => t('ค้นหาทรัพย์', 'Discovery');
  String get chatStaffEscalated => t(
        'ทีมงานได้รับแจ้งแล้ว — จะตอบในแชทนี้โดยเร็วที่สุด',
        'Team notified — will reply in this chat ASAP',
      );
  String get chatHintThai => t('พิมพ์คำถาม...', 'Type your question...');
  String get chatHintEnglish => t('Type in English...', 'Type in English...');
  String get chatViewingSubmitted => t('ส่งคำขอนัดดูแล้ว', 'Viewing request sent');
  String get chatTeamLivingBkk => t('ทีมงาน RealXtate', 'RealXtate team');
  String get chatMessageCopied =>
      t('คัดลอกข้อความแล้ว', 'Message copied');
  String get chatMessageCopyHint =>
      t('ลากคลุมข้อความเพื่อคัดลอก', 'Drag to select and copy');
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
  String get workLeadInbox => t('กล่องเคสลูกค้า (มอบหมาย)', 'Lead inbox (assigned)');
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
    if (f.hasZoneFilters) {
      parts.add(t('${f.zoneFilterCount} ทำเล', '${f.zoneFilterCount} areas'));
    }
    if (f.coAgentEligibleOnly == true) parts.add(filterLabelCoAgent);
    if (f.investorCategory == 'with_tenant') parts.add(filterSaleWithTenant);
    if (f.investorCategory == 'bmv') parts.add(filterBmv);
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
      t('RealXtate — ค้นหาทรัพย์', 'RealXtate — Property search');

  String get chatStaffRoomTitle =>
      t('เจ้าหน้าที่ RealXtate', 'RealXtate staff');

  String get chatDemandOfferRoomTitle => t('เสนอทรัพย์', 'Submit listing');
  String get chatDemandOfferWelcome => t(
        'แชทหมวด「เสนอทรัพย์」 — ส่งข้อเสนอตรงความต้องการบนบอร์ดได้ที่นี่\n'
        'ทีม RealXtate จะตรวจสอบและติดต่อกลับในแชทนี้',
        'Submit listing chat — send offers matching board requests here.\n'
        'RealXtate team will review and follow up in this chat.',
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
        'แชทส่งความต้องการหาทรัพย์ — ทีม RealXtate จะช่วยหาทรัพย์ที่ตรงเงื่อนไข\n'
        'และติดต่อกลับในแชทนี้',
        'Property need chat — RealXtate team will find matches\n'
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
        'สวัสดีครับ ผมผู้ช่วย RealXtate\n'
        '$chatAiDisclaimer\n\n'
        'บอกทำเล · โครงการ · งบประมาณ — ผมช่วยคัดทรัพย์ในระบบให้\n'
        'ตัวอย่าง: 「หาคอนโดเช่า ทองหล่อ งบ 18,000」',
        'Hello, I\'m the RealXtate assistant.\n'
        '$chatAiDisclaimer\n\n'
        'Tell me area, project & budget — I\'ll match listings for you.\n'
        'e.g. "Condo rent Thonglor budget 18,000"',
      );

  String chatStaffWelcome() => t(
        'สวัสดีครับ ทีม RealXtate พร้อมช่วยเหลือ\n'
        'พิมพ์คำถามได้เลย เราจะตอบกลับในแชทนี้โดยเร็วที่สุด',
        'Hello, the RealXtate team is here to help.\n'
        'Type your question — we\'ll reply in this chat ASAP.',
      );

  String chatPropertyWelcome(String listingTitle, {required bool allowViewing}) =>
      allowViewing
          ? t(
              'สวัสดีครับ ผมผู้ช่วย RealXtate สำหรับ $listingTitle\n'
              '$chatAiDisclaimer\n\n'
              'ถามรายละเอียดทรัพย์นี้ได้เลย — ถามหาทรัพย์อื่น/ทำเล/งบก็ได้ในแชทนี้\n'
              'หากต้องการนัดดูห้อง กด「ขอนัดดูห้อง」ด้านล่างเมื่อพร้อมครับ',
              'Hello, RealXtate assistant for $listingTitle.\n'
              '$chatAiDisclaimer\n\n'
              'Ask about this listing — or other areas/budgets in this chat.\n'
              'Tap「Request viewing」below when ready to book a visit.',
            )
          : t(
              'สวัสดีครับ ผมผู้ช่วย RealXtate สำหรับ $listingTitle\n'
              '$chatAiDisclaimer\n\n'
              'ถามเรื่องทำเล ราคา เงื่อนไข หรือให้แนะนำทรัพย์อื่นในระบบได้เลยครับ',
              'Hello, RealXtate assistant for $listingTitle.\n'
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
