/// แถวโครงการจาก property_projects (แอดมิน)
class PropertyProjectRow {
  const PropertyProjectRow({
    required this.id,
    required this.slug,
    required this.nameTh,
    required this.nameEn,
    required this.district,
    required this.propertyType,
    required this.lat,
    required this.lng,
    required this.isActive,
    this.btsStation,
    this.nearbyTransit = const [],
    this.aliases = const [],
    this.yearBuilt,
    this.facilities = const [],
    this.geoZoneId,
    this.sourceUrl,
    this.sourcePlatform = 'manual',
    this.descriptionTh,
    this.descriptionEn,
    this.coverImageUrl,
    this.adminNotes,
  });

  final String id;
  final String slug;
  final String nameTh;
  final String nameEn;
  final String district;
  final String? btsStation;
  final List<String> nearbyTransit;
  final String propertyType;
  final double lat;
  final double lng;
  final bool isActive;
  final List<String> aliases;
  final int? yearBuilt;
  final List<String> facilities;
  final String? geoZoneId;
  final String? sourceUrl;
  final String sourcePlatform;
  final String? descriptionTh;
  final String? descriptionEn;
  final String? coverImageUrl;
  final String? adminNotes;

  String get displayLabel => '$nameTh · $district';

  factory PropertyProjectRow.fromJson(Map<String, dynamic> json) {
    final aliasesRaw = json['aliases'];
    final facilitiesRaw = json['facilities'];
    final nearbyTransitRaw = json['nearby_transit'];
    return PropertyProjectRow(
      id: json['id'] as String,
      slug: json['slug'] as String? ?? '',
      nameTh: json['name_th'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      district: json['district'] as String? ?? '',
      btsStation: json['bts_station'] as String?,
      nearbyTransit: nearbyTransitRaw is List
          ? nearbyTransitRaw.map((e) => e.toString()).toList()
          : const [],
      propertyType: json['property_type'] as String? ?? 'condo',
      lat: (json['lat'] as num?)?.toDouble() ?? 13.7563,
      lng: (json['lng'] as num?)?.toDouble() ?? 100.5018,
      isActive: json['is_active'] as bool? ?? true,
      aliases: aliasesRaw is List
          ? aliasesRaw.map((e) => e.toString()).toList()
          : const [],
      yearBuilt: (json['year_built'] as num?)?.toInt(),
      facilities: facilitiesRaw is List
          ? facilitiesRaw.map((e) => e.toString()).toList()
          : const [],
      geoZoneId: json['geo_zone_id'] as String?,
      sourceUrl: json['source_url'] as String?,
      sourcePlatform: json['source_platform'] as String? ?? 'manual',
      descriptionTh: json['description_th'] as String?,
      descriptionEn: json['description_en'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      adminNotes: json['admin_notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        if (slug.isNotEmpty) 'slug': slug,
        'name_th': nameTh,
        'name_en': nameEn,
        'district': district,
        if (btsStation != null && btsStation!.isNotEmpty) 'bts_station': btsStation,
        if (nearbyTransit.isNotEmpty) 'nearby_transit': nearbyTransit,
        'property_type': propertyType,
        'lat': lat,
        'lng': lng,
        'aliases': aliases,
        if (yearBuilt != null) 'year_built': yearBuilt,
        'facilities': facilities,
        if (geoZoneId != null) 'geo_zone_id': geoZoneId,
        if (sourceUrl != null) 'source_url': sourceUrl,
        'source_platform': sourcePlatform,
        if (descriptionTh != null) 'description_th': descriptionTh,
        if (descriptionEn != null) 'description_en': descriptionEn,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        if (adminNotes != null) 'admin_notes': adminNotes,
        'is_active': isActive,
      };
}
