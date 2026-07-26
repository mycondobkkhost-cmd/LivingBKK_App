import '../models/listing_public.dart';
import '../models/listing_transaction_types.dart';
import '../utils/reference_codes.dart';
import 'demo_media.dart';
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
    ('อโศก', 'Asoke', 'sukhumvit'),
    ('พร้อมพงษ์', 'Phrom Phong', 'sukhumvit'),
    ('เอกมัย', 'Ekkamai', 'thonglor'),
    ('รัชดา', 'Ratchada', 'bangkok-all'),
    ('ห้วยขวาง', 'Huai Khwang', 'bangkok-all'),
    ('พระราม 9', 'Rama 9', 'bangkok-all'),
    ('สาทร', 'Sathorn', 'bangkok-all'),
    ('สีลม', 'Silom', 'bangkok-all'),
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
      'condo' => 48,
      'house' => 28,
      'townhome' => 24,
      'apartment' => 24,
      'land' => 20,
      _ => 16,
    };

    return List.generate(count, (i) => _build(cat.slug, cat.dbValue, i));
  }

  static ListingPublic _build(String slug, String dbValue, int index) {
    final district = _districts[index % _districts.length];
    final districtTh = district.$1;
    final districtEn = district.$2;
    final geoZone = district.$3;
    final isRent = index.isEven;
    final isDual = slug == 'condo' && index % 8 == 1;
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
      'condo' => switch (index % 5) {
          0 => 'ไลฟ์ อโศก ${index + 1}',
          1 => 'ไอดีโอ Q ${index + 1}',
          2 => 'โนเบิล อราวน์ ${index + 1}',
          3 => 'ดิเอ็กซ์คลูซีฟ ${index + 1}',
          _ => 'ริทึ่ม สุขุมวิท ${index + 1}',
        },
      'house' => 'บ้านเดี่ยว $districtTh ${index + 1}',
      'townhome' => 'ทาวน์โฮม $districtTh ${index + 1}',
      'apartment' => 'อพาร์ทเมนต์ $districtTh ${index + 1}',
      'land' => 'ที่ดิน $districtTh ${index + 1}',
      'office' => 'สำนักงาน $districtTh ${index + 1}',
      'commercial' => 'อาคารพาณิชย์ $districtTh ${index + 1}',
      'home_office' => 'โฮมออฟฟิศ $districtTh ${index + 1}',
      'showroom' => 'โชว์รูม $districtTh ${index + 1}',
      'business' => 'กิจการ $districtTh ${index + 1}',
      'warehouse' => 'โกดัง $districtTh ${index + 1}',
      'factory' => 'โรงงาน $districtTh ${index + 1}',
      'co_working' => 'Co-Working $districtTh ${index + 1}',
      'pool_villa' => 'พูลวิลล่า $districtTh ${index + 1}',
      _ => '$labelTh $districtTh ${index + 1}',
    };

    final bedLabel = bedrooms == 0 ? 'สตูดิโอ' : '$bedrooms นอน';
    final bedLabelEn = bedrooms == 0 ? 'Studio' : '$bedrooms bed';
    // หัวข้อ 2 บรรทัดแนวรายการอสังหา — ไม่ซ้ำป้ายเช่า/ขายบนรูป
    final title = '$project\n'
        '${area.toInt()} ตร.ม. · $bedLabel · $districtTh';
    final titleEn = '$project\n'
        '${area.toInt()} sqm · $bedLabelEn · $districtEn';

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
      imageUrls: DemoMedia.gallery(
        'demo-cat-$slug-$index',
        count: 4 + (index % 3),
        width: 900,
        height: 600,
        propertyType: dbValue,
      ),
      description:
          'ตัวอย่าง$labelTh — $project ทำเล$districtTh พื้นที่ ${area.toInt()} ตร.ม. '
          'สำหรับทดสอบหน้าหมวดหมู่',
      descriptionEn:
          'Sample $labelTh listing — $project, $districtEn, ${area.toInt()} sqm.',
      ownerExclusiveMandate: false,
      ownerExclusiveContractDays: null,
      lastBumpAt: DateTime.now().subtract(
        Duration(minutes: index == 0 ? 25 : index * 90),
      ),
      updatedAt: DateTime.now().subtract(
        Duration(minutes: index == 0 ? 25 : index * 90),
      ),
    );
  }
}
