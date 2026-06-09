/// สร้าง catalog id ให้ตรงกับ [SearchZoneCatalog._transitId]
abstract final class SearchTagIds {
  static String transit(String system, String nameEn) {
    final sys = system.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final name = nameEn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return '$sys-$name'
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static String? transitLabelToId(String labelTh) {
    final m = RegExp(r'^(BTS|MRT|ARL|Gold)\s+(.+)$').firstMatch(labelTh.trim());
    if (m == null) return null;
    final system = m.group(1)!;
    final nameTh = m.group(2)!.trim();
    for (final s in _stationNameEnByTh.entries) {
      if (s.key == nameTh) return transit(system, s.value);
    }
    return transit(system, nameTh.replaceAll(' ', '-'));
  }

  static const _stationNameEnByTh = <String, String>{
    'หมอชิต': 'Mo Chit',
    'อารีย์': 'Ari',
    'สนามเป้า': 'Sanam Pao',
    'อนุสาวรีย์ชัยฯ': 'Victory Monument',
    'พญาไท': 'Phaya Thai',
    'ราชเทวี': 'Ratchathewi',
    'สยาม': 'Siam',
    'ชิดลม': 'Chit Lom',
    'เพลินจิต': 'Phloen Chit',
    'นานา': 'Nana',
    'อโศก': 'Asok',
    'พร้อมพงษ์': 'Phrom Phong',
    'ทองหล่อ': 'Thong Lo',
    'เอกมัย': 'Ekkamai',
    'อ่อนนุช': 'On Nut',
    'บางจาก': 'Bang Chak',
    'แบริ่ง': 'Bearing',
    'สำโรง': 'Samrong',
    'สุขุมวิท': 'Sukhumvit',
    'สีลม': 'Silom',
    'ลุมพินี': 'Lumphini',
    'คลองเตย': 'Khlong Toei',
    'พระราม 9': 'Phra Ram 9',
    'ห้วยขวาง': 'Huai Khwang',
    'ลาดพร้าว': 'Lat Phrao',
    'มักกะสัน': 'Makkasan',
    'หัวลำโพง': 'Hua Lamphong',
  };
}
