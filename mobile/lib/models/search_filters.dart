import 'listing_transaction_types.dart';

class SearchFilters {
  const SearchFilters({
    this.query,
    this.listingType,
    this.propertyType,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.projectName,
    this.geoZoneSlugs,
    this.petAllowed,
    this.coAgentEligibleOnly,
    this.investorCategory,
    this.minYield,
  });

  final String? query;
  final String? listingType;
  final String? propertyType;
  final double? minPrice;
  final double? maxPrice;
  final int? bedrooms;
  final String? projectName;
  final List<String>? geoZoneSlugs;
  final bool? petAllowed;
  /// Killer filter: เปิดรับโคเอเจนซี่
  final bool? coAgentEligibleOnly;
  /// `with_tenant` | `bmv` | null = ไม่กรอง
  final String? investorCategory;
  final double? minYield;

  SearchFilters copyWith({
    String? query,
    String? listingType,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    String? projectName,
    List<String>? geoZoneSlugs,
    bool? petAllowed,
    bool? coAgentEligibleOnly,
    String? investorCategory,
    double? minYield,
    bool clearQuery = false,
    bool clearListingType = false,
    bool clearPropertyType = false,
    bool clearBedrooms = false,
    bool clearProject = false,
    bool clearGeoZones = false,
    bool clearCoAgent = false,
    bool clearInvestor = false,
    bool clearMinYield = false,
  }) {
    return SearchFilters(
      query: clearQuery ? null : (query ?? this.query),
      listingType: clearListingType ? null : (listingType ?? this.listingType),
      propertyType: clearPropertyType ? null : (propertyType ?? this.propertyType),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      bedrooms: clearBedrooms ? null : (bedrooms ?? this.bedrooms),
      projectName: clearProject ? null : (projectName ?? this.projectName),
      geoZoneSlugs: clearGeoZones ? null : (geoZoneSlugs ?? this.geoZoneSlugs),
      petAllowed: petAllowed ?? this.petAllowed,
      coAgentEligibleOnly:
          clearCoAgent ? null : (coAgentEligibleOnly ?? this.coAgentEligibleOnly),
      investorCategory:
          clearInvestor ? null : (investorCategory ?? this.investorCategory),
      minYield: clearMinYield ? null : (minYield ?? this.minYield),
    );
  }

  bool get hasActiveFilters =>
      listingType != null ||
      propertyType != null ||
      minPrice != null ||
      maxPrice != null ||
      bedrooms != null ||
      projectName != null ||
      (geoZoneSlugs != null && geoZoneSlugs!.isNotEmpty) ||
      petAllowed == true ||
      investorCategory != null ||
      minYield != null;

