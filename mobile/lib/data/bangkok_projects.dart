/// โครงการจริงในกรุงเทพ — พิกัดจาก Google Places (searchText) อัปเดต 2026-07
/// ใช้สำหรับ demo, ค้นหา, และ Places API fallback
class BangkokProject {
  const BangkokProject({
    required this.slug,
    this.id,
    this.geoZoneId,
    required this.nameTh,
    required this.nameEn,
    required this.district,
    required this.lat,
    required this.lng,
    this.bts,
    this.aliases = const [],
    this.propertyType = 'condo',
    this.yearBuilt,
    this.facilities = const [],
  });

  final String slug;
  final String? id;
  final String? geoZoneId;
  final String nameTh;
  final String nameEn;
  final String district;
  final double lat;
  final double lng;
  final String? bts;
  final List<String> aliases;
  final String propertyType;
  /// จาก DB หรือ meta — ปีที่สร้างเสร็จ
  final int? yearBuilt;
  final List<String> facilities;
}

class BangkokProjects {
  static List<BangkokProject>? _cloudOverride;

  /// เรียกจาก [ProjectCatalog.load] เมื่อดึงจาก Supabase สำเร็จ
  static void useCloud(List<BangkokProject> projects) {
    _cloudOverride = projects;
  }

  static List<BangkokProject> get all => _cloudOverride ?? bootstrap;

