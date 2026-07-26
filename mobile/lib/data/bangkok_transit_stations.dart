/// สถานี BTS/MRT สำหรับผลค้นหาแบบ Property Hub
/// aliases รวมชื่อไทย/อังกฤษจาก Pantip hub ที่ map เข้าสถานี RealXtate ได้
class TransitStationHit {
  const TransitStationHit({
    required this.nameTh,
    required this.nameEn,
    required this.geoZoneSlugs,
    this.aliases = const [],
  });

  final String nameTh;
  final String nameEn;
  final List<String> geoZoneSlugs;
  final List<String> aliases;
}

abstract final class BangkokTransitStations {
  static const all = <TransitStationHit>[
    TransitStationHit(
      nameTh: 'BTS อโศก',
      nameEn: 'BTS Asok',
      geoZoneSlugs: ['asok', 'sukhumvit'],
      aliases: ['อโศก', 'asok', 'asoke', 'bts asok', 'bts อโศก'],
    ),
    TransitStationHit(
      nameTh: 'BTS ทองหล่อ',
      nameEn: 'BTS Thong Lo',
      geoZoneSlugs: ['thonglor'],
      aliases: ['ทองหล่อ', 'thonglor', 'thong lo', 'bts ทองหล่อ'],
    ),
    TransitStationHit(
      nameTh: 'BTS เอกมัย',
      nameEn: 'BTS Ekkamai',
      geoZoneSlugs: ['thonglor'],
      aliases: ['เอกมัย', 'ekkamai', 'ekamai', 'bts เอกมัย'],
    ),
    TransitStationHit(
      nameTh: 'BTS พร้อมพงษ์',
      nameEn: 'BTS Phrom Phong',
      geoZoneSlugs: ['sukhumvit'],
      aliases: ['พร้อมพงษ์', 'phrom phong', 'phromphong', 'bts พร้อมพงษ์'],
    ),
    TransitStationHit(
      nameTh: 'BTS นานา',
      nameEn: 'BTS Nana',
      geoZoneSlugs: ['asok', 'sukhumvit'],
      aliases: ['นานา', 'nana', 'bts นานา'],
    ),
    TransitStationHit(
      nameTh: 'BTS ชิดลม',
      nameEn: 'BTS Chit Lom',
      geoZoneSlugs: ['asok'],
      aliases: ['ชิดลม', 'chidlom', 'chitlom', 'chit lom', 'bts ชิดลม'],
    ),
    TransitStationHit(
      nameTh: 'BTS เพลินจิต',
      nameEn: 'BTS Phloen Chit',
      geoZoneSlugs: ['asok'],
      aliases: ['เพลินจิต', 'ploenchit', 'phloen chit', 'bts เพลินจิต'],
    ),
    TransitStationHit(
      nameTh: 'BTS อ่อนนุช',
      nameEn: 'BTS On Nut',
      geoZoneSlugs: ['onnut'],
      aliases: ['อ่อนนุช', 'on nut', 'onnut', 'bts อ่อนนุช'],
    ),
    TransitStationHit(
      nameTh: 'BTS บางจาก',
      nameEn: 'BTS Bang Chak',
      geoZoneSlugs: ['onnut', 'bangna'],
      aliases: ['บางจาก', 'bangchak', 'bang chak', 'bts บางจาก'],
    ),
    TransitStationHit(
      nameTh: 'BTS บางนา',
      nameEn: 'BTS Bang Na',
      geoZoneSlugs: ['bangna'],
      aliases: ['บางนา', 'bangna', 'bang na', 'bts บางนา'],
    ),
    TransitStationHit(
      nameTh: 'BTS แบริ่ง',
      nameEn: 'BTS Bearing',
      geoZoneSlugs: ['bangna'],
      aliases: ['แบริ่ง', 'bearing', 'bts แบริ่ง'],
    ),
    TransitStationHit(
      nameTh: 'BTS สำโรง',
      nameEn: 'BTS Samrong',
      geoZoneSlugs: ['bangna'],
      aliases: ['สำโรง', 'samrong', 'bts สำโรง'],
    ),
    TransitStationHit(
      nameTh: 'BTS อารีย์',
      nameEn: 'BTS Ari',
      geoZoneSlugs: ['ari'],
      aliases: ['อารีย์', 'ari', 'bts อารีย์'],
    ),
    TransitStationHit(
      nameTh: 'BTS สยาม',
      nameEn: 'BTS Siam',
      geoZoneSlugs: ['asok'],
      aliases: ['สยาม', 'siam', 'bts สยาม'],
    ),
    TransitStationHit(
      nameTh: 'BTS พญาไท',
      nameEn: 'BTS Phaya Thai',
      geoZoneSlugs: ['ari'],
      aliases: ['พญาไท', 'phaya thai', 'bts พญาไท'],
    ),
    TransitStationHit(
      nameTh: 'BTS ราชเทวี',
      nameEn: 'BTS Ratchathewi',
      geoZoneSlugs: ['asok'],
      aliases: ['ราชเทวี', 'ratchathewi', 'bts ราชเทวี'],
    ),
    TransitStationHit(
      nameTh: 'BTS ศาลาแดง',
      nameEn: 'BTS Sala Daeng',
      geoZoneSlugs: ['silom'],
      aliases: ['ศาลาแดง', 'sala daeng', 'bts ศาลาแดง'],
    ),
    TransitStationHit(
      nameTh: 'BTS ช่องนนทรี',
      nameEn: 'BTS Chong Nonsi',
      geoZoneSlugs: ['silom'],
      aliases: ['ช่องนนทรี', 'chong nonsi', 'bts ช่องนนทรี'],
    ),
    TransitStationHit(
      nameTh: 'BTS สุรศักดิ์',
      nameEn: 'BTS Surasak',
      geoZoneSlugs: ['silom'],
      aliases: ['สุรศักดิ์', 'surasak', 'bts สุรศักดิ์'],
    ),
    TransitStationHit(
      nameTh: 'MRT สุขุมวิท',
      nameEn: 'MRT Sukhumvit',
      geoZoneSlugs: ['asok', 'sukhumvit'],
      aliases: ['mrt สุขุมวิท', 'mrt sukhumvit'],
    ),
    TransitStationHit(
      nameTh: 'MRT พระราม 9',
      nameEn: 'MRT Rama 9',
      geoZoneSlugs: ['rama-9'],
      aliases: ['พระราม 9', 'rama 9', 'rama9', 'mrt พระราม 9', 'mrt rama 9'],
    ),
    TransitStationHit(
      nameTh: 'MRT ห้วยขวาง',
      nameEn: 'MRT Huai Khwang',
      geoZoneSlugs: ['huai-khwang'],
      aliases: ['ห้วยขวาง', 'huai khwang', 'huaikhwang', 'mrt ห้วยขวาง'],
    ),
    TransitStationHit(
      nameTh: 'MRT ลาดพร้าว',
      nameEn: 'MRT Lat Phrao',
      geoZoneSlugs: ['ladprao'],
      aliases: ['ลาดพร้าว', 'lat phrao', 'ladprao', 'mrt ลาดพร้าว'],
    ),
    TransitStationHit(
      nameTh: 'MRT สีลม',
      nameEn: 'MRT Silom',
      geoZoneSlugs: ['silom'],
      aliases: ['mrt สีลม', 'mrt silom'],
    ),
    TransitStationHit(
      nameTh: 'MRT ลุมพินี',
      nameEn: 'MRT Lumphini',
      geoZoneSlugs: ['silom'],
      aliases: ['ลุมพินี', 'lumpini', 'lumphini', 'mrt ลุมพินี'],
    ),
    TransitStationHit(
      nameTh: 'ARL มักกะสัน',
      nameEn: 'ARL Makkasan',
      geoZoneSlugs: ['asok'],
      aliases: ['มักกะสัน', 'makkasan', 'arl มักกะสัน', 'airport link มักกะสัน'],
    ),
  ];

  static List<TransitStationHit> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];
    return all.where((s) {
      final hay = [
        s.nameTh,
        s.nameEn,
        ...s.aliases,
      ].join(' ').toLowerCase();
      final tokens = q.split(RegExp(r'\s+')).where((t) => t.length >= 2);
      return tokens.every(hay.contains) || hay.contains(q);
    }).toList();
  }
}
