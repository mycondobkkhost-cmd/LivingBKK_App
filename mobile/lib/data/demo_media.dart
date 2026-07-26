/// รูป·วิดีโอตัวอย่างอสังหา (คอนโด / บ้าน / ห้อง) — ไม่ใช้ picsum แบบสุ่ม
abstract final class DemoMedia {
  /// คลิปทัวร์ห้อง/อพาร์ตเมนต์สั้น (เงียบ·ลูปได้)
  static const sampleTourVideoUrl =
      'https://videos.pexels.com/video-files/3773486/3773486-sd_640_360_30fps.mp4';

  /// คลิปสำรอง — บ้านสมัยใหม่
  static const sampleHomeVideoUrl =
      'https://videos.pexels.com/video-files/5495938/5495938-sd_640_360_25fps.mp4';

  /// คอนโด / อพาร์ตเมนต์ — ภายในห้อง
  static const _condoIds = <String>[
    '1502672260266-1c1ef2d93688',
    '1522708323590-d24dbb6b0267',
    '1560448204-e02f11c3d0e2',
    '1493809842364-78817add7ffb',
    '1484154218962-a197022b5858',
    '1600607687939-ce8a6c25118c',
    '1600566753190-17f0baa2a6c3',
    '1600210492486-724fe5c67fb0',
    '1600210492493-0946911123ea',
    '1554995207-c18c203806cb',
    '1560185127-6ed189bf02f4',
    '1586023492125-27b2c045efd7',
    '1600047509807-ba8f99d2cdbc',
    '1560185893-a55cbc8c57bb',
  ];

  /// บ้าน / ทาวน์โฮม — หน้าบ้าน·สวน
  static const _houseIds = <String>[
    '1600596542815-ffad4c1539a9',
    '1600585154340-be6161a56a0c',
    '1512917774080-9991f1c4c750',
    '1613490493576-7fde63acd811',
    '1564013799919-ab600027ffc6',
    '1570129477492-45c003edd2be',
    '1600047509358-9dc7554da01e',
    '1605276374104-f3ad0e6b3f0f',
  ];

  /// ที่ดิน — ที่ว่าง / วิวที่ดิน
  static const _landIds = <String>[
    '1500382017468-9049fed747ef',
    '1628624747186-a941c476b98d',
    '1464822759023-fed622ff2c3b',
    '1500382017468-9049fed747ef',
    '1441975473320-08269d334dcc',
    '1472214103451-9374bd1c798e',
  ];

  /// Unsplash — รวม (fallback)
  static const _photoIds = <String>[
    ..._condoIds,
    ..._houseIds,
    '1563492065599-3520f775eeed',
    '1528183429752-a53968202fa0',
  ];

  /// โปสเตอร์โฆษณา 3:4
  static const promoExclusiveRent =
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=750&h=1000&q=80';
  static const promoRoomService =
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=750&h=1000&q=80';
  static const promoAgentPartner =
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=750&h=1000&q=80';

  /// ทำเลยอดฮิต — แนว skyline / อาคารเมือง
  static const areaThonglor =
      'https://images.unsplash.com/photo-1563492065599-3520f775eeed?auto=format&fit=crop&w=800&h=480&q=80';
  static const areaAsok =
      'https://images.unsplash.com/photo-1528183429752-a53968202fa0?auto=format&fit=crop&w=800&h=480&q=80';
  static const areaSukhumvit =
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&h=480&q=80';
  static const areaBangna =
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&h=480&q=80';
  static const areaAri =
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=800&h=480&q=80';
  static const areaSilom =
      'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=800&h=480&q=80';
  static const areaLadprao =
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&h=480&q=80';
  static const areaNonthaburi =
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&h=480&q=80';

  static List<String> _poolFor(String? propertyType) {
    final t = (propertyType ?? '').toLowerCase();
    if (t.contains('land') || t == 'ที่ดิน') return _landIds;
    if (t.contains('house') ||
        t.contains('town') ||
        t.contains('villa') ||
        t == 'บ้าน') {
      return _houseIds;
    }
    if (t.contains('condo') ||
        t.contains('apartment') ||
        t.contains('อพาร์ต') ||
        t.contains('คอนโด')) {
      return _condoIds;
    }
    return _photoIds;
  }

  static String photo(
    String seed, {
    int width = 800,
    int height = 600,
    String? propertyType,
  }) {
    final pool = _poolFor(propertyType);
    final id = pool[_stableIndex(seed, pool.length)];
    return 'https://images.unsplash.com/photo-$id'
        '?auto=format&fit=crop&w=$width&h=$height&q=80';
  }

  static List<String> gallery(
    String seed, {
    int count = 5,
    int width = 800,
    int height = 600,
    String? propertyType,
  }) {
    final pool = _poolFor(propertyType);
    final n = count.clamp(1, pool.length);
    return List.generate(
      n,
      (i) => photo(
        '$seed-$i',
        width: width,
        height: height,
        propertyType: propertyType,
      ),
    );
  }

  static int _stableIndex(String seed, int modulo) {
    if (modulo <= 0) return 0;
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h % modulo;
  }
}
