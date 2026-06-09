import '../data/property_catalog.dart';
import 'listing_transaction_types.dart';
import '../utils/search_filter_match.dart';

/// Default / min / max radius (km) for map pin search — 500 m … 10 km.
const double kSearchPinRadiusDefaultKm = 0.5;
const double kSearchPinRadiusMinKm = 0.5;
const double kSearchPinRadiusMaxKm = 10;

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
    this.transitSlugs,
    this.projectSlugs,
    this.educationSlugs,
    this.pinLatitude,
    this.pinLongitude,
    this.radiusKm,
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
  final List<String>? transitSlugs;
  final List<String>? projectSlugs;
  final List<String>? educationSlugs;
  /// Map pin search — listings within [radiusKm] of this point (AND with tag filters).
  final double? pinLatitude;
  final double? pinLongitude;
  final double? radiusKm;
  final bool? petAllowed;
  /// Killer filter: เปิดรับโคเอเจนซี่
  final bool? coAgentEligibleOnly;
  /// `with_tenant` | `bmv` | null = ไม่กรอง
  final String? investorCategory;
  final double? minYield;

  bool get hasPinRadius =>
      pinLatitude != null && pinLongitude != null && radiusKm != null;

  bool get hasZoneFilters =>
      (geoZoneSlugs?.isNotEmpty ?? false) ||
      (transitSlugs?.isNotEmpty ?? false) ||
      (educationSlugs?.isNotEmpty ?? false);

  int get zoneFilterCount =>
      (geoZoneSlugs?.length ?? 0) +
      (transitSlugs?.length ?? 0) +
      (educationSlugs?.length ?? 0);

  SearchFilters copyWith({
    String? query,
    String? listingType,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    String? projectName,
    List<String>? geoZoneSlugs,
    List<String>? transitSlugs,
    List<String>? projectSlugs,
    List<String>? educationSlugs,
    double? pinLatitude,
    double? pinLongitude,
    double? radiusKm,
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
    bool clearTransit = false,
    bool clearProjectSlugs = false,
    bool clearEducation = false,
    bool clearPin = false,
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
      transitSlugs: clearTransit ? null : (transitSlugs ?? this.transitSlugs),
      projectSlugs:
          clearProjectSlugs ? null : (projectSlugs ?? this.projectSlugs),
      educationSlugs:
          clearEducation ? null : (educationSlugs ?? this.educationSlugs),
      pinLatitude: clearPin ? null : (pinLatitude ?? this.pinLatitude),
      pinLongitude: clearPin ? null : (pinLongitude ?? this.pinLongitude),
      radiusKm: clearPin ? null : (radiusKm ?? this.radiusKm),
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
      hasZoneFilters ||
      hasPinRadius ||
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
        if (transitSlugs != null) 'transit_slugs': transitSlugs,
        if (projectSlugs != null) 'project_slugs': projectSlugs,
        if (educationSlugs != null) 'education_slugs': educationSlugs,
        if (pinLatitude != null) 'pin_latitude': pinLatitude,
        if (pinLongitude != null) 'pin_longitude': pinLongitude,
        if (radiusKm != null) 'radius_km': radiusKm,
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
      transitSlugs: (json['transit_slugs'] as List?)?.cast<String>(),
      projectSlugs: (json['project_slugs'] as List?)?.cast<String>(),
      educationSlugs: (json['education_slugs'] as List?)?.cast<String>(),
      pinLatitude: (json['pin_latitude'] as num?)?.toDouble(),
      pinLongitude: (json['pin_longitude'] as num?)?.toDouble(),
      radiusKm: (json['radius_km'] as num?)?.toDouble(),
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
    if (hasZoneFilters) parts.add('$zoneFilterCount ทำเล');
    if (hasPinRadius) {
      final km = radiusKm!;
      if (km < 1) {
        parts.add('รัศมี ${(km * 1000).round()} ม.');
      } else {
        parts.add('รัศมี ${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)} กม.');
      }
    }
    if (coAgentEligibleOnly == true) parts.add('โคนายหน้า');
    if (investorCategory == 'with_tenant') parts.add('ขายพร้อมผู้เช่า');
    if (investorCategory == 'bmv') parts.add('BMV');
    return parts.isEmpty ? 'ทั้งหมด' : parts.join(' · ');
  }

  bool matchesListing(dynamic listing) {
    String? listingType;
    String? propertyType;
    double? priceNet;
    int? bedrooms;
    String? projectName;
    String? projectSlug;
    String? district;
    String? title;
    bool? coAgentEligible;
    bool? listingPetAllowed;
    String? investorCategory;
    double? yieldPercent;
    String? geoZoneSlug;
    double? lat;
    double? lng;

    if (listing is Map) {
      listingType = listing['listing_type'] as String?;
      propertyType = listing['property_type'] as String?;
      priceNet = (listing['price_net'] as num?)?.toDouble();
      bedrooms = listing['bedrooms'] as int?;
      projectName = listing['project_name'] as String?;
      projectSlug = listing['project_slug'] as String?;
      district = listing['district'] as String?;
      title = listing['title'] as String?;
      coAgentEligible = listing['co_agent_eligible'] as bool?;
      listingPetAllowed = listing['pet_allowed'] as bool?;
      investorCategory = listing['investor_category'] as String?;
      yieldPercent = (listing['yield_percent'] as num?)?.toDouble();
      geoZoneSlug = listing['geo_zone_slug'] as String?;
      lat = (listing['lat'] as num?)?.toDouble();
      lng = (listing['lng'] as num?)?.toDouble();
    } else {
      try {
        final l = listing as dynamic;
        listingType = l.listingType as String?;
        propertyType = l.propertyType as String?;
        priceNet = l.priceNet as double?;
        bedrooms = l.bedrooms as int?;
        projectName = l.projectName as String?;
        projectSlug = l.projectSlug as String?;
        district = l.district as String?;
        title = l.title as String?;
        coAgentEligible = l.coAgentEligible as bool?;
        listingPetAllowed = l.petAllowed as bool?;
        investorCategory = l.investorCategory as String?;
        yieldPercent = l.yieldPercent as double?;
        geoZoneSlug = l.geoZoneSlug as String?;
        lat = l.lat as double?;
        lng = l.lng as double?;
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
    if (this.propertyType != null) {
      final wantDb =
          PropertyCatalog.dbValueForSlug(this.propertyType!) ?? this.propertyType!;
      if (propertyType != wantDb && propertyType != this.propertyType) {
        return false;
      }
    }
    final effectivePrice = _effectivePriceForFilter(
      listingType: listingType,
      priceNet: priceNet,
      priceSaleNet: listing is Map
          ? (listing['price_sale_net'] as num?)?.toDouble()
          : _priceSaleNetFromDynamic(listing),
    );
    if (minPrice != null &&
        (effectivePrice == null || effectivePrice < minPrice!)) {
      return false;
    }
    if (maxPrice != null &&
        (effectivePrice == null || effectivePrice > maxPrice!)) {
      return false;
    }
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
    if (hasZoneFilters &&
        !matchesZoneFilters(
          this,
          geoZoneSlug: geoZoneSlug,
          district: district,
          projectName: projectName,
          projectSlug: projectSlug,
          title: title,
          lat: lat,
          lng: lng,
        )) {
      return false;
    }
    if (hasPinRadius && !matchesPinRadiusFilter(this, lat: lat, lng: lng)) {
      return false;
    }
    return true;
  }

  static double? _priceSaleNetFromDynamic(dynamic listing) {
    try {
      return listing.priceSaleNet as double?;
    } catch (_) {
      return null;
    }
  }

  double? _effectivePriceForFilter({
    required String? listingType,
    required double? priceNet,
    required double? priceSaleNet,
  }) {
    if (priceNet == null) return null;
    if (ListingTransactionTypes.isRentAndSale(listingType)) {
      if (this.listingType == ListingTransactionTypes.sale) {
        return priceSaleNet ?? priceNet;
      }
      return priceNet;
    }
    return priceNet;
  }
}
