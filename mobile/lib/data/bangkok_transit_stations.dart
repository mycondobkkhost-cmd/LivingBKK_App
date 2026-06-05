/// สถานี BTS/MRT สำหรับผลค้นหาแบบ Property Hub
class TransitStationHit {
  const TransitStationHit({
    required this.nameTh,
    required this.nameEn,
    required this.geoZoneSlugs,
  });

  final String nameTh;
  final String nameEn;
  final List<String> geoZoneSlugs;
}

abstract final class BangkokTransitStations {
  static const all = <TransitStationHit>[
    TransitStationHit(
      nameTh: 'BTS อโศก',
      nameEn: 'BTS Asok',
      geoZoneSlugs: ['asok', 'sukhumvit'],
    ),
    TransitStationHit(
      nameTh: 'BTS ทองหล่อ',
      nameEn: 'BTS Thong Lo',
      geoZoneSlugs: ['thonglor'],
    ),
    TransitStationHit(
      nameTh: 'BTS เอกมัย',
      nameEn: 'BTS Ekkamai',
      geoZoneSlugs: ['thonglor'],
    ),
    TransitStationHit(
      nameTh: 'BTS บางนา',
      nameEn: 'BTS Bang Na',
      geoZoneSlugs: ['bangna'],
    ),
    TransitStationHit(
      nameTh: 'BTS อารีย์',
      nameEn: 'BTS Ari',
      geoZoneSlugs: ['ari'],
    ),
    TransitStationHit(
      nameTh: 'BTS สยาม',
      nameEn: 'BTS Siam',
      geoZoneSlugs: ['asok'],
    ),
    TransitStationHit(
      nameTh: 'MRT สุขุมวิท',
      nameEn: 'MRT Sukhumvit',
      geoZoneSlugs: ['asok', 'sukhumvit'],
    ),
    TransitStationHit(
      nameTh: 'MRT พระราม 9',
      nameEn: 'MRT Rama 9',
      geoZoneSlugs: ['rama-9'],
    ),
    TransitStationHit(
      nameTh: 'MRT ห้วยขวาง',
      nameEn: 'MRT Huai Khwang',
      geoZoneSlugs: ['huai-khwang'],
    ),
    TransitStationHit(
      nameTh: 'MRT ลาดพร้าว',
      nameEn: 'MRT Lat Phrao',
      geoZoneSlugs: ['ladprao'],
    ),
  ];

  static List<TransitStationHit> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];
    return all.where((s) {
      final hay = '${s.nameTh} ${s.nameEn}'.toLowerCase();
      final tokens = q.split(RegExp(r'\s+')).where((t) => t.length >= 2);
      return tokens.every(hay.contains) || hay.contains(q);
    }).toList();
  }
}