  Map<String, dynamic> toJson() => {
        if (query != null) 'query': query,
        if (listingType != null) 'listing_type': listingType,
        if (propertyType != null) 'property_type': propertyType,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (bedrooms != null) 'bedrooms': bedrooms,
        if (projectName != null) 'project_name': projectName,
        if (geoZoneSlugs != null) 'geo_zone_slugs': geoZoneSlugs,
        if (petAllowed != null) 'pet_allowed': petAllowed,
        if (coAgentEligibleOnly != null) 'co_agent_eligible_only': coAgentEligibleOnly,
        if (investorCategory != null) 'investor_category': investorCategory,
        if (minYield != null) 'min_yield': minYield,
      };

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      query: json['query'] as String?,
      listingType: json['listing_type'] as String?,
      propertyType: json['property_type'] as String?,
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      bedrooms: json['bedrooms'] as int?,
      projectName: json['project_name'] as String?,
      geoZoneSlugs: (json['geo_zone_slugs'] as List?)?.cast<String>(),
      petAllowed: json['pet_allowed'] as bool?,
      coAgentEligibleOnly: json['co_agent_eligible_only'] as bool?,
      investorCategory: json['investor_category'] as String?,
      minYield: (json['min_yield'] as num?)?.toDouble(),
    );
  }

  String summaryTh() {
    final parts = <String>[];
    if (listingType == 'rent') parts.add('เช่า');
    if (listingType == 'sale') parts.add('ขาย');
    if (listingType == 'sale_installment') parts.add('ขายฝาก');
    if (propertyType != null) parts.add(propertyType!);
    if (maxPrice != null) parts.add('≤${maxPrice!.toInt()}');
    if (geoZoneSlugs != null && geoZoneSlugs!.isNotEmpty) {
      parts.add(geoZoneSlugs!.join(', '));
    }
    if (coAgentEligibleOnly == true) parts.add('โคนายหน้า');
    return parts.isEmpty ? 'ทั้งหมด' : parts.join(' · ');
  }

  bool matchesListing(dynamic listing) {
    String? listingType;
    String? propertyType;
    double? priceNet;
    int? bedrooms;
    String? projectName;
    String? district;
    String? title;
    bool? coAgentEligible;
    bool? listingPetAllowed;
    String? investorCategory;
    double? yieldPercent;
    String? geoZoneSlug;

    if (listing is Map) {
      listingType = listing['listing_type'] as String?;
      propertyType = listing['property_type'] as String?;
      priceNet = (listing['price_net'] as num?)?.toDouble();
      bedrooms = listing['bedrooms'] as int?;
      projectName = listing['project_name'] as String?;
      district = listing['district'] as String?;
      title = listing['title'] as String?;
      coAgentEligible = listing['co_agent_eligible'] as bool?;
      listingPetAllowed = listing['pet_allowed'] as bool?;
      investorCategory = listing['investor_category'] as String?;
      yieldPercent = (listing['yield_percent'] as num?)?.toDouble();
      geoZoneSlug = listing['geo_zone_slug'] as String?;
    } else {
      try {
        final l = listing as dynamic;
        listingType = l.listingType as String?;
        propertyType = l.propertyType as String?;
        priceNet = l.priceNet as double?;
        bedrooms = l.bedrooms as int?;
        projectName = l.projectName as String?;
        district = l.district as String?;
        title = l.title as String?;
        coAgentEligible = l.coAgentEligible as bool?;
        listingPetAllowed = l.petAllowed as bool?;
        investorCategory = l.investorCategory as String?;
        yieldPercent = l.yieldPercent as double?;
        geoZoneSlug = l.geoZoneSlug as String?;
      } catch (_) {
        return false;
      }
    }

    if (this.listingType != null) {
      if (listingType == null ||
          !ListingTransactionTypes.matchesBrowseFilter(this.listingType, listingType)) {
        return false;
      }
    }
    if (this.propertyType != null && propertyType != this.propertyType) return false;
    if (minPrice != null && (priceNet == null || priceNet < minPrice!)) return false;
    if (maxPrice != null && (priceNet == null || priceNet > maxPrice!)) return false;
    if (bedrooms != null && bedrooms != this.bedrooms) return false;
    if (this.projectName != null &&
        !(projectName?.contains(this.projectName!) == true ||
            title?.contains(this.projectName!) == true)) {
      return false;
    }
    if (coAgentEligibleOnly == true && coAgentEligible != true) return false;
    if (this.petAllowed == true && listingPetAllowed != true) return false;
    if (investorCategory != null && investorCategory != this.investorCategory) {
      return false;
    }
    if (minYield != null && (yieldPercent == null || yieldPercent < minYield!)) {
      return false;
    }
    if (geoZoneSlugs != null && geoZoneSlugs!.isNotEmpty) {
      final slug = geoZoneSlug;
      if (slug == null || !geoZoneSlugs!.contains(slug)) {
        final hay = '${district ?? ''} ${projectName ?? ''} ${title ?? ''}'.toLowerCase();
        final ok = geoZoneSlugs!.any((s) => hay.contains(s.replaceAll('-', ' ')));
        if (!ok) return false;
      }
    }
    return true;
  }
}
