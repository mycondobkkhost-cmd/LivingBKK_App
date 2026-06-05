/// หมวดทรัพย์สำหรับค้นหา — เรียงคอนโด/บ้านก่อน (ค่า db ตรง enum Supabase หรือแมป)
class PropertyCategory {
  const PropertyCategory({
    required this.slug,
    required this.labelTh,
    required this.labelEn,
    required this.dbValue,
  });

  final String slug;
  final String labelTh;
  final String labelEn;
  /// ค่าใน `listings.property_type` — หมวดใหม่ที่ยังไม่มีใน DB ใช้ `other`
  final String dbValue;

  String label(bool isEnglish) => isEnglish ? labelEn : labelTh;
}

abstract final class PropertyCatalog {
  static const categories = [
    PropertyCategory(slug: 'condo', labelTh: 'คอนโด', labelEn: 'Condo', dbValue: 'condo'),
    PropertyCategory(slug: 'house', labelTh: 'บ้าน', labelEn: 'House', dbValue: 'house'),
    PropertyCategory(slug: 'townhome', labelTh: 'ทาวน์เฮ้าส์', labelEn: 'Townhome', dbValue: 'townhouse'),
    PropertyCategory(slug: 'apartment', labelTh: 'อพาร์ทเมนต์', labelEn: 'Apartment', dbValue: 'apartment'),
    PropertyCategory(slug: 'office', labelTh: 'ออฟฟิศ', labelEn: 'Office', dbValue: 'other'),
    PropertyCategory(slug: 'commercial', labelTh: 'อาคารพาณิชย์', labelEn: 'Commercial', dbValue: 'other'),
    PropertyCategory(slug: 'home_office', labelTh: 'โฮมออฟฟิศ', labelEn: 'Home office', dbValue: 'other'),
    PropertyCategory(slug: 'warehouse', labelTh: 'โกดัง', labelEn: 'Warehouse', dbValue: 'other'),
    PropertyCategory(slug: 'factory', labelTh: 'โรงงาน', labelEn: 'Factory', dbValue: 'other'),
    PropertyCategory(slug: 'land', labelTh: 'ที่ดิน', labelEn: 'Land', dbValue: 'other'),
  ];

  static PropertyCategory? bySlug(String? slug) {
    if (slug == null) return null;
    for (final c in categories) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  static String? dbValueForSlug(String? slug) => bySlug(slug)?.dbValue;
}
