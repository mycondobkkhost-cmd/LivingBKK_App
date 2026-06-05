import 'package:flutter/material.dart';

/// สายรถไฟฟ้า BTS / MRT — สีตามสายจริง + geo zones สำหรับกรองประกาศ
class BangkokTransitLine {
  const BangkokTransitLine({
    required this.slug,
    required this.systemTh,
    required this.systemEn,
    required this.nameTh,
    required this.nameEn,
    required this.stationsTh,
    required this.stationsEn,
    required this.color,
    required this.geoZoneSlugs,
    required this.imageSeed,
  });

  final String slug;
  final String systemTh;
  final String systemEn;
  final String nameTh;
  final String nameEn;
  final String stationsTh;
  final String stationsEn;
  final Color color;
  final List<String> geoZoneSlugs;
  final String imageSeed;

  String system(bool isEnglish) => isEnglish ? systemEn : systemTh;
  String name(bool isEnglish) => isEnglish ? nameEn : nameTh;
  String stations(bool isEnglish) => isEnglish ? stationsEn : stationsTh;
}

abstract final class BangkokTransitLines {
  static const all = <BangkokTransitLine>[
    BangkokTransitLine(
      slug: 'bts-sukhumvit',
      systemTh: 'BTS',
      systemEn: 'BTS',
      nameTh: 'สายสุขุมวิต',
      nameEn: 'Sukhumvit Line',
      stationsTh: 'อโศก · ทองหล่อ · เอกมัย · บางนา',
      stationsEn: 'Mo Chit · Asok · Thong Lo · Bang Na',
      color: Color(0xFF6DB33F),
      geoZoneSlugs: ['sukhumvit', 'asok', 'thonglor', 'bangna', 'ari'],
      imageSeed: 'bts-green',
    ),
    BangkokTransitLine(
      slug: 'bts-silom',
      systemTh: 'BTS',
      systemEn: 'BTS',
      nameTh: 'สายสีลม',
      nameEn: 'Silom Line',
      stationsTh: 'สนามกีฬา · ศาลาแดง · สุรศักดิ์',
      stationsEn: 'National Stadium · Sala Daeng · Surasak',
      color: Color(0xFF007A3D),
      geoZoneSlugs: ['silom'],
      imageSeed: 'bts-silom',
    ),
    BangkokTransitLine(
      slug: 'mrt-blue',
      systemTh: 'MRT',
      systemEn: 'MRT',
      nameTh: 'สายสีน้ำเงิน',
      nameEn: 'Blue Line',
      stationsTh: 'ลาดพร้าว · พระราม 9 · สุขุมวิท · หัวลำโพง',
      stationsEn: 'Lat Phrao · Rama IX · Sukhumvit · Hua Lamphong',
      color: Color(0xFF1A4F9C),
      geoZoneSlugs: ['ladprao', 'asok', 'sukhumvit'],
      imageSeed: 'mrt-blue',
    ),
    BangkokTransitLine(
      slug: 'mrt-purple',
      systemTh: 'MRT',
      systemEn: 'MRT',
      nameTh: 'สายสีม่วง',
      nameEn: 'Purple Line',
      stationsTh: 'เตาปูน · บางซื่อ · แยกติวานนท์ · คลองบางไผ่',
      stationsEn: 'Tao Poon · Bang Sue · Tiwanon · Bang Phai',
      color: Color(0xFF7B2D8E),
      geoZoneSlugs: ['nonthaburi'],
      imageSeed: 'mrt-purple',
    ),
    BangkokTransitLine(
      slug: 'mrt-yellow',
      systemTh: 'MRT',
      systemEn: 'MRT',
      nameTh: 'สายสีเหลือง',
      nameEn: 'Yellow Line',
      stationsTh: 'ลาดพร้าว · ภาวนา · ศรีกรีฑa · สมุทรปราการ',
      stationsEn: 'Lat Phrao · Phawana · Si Kritha · Samut Prakan',
      color: Color(0xFFF5C518),
      geoZoneSlugs: ['ladprao', 'samut-prakan'],
      imageSeed: 'mrt-yellow',
    ),
    BangkokTransitLine(
      slug: 'arl',
      systemTh: 'ARL',
      systemEn: 'ARL',
      nameTh: 'แอร์พอร์ต เรล ลิงก์',
      nameEn: 'Airport Rail Link',
      stationsTh: 'พญาไท · มักกะสัน · ลาดกระบัง · สวนพล',
      stationsEn: 'Phaya Thai · Makkasan · Lat Krabang · Suvarnabhumi',
      color: Color(0xFF8B2332),
      geoZoneSlugs: ['bangkok-all'],
      imageSeed: 'arl-red',
    ),
  ];

  static BangkokTransitLine? bySlug(String? slug) {
    if (slug == null) return null;
    for (final line in all) {
      if (line.slug == slug) return line;
    }
    return null;
  }
}
