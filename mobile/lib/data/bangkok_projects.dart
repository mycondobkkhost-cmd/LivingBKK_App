/// โครงการจริงในกรุงเทพ (พิกัดโดยประมาณจาก Google Maps / ข้อมูลสาธารณะ)
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
      lat: 13.7242,
      lng: 100.5805,
      bts: 'BTS ทองหล่อ',
      aliases: ['ทรู', 'ทองหล่อ', 'thonglor', 'trendy'],
    ),
    BangkokProject(
      slug: 'the-line-sukhumvit-101',
      nameTh: 'เดอะไลน์ สุขุมวิท 101',
      nameEn: 'The Line Sukhumvit 101',
      district: 'วัฒนา',
      lat: 13.6898,
      lng: 100.6072,
      bts: 'BTS บางจาก',
      aliases: ['line 101', 'เดอะไลน์'],
    ),
    BangkokProject(
      slug: 'noble-remix-thonglor',
      nameTh: 'โนเบิล รีมิกซ์ ทองหล่อ',
      nameEn: 'Noble Remix Thonglor',
      district: 'วัฒนา',
      lat: 13.7265,
      lng: 100.5828,
      bts: 'BTS ทองหล่อ',
      aliases: ['noble remix', 'โนเบิล'],
    ),
    BangkokProject(
      slug: 'rhythm-sukhumvit-36',
      nameTh: 'ริธึม สุขุมวิท 36',
      nameEn: 'Rhythm Sukhumvit 36',
      district: 'คลองเตย',
      lat: 13.7358,
      lng: 100.5712,
      bts: 'BTS ทองหล่อ',
      aliases: ['rhythm 36', 'ริธึม'],
    ),
    BangkokProject(
      slug: 'ashton-asoke',
      nameTh: 'แอสตัน อโศก',
      nameEn: 'Ashton Asoke',
      district: 'วัฒนา',
      lat: 13.7395,
      lng: 100.5635,
      bts: 'BTS อโศก / MRT สุขุมวิท',
      aliases: ['ashton', 'อโศก', 'asok'],
    ),
    BangkokProject(
      slug: 'life-asoke-hype',
      nameTh: 'ไลฟ์ อโศก ไฮป์',
      nameEn: 'Life Asoke Hype',
      district: 'วัฒนา',
      lat: 13.7412,
      lng: 100.5618,
      bts: 'BTS อโศก',
      aliases: ['life asoke', 'ไลฟ์ อโศก'],
    ),
    BangkokProject(
      slug: 'the-lofts-ekkamai',
      nameTh: 'เดอะ ลอฟท์ เอกมัย',
      nameEn: 'The Lofts Ekkamai',
      district: 'วัฒนา',
      lat: 13.7195,
      lng: 100.5855,
      bts: 'BTS เอกมัย',
      aliases: ['lofts ekkamai', 'เอกมัย', 'ekkamai'],
    ),
    BangkokProject(
      slug: 'hq-sukhumvit-101',
      nameTh: 'HQ สุขุมวิท 101',
      nameEn: 'HQ Sukhumvit 101',
      district: 'วัฒนา',
      lat: 13.6912,
      lng: 100.6058,
      bts: 'BTS บางจาก',
      aliases: ['hq 101'],
    ),
    BangkokProject(
      slug: 'tela-thonglor',
      nameTh: 'เทล่า ทองหล่อ',
      nameEn: 'Tela Thonglor',
      district: 'วัฒนา',
      lat: 13.7258,
      lng: 100.5778,
      bts: 'BTS ทองหล่อ',
      aliases: ['tela'],
    ),
    BangkokProject(
      slug: 'beatniq-sukhumvit-32',
      nameTh: 'บีทนิค สุขุมวิท 32',
      nameEn: 'Beatniq Sukhumvit 32',
      district: 'คลองเตย',
      lat: 13.7382,
      lng: 100.5675,
      bts: 'BTS ทองหล่อ',
      aliases: ['beatniq'],
    ),
    BangkokProject(
      slug: 'ideo-q-sukhumvit-36',
      nameTh: 'ไอดีโอ คิว สุขุมวิท 36',
      nameEn: 'Ideo Q Sukhumvit 36',
      district: 'คลองเตย',
      lat: 13.7345,
      lng: 100.5725,
      bts: 'BTS ทองหล่อ',
      aliases: ['ideo q', 'ไอดีโอ'],
    ),
    BangkokProject(
      slug: 'hyde-sukhumvit-11',
      nameTh: 'ไฮด์ สุขุมวิท 11',
      nameEn: 'Hyde Sukhumvit 11',
      district: 'วัฒนา',
      lat: 13.7448,
      lng: 100.5562,
      bts: 'BTS นานา',
      aliases: ['hyde 11', 'นานา', 'nana'],
    ),
    BangkokProject(
      slug: 'the-room-sukhumvit-38',
      nameTh: 'เดอะ รูม สุขุมวิท 38',
      nameEn: 'The Room Sukhumvit 38',
      district: 'คลองเตย',
      lat: 13.7328,
      lng: 100.5742,
      bts: 'BTS ทองหล่อ',
      aliases: ['the room 38'],
    ),
    BangkokProject(
      slug: 'aspire-sukhumvit-48',
      nameTh: 'แอสไพร์ สุขุมวิท 48',
      nameEn: 'Aspire Sukhumvit 48',
      district: 'คลองเตย',
      lat: 13.7285,
      lng: 100.5788,
      bts: 'BTS พร้อมพงษ์',
      aliases: ['aspire 48', 'พร้อมพงษ์'],
    ),
    BangkokProject(
      slug: 'lumpini-place-rama9',
      nameTh: 'ลุมพินี เพลส พระราม 9',
      nameEn: 'Lumpini Place Rama 9',
      district: 'ห้วยขวาง',
      lat: 13.7585,
      lng: 100.5652,
      bts: 'MRT พระราม 9',
      aliases: ['ลุมพินี พระราม 9', 'rama 9'],
    ),
    BangkokProject(
      slug: 'siamese-exclusive-queens',
      nameTh: 'ไซมิส เอ็กซ์คลูซีฟ ควีนส์',
      nameEn: 'Siamese Exclusive Queens',
      district: 'คลองเตย',
      lat: 13.7315,
      lng: 100.5765,
      bts: 'BTS ทองหล่อ',
      aliases: ['siamese queens'],
    ),
    BangkokProject(
      slug: 'the-tree-sukhumvit-71',
      nameTh: 'เดอะ ทรี สุขุมวิท 71',
      nameEn: 'The Tree Sukhumvit 71',
      district: 'วัฒนา',
      lat: 13.6985,
      lng: 100.6012,
      bts: 'BTS บางจาก',
      aliases: ['the tree 71'],
    ),
    BangkokProject(
      slug: 'u-delight-bangna',
      nameTh: 'ยู ดีไลท์ บางนา',
      nameEn: 'U Delight Bangna',
      district: 'บางนา',
      lat: 13.6702,
      lng: 100.6045,
      bts: 'BTS บางนา',
      aliases: ['u delight', 'บางนา', 'bangna'],
      propertyType: 'condo',
    ),
    BangkokProject(
      slug: 'the-key-wutthakat',
      nameTh: 'เดอะ คีย์ BTS วุฒากาศ',
      nameEn: 'The Key BTS Wutthakat',
      district: 'บางบอน',
      lat: 13.6635,
      lng: 100.5452,
      bts: 'BTS วุฒากาศ',
      aliases: ['the key wutthakat'],
    ),
    BangkokProject(
      slug: 'ideo-mobi-sukhumvit-81',
      nameTh: 'ไอดีโอ โมบิ สุขุมวิท 81',
      nameEn: 'Ideo Mobi Sukhumvit 81',
      district: 'บางนา',
      lat: 13.6855,
      lng: 100.6095,
      bts: 'BTS บางจาก',
      aliases: ['ideo mobi 81'],
    ),
    BangkokProject(
      slug: 'the-address-asoke',
      nameTh: 'ดิ แอดเดรส อโศก',
      nameEn: 'The Address Asoke',
      district: 'วัฒนา',
      lat: 13.7378,
      lng: 100.5625,
      bts: 'BTS อโศก',
      aliases: ['address asoke', 'แอดเดรส'],
    ),
    BangkokProject(
      slug: 'm-neighborhood-ari',
      nameTh: 'เอ็ม นีโบฮู้ด อารีย์',
      nameEn: 'M Neighborhood Ari',
      district: 'พญาไท',
      lat: 13.7795,
      lng: 100.5448,
      bts: 'BTS อารีย์',
      aliases: ['ari', 'อารีย์', 'm neighborhood'],
    ),
    BangkokProject(
      slug: 'villa-bangna-townhome',
      nameTh: 'วิลล่า บางนา',
      nameEn: 'Villa Bangna Townhome',
      district: 'บางนา',
      lat: 13.6688,
      lng: 100.6068,
      bts: 'BTS บางนา',
      aliases: ['วิลล่า บางนา'],
      propertyType: 'townhouse',
    ),
    BangkokProject(
      slug: 'sansiri-house-onnut',
      nameTh: 'บ้านเดี่ยว อ่อนนุช',
      nameEn: 'Detached House On Nut',
      district: 'สวนหลวง',
      lat: 13.7055,
      lng: 100.6285,
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
