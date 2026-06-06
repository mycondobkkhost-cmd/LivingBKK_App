import 'package:intl/intl.dart';

import '../data/property_catalog.dart';

/// ความต้องการหาทรัพย์ของลูกค้า — ส่งให้ทีมงานช่วยประกาศบนบอร์ด
class CustomerRequirement {
  const CustomerRequirement({
    required this.id,
    required this.transactionType,
    required this.propertyType,
    this.propertyTypes = const [],
    required this.zone,
    this.requesterRole = 'direct',
    this.locationLabels = const [],
    this.minPriceNet,
    this.maxPriceNet,
    this.minAreaSqm,
    this.furnishing = 'any',
    this.notes,
    this.contractStartBy,
    this.decisionTimeframe,
    this.preferredProjectName,
    this.preferredProjectSlug,
    this.buyPaymentTypes = const [],
    this.buyPurposes = const [],
    this.contactName = '',
    this.contactPhone = '',
    this.messengerId,
    this.status = 'pending',
    this.createdAt,
    this.savedToDatabase = false,
    this.urgentRush = false,
    this.threadId,
    this.demandPostId,
    this.demandPostCode,
  });

  final String id;
  final String transactionType; // rent | sale
  final String propertyType;
  final List<String> propertyTypes;
  final String zone;
  final String requesterRole; // direct | agent
  final List<String> locationLabels;
  final double? minPriceNet;
  final double? maxPriceNet;
  final double? minAreaSqm;
  final String furnishing;
  final String? notes;
  final DateTime? contractStartBy;
  final String? decisionTimeframe;
  final String? preferredProjectName;
  final String? preferredProjectSlug;
  final List<String> buyPaymentTypes;
  final List<String> buyPurposes;
  final String contactName;
  final String contactPhone;
  final String? messengerId;
  final String status;
  final DateTime? createdAt;
  final bool savedToDatabase;

  /// ลูกค้าต้องการหาแบบด่วนที่สุด — ทีมเผยแพร่บนบอร์ดพร้อมป้ายไฟ
  final bool urgentRush;

  /// แชทเคสความต้องการ (หลังส่งฟอร์ม)
  final String? threadId;

  /// บอร์ดที่เผยแพร่แล้ว
  final String? demandPostId;
  final String? demandPostCode;

  bool get isSale => transactionType == 'sale';
  bool get isRent => transactionType == 'rent';

  String titleTh({NumberFormat? currency}) => _title(isEnglish: false);
  String titleEn({NumberFormat? currency}) => _title(isEnglish: true);
  String localizedTitle(bool isEnglish) => _title(isEnglish: isEnglish);

  String _title({required bool isEnglish}) {
    final txn = isSale
        ? (isEnglish ? 'Buy ' : 'หาซื้อ')
        : (isEnglish ? 'Rent ' : 'หาเช่า');
    final prop = _propertyLabel(isEnglish);
    final zonePart = zone.trim().isNotEmpty
        ? zone.trim()
        : (locationLabels.isNotEmpty
            ? locationLabels.first
            : (preferredProjectName ?? (isEnglish ? 'Bangkok' : 'กทม.')));
    final parts = <String>['$txn$prop $zonePart'];

    if (minPriceNet != null || maxPriceNet != null) {
      parts.add(_budgetLabel(isEnglish));
    }
    if (minAreaSqm != null) {
      parts.add(isEnglish
          ? '${minAreaSqm!.toStringAsFixed(0)}+ sqm'
          : '${minAreaSqm!.toStringAsFixed(0)} ตร.ม. ขึ้นไป');
    }
    if (isRent && furnishing == 'unfurnished') {
      parts.add(isEnglish ? 'unfurnished' : 'ห้องเปล่า');
    }
    if (isRent && furnishing == 'furnished') {
      parts.add(isEnglish ? 'furnished' : 'พร้อมเฟอร์');
    }
    if (preferredProjectName != null && preferredProjectName!.isNotEmpty) {
      parts.add(isEnglish ? 'Project: $preferredProjectName' : 'โครงการ: $preferredProjectName');
    }
    if (requesterRole == 'agent') {
      parts.add(isEnglish ? 'Broker for client' : 'นายหน้ากำลังหาให้ลูกค้า');
    }
    return parts.join(' · ');
  }

