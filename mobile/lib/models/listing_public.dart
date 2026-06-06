import '../data/demo_listings_factory.dart';
import 'listing_pet_policy.dart';

class ListingPublic {
  const ListingPublic({
    required this.id,
    required this.listingCode,
    required this.listingType,
    required this.title,
    required this.priceNet,
    this.titleEn,
    this.district,
    this.districtEn,
    this.projectName,
    this.projectNameEn,
    this.projectSlug,
    this.propertyType = 'condo',
    this.areaSqm,
    this.bedrooms,
    this.bathrooms,
    this.floorRange,
    this.floorRangeEn,
    this.yieldPercent,
    this.coAgentListingType,
    this.investorCategory,
    this.coAgentEligible = false,
    this.petAllowed = false,
    this.petPolicy = const ListingPetPolicyInput(),
    this.lat,
    this.lng,
    this.geoZoneSlug,
    this.imageUrls = const [],
    this.description,
    this.descriptionEn,
    this.updatedAt,
    this.inventoryId,
    this.inventoryCode,
    this.inventoryMemberCount,
    this.ownerExclusiveMandate = false,
    this.ownerExclusiveContractDays,
    this.agentExclusive = false,
    this.lastBumpAt,
  });

  final String id;
  final String listingCode;
  final String listingType;
  final String title;
  final String? titleEn;
  final double priceNet;
  final String? district;
  final String? districtEn;
  final String? projectName;
  final String? projectNameEn;
  final String? projectSlug;
  final String propertyType;
  final double? areaSqm;
  final int? bedrooms;
  final int? bathrooms;
  final String? floorRange;
  final String? floorRangeEn;
  final double? yieldPercent;
  final String? coAgentListingType;
  final String? investorCategory;
  final bool coAgentEligible;
  final bool petAllowed;
  final ListingPetPolicyInput petPolicy;
  final double? lat;
  final double? lng;
  final String? geoZoneSlug;
  final List<String> imageUrls;
  final String? description;
  final String? descriptionEn;
  final DateTime? updatedAt;
  final String? inventoryId;
  final String? inventoryCode;
  final int? inventoryMemberCount;
  final bool ownerExclusiveMandate;
  final int? ownerExclusiveContractDays;
  final bool agentExclusive;
  final DateTime? lastBumpAt;

  bool get isFeedExclusive => ownerExclusiveMandate || agentExclusive;

  factory ListingPublic.fromJson(Map<String, dynamic> json) {
    return ListingPublic(
      id: json['id'] as String,
      listingCode: json['listing_code'] as String,
      listingType: json['listing_type'] as String,
      title: json['title'] as String? ?? '',
      titleEn: json['title_en'] as String?,
      priceNet: (json['price_net'] as num).toDouble(),
      district: json['district'] as String?,
      districtEn: json['district_en'] as String?,
      projectName: json['project_name'] as String?,
      projectNameEn: json['project_name_en'] as String?,
      projectSlug: json['project_slug'] as String?,
      propertyType: json['property_type'] as String? ?? 'condo',
      areaSqm: (json['area_sqm'] as num?)?.toDouble(),
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      floorRange: json['floor_range'] as String?,
      floorRangeEn: json['floor_range_en'] as String?,
      yieldPercent: (json['yield_percent'] as num?)?.toDouble(),
      coAgentListingType: json['co_agent_listing_type'] as String?,
      investorCategory: json['investor_category'] as String?,
      coAgentEligible: json['co_agent_eligible'] as bool? ?? false,
      petAllowed: json['pet_allowed'] as bool? ?? false,
      petPolicy: ListingPetPolicyInput.fromJson(
        json['pet_policy'] as Map<String, dynamic>?,
      ),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      geoZoneSlug: json['geo_zone_slug'] as String?,
      imageUrls: _parseImageUrls(json['image_urls']),
      description: json['description'] as String?,
      descriptionEn: json['description_en'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      inventoryId: json['inventory_id'] as String?,
      inventoryCode: json['inventory_code'] as String?,
      inventoryMemberCount: (json['inventory_member_count'] as num?)?.toInt(),
      ownerExclusiveMandate: json['owner_exclusive_mandate'] as bool? ?? false,
      ownerExclusiveContractDays:
          (json['owner_exclusive_contract_days'] as num?)?.toInt(),
      agentExclusive: json['agent_exclusive'] as bool? ?? false,
      lastBumpAt: json['last_bump_at'] != null
          ? DateTime.tryParse(json['last_bump_at'].toString())
          : null,
    );
  }

  /// ใช้แสดง "อัปเดตล่าสุด" — fallback จาก id ถ้าไม่มีข้อมูลจริง
  DateTime get effectiveUpdatedAt {
    if (updatedAt != null) return updatedAt!;
    final hash = id.hashCode.abs() % 14;
    return DateTime.now().subtract(Duration(days: hash == 0 ? 0 : hash, hours: hash * 2 % 8));
  }

  static List<ListingPublic> demo() => DemoListingsFactory.cached;

  static List<String> _parseImageUrls(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((u) => u.isNotEmpty).toList();
    }
    if (raw is String && raw.startsWith('[')) {
      return raw
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
