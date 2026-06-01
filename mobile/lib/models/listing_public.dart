class ListingPublic {
  const ListingPublic({
    required this.id,
    required this.listingCode,
    required this.listingType,
    required this.title,
    required this.priceNet,
    this.district,
    this.projectName,
    this.areaSqm,
    this.bedrooms,
    this.yieldPercent,
    this.coAgentListingType,
    this.investorCategory,
    this.coAgentEligible = false,
    this.petAllowed = false,
    this.lat,
    this.lng,
  });

  final String id;
  final String listingCode;
  final String listingType;
  final String title;
  final double priceNet;
  final String? district;
  final String? projectName;
  final double? areaSqm;
  final int? bedrooms;
  final double? yieldPercent;
  final String? coAgentListingType;
  final String? investorCategory;
  final bool coAgentEligible;
  final bool petAllowed;
  final double? lat;
  final double? lng;

  factory ListingPublic.fromJson(Map<String, dynamic> json) {
    return ListingPublic(
      id: json['id'] as String,
      listingCode: json['listing_code'] as String,
      listingType: json['listing_type'] as String,
      title: json['title'] as String? ?? '',
      priceNet: (json['price_net'] as num).toDouble(),
      district: json['district'] as String?,
      projectName: json['project_name'] as String?,
      areaSqm: (json['area_sqm'] as num?)?.toDouble(),
      bedrooms: json['bedrooms'] as int?,
      yieldPercent: (json['yield_percent'] as num?)?.toDouble(),
      coAgentListingType: json['co_agent_listing_type'] as String?,
      investorCategory: json['investor_category'] as String?,
      coAgentEligible: json['co_agent_eligible'] as bool? ?? false,
      petAllowed: json['pet_allowed'] as bool? ?? false,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  static List<ListingPublic> demo() => [
        const ListingPublic(
          id: 'demo-1',
          listingCode: 'LB-2026-000001',
          listingType: 'rent',
          title: 'คอนโดทองหล่อ วิวดี',
          priceNet: 15000,
          district: 'วัฒนา',
          projectName: 'The Address',
          areaSqm: 35,
          bedrooms: 1,
          coAgentListingType: 'owner_direct',
          petAllowed: true,
          lat: 13.7234,
          lng: 100.5794,
        ),
        const ListingPublic(
          id: 'demo-2',
          listingCode: 'LB-2026-000002',
          listingType: 'rent',
          title: 'ใกล้ BTS อโศก',
          priceNet: 18500,
          district: 'คลองเตย',
          areaSqm: 42,
          bedrooms: 2,
          yieldPercent: 6.2,
          investorCategory: 'with_tenant',
          coAgentEligible: true,
          coAgentListingType: 'co_agent_50_50',
          lat: 13.7373,
          lng: 100.5606,
        ),
      ];
}