  String _budgetLabel(bool isEnglish) {
    String fmt(double v) {
      if (v >= 1000000) {
        final m = v / 1000000;
        return isEnglish
            ? '${m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}M'
            : '${m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1)} ล้าน';
      }
      return isEnglish
          ? NumberFormat('#,###').format(v)
          : '${NumberFormat('#,###').format(v)} บาท';
    }

    if (minPriceNet != null && maxPriceNet != null) {
      return isEnglish
          ? '${fmt(minPriceNet!)}–${fmt(maxPriceNet!)}'
          : '${fmt(minPriceNet!)}–${fmt(maxPriceNet!)}';
    }
    if (maxPriceNet != null) {
      return isEnglish ? 'max ${fmt(maxPriceNet!)}' : 'ไม่เกิน ${fmt(maxPriceNet!)}';
    }
    return '';
  }

  List<String> get effectivePropertySlugs =>
      propertyTypes.isNotEmpty ? propertyTypes : [propertyType];

  String _propertyLabel(bool isEnglish) {
    final slugs = effectivePropertySlugs;
    if (slugs.length > 1) {
      return slugs
          .map((slug) {
            final cat = PropertyCatalog.bySlug(slug);
            return cat?.label(isEnglish) ?? slug;
          })
          .join(isEnglish ? ' / ' : '/');
    }
    final cat = PropertyCatalog.bySlug(slugs.first);
    if (cat != null) return cat.label(isEnglish);
    return slugs.first;
  }

  /// สรุปสำหรับส่งในแชททีมงาน
  Map<String, String> toChatSummary(bool isEnglish) {
    final map = <String, String>{};
    map[isEnglish ? 'Need' : 'ความต้องการ'] = localizedTitle(isEnglish);
    map[isEnglish ? 'Role' : 'ผู้แจ้ง'] = requesterRole == 'agent'
        ? (isEnglish ? 'Broker for client' : 'นายหน้ากำลังหาให้ลูกค้า')
        : (isEnglish ? 'Direct customer' : 'ลูกค้าโดยตรง');
    map[isEnglish ? 'Transaction' : 'ประเภท'] =
        isSale ? (isEnglish ? 'Buy' : 'หาซื้อ') : (isEnglish ? 'Rent' : 'หาเช่า');
    map[isEnglish ? 'Property type' : 'ประเภททรัพย์'] = _propertyLabel(isEnglish);
    if (locationLabels.isNotEmpty) {
      map[isEnglish ? 'Projects / areas' : 'โครงการ / ทำเล'] =
          locationLabels.join(', ');
    }
    if (minPriceNet != null && maxPriceNet != null) {
      map[isEnglish ? 'Budget' : 'งบ'] =
          '${minPriceNet!.toInt()}–${maxPriceNet!.toInt()}';
    }
    if (minAreaSqm != null) {
      map[isEnglish ? 'Min area' : 'ขนาดขั้นต่ำ'] =
          '${minAreaSqm!.toStringAsFixed(0)} ${isEnglish ? 'sqm' : 'ตร.ม.'}';
    }
    if (isRent && furnishing != 'any') {
      map[isEnglish ? 'Furnishing' : 'การตกแต่ง'] = furnishing == 'furnished'
          ? (isEnglish ? 'Furnished' : 'พร้อมเฟอร์')
          : (isEnglish ? 'Unfurnished' : 'ห้องเปล่า');
    }
    if (contractStartBy != null) {
      map[isEnglish ? 'Lease start by' : 'เริ่มสัญญาไม่เกิน'] =
          contractStartBy!.toIso8601String().split('T').first;
    }
    if (decisionTimeframe != null) {
      map[isEnglish ? 'Decision' : 'ตัดสินใจ'] =
          _decisionLabel(decisionTimeframe!, isEnglish);
    }
    if (contactName.trim().isNotEmpty) {
      map[isEnglish ? 'Name' : 'ชื่อ'] = contactName.trim();
    }
    if (contactPhone.trim().isNotEmpty) {
      map[isEnglish ? 'Phone' : 'เบอร์โทร'] = contactPhone.trim();
    }
    if (messengerId != null && messengerId!.trim().isNotEmpty) {
      map[isEnglish ? 'WhatsApp' : 'Line ID'] = messengerId!.trim();
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      map[isEnglish ? 'Notes' : 'หมายเหตุ'] = notes!.trim();
    }
    if (urgentRush) {
      map[isEnglish ? 'Urgency' : 'ความเร่งด่วน'] = isEnglish
          ? '🔥 Fastest match — rush badge on board'
          : '🔥 หาแบบด่วนที่สุด — แสดงป้ายไฟบนบอร์ด';
    }
    return map;
  }

