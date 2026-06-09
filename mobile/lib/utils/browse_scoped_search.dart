import '../data/property_catalog.dart';
import '../models/browse_list_route_extra.dart';
import '../models/listing_public.dart';
import '../models/search_filters.dart';

/// Search filters scoped to a [BrowseListRouteExtra] context (category, project, area, …).
abstract final class BrowseScopedSearch {
  static String? lockedPropertyType(BrowseListRouteExtra extra) {
    if (extra.mode != BrowseListMode.category) return null;
    return PropertyCatalog.dbValueForSlug(extra.categorySlug);
  }

  static SearchFilters initial(BrowseListRouteExtra extra) {
    var filters = const SearchFilters();
    final locked = lockedPropertyType(extra);
    if (locked != null) {
      filters = filters.copyWith(propertyType: locked);
    }
    switch (extra.mode) {
      case BrowseListMode.project:
        final name = extra.projectName;
        if (name != null && name.isNotEmpty) {
          filters = filters.copyWith(projectName: name);
        }
      case BrowseListMode.area:
      case BrowseListMode.transit:
        final zones = extra.geoZoneSlugs;
        if (zones != null && zones.isNotEmpty) {
          filters = filters.copyWith(geoZoneSlugs: List<String>.from(zones));
        }
      case BrowseListMode.category:
      case BrowseListMode.section:
      case BrowseListMode.tag:
        break;
    }
    return filters;
  }

  static SearchFilters enforce(SearchFilters filters, BrowseListRouteExtra extra) {
    var next = filters;
    final locked = lockedPropertyType(extra);
    if (locked != null) {
      next = next.copyWith(propertyType: locked);
    }
    if (extra.mode == BrowseListMode.project) {
      final name = extra.projectName;
      if (name != null && name.isNotEmpty) {
        next = next.copyWith(projectName: name);
      }
    }
    return next;
  }

  static bool matchesQuery(ListingPublic listing, String? query) {
    if (query == null || query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    final hay = [
      listing.title,
      listing.projectName,
      listing.district,
      listing.listingCode,
    ].whereType<String>().join(' ').toLowerCase();
    return q
        .split(RegExp(r'\s+'))
        .every((t) => t.length < 2 || hay.contains(t));
  }
}