  static const bootstrap = <BangkokProject>[
    BangkokProject(
      slug: 'true-thonglor',
      nameTh: 'ทรู ทองหล่อ',
      nameEn: 'THRU Thonglor',
      district: 'วัฒนา',
      lat: 13.744168,
      lng: 100.585446,
      bts: 'BTS ทองหล่อ',
      aliases: ['ทรู', 'ทองหล่อ', 'thonglor', 'trendy'],
    ),
    BangkokProject(
      slug: 'the-line-sukhumvit-101',
      nameTh: 'เดอะไลน์ สุขุมวิท 101',
      nameEn: 'The Line Sukhumvit 101',
      district: 'วัฒนา',
      lat: 13.691995,
      lng: 100.608228,
      bts: 'BTS บางจาก',
      aliases: ['line 101', 'เดอะไลน์'],
    ),
    BangkokProject(
      slug: 'noble-remix-thonglor',
      nameTh: 'โนเบิล รีมิกซ์ ทองหล่อ',
      nameEn: 'Noble Remix Thonglor',
      district: 'วัฒนา',
      lat: 13.724567,
      lng: 100.577260,
      bts: 'BTS ทองหล่อ',
      aliases: ['noble remix', 'โนเบิล'],
    ),
    BangkokProject(
      slug: 'rhythm-sukhumvit-36',
      nameTh: 'ริธึม สุขุมวิท 36',
      nameEn: 'Rhythm Sukhumvit 36',
      district: 'คลองเตย',
      lat: 13.721870,
      lng: 100.576904,
      bts: 'BTS ทองหล่อ',
      aliases: ['rhythm 36', 'ริธึม'],
    ),
    BangkokProject(
      slug: 'ashton-asoke',
      nameTh: 'แอสตัน อโศก',
      nameEn: 'Ashton Asoke',
      district: 'วัฒนา',
      lat: 13.738783,
      lng: 100.561071,
      bts: 'BTS อโศก / MRT สุขุมวิท',
      aliases: ['ashton', 'อโศก', 'asok'],
    ),
    BangkokProject(
      slug: 'life-asoke-hype',
      nameTh: 'ไลฟ์ อโศก ไฮป์',
      nameEn: 'Life Asoke Hype',
      district: 'วัฒนา',
      lat: 13.754291,
      lng: 100.562893,
      bts: 'BTS อโศก',
      aliases: ['life asoke', 'ไลฟ์ อโศก'],
    ),
    BangkokProject(
      slug: 'the-lofts-ekkamai',
      nameTh: 'เดอะ ลอฟท์ เอกมัย',
      nameEn: 'The Lofts Ekkamai',
      district: 'วัฒนา',
      lat: 13.718407,
      lng: 100.587647,
      bts: 'BTS เอกมัย',
      aliases: ['lofts ekkamai', 'เอกมัย', 'ekkamai'],
    ),
    BangkokProject(
      slug: 'hq-sukhumvit-101',
      nameTh: 'HQ สุขุมวิท 101',
      nameEn: 'HQ Sukhumvit 101',
      district: 'วัฒนา',
      lat: 13.729764,
      lng: 100.581401,
      bts: 'BTS บางจาก',
      aliases: ['hq 101'],
    ),
    BangkokProject(
      slug: 'tela-thonglor',
      nameTh: 'เทล่า ทองหล่อ',
      nameEn: 'Tela Thonglor',
      district: 'วัฒนา',
      lat: 13.733041,
      lng: 100.582043,
      bts: 'BTS ทองหล่อ',
      aliases: ['tela'],
    ),
    BangkokProject(
      slug: 'beatniq-sukhumvit-32',
      nameTh: 'บีทนิค สุขุมวิท 32',
      nameEn: 'Beatniq Sukhumvit 32',
      district: 'คลองเตย',
      lat: 13.726175,
      lng: 100.575635,
      bts: 'BTS ทองหล่อ',
      aliases: ['beatniq'],
    ),
    BangkokProject(
      slug: 'ideo-q-sukhumvit-36',
      nameTh: 'ไอดีโอ คิว สุขุมวิท 36',
      nameEn: 'Ideo Q Sukhumvit 36',
      district: 'คลองเตย',
      lat: 13.720876,
      lng: 100.576305,
      bts: 'BTS ทองหล่อ',
      aliases: ['ideo q', 'ไอดีโอ'],
    ),
    BangkokProject(
      slug: 'hyde-sukhumvit-11',
      nameTh: 'ไฮด์ สุขุมวิท 11',
      nameEn: 'Hyde Sukhumvit 11',
      district: 'วัฒนา',
      lat: 13.743641,
      lng: 100.556536,
      bts: 'BTS นานา',
      aliases: ['hyde 11', 'นานา', 'nana'],
    ),
    BangkokProject(
      slug: 'the-room-sukhumvit-38',
      nameTh: 'เดอะ รูม สุขุมวิท 38',
      nameEn: 'The Room Sukhumvit 38',
      district: 'คลองเตย',
      lat: 13.716981,
      lng: 100.579988,
      bts: 'BTS ทองหล่อ',
      aliases: ['the room 38'],
    ),
    BangkokProject(
      slug: 'aspire-sukhumvit-48',
      nameTh: 'แอสไพร์ สุขุมวิท 48',
      nameEn: 'Aspire Sukhumvit 48',
      district: 'คลองเตย',
      lat: 13.711081,
      lng: 100.593920,
      bts: 'BTS พร้อมพงษ์',
      aliases: ['aspire 48', 'พร้อมพงษ์'],
    ),
    BangkokProject(
      slug: 'lumpini-place-rama9',
      nameTh: 'ลุมพินี เพลส พระราม 9',
      nameEn: 'Lumpini Place Rama 9',
      district: 'ห้วยขวาง',
      lat: 13.756149,
      lng: 100.571142,
      bts: 'MRT พระราม 9',
      aliases: ['ลุมพินี พระราม 9', 'rama 9'],
    ),
    BangkokProject(
      slug: 'siamese-exclusive-queens',
      nameTh: 'ไซมิส เอ็กซ์คลูซีฟ ควีนส์',
      nameEn: 'Siamese Exclusive Queens',
      district: 'คลองเตย',
      lat: 13.723233,
      lng: 100.561119,
      bts: 'BTS ทองหล่อ',
      aliases: ['siamese queens'],
    ),
    BangkokProject(
      slug: 'the-tree-sukhumvit-71',
      nameTh: 'เดอะ ทรี สุขุมวิท 71',
      nameEn: 'The Tree Sukhumvit 71',
      district: 'วัฒนา',
      lat: 13.740614,
      lng: 100.599997,
      bts: 'BTS บางจาก',
      aliases: ['the tree 71'],
    ),
    BangkokProject(
      slug: 'u-delight-bangna',
      nameTh: 'ยู ดีไลท์ บางนา',
      nameEn: 'U Delight Bangna',
      district: 'บางนา',
      lat: 13.668200,
      lng: 100.604500,
      bts: 'BTS บางนา',
      aliases: ['u delight', 'บางนา', 'bangna'],
      propertyType: 'condo',
    ),
    BangkokProject(
      slug: 'the-key-wutthakat',
      nameTh: 'เดอะ คีย์ BTS วุฒากาศ',
      nameEn: 'The Key BTS Wutthakat',
      district: 'บางบอน',
      lat: 13.714112,
      lng: 100.468207,
      bts: 'BTS วุฒากาศ',
      aliases: ['the key wutthakat'],
    ),
    BangkokProject(
      slug: 'ideo-mobi-sukhumvit-81',
      nameTh: 'ไอดีโอ โมบิ สุขุมวิท 81',
      nameEn: 'Ideo Mobi Sukhumvit 81',
      district: 'บางนา',
      lat: 13.704654,
      lng: 100.602019,
      bts: 'BTS บางจาก',
      aliases: ['ideo mobi 81'],
    ),
    BangkokProject(
      slug: 'the-address-asoke',
      nameTh: 'ดิ แอดเดรส อโศก',
      nameEn: 'The Address Asoke',
      district: 'วัฒนา',
      lat: 13.749328,
      lng: 100.561926,
      bts: 'BTS อโศก',
      aliases: ['address asoke', 'แอดเดรส'],
    ),
    BangkokProject(
      slug: 'm-neighborhood-ari',
      nameTh: 'เอ็ม นีโบฮู้ด อารีย์',
      nameEn: 'M Neighborhood Ari',
      district: 'พญาไท',
      lat: 13.779689,
      lng: 100.544646,
      bts: 'BTS อารีย์',
      aliases: ['ari', 'อารีย์', 'm neighborhood'],
    ),
    BangkokProject(
      slug: 'villa-bangna-townhome',
      nameTh: 'วิลล่า บางนา',
      nameEn: 'Villa Bangna Townhome',
      district: 'บางนา',
      lat: 13.674863,
      lng: 100.599097,
      bts: 'BTS บางนา',
      aliases: ['วิลล่า บางนา'],
      propertyType: 'townhouse',
    ),
    BangkokProject(
      slug: 'sansiri-house-onnut',
      nameTh: 'บ้านเดี่ยว อ่อนนุช',
      nameEn: 'Detached House On Nut',
      district: 'สวนหลวง',
      lat: 13.712898,
      lng: 100.600884,
      bts: 'BTS อ่อนนุช',
      aliases: ['บ้าน', 'onnut', 'อ่อนนุช'],
      propertyType: 'house',
    ),
  ];

  static List<BangkokProject> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];
    return all.where((p) {
      final hay = [
        p.nameTh.toLowerCase(),
        p.nameEn.toLowerCase(),
        p.district.toLowerCase(),
        p.bts?.toLowerCase(),
        ...p.aliases.map((a) => a.toLowerCase()),
      ].whereType<String>().join(' ');
      return q.split(RegExp(r'\s+')).every((t) => t.length < 2 || hay.contains(t));
    }).toList();
  }

  static BangkokProject? bySlug(String slug) {
    for (final p in all) {
      if (p.slug == slug) return p;
    }
    return null;
  }
}
