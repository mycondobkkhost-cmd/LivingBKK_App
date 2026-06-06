/// ตัวเลือกฟอร์มลงประกาศ — แฮชแท็ก / ส่วนกลาง (อ้างอิง LI ย่อ)
class ListingFormOption {
  const ListingFormOption({required this.id, required this.labelTh, required this.labelEn});

  final String id;
  final String labelTh;
  final String labelEn;

  String label(bool isEnglish) => isEnglish ? labelEn : labelTh;
}

abstract final class ListingFormOptions {
  static const hashtags = [
    ListingFormOption(id: 'foreign_quota', labelTh: 'โควต้าต่างชาติ', labelEn: 'Foreign quota'),
    ListingFormOption(id: 'brand_new', labelTh: 'ทรัพย์มือ 1', labelEn: 'Brand new'),
    ListingFormOption(id: 'second_hand', labelTh: 'ทรัพย์มือสอง', labelEn: 'Resale / second-hand'),
    ListingFormOption(id: 'renovated', labelTh: 'ทรัพย์รีโนเวท', labelEn: 'Renovated'),
    ListingFormOption(id: 'company_reg', labelTh: 'จดทะเบียนบริษัทได้', labelEn: 'Company registration'),
    ListingFormOption(id: 'direct_owner', labelTh: 'ผ่อนตรงเจ้าของ', labelEn: 'Pay owner directly'),
    ListingFormOption(id: 'npa', labelTh: 'ทรัพย์ NPA', labelEn: 'NPA property'),
  ];

  static const facilities = [
    ListingFormOption(id: 'security', labelTh: 'ระบบรักษาความปลอดภัย', labelEn: 'Security'),
    ListingFormOption(id: 'pool', labelTh: 'สระว่ายน้ำ', labelEn: 'Swimming pool'),
    ListingFormOption(id: 'fitness', labelTh: 'ฟิตเนส', labelEn: 'Fitness'),
    ListingFormOption(id: 'parking', labelTh: 'ที่จอดรถ', labelEn: 'Parking'),
    ListingFormOption(id: 'playground', labelTh: 'สนามเด็กเล่น', labelEn: 'Playground'),
    ListingFormOption(id: 'clubhouse', labelTh: 'คลับเฮ้าส์', labelEn: 'Clubhouse'),
    ListingFormOption(id: 'garden', labelTh: 'สวนหย่อม', labelEn: 'Garden'),
    ListingFormOption(id: 'ev_charger', labelTh: 'EV Charger', labelEn: 'EV charger'),
    ListingFormOption(id: 'coworking', labelTh: 'Co-working', labelEn: 'Co-working'),
  ];

  static String formatTagsSection(
    List<String> hashtagIds,
    List<String> facilityIds, {
    required bool isEnglish,
  }) {
    final parts = <String>[];
    if (hashtagIds.isNotEmpty) {
      final labels = hashtagIds
          .map((id) => hashtags.firstWhere((h) => h.id == id, orElse: () => ListingFormOption(id: id, labelTh: id, labelEn: id)))
          .map((h) => h.label(isEnglish))
          .join(', ');
      parts.add(isEnglish ? 'Highlights: $labels' : 'จุดเด่น: $labels');
    }
    if (facilityIds.isNotEmpty) {
      final labels = facilityIds
          .map((id) => facilities.firstWhere((f) => f.id == id, orElse: () => ListingFormOption(id: id, labelTh: id, labelEn: id)))
          .map((f) => f.label(isEnglish))
          .join(', ');
      parts.add(isEnglish ? 'Facilities: $labels' : 'ส่วนกลาง: $labels');
    }
    return parts.join('\n');
  }
}
