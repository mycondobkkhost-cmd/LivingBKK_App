import 'package:flutter/material.dart';

import '../data/demo_media.dart';
import '../theme/living_bkk_brand.dart';

/// โปรโมชั่นหน้าแรก — เพิ่มรายการใหม่ได้ที่นี่ (รองรับอนาคต)
class HomePromoItem {
  const HomePromoItem({
    required this.id,
    required this.titleTh,
    required this.titleEn,
    required this.subtitleTh,
    required this.subtitleEn,
    required this.detailTh,
    required this.detailEn,
    required this.bulletTh,
    required this.bulletEn,
    this.imageAsset,
    this.imageUrl,
    this.videoUrl,
    required this.gradient,
    required this.accentColor,
    this.badgeTh,
    this.badgeEn,
  });

  final String id;
  final String titleTh;
  final String titleEn;
  final String subtitleTh;
  final String subtitleEn;
  final String detailTh;
  final String detailEn;
  final List<String> bulletTh;
  final List<String> bulletEn;
  final String? imageAsset;
  final String? imageUrl;
  /// ถ้ามี = ใช้ในช่องวิดีโอสั้นฝั่งขวา
  final String? videoUrl;
  final Gradient gradient;

  bool get hasNetworkImage => imageUrl?.isNotEmpty == true;
  bool get hasBundledImage => imageAsset?.isNotEmpty == true;
  bool get hasVideo => videoUrl?.isNotEmpty == true;
  final Color accentColor;
  final String? badgeTh;
  final String? badgeEn;

  String title(bool en) => en ? titleEn : titleTh;
  String subtitle(bool en) => en ? subtitleEn : subtitleTh;
  String detail(bool en) => en ? detailEn : detailTh;
  List<String> bullets(bool en) => en ? bulletEn : bulletTh;
  String? badge(bool en) {
    final b = en ? badgeEn : badgeTh;
    return b?.isNotEmpty == true ? b : null;
  }
}

abstract final class HomePromoConfig {
  static const assetDir = 'assets/promo/';

  /// ขนาดรูปสไลด์ซ้าย / โปสเตอร์วิดีโอขวา — กรอบ 3:4 เท่ากัน
  static const int imageWidthPx = 750;
  static const int imageHeightPx = 1000;
  static const double imageAspectRatio = 3 / 4;

  static const exclusiveRent = HomePromoItem(
    id: 'exclusive_rent',
    titleTh: 'ฝากปล่อยเช่า Exclusive',
    titleEn: 'Exclusive rental management',
    subtitleTh: 'ขั้นต่ำ 60 วัน · ล้างแอร์ฟรี 1 ครั้ง',
    subtitleEn: 'Min. 60 days · Free AC cleaning once',
    detailTh:
        'ฝากปล่อยเช่ากับ RealXtate แบบ Exclusive — ทีมงานดูแลครบตั้งแต่หาผู้เช่าจนถึงส่งมอบห้อง',
    detailEn:
        'List your rental exclusively with RealXtate — full-service from tenant matching to handover.',
    bulletTh: [
      'สัญญาขั้นต่ำเพียง 60 วัน',
      'รับโปรโมชั่นล้างแอร์ฟรี 1 ครั้ง ระหว่างที่มีผู้เช่า',
      'ไม่จำกัดจำนวนเครื่องแอร์',
      'ทีมงานช่วยโปรโมตและคัดกรองผู้เช่าให้',
    ],
    bulletEn: [
      'Minimum contract just 60 days',
      'Free AC cleaning once while tenanted',
      'Unlimited AC units included',
      'Our team promotes and screens tenants for you',
    ],
    imageAsset: '${assetDir}promo_exclusive_rent.png',
    imageUrl: DemoMedia.promoExclusiveRent,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [LivingBkkBrand.propNavy, LivingBkkBrand.piterPink],
    ),
    accentColor: Color(0xFFFFD54F),
  );

  static const roomService = HomePromoItem(
    id: 'room_service',
    titleTh: 'บริการตรวจรับห้องคืน',
    titleEn: 'Move-out room services',
    subtitleTh: 'ขั้นต่ำ 1,500 บาท',
    subtitleEn: 'From ฿1,500',
    detailTh:
        'บริการตรวจรับห้องคืน เริ่มต้นที่ 1,500 บาท — จ้างแม่บ้าน ซ่อมแซมและรีโนเวทในราคาพิเศษเมื่อจองผ่านทีมงาน RealXtate',
    detailEn:
        'Move-out room inspection from ฿1,500 — housekeeping, repairs and renovation at special rates via our team.',
    bulletTh: [
      'ตรวจรับห้องคืน เริ่มต้นที่ 1,500 บาท',
      'รายงานภาพประกอบหลังตรวจรับ',
      'จ้างแม่บ้านทำความสะอาดลึก',
      'ซ่อมแซมและรีโนเวทก่อนปล่อยเช่าใหม่',
    ],
    bulletEn: [
      'Move-out inspection from ฿1,500',
      'Photo report included',
      'Deep cleaning by vetted housekeeping',
      'Repairs and renovation before re-listing',
    ],
    imageAsset: '${assetDir}promo_room_service.png',
    imageUrl: DemoMedia.promoRoomService,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [LivingBkkBrand.propNavy, LivingBkkBrand.piterPink],
    ),
    accentColor: Color(0xFF4DD0E1),
  );

  /// ช่องขวา — วิดีโอสั้น (โปสเตอร์ + เล่นลูป)
  static const shortVideo = HomePromoItem(
    id: 'home_short_video',
    titleTh: 'พาร์ทเนอร์นายหน้า RealXtate',
    titleEn: 'RealXtate agent partners',
    subtitleTh: 'รับงานขาย·เช่า',
    subtitleEn: 'Sales & rent deals',
    detailTh:
        'คลิปสั้นทัวร์ห้องตัวอย่าง — เครือข่ายนายหน้า RealXtate รับงานขายและเช่า พร้อมทีมแอดมินช่วยประสาน',
    detailEn:
        'Short condo tour clip — join RealXtate agent partners for sales and rental deals with admin support.',
    bulletTh: [
      'รับงานทั้งขายและเช่าในพื้นที่ กทม.และปริมณฑล',
      'มีลีดและนัดชมจากระบบแมตช์',
    ],
    bulletEn: [
      'Sales and rental deals in Bangkok metro',
      'Leads and viewings from matching',
    ],
    imageAsset: '${assetDir}promo_agent_partner.png',
    imageUrl: DemoMedia.promoAgentPartner,
    videoUrl: DemoMedia.sampleTourVideoUrl,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [LivingBkkBrand.propNavy, Color(0xFF7C3AED)],
    ),
    accentColor: Color(0xFFFF8A65),
    badgeTh: 'คลิปสั้น',
    badgeEn: 'Short',
  );

  /// รายการทั้งหมด — ซ้ายสไลด์รูป / ขวาวิดีโอสั้น
  static const List<HomePromoItem> items = [
    exclusiveRent,
    roomService,
    shortVideo,
  ];

  static const Map<String, HomePromoItem> assetBySlug = {
    'exclusive_rent': exclusiveRent,
    'room_service': roomService,
    'home_short_video': shortVideo,
    'agent_partner': shortVideo,
  };
}
