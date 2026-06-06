import '../data/property_catalog.dart';
import 'demand_offer_acceptance.dart';

class DemandPost {
  const DemandPost({
    required this.id,
    required this.postCode,
    required this.title,
    required this.transactionType,
    this.titleEn,
    this.description,
    this.descriptionEn,
    this.propertyType = 'condo',
    this.zones = const [],
    this.preferredProject,
    this.maxPriceNet,
    this.minPriceNet,
    this.minAreaSqm,
    this.maxDistanceBtsKm,
    this.extraCriteria = const {},
    this.status = 'open',
    this.openUntil,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String postCode;
  final String title;
  final String? titleEn;
  final String transactionType;
  final String? description;
  final String? descriptionEn;
  final String propertyType;
  final List<String> zones;
  final String? preferredProject;
  final double? maxPriceNet;
  final double? minPriceNet;
  final double? minAreaSqm;
  final double? maxDistanceBtsKm;
  final Map<String, dynamic> extraCriteria;
  final String status;
  final DateTime? openUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DateTime get displayTime => updatedAt ?? createdAt ?? DateTime.now();

  DemandOfferAcceptancePolicy get offerAcceptancePolicy =>
      DemandBoardPostMeta.policyFromExtra(extraCriteria);

  DemandLeadSource? get leadSource =>
      DemandBoardPostMeta.leadSourceFromExtra(extraCriteria);

  /// เลข 4 ตัวท้ายเบอร์ลูกค้า (โคเอเจนหาให้) — เก็บใน extra_criteria
  String? get customerPhoneLast4 =>
      DemandBoardPostMeta.customerPhoneLast4FromExtra(extraCriteria);

  bool get requiresCustomerPhoneLast4 =>
      leadSource == DemandLeadSource.coAgentSourced;

  List<String> get allowedOffererCapacities =>
      DemandBoardPostMeta.allowedOffererCapacities(offerAcceptancePolicy);

  bool allowsCapacity(String capacity) =>
      DemandBoardPostMeta.capacityAllowed(offerAcceptancePolicy, capacity);

  bool get isUrgentRush => DemandBoardPostMeta.isUrgentRushFromExtra(extraCriteria);

  bool get isCashCase {
    if (extraCriteria['cash'] == true) return true;
    if (extraCriteria['payment'] == 'cash') return true;
    final payments = extraCriteria['buy_payment_types'];
    if (payments is List && payments.contains('cash')) return true;
    final hay = '${title} ${description ?? ''}'.toLowerCase();
    return hay.contains('เงินสด') || hay.contains('cash buyer');
  }

  String propertyLabel(bool isEnglish) {
    final cat = PropertyCatalog.bySlug(_slugForType(propertyType));
    return cat?.label(isEnglish) ?? propertyType;
  }

  String? zoneLabel(bool isEnglish) {
    if (zones.isNotEmpty) return zones.first;
    return null;
  }

  String? projectLine(bool isEnglish) {
    if (preferredProject != null && preferredProject!.trim().isNotEmpty) {
      return preferredProject;
    }
    if (zones.length > 1) return zones[1];
    return null;
  }

  static String _slugForType(String dbType) {
    switch (dbType) {
      case 'townhouse':
        return 'townhome';
      default:
        return dbType;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_code': postCode,
      'title': title,
      if (titleEn != null) 'title_en': titleEn,
      'transaction_type': transactionType,
      if (description != null) 'description': description,
      if (descriptionEn != null) 'description_en': descriptionEn,
      'property_type': propertyType,
      'zones': zones,
      if (preferredProject != null) 'preferred_project': preferredProject,
      if (maxPriceNet != null) 'max_price_net': maxPriceNet,
      if (minPriceNet != null) 'min_price_net': minPriceNet,
      if (minAreaSqm != null) 'min_area_sqm': minAreaSqm,
      if (maxDistanceBtsKm != null) 'max_distance_bts_km': maxDistanceBtsKm,
      'extra_criteria': extraCriteria,
      'status': status,
      if (openUntil != null) 'open_until': openUntil!.toUtc().toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }

  factory DemandPost.fromJson(Map<String, dynamic> json) {
    final zonesRaw = json['zones'];
    List<String> zones = const [];
    if (zonesRaw is List) {
      zones = zonesRaw.map((e) => e.toString()).toList();
    }
    final extra = json['extra_criteria'];
    return DemandPost(
      id: json['id'] as String,
      postCode: json['post_code'] as String,
      title: json['title'] as String,
      titleEn: json['title_en'] as String?,
      transactionType: json['transaction_type'] as String,
      description: json['description'] as String?,
      descriptionEn: json['description_en'] as String?,
      propertyType: json['property_type'] as String? ?? 'condo',
      zones: zones,
      preferredProject: json['preferred_project'] as String? ??
          (extra is Map ? extra['preferred_project'] as String? : null),
      maxPriceNet: (json['max_price_net'] as num?)?.toDouble(),
      minPriceNet: (json['min_price_net'] as num?)?.toDouble(),
      minAreaSqm: (json['min_area_sqm'] as num?)?.toDouble(),
      maxDistanceBtsKm: (json['max_distance_bts_km'] as num?)?.toDouble(),
      extraCriteria: extra is Map
          ? Map<String, dynamic>.from(extra)
          : const {},
      status: json['status'] as String? ?? 'open',
      openUntil: json['open_until'] != null
          ? DateTime.tryParse(json['open_until'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  static List<DemandPost> demo() {
    final now = DateTime.now();
    return [
      DemandPost(
        id: 'dm-urgent',
        postCode: 'DM-2026-000008',
        title: 'หาคอนโดเช่า อโศก — ด่วนมาก',
        titleEn: 'Condo for rent — Asoke, urgent',
        transactionType: 'rent',
        propertyType: 'condo',
        zones: ['อโศก', 'BTS อโศก'],
        preferredProject: 'The Esse Asoke',
        maxPriceNet: 28000,
        minAreaSqm: 35,
        extraCriteria: const {
          'urgent_rush': true,
          'accepted_offerer_policy': 'owner_and_co_agent',
          'lead_source': 'customer_direct',
        },
        openUntil: now.add(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(minutes: 20)),
      ),
      DemandPost(
        id: 'dm-1',
        postCode: 'DM-2026-000001',
        title: 'หาคอนโดเช่า ทองหล่อ–เอกมัย',
        titleEn: 'Condo for rent — Thonglor–Ekkamai',
        transactionType: 'rent',
        propertyType: 'condo',
        zones: ['ทองหล่อ', 'เอกมัย', 'BTS เอกมัย', 'BTS ทองหล่อ'],
        preferredProject: 'Noble Remix',
        maxPriceNet: 18000,
        minAreaSqm: 30,
        maxDistanceBtsKm: 0.8,
        extraCriteria: const {
          'accepted_offerer_policy': 'owner_and_co_agent',
          'lead_source': 'customer_direct',
        },
        openUntil: now.add(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
      DemandPost(
        id: 'dm-2',
        postCode: 'DM-2026-000002',
        title: 'หาซื้อทาวน์เฮ้าส์ บางนา–อุดมสุข',
        titleEn: 'Townhouse for sale — Bang Na–Udom Suk',
        transactionType: 'sale',
        propertyType: 'townhouse',
        zones: ['บางนา–อุดมสุข', 'BTS บางนา'],
        preferredProject: 'เมกะบางนา',
        maxPriceNet: 8500000,
        minAreaSqm: 200,
        maxDistanceBtsKm: 1.2,
        extraCriteria: const {
          'accepted_offerer_policy': 'owner_only',
          'lead_source': 'co_agent_sourced',
          'customer_phone_last4': '7890',
        },
        openUntil: now.add(const Duration(days: 21)),
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      DemandPost(
        id: 'dm-3',
        postCode: 'DM-2026-000003',
        title: 'หาคอนโดขาย สุขุมวิท ใกล้ BTS',
        titleEn: 'Condo for sale — Sukhumvit near BTS',
        transactionType: 'sale',
        propertyType: 'condo',
        zones: ['พระโขนง', 'BTS พระโขนง'],
        preferredProject: 'The Line Sukhumvit',
        maxPriceNet: 4200000,
        minPriceNet: 3500000,
        extraCriteria: const {
          'cash': true,
          'payment': 'cash',
          'accepted_offerer_policy': 'owner_and_co_agent',
          'lead_source': 'customer_direct',
        },
        minAreaSqm: 28,
        maxDistanceBtsKm: 0.5,
        openUntil: now.add(const Duration(days: 30)),
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(minutes: 45)),
      ),
      DemandPost(
        id: 'dm-rama9',
        postCode: 'DM-2026-000007',
        title: 'หาคอนโดเช่า พระราม 9–รัชดา',
        titleEn: 'Condo for rent — Rama 9–Ratchada',
        transactionType: 'rent',
        propertyType: 'condo',
        zones: ['พระราม 9', 'รัชดา', 'MRT พระราม 9'],
        preferredProject: 'The Line Asoke-Ratchada',
        maxPriceNet: 22000,
        minAreaSqm: 32,
        extraCriteria: const {
          'accepted_offerer_policy': 'owner_only',
          'lead_source': 'customer_direct',
        },
        openUntil: now.add(const Duration(days: 18)),
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      DemandPost(
        id: 'dm-4',
        postCode: 'DM-2026-000005',
        title: 'หาบ้านเดี่ยวเช่า รามคำแหง',
        titleEn: 'Detached house for rent — Ramkhamhaeng',
        transactionType: 'rent',
        propertyType: 'house',
        zones: ['รามคำแหง', 'ใกล้ MRT'],
        maxPriceNet: 45000,
        minAreaSqm: 200,
        extraCriteria: const {
          'accepted_offerer_policy': 'owner_and_co_agent',
          'lead_source': 'co_agent_sourced',
        },
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      DemandPost(
        id: 'dm-5',
        postCode: 'DM-2026-000006',
        title: 'หาซื้อบ้านเดี่ยว เงินสด พร้อมโอน',
        titleEn: 'Detached house — cash buyer',
        transactionType: 'sale',
        propertyType: 'house',
        zones: ['ลาดพร้าว', 'วังทองหลาง'],
        preferredProject: 'Moobaan Ladprao',
        maxPriceNet: 12000000,
        minPriceNet: 9000000,
        extraCriteria: const {
          'cash': true,
          'accepted_offerer_policy': 'owner_only',
          'lead_source': 'co_agent_sourced',
        },
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      DemandPost(
        id: 'dm-closed',
        postCode: 'DM-2026-000004',
        title: 'หาบ้านเช่า รามคำแหง–มหาวิทยาลัย',
        titleEn: 'House for rent — Ramkhamhaeng area',
        transactionType: 'rent',
        propertyType: 'house',
        zones: ['รามคำแหง'],
        maxPriceNet: 25000,
        minAreaSqm: 120,
        status: 'closed',
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
