/// โซนทำเลสำหรับแท็กค้นหา — เชื่อมจากสถานีใกล้ / พิกัด
/// aliases รวมชื่อทำเลจาก Pantip hub (ไม่สร้าง polygon ใหม่)
class GeoZoneTagDef {
  const GeoZoneTagDef({
    required this.slug,
    required this.labelTh,
    required this.labelEn,
    required this.stationNamesTh,
    this.aliases = const [],
    this.maxKmFromZoneCenter = 1.2,
    this.centerLat,
    this.centerLng,
  });

  final String slug;
  final String labelTh;
  final String labelEn;
  final List<String> stationNamesTh;
  /// คำค้นเพิ่มจาก Pantip ZONE_ALIASES / zone_verified ที่พบบ่อย
  final List<String> aliases;
  final double maxKmFromZoneCenter;
  final double? centerLat;
  final double? centerLng;

  String label(bool english) => english ? labelEn : labelTh;
}

abstract final class BangkokGeoZoneTags {
  static const all = <GeoZoneTagDef>[
    GeoZoneTagDef(
      slug: 'sukhumvit-early',
      labelTh: 'สุขุมวิทตอนต้น',
      labelEn: 'Upper Sukhumvit',
      stationNamesTh: ['นานา', 'เพลินจิต', 'ชิดลม', 'ราชเทวี', 'พญาไท'],
      aliases: ['สุขุมวิท', 'sukhumvit', 'นานา', 'nana', 'ชิดลม', 'เพลินจิต'],
      centerLat: 13.742,
      centerLng: 100.552,
    ),
    GeoZoneTagDef(
      slug: 'asok',
      labelTh: 'อโศก',
      labelEn: 'Asok',
      stationNamesTh: ['อโศก', 'สุขุมวิท'],
      aliases: ['อโศก', 'asok', 'asoke', 'มักกะสัน', 'makkasan'],
      centerLat: 13.738,
      centerLng: 100.561,
    ),
    GeoZoneTagDef(
      slug: 'sukhumvit-mid',
      labelTh: 'สุขุมวิทกลาง',
      labelEn: 'Mid Sukhumvit',
      stationNamesTh: ['พร้อมพงษ์', 'ทองหล่อ', 'เอกมัย'],
      aliases: ['พร้อมพงษ์', 'phrom phong', 'สุขุมวิทกลาง'],
      centerLat: 13.728,
      centerLng: 100.576,
    ),
    GeoZoneTagDef(
      slug: 'thonglor',
      labelTh: 'ทองหล่อ–เอกมัย',
      labelEn: 'Thong Lo–Ekkamai',
      stationNamesTh: ['ทองหล่อ', 'เอกมัย'],
      aliases: [
        'ทองหล่อ',
        'thonglor',
        'thong lo',
        'เอกมัย',
        'ekkamai',
        'ekamai',
      ],
      centerLat: 13.722,
      centerLng: 100.582,
    ),
    GeoZoneTagDef(
      slug: 'bangna',
      labelTh: 'บางนา',
      labelEn: 'Bang Na',
      stationNamesTh: ['บางนา', 'แบริ่ง', 'สำโรง', 'บางจาก'],
      aliases: ['บางนา', 'bangna', 'bang na', 'แบริ่ง', 'สำโรง'],
      centerLat: 13.668,
      centerLng: 100.602,
    ),
    GeoZoneTagDef(
      slug: 'ari',
      labelTh: 'อารีย์',
      labelEn: 'Ari',
      stationNamesTh: ['อารีย์', 'สนามเป้า', 'หมอชิต'],
      aliases: ['อารีย์', 'ari', 'สนามเป้า', 'หมอชิต'],
      centerLat: 13.780,
      centerLng: 100.545,
    ),
    GeoZoneTagDef(
      slug: 'silom',
      labelTh: 'สีลม–สาทร',
      labelEn: 'Silom–Sathorn',
      stationNamesTh: ['ศาลาแดง', 'สีลม', 'ช่องนนทรี', 'สุรศักดิ์'],
      aliases: ['สีลม', 'silom', 'สาทร', 'sathorn', 'sathon', 'ศาลาแดง'],
      centerLat: 13.726,
      centerLng: 100.532,
    ),
    GeoZoneTagDef(
      slug: 'rama-9',
      labelTh: 'พระราม 9',
      labelEn: 'Rama IX',
      stationNamesTh: ['พระราม 9', 'ศูนย์วัฒนธรรม'],
      aliases: [
        'พระราม 9',
        'rama 9',
        'rama9',
        'RCA',
        'อาร์ซีเอ',
        'เพชรบุรีตัดใหม่',
        'เพชรบุรี',
      ],
      centerLat: 13.760,
      centerLng: 100.568,
    ),
    GeoZoneTagDef(
      slug: 'huai-khwang',
      labelTh: 'ห้วยขวาง',
      labelEn: 'Huai Khwang',
      stationNamesTh: ['ห้วยขวาง', 'สุทธิสาร'],
      aliases: ['ห้วยขวาง', 'huai khwang', 'huaikhwang', 'รัชดา', 'ratchada'],
      centerLat: 13.7785,
      centerLng: 100.5736,
    ),
    GeoZoneTagDef(
      slug: 'ladprao',
      labelTh: 'ลาดพร้าว',
      labelEn: 'Lat Phrao',
      stationNamesTh: ['ลาดพร้าว', 'ห้วยขวาง', 'พหลโยธิน'],
      aliases: ['ลาดพร้าว', 'ladprao', 'lat phrao'],
      centerLat: 13.800,
      centerLng: 100.573,
    ),
    GeoZoneTagDef(
      slug: 'onnut',
      labelTh: 'อ่อนนุช',
      labelEn: 'On Nut',
      stationNamesTh: [
        'อ่อนนุช',
        'อุดมสุข',
        'พระโขนง',
        'บางจาก',
        'ปุณณวิถี',
      ],
      aliases: ['อ่อนนุช', 'onnut', 'on nut', 'อุดมสุข', 'พระโขนง'],
      centerLat: 13.700,
      centerLng: 100.603,
    ),
  ];

  static GeoZoneTagDef? bySlug(String slug) {
    for (final z in all) {
      if (z.slug == slug) return z;
    }
    return null;
  }
}