  static String _decisionLabel(String key, bool isEnglish) {
    const th = {
      'book_now': 'พร้อมจองเลย',
      'still_comparing': 'ยังเปรียบเทียบอยู่',
      'within_1_week': 'ภายใน 1 สัปดาห์',
      'within_2_weeks': 'ภายใน 2 สัปดาห์',
      'within_1_month': 'ภายใน 1 เดือน',
      'flexible': 'ยืดหยุ่น',
    };
    const en = {
      'book_now': 'Ready to book',
      'still_comparing': 'Still comparing',
      'within_1_week': 'Within 1 week',
      'within_2_weeks': 'Within 2 weeks',
      'within_1_month': 'Within 1 month',
      'flexible': 'Flexible',
    };
    return (isEnglish ? en : th)[key] ?? key;
  }

  String statusLabel(bool isEnglish) {
    switch (status) {
      case 'published':
        return isEnglish ? 'Published on board' : 'ประกาศบนบอร์ดแล้ว';
      case 'closed':
        return isEnglish ? 'Closed' : 'ปิดแล้ว';
      default:
        return isEnglish ? 'Pending team review' : 'รอทีมงานตรวจสอบ';
    }
  }

  @Deprecated('Use statusLabel(isEnglish)')
  String statusLabelTh() => statusLabel(false);

  Map<String, dynamic> toInsertJson(String? userId) {
    return {
      if (userId != null) 'user_id': userId,
      'transaction_type': transactionType,
      'property_type': propertyType,
      'zone': zone,
      'min_price_net': minPriceNet,
      'max_price_net': maxPriceNet,
      'min_area_sqm': minAreaSqm,
      'furnishing': furnishing,
      'notes': compiledNotes(),
      'title': titleTh(),
      'status': 'pending',
      'requester_role': requesterRole,
      'urgent_rush': urgentRush,
      'payload': toPayloadJson(),
    };
  }

  Map<String, dynamic> toPayloadJson() => {
        'property_types': propertyTypes,
        'location_labels': locationLabels,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        if (messengerId != null) 'messenger_id': messengerId,
        if (contractStartBy != null)
          'contract_start_by': contractStartBy!.toIso8601String(),
        if (decisionTimeframe != null) 'decision_timeframe': decisionTimeframe,
        if (preferredProjectName != null) 'preferred_project_name': preferredProjectName,
        if (preferredProjectSlug != null) 'preferred_project_slug': preferredProjectSlug,
        'buy_payment_types': buyPaymentTypes,
        'buy_purposes': buyPurposes,
        if (notes != null && notes!.trim().isNotEmpty) 'raw_notes': notes!.trim(),
      };

  factory CustomerRequirement.fromRow(Map<String, dynamic> row) {
    final payload = row['payload'];
    final map = payload is Map ? Map<String, dynamic>.from(payload) : <String, dynamic>{};

    List<String> strList(dynamic v) {
      if (v is! List) return const [];
      return v.map((e) => e.toString()).toList();
    }

    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final propertyTypes = strList(map['property_types']);
    final locationLabels = strList(map['location_labels']);

    return CustomerRequirement(
      id: row['id']?.toString() ?? '',
      transactionType: row['transaction_type']?.toString() ?? 'rent',
      propertyType: row['property_type']?.toString() ?? 'condo',
      propertyTypes: propertyTypes,
      zone: row['zone']?.toString() ?? '',
      requesterRole: row['requester_role']?.toString() ?? 'direct',
      locationLabels: locationLabels.isNotEmpty
          ? locationLabels
          : (row['zone']?.toString().isNotEmpty == true
              ? [row['zone'].toString()]
              : const []),
      minPriceNet: _num(row['min_price_net']) ?? _num(map['min_price_net']),
      maxPriceNet: _num(row['max_price_net']),
      minAreaSqm: _num(row['min_area_sqm']),
      furnishing: row['furnishing']?.toString() ?? 'any',
      notes: map['raw_notes']?.toString() ?? row['notes']?.toString(),
      contractStartBy: parseDt(map['contract_start_by']),
      decisionTimeframe: map['decision_timeframe']?.toString(),
      preferredProjectName: map['preferred_project_name']?.toString(),
      preferredProjectSlug: map['preferred_project_slug']?.toString(),
      buyPaymentTypes: strList(map['buy_payment_types']),
      buyPurposes: strList(map['buy_purposes']),
      contactName: map['contact_name']?.toString() ?? '',
      contactPhone: map['contact_phone']?.toString() ?? '',
      messengerId: map['messenger_id']?.toString(),
      status: row['status']?.toString() ?? 'pending',
      createdAt: parseDt(row['created_at']),
      savedToDatabase: true,
      urgentRush: row['urgent_rush'] == true,
      threadId: row['thread_id']?.toString(),
      demandPostId: row['demand_post_id']?.toString(),
      demandPostCode: _demandPostCodeFromRow(row),
    );
  }

