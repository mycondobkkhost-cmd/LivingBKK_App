import '../models/listing_public.dart';
import '../models/search_filters.dart';
import '../models/search_zone_catalog_entry.dart';
import '../services/search_zone_catalog.dart';
import 'geo_distance.dart';
import 'geo_zone_match.dart';

/// Pin-radius filter — inactive when pin/radius not set.
bool matchesPinRadiusFilter(SearchFilters filters, {
  double? lat,
  double? lng,
}) {
  if (!filters.hasPinRadius) return true;
  if (lat == null || lng == null) return false;
  return haversineKm(
        filters.pinLatitude!,
        filters.pinLongitude!,
        lat,
        lng,
      ) <=
      filters.radiusKm!;
}

/// OR within category · AND across categories (location + transit + project + education).
bool matchesZoneFilters(SearchFilters filters, {
  String? geoZoneSlug,
  String? projectGeoZoneSlug,
  List<String> projectSearchTags = const [],
  String? district,
  String? projectName,
  String? projectSlug,
  String? title,
  double? lat,
  double? lng,
}) {
  final effectiveGeoZone = geoZoneSlug ?? projectGeoZoneSlug;
  if (filters.geoZoneSlugs != null && filters.geoZoneSlugs!.isNotEmpty) {
    if (!_matchesLocation(
      slugs: filters.geoZoneSlugs!,
      geoZoneSlug: effectiveGeoZone,
      projectSearchTags: projectSearchTags,
      district: district,
      projectName: projectName,
      title: title,
    )) {
      return false;
    }
  }
  if (filters.transitSlugs != null && filters.transitSlugs!.isNotEmpty) {
    if (!_matchesCatalogSlugs(
      filters.transitSlugs!,
      lat: lat,
      lng: lng,
      geoZoneSlug: effectiveGeoZone,
      projectSearchTags: projectSearchTags,
      district: district,
      projectName: projectName,
      title: title,
    )) {
      return false;
    }
  }
  if (filters.projectSlugs != null && filters.projectSlugs!.isNotEmpty) {
    if (!_matchesProjectSlugs(
      filters.projectSlugs!,
      projectSlug: projectSlug,
      projectName: projectName,
      projectSearchTags: projectSearchTags,
      title: title,
    )) {
      return false;
    }
  }
  if (filters.educationSlugs != null && filters.educationSlugs!.isNotEmpty) {
    if (!_matchesCatalogSlugs(
      filters.educationSlugs!,
      lat: lat,
      lng: lng,
      geoZoneSlug: effectiveGeoZone,
      projectSearchTags: projectSearchTags,
      district: district,
      projectName: projectName,
      title: title,
    )) {
      return false;
    }
  }
  return true;
}

bool matchesZoneFiltersListing(ListingPublic listing, SearchFilters filters) =>
    matchesZoneFilters(
      filters,
      geoZoneSlug: listing.geoZoneSlug,
      projectGeoZoneSlug: listing.projectGeoZoneSlug,
      projectSearchTags: listing.projectSearchTags,
      district: listing.district,
      projectName: listing.projectName,
      projectSlug: listing.projectSlug,
      title: listing.title,
      lat: listing.lat,
      lng: listing.lng,
    );

bool _matchesLocation({
  required List<String> slugs,
  String? geoZoneSlug,
  List<String> projectSearchTags = const [],
  String? district,
  String? projectName,
  String? title,
}) {
  if (geoZoneSlug != null && slugs.contains(geoZoneSlug)) return true;
  if (projectSearchTags.any(slugs.contains)) return true;
  return listingMatchesGeoZones(
    slugs: slugs,
    district: district,
    projectName: projectName,
    title: title,
  );
}

bool _matchesCatalogSlugs(
  List<String> ids, {
  double? lat,
  double? lng,
  String? geoZoneSlug,
  List<String> projectSearchTags = const [],
  String? district,
  String? projectName,
  String? title,
}) {
  for (final id in ids) {
    if (projectSearchTags.contains(id)) return true;
  }
  final catalog = SearchZoneCatalog.instance;
  for (final id in ids) {
    final entry = catalog.byId(id);
    if (entry == null) continue;
    if (_entryMatchesListing(
      entry,
      lat: lat,
      lng: lng,
      geoZoneSlug: geoZoneSlug,
      projectSearchTags: projectSearchTags,
      district: district,
      projectName: projectName,
      title: title,
    )) {
      return true;
    }
  }
  return false;
}

bool _entryMatchesListing(
  SearchZoneCatalogEntry entry, {
  double? lat,
  double? lng,
  String? geoZoneSlug,
  List<String> projectSearchTags = const [],
  String? district,
  String? projectName,
  String? title,
}) {
  if (projectSearchTags.contains(entry.id)) return true;
  if (entry.geoZoneSlugs.isNotEmpty) {
    if (geoZoneSlug != null && entry.geoZoneSlugs.contains(geoZoneSlug)) {
      return true;
    }
    if (projectSearchTags.any(entry.geoZoneSlugs.contains)) return true;
    if (listingMatchesGeoZones(
      slugs: entry.geoZoneSlugs,
      district: district,
      projectName: projectName,
      title: title,
    )) {
      return true;
    }
  }
  if (lat != null && lng != null && entry.lat != null && entry.lng != null) {
    final km = haversineKm(lat, lng, entry.lat!, entry.lng!);
    if (km <= entry.matchRadiusKm) return true;
  }
  return false;
}

bool _matchesProjectSlugs(
  List<String> slugs, {
  String? projectSlug,
  String? projectName,
  List<String> projectSearchTags = const [],
  String? title,
}) {
  final slugSet = slugs.map((s) => s.toLowerCase()).toSet();
  if (projectSearchTags.any((t) => slugSet.contains(t.toLowerCase()))) {
    return true;
  }
  if (projectSlug != null && slugSet.contains(projectSlug.toLowerCase())) {
    return true;
  }
  final catalog = SearchZoneCatalog.instance;
  for (final id in slugs) {
    final entry = catalog.byId(id);
    if (entry == null) continue;
    final names = [
      entry.titleTh.toLowerCase(),
      entry.titleEn.toLowerCase(),
      ...entry.aliases.map((a) => a.toLowerCase()),
    ];
    final hay = [
      projectName?.toLowerCase(),
      title?.toLowerCase(),
      projectSlug?.toLowerCase(),
    ].whereType<String>().join(' ');
    if (names.any((n) => n.isNotEmpty && hay.contains(n))) return true;
    if (entry.projectSlug != null &&
        projectSlug != null &&
        entry.projectSlug == projectSlug) {
      return true;
    }
  }
  return false;
}
