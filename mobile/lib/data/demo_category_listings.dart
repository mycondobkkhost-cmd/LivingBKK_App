import '../models/listing_public.dart';
import '../models/listing_transaction_types.dart';
import '../utils/reference_codes.dart';
import 'property_catalog.dart';

/// ตัวอย่างประกาศต่อหมวดทรัพย์ — แสดงเมื่อกดเมนูหมวดจากหน้าแรก
abstract final class DemoCategoryListings {
  static const _districts = [
    ('สุขุมวิท', 'Sukhumvit', 'sukhumvit'),
    ('ทองหล่อ', 'Thong Lo', 'thonglor'),
    ('อ่อนนุช', 'On Nut', 'bangna'),
    ('ลาดพร้าว', 'Lat Phrao', 'ladprao'),
    ('บางนา', 'Bang Na', 'bangna'),
    ('พญาไท', 'Phaya Thai', 'bangkok-all'),
    ('จตุจักร', 'Chatuchak', 'bangkok-all'),
    ('รามคำแหง', 'Ramkhamhaeng', 'bangkok-all'),
  ];

  static List<ListingPublic> all() {
    final out = <ListingPublic>[];
    for (final cat in PropertyCatalog.categories) {
      out.addAll(forSlug(cat.slug));
    }
    return out;
  }

  static List<ListingPublic> forSlug(String? slug) {
    if (slug == null || slug.isEmpty) return const [];
    final cat = PropertyCatalog.bySlug(slug);
    if (cat == null) return const [];

    final count = switch (slug) {
      'condo' => 8,
      'house' => 5,
      'townhome' => 5,
      'apartment' => 4,
      _ => 3,
    };

    return List.generate(count, (i) => _build(cat.slug, cat.dbValue, i));
  }

  static ListingPublic _build(String slug, String dbValue, int index) {
    final district = _districts[index % _districts.length];
    final districtTh = district.$1;
    final districtEn = district.$2;
    final geoZone = district.$3;
    final isRent = index.isEven;
    final isDual = slug == 'condo' && index == 1;
    final listingType = isDual
        ? ListingTransactionTypes.rentAndSale
        : (isRent ? 'rent' : 'sale');
    final bedrooms = switch (slug) {
      'condo' || 'apartment' => index % 3,
      'townhome' => 2 + (index % 2),
      'house' => 3 + (index % 2),
      'land' => 0,
      _ => 1 + (index % 2),
    };
    final area = switch (slug) {
      'condo' || 'apartment' => 28.0 + index * 6,
      'townhome' => 120.0 + index * 15,
      'house' || 'pool_villa' => 150.0 + index * 20,
      'land' => 200.0 + index * 50,
      'office' || 'commercial' || 'showroom' || 'business' || 'co_working' =>
        80.0 + index * 25,
      _ => 60.0 + index * 12,
    };
    final rentPrice = (14000 + index * 3500).toDouble();
    final salePrice = (2800000 + index * 850000).toDouble();
    final promoRent = isRent || isDual ? rentPrice * 0.92 : null;
    final promoSale = !isRent || isDual ? salePrice * 0.95 : null;

    final labelTh = PropertyCatalog.bySlug(slug)?.labelTh ?? slug;
    final project = switch (slug) {
      'condo' => 'ไลฟ์ อโศก ${index + 1}',
      'house' => 'บ้านเดี่ยว $districtTh',
      'townhome' => 'ทาวน์โฮม $districtTh',
      'apartment' => 'อพาร์ทเมนต์ $districtTh',
      'land' => 'ที่ดิน $districtTh',
      'office' => 'สำนักงาน $districtTh',
      'commercial' => 'อาคารพาณิชย์ $districtTh',
      'home_office' => 'โฮมออฟฟิศ $districtTh',
      'showroom' => 'โชว์รูม $districtTh',
      'business' => 'กิจการ $districtTh',
      'warehouse' => 'โกดัง $districtTh',
      'factory' => 'โรงงาน $districtTh',
      'co_working' => 'Co-Working $districtTh',
      'pool_villa' => 'พูลวิลล่า $districtTh',
      _ => '$labelTh $districtTh',
    };

    final bedLabel = bedrooms == 0 ? 'สตูดิโอ' : '$bedrooms นอน';
    final txnLabel = isDual
        ? 'ขาย+เช่า'
        : (isRent ? 'เช่า' : 'ขาย');
    final title = '$txnLabel$labelTh · $project\n'
        '${area.toInt()} ตร.ม. · $bedLabel · ใกล้$districtTh';
    final titleEn = isDual
        ? 'Sale+rent $labelTh · $project\n'
            '${area.toInt()} sqm · near $districtEn'
        : '${isRent ? 'Rent' : 'Sale'} · $project\n'
            '${area.toInt()} sqm · near $districtEn';

    final seq = 800 + index + slug.hashCode.abs() % 100;
    final code = ReferenceCodes.listingCode(
      listingType: listingType,
      propertyType: dbValue,
      sequence: seq,
    );

    return ListingPublic(
      id: 'demo-cat-$slug-$index',
      listingCode: code,
      listingType: listingType,
      title: title,
      titleEn: titleEn,
      priceNet: isDual || isRent ? rentPrice : salePrice,
      priceSaleNet: isDual ? salePrice : null,
      promoPriceNet: promoRent,
      promoSalePriceNet: isDual ? promoSale : (promoSale != null && !isRent ? promoSale : null),
      district: districtTh,
      districtEn: districtEn,
      projectName: project,
      projectSlug: 'demo-cat-$slug',
      propertyType: dbValue,
      areaSqm: area,
      bedrooms: bedrooms,
      bathrooms: bedrooms <= 1 ? 1 : 2,
      floorRange: slug == 'condo' || slug == 'apartment' ? 'ชั้น ${8 + index}' : null,
      coAgentEligible: index % 3 == 0,
      petAllowed: index % 4 == 0,
      lat: 13.7563 + (index % 5) * 0.004,
      lng: 100.5018 + (index % 4) * 0.004,
      geoZoneSlug: geoZone,
      imageUrls: [
        'https://picsum.photos/seed/demo-cat-$slug-$index/900/600',
        'https://picsum.photos/seed/demo-cat-$slug-$index-b/900/600',
      ],
      description:
          'ตัวอย่าง$labelTh — $project ทำเล$districtTh พื้นที่ ${area.toInt()} ตร.ม. '
          'สำหรับทดสอบหน้าหมวดหมู่',
      descriptionEn:
          'Sample $labelTh listing — $project, $districtEn, ${area.toInt()} sqm.',
      ownerExclusiveMandate: index < 4,
      ownerExclusiveContractDays: index < 4 ? 30 : null,
      lastBumpAt: DateTime.now().subtract(
        Duration(minutes: index == 0 ? 25 : index * 90),
      ),
      updatedAt: DateTime.now().subtract(
        Duration(minutes: index == 0 ? 25 : index * 90),
      ),
    );
  }
}
