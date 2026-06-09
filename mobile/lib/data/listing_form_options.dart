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
    // ── สถานะทรัพย์ / โควต้า ──
    ListingFormOption(id: 'foreign_quota', labelTh: 'โควต้าต่างชาติ', labelEn: 'Foreign quota'),
    ListingFormOption(id: 'brand_new', labelTh: 'ทรัพย์มือ 1', labelEn: 'Brand new'),
    ListingFormOption(id: 'second_hand', labelTh: 'ทรัพย์มือสอง', labelEn: 'Resale / second-hand'),
    ListingFormOption(id: 'renovated', labelTh: 'ทรัพย์รีโนเวท', labelEn: 'Renovated'),
    ListingFormOption(id: 'move_in_ready', labelTh: 'พร้อมย้ายเข้า', labelEn: 'Move-in ready'),
    ListingFormOption(id: 'modern_decor', labelTh: 'ตกแต่งทันสมัย', labelEn: 'Modern decor'),
    ListingFormOption(id: 'spacious', labelTh: 'ห้องกว้าง', labelEn: 'Spacious'),
    ListingFormOption(id: 'corner_unit', labelTh: 'มุมห้อง', labelEn: 'Corner unit'),
    ListingFormOption(id: 'high_floor', labelTh: 'ชั้นสูง', labelEn: 'High floor'),
    ListingFormOption(id: 'low_rise', labelTh: 'คอนโด Low-rise', labelEn: 'Low-rise'),
    ListingFormOption(id: 'high_rise', labelTh: 'คอนโด High-rise', labelEn: 'High-rise'),
    ListingFormOption(id: 'penthouse', labelTh: 'เพนท์เฮาส์', labelEn: 'Penthouse'),
    ListingFormOption(id: 'duplex', labelTh: 'ดูเพล็กซ์', labelEn: 'Duplex'),
    ListingFormOption(id: 'loft', labelTh: 'ลอฟท์', labelEn: 'Loft'),
    // ── ทำเล / การเดินทาง ──
    ListingFormOption(id: 'near_transit', labelTh: 'ใกล้ BTS/MRT', labelEn: 'Near BTS/MRT'),
    ListingFormOption(id: 'transit_linked', labelTh: 'ติดรถไฟฟ้า', labelEn: 'Transit-linked'),
    ListingFormOption(id: 'near_mall', labelTh: 'ใกล้ห้าง', labelEn: 'Near mall'),
    ListingFormOption(id: 'near_intl_school', labelTh: 'ใกล้โรงเรียนนานาชาติ', labelEn: 'Near intl. school'),
    ListingFormOption(id: 'river_view', labelTh: 'วิวแม่น้ำ', labelEn: 'River view'),
    ListingFormOption(id: 'park_view', labelTh: 'วิวสวน/สวนสาธารณะ', labelEn: 'Park / green view'),
    ListingFormOption(id: 'city_view', labelTh: 'วิวเมือง', labelEn: 'City view'),
    // ── เฟอร์นิเจอร์ / สิ่งอำนวยความสะดวกในห้อง ──
    ListingFormOption(id: 'fully_furnished', labelTh: 'เฟอร์ครบ', labelEn: 'Fully furnished'),
    ListingFormOption(id: 'unfurnished', labelTh: 'ห้องเปล่า', labelEn: 'Unfurnished'),
    ListingFormOption(id: 'appliances_included', labelTh: 'เครื่องใช้ไฟฟ้าครบ', labelEn: 'Appliances included'),
    ListingFormOption(id: 'new_ac', labelTh: 'แอร์ใหม่', labelEn: 'New A/C'),
    ListingFormOption(id: 'wide_parking', labelTh: 'ที่จอดรถกว้าง', labelEn: 'Wide parking'),
    // ── นโยบาย / กลุ่มผู้เช่า ──
    ListingFormOption(id: 'expat_friendly', labelTh: 'เหมาะชาวต่างชาติ', labelEn: 'Expat-friendly'),
    ListingFormOption(id: 'visa_ok', labelTh: 'รับ Visa / Work Permit', labelEn: 'Visa / work permit OK'),
    ListingFormOption(id: 'digital_nomad', labelTh: 'Digital Nomad', labelEn: 'Digital nomad'),
    ListingFormOption(id: 'company_reg', labelTh: 'จดทะเบียนบริษัทได้', labelEn: 'Company registration'),
    ListingFormOption(id: 'long_lease', labelTh: 'สัญญาเช่ายาว', labelEn: 'Long lease'),
    // ── การเงิน / ธุรกรรม ──
    ListingFormOption(id: 'direct_owner', labelTh: 'ผ่อนตรงเจ้าของ', labelEn: 'Pay owner directly'),
    ListingFormOption(id: 'negotiable', labelTh: 'ราคาต่อรองได้', labelEn: 'Negotiable'),
    ListingFormOption(id: 'urgent_sale', labelTh: 'ขายด่วน', labelEn: 'Urgent sale'),
    ListingFormOption(id: 'bank_loan_ok', labelTh: 'รับสินเชื่อธนาคาร', labelEn: 'Bank loan OK'),
    ListingFormOption(id: 'freehold', labelTh: 'Freehold', labelEn: 'Freehold'),
    ListingFormOption(id: 'leasehold', labelTh: 'Leasehold', labelEn: 'Leasehold'),
    ListingFormOption(id: 'low_common_fee', labelTh: 'ค่าส่วนกลางถูก', labelEn: 'Low common fee'),
    ListingFormOption(id: 'common_fee_included', labelTh: 'ค่าส่วนกลางรวมแล้ว', labelEn: 'Common fee included'),
    // ── ลงทุน ──
    ListingFormOption(id: 'investment_yield', labelTh: 'ลงทุนปล่อยเช่า', labelEn: 'Investment / rental yield'),
    ListingFormOption(id: 'tenanted_investment', labelTh: 'มีผู้เช่าปัจจุบัน', labelEn: 'Tenanted investment'),
    ListingFormOption(id: 'npa', labelTh: 'ทรัพย์ NPA', labelEn: 'NPA property'),
    ListingFormOption(id: 'luxury', labelTh: 'หรู / พรีเมียม', labelEn: 'Luxury / premium'),
    ListingFormOption(id: 'budget_friendly', labelTh: 'งบน้อย / คุ้มค่า', labelEn: 'Budget-friendly'),
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

  static const suggestedHashtagCount = 5;

  /// แท็กแนะนำตามประเภทประกาศ + ทรัพย์ — แสดงก่อน ที่เหลืออยู่หลัง「ดูเพิ่มเติม」
  static List<String> suggestedHashtagIds({
    required String listingType,
    String? propertyType,
    int limit = suggestedHashtagCount,
  }) {
    final pool = <String>[];

    switch (listingType) {
      case 'rent':
        pool.addAll([
          'near_transit',
          'fully_furnished',
          'move_in_ready',
          'expat_friendly',
          'long_lease',
          'budget_friendly',
          'company_reg',
        ]);
        break;
      case 'sale':
        pool.addAll([
          'second_hand',
          'brand_new',
          'bank_loan_ok',
          'freehold',
          'negotiable',
          'urgent_sale',
        ]);
        break;
      case 'sale_installment':
        pool.addAll([
          'direct_owner',
          'second_hand',
          'negotiable',
          'bank_loan_ok',
          'brand_new',
        ]);
        break;
      case 'rent_and_sale':
        pool.addAll([
          'near_transit',
          'fully_furnished',
          'investment_yield',
          'negotiable',
          'move_in_ready',
          'tenanted_investment',
        ]);
        break;
      default:
        pool.addAll([
          'near_transit',
          'move_in_ready',
          'negotiable',
          'brand_new',
          'second_hand',
        ]);
    }

    final pt = propertyType?.toLowerCase();
    if (pt == 'condo') {
      pool.insertAll(0, ['foreign_quota', 'high_rise', 'near_transit']);
    } else if (pt == 'house' || pt == 'townhouse') {
      pool.insertAll(0, ['spacious', 'wide_parking', 'move_in_ready']);
    } else if (pt == 'apartment') {
      pool.insertAll(0, ['budget_friendly', 'fully_furnished', 'near_transit']);
    }

    final seen = <String>{};
    final out = <String>[];
    for (final id in pool) {
      if (!hashtags.any((h) => h.id == id)) continue;
      if (seen.add(id)) out.add(id);
      if (out.length >= limit) break;
    }
    return out;
  }

  static ListingFormOption hashtagById(String id) =>
      hashtags.firstWhere(
        (h) => h.id == id,
        orElse: () => ListingFormOption(id: id, labelTh: id, labelEn: id),
      );

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
