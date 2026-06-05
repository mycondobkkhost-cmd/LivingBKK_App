/// ทำเลยอดฮิตบนหน้าแรก — slug ตรง geo_zone ในระบบค้นหา
class PopularArea {
  const PopularArea({
    required this.slug,
    required this.nameTh,
    required this.nameEn,
    required this.subtitleTh,
    required this.subtitleEn,
    required this.imageUrl,
  });

  final String slug;
  final String nameTh;
  final String nameEn;
  final String subtitleTh;
  final String subtitleEn;
  final String imageUrl;

  String name(bool isEnglish) => isEnglish ? nameEn : nameTh;
  String subtitle(bool isEnglish) => isEnglish ? subtitleEn : subtitleTh;
}

/// แถวใน grid — เต็มความกว้าง หรือคู่ครึ่งความกว้าง (อ้างอิง RentHub)
class PopularAreasRowLayout {
  const PopularAreasRowLayout(this.slugs);

  final List<String> slugs;
  bool get isFull => slugs.length == 1;
}

class PopularAreasPageLayout {
  const PopularAreasPageLayout(this.rows);
  final List<PopularAreasRowLayout> rows;
}

abstract final class PopularAreas {
  static const all = <PopularArea>[
    PopularArea(
      slug: 'thonglor',
      nameTh: 'ทองหล่อ',
      nameEn: 'Thong Lo',
      subtitleTh: 'BTS ทองหล่อ · เอกมัย',
      subtitleEn: 'BTS Thong Lo · Ekkamai',
      imageUrl: 'https://picsum.photos/seed/livingbkk-thonglor/800/480',
    ),
    PopularArea(
      slug: 'asok',
      nameTh: 'อโศก',
      nameEn: 'Asok',
      subtitleTh: 'BTS อโศก · MRT สุขุมวิท',
      subtitleEn: 'BTS Asok · MRT Sukhumvit',
      imageUrl: 'https://picsum.photos/seed/livingbkk-asok/800/480',
    ),
    PopularArea(
      slug: 'sukhumvit',
      nameTh: 'สุขุมวิท',
      nameEn: 'Sukhumvit',
      subtitleTh: 'พร้อมพงษ์ · ทองหล่อ · อารีย์',
      subtitleEn: 'Phrom Phong · Thong Lo · Ari',
      imageUrl: 'https://picsum.photos/seed/livingbkk-sukhumvit/800/480',
    ),
    PopularArea(
      slug: 'bangna',
      nameTh: 'บางนา',
      nameEn: 'Bang Na',
      subtitleTh: 'BTS บางนา · อุดมสุข',
      subtitleEn: 'BTS Bang Na · Udom Suk',
      imageUrl: 'https://picsum.photos/seed/livingbkk-bangna/800/480',
    ),
    PopularArea(
      slug: 'ari',
      nameTh: 'อารีย์',
      nameEn: 'Ari',
      subtitleTh: 'BTS อารีย์ · ห้วยขวาง',
      subtitleEn: 'BTS Ari · Huai Khwang',
      imageUrl: 'https://picsum.photos/seed/livingbkk-ari/800/480',
    ),
    PopularArea(
      slug: 'silom',
      nameTh: 'สีลม–สาทร',
      nameEn: 'Silom–Sathorn',
      subtitleTh: 'BTS ศาลาแดง · Sathorn',
      subtitleEn: 'BTS Sala Daeng · Sathorn',
      imageUrl: 'https://picsum.photos/seed/livingbkk-silom/800/480',
    ),
    PopularArea(
      slug: 'ladprao',
      nameTh: 'ลาดพร้าว',
      nameEn: 'Lat Phrao',
      subtitleTh: 'MRT ลาดพร้าว · รัชโยธิน',
      subtitleEn: 'MRT Lat Phrao · Ratchadaphisek',
      imageUrl: 'https://picsum.photos/seed/livingbkk-ladprao/800/480',
    ),
    PopularArea(
      slug: 'nonthaburi',
      nameTh: 'นนทบุรี',
      nameEn: 'Nonthaburi',
      subtitleTh: 'Purple Line · ปากเกร็ด',
      subtitleEn: 'MRT Purple · Pak Kret',
      imageUrl: 'https://picsum.photos/seed/livingbkk-nonthaburi/800/480',
    ),
  ];

  /// หน้า grid แบบ RentHub — เต็มความกว้าง / คู่ครึ่งความกว้าง
  static const pages = <PopularAreasPageLayout>[
    PopularAreasPageLayout([
      PopularAreasRowLayout(['thonglor']),
      PopularAreasRowLayout(['ladprao', 'sukhumvit']),
      PopularAreasRowLayout(['asok']),
      PopularAreasRowLayout(['bangna']),
    ]),
    PopularAreasPageLayout([
      PopularAreasRowLayout(['silom']),
      PopularAreasRowLayout(['ari', 'nonthaburi']),
    ]),
  ];

  static final Map<String, PopularArea> _bySlug = {
    for (final a in all) a.slug: a,
  };

  static PopularArea? bySlug(String slug) => _bySlug[slug];
}
