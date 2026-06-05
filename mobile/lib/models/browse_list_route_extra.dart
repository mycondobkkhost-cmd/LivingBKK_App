import 'listing_public.dart';

enum BrowseListMode {
  category,
  project,
  area,
  transit,
  section,
  tag,
}

class BrowseListRouteExtra {
  const BrowseListRouteExtra({
    required this.title,
    required this.mode,
    required this.isAgent,
    this.categorySlug,
    this.projectName,
    this.projectSlug,
    this.geoZoneSlugs,
    this.tagLabel,
    this.presetItems,
  });

  final String title;
  final BrowseListMode mode;
  final bool isAgent;
  final String? categorySlug;
  final String? projectName;
  final String? projectSlug;
  final List<String>? geoZoneSlugs;
  final String? tagLabel;
  final List<ListingPublic>? presetItems;
}