  static String? _demandPostCodeFromRow(Map<String, dynamic> row) {
    final posts = row['demand_posts'];
    if (posts is Map) {
      return posts['post_code']?.toString();
    }
    return null;
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// ข้อความบอร์ดเริ่มต้นจากคำขอหน้าหลัก (แอดมินแก้ได้ก่อนเผยแพร่)
  String suggestedBoardDescription() => compiledNotes();

  /// รวมรายละเอียดทั้งหมดใน notes สำหรับทีมงาน
  String compiledNotes() {
    final buf = <String>[];
    if (propertyTypes.isNotEmpty) {
      final labels = propertyTypes
          .map((slug) => PropertyCatalog.bySlug(slug)?.label(false) ?? slug)
          .join(', ');
      buf.add('ประเภททรัพย์: $labels');
    }
    if (minPriceNet != null && maxPriceNet != null) {
      buf.add('งบ: ${minPriceNet!.toInt()}–${maxPriceNet!.toInt()}');
    }
    if (contractStartBy != null) {
      buf.add('เริ่มสัญญาไม่เกิน: ${contractStartBy!.toIso8601String().split('T').first}');
    }
    if (decisionTimeframe != null) {
      buf.add('ตัดสินใจ: $decisionTimeframe');
    }
    if (locationLabels.isNotEmpty) {
      buf.add('ทำเล/โครงการ: ${locationLabels.join(", ")}');
    }
    if (requesterRole == 'agent') {
      buf.add('ผู้แจ้ง: นายหน้ากำลังหาให้ลูกค้า');
    }
    if (contactName.trim().isNotEmpty) {
      buf.add('ชื่อ: ${contactName.trim()}');
    }
    if (contactPhone.trim().isNotEmpty) {
      buf.add('เบอร์: ${contactPhone.trim()}');
    }
    if (messengerId != null && messengerId!.trim().isNotEmpty) {
      buf.add('Line/WhatsApp: ${messengerId!.trim()}');
    }
    if (buyPaymentTypes.isNotEmpty) {
      buf.add('การชำระ: ${buyPaymentTypes.join(", ")}');
    }
    if (buyPurposes.isNotEmpty) {
      buf.add('วัตถุประสงค์: ${buyPurposes.join(", ")}');
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      buf.add(notes!.trim());
    }
    if (urgentRush) {
      buf.add('⚡ หาแบบด่วนที่สุด — ให้แสดงป้ายไฟบนบอร์ด (extra_criteria.urgent_rush)');
    }
    return buf.join('\n');
  }

  CustomerRequirement copyWith({
    String? id,
    String? status,
    bool? savedToDatabase,
    bool? urgentRush,
    String? threadId,
    String? demandPostId,
    String? demandPostCode,
  }) {
    return CustomerRequirement(
      id: id ?? this.id,
      transactionType: transactionType,
      propertyType: propertyType,
      propertyTypes: propertyTypes,
      zone: zone,
      requesterRole: requesterRole,
      locationLabels: locationLabels,
      minPriceNet: minPriceNet,
      maxPriceNet: maxPriceNet,
      minAreaSqm: minAreaSqm,
      furnishing: furnishing,
      notes: notes,
      contractStartBy: contractStartBy,
      decisionTimeframe: decisionTimeframe,
      preferredProjectName: preferredProjectName,
      preferredProjectSlug: preferredProjectSlug,
      buyPaymentTypes: buyPaymentTypes,
      buyPurposes: buyPurposes,
      contactName: contactName,
      contactPhone: contactPhone,
      messengerId: messengerId,
      status: status ?? this.status,
      createdAt: createdAt,
      savedToDatabase: savedToDatabase ?? this.savedToDatabase,
      urgentRush: urgentRush ?? this.urgentRush,
      threadId: threadId ?? this.threadId,
      demandPostId: demandPostId ?? this.demandPostId,
      demandPostCode: demandPostCode ?? this.demandPostCode,
    );
  }

  static CustomerRequirement demo() {
    return CustomerRequirement(
      id: 'req-demo-1',
      transactionType: 'sale',
      propertyType: 'condo',
      zone: 'ทองหล่อ',
      minPriceNet: 2500000,
      maxPriceNet: 3000000,
      minAreaSqm: 40,
      furnishing: 'unfurnished',
      notes: 'ต้องการห้องมุม วิวเมือง',
      decisionTimeframe: 'still_comparing',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      savedToDatabase: false,
    );
  }
}
