import '../models/listing_public.dart';

/// ทรัพย์ตัวอย่างที่ผูกกับรหัสในโหมดเดโม (ลีด/ปฏิทิน/แชท)
abstract final class DemoCastListingPins {
  static const _coords = <String, (double lat, double lng)>{
    'LB-2026-000102': (13.7373, 100.5601),
    'RENT-CD-2026-000015': (13.7268, 100.5693),
    'SALE-HS-2026-000003': (13.8562, 100.5917),
    'RENT-CD-2026-000021': (13.7265, 100.5698),
    'SALE-CD-2026-000012': (13.7056, 100.6012),
    'RENT-CD-2026-000033': (13.7489, 100.5634),
    'RENT-CD-2026-000044': (13.7567, 100.5345),
    'RENT-CD-2026-000055': (13.7302, 100.5691),
    'SALE-HS-2026-000008': (13.6823, 100.6018),
    'RENT-CD-2026-000066': (13.6689, 100.6487),
    'RENT-CD-2026-000077': (13.8031, 100.5502),
    'SALE-CD-2026-000099': (13.7234, 100.5794),
    'RENT-CD-2026-000042': (13.7123, 100.6012),
  };

  static const titles = <String, String>{
    'LB-2026-000102': 'The Esse Asoke · 1BR',
    'RENT-CD-2026-000015': 'Rhythm Sukhumvit 36',
    'SALE-HS-2026-000003': 'บ้านเดี่ยว รามอินทรา',
    'RENT-CD-2026-000021': 'Ideo Q Sukhumvit 36',
    'SALE-CD-2026-000012': 'บ้านอ่อนนุชคอนโดมิเนียม',
    'RENT-CD-2026-000033': 'Life Asoke Hype',
    'RENT-CD-2026-000044': 'เดอะ ไลน์ ราชเทรี',
    'RENT-CD-2026-000055': 'ดี คอนโด เอกมัย',
    'SALE-HS-2026-000008': 'บ้านเดี่ยว พัฒนาการ',
    'RENT-CD-2026-000066': 'ศุภาลัย ปาร์ค บางนา',
    'RENT-CD-2026-000077': 'The Line จตุจักร',
    'SALE-CD-2026-000099': 'คอนโด สุขุมวิท',
    'RENT-CD-2026-000042': 'The Line Sukhumvit 101 · 2BR',
  };

  static String idForCode(String code) =>
      'demo-cast-${code.toLowerCase().replaceAll('-', '')}';

  static String? resolveId(String listingCode) {
    final upper = listingCode.trim().toUpperCase();
    if (upper.isEmpty || !titles.containsKey(upper)) return null;
    return idForCode(upper);
  }

  static List<ListingPublic> all() {
    return titles.entries.map((e) {
      final code = e.key;
      final title = e.value;
      final isRent = code.startsWith('RENT') || code.startsWith('LB');
      final isHouse = code.contains('-HS-');
      final coords = _coords[code] ?? (13.7234, 100.5794);
      final project = title.split(' · ').first;
      return ListingPublic(
        id: idForCode(code),
        listingCode: code,
        listingType: isRent ? 'rent' : 'sale',
        title: title,
        priceNet: isRent ? 28000 : 4500000,
        district: 'กรุงเทพฯ',
        projectName: project,
        propertyType: isHouse ? 'house' : 'condo',
        areaSqm: isHouse ? 120 : 35,
        bedrooms: isHouse ? 3 : 1,
        bathrooms: isHouse ? 3 : 1,
        lat: coords.$1,
        lng: coords.$2,
        imageUrls: [
          'https://picsum.photos/seed/$code-1/800/600',
          'https://picsum.photos/seed/$code-2/800/600',
        ],
        description: 'ทรัพย์ตัวอย่างสำหรับทดสอบแท็กหลังบ้าน — $title',
        coAgentEligible: true,
        petAllowed: false,
      );
    }).toList();
  }
}
