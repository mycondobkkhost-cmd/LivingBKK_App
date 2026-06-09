class SearchZoneCatalogEntry {
  const SearchZoneCatalogEntry({
    required this.id,
    required this.category,
    required this.titleTh,
    required this.titleEn,
    this.geoZoneSlugs = const [],
    this.lat,
    this.lng,
    this.matchRadiusKm = 1.5,
    this.aliases = const [],
    this.projectSlug,
  });

  final String id;
  /// `location` | `transit` | `project` | `education`
  final String category;
  final String titleTh;
  final String titleEn;
  final List<String> geoZoneSlugs;
  final double? lat;
  final double? lng;
  final double matchRadiusKm;
  final List<String> aliases;
  final String? projectSlug;

  String label(bool isEnglish) => isEnglish ? titleEn : titleTh;
}
