enum SearchSuggestionKind { project, location, listing, hint }

/// ลำดับแสดงผล: โครงการตรงคำค้น → โครงการในทำเล → ทำเล
enum SearchSuggestionGroup { projectMatch, projectInArea, location, hint }

/// แท็บแบบ Property Hub
enum SearchResultTab { transit, location, project }

/// หมวดย่อยในผลค้นหา
enum SearchResultSection {
  btsMrt,
  location,
  road,
  shopping,
  hospital,
  education,
  project,
}

class SearchSuggestion {
  const SearchSuggestion({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.group = SearchSuggestionGroup.projectMatch,
    this.tab = SearchResultTab.location,
    this.section = SearchResultSection.location,
    this.titleTh,
    this.titleEn,
    this.projectName,
    this.projectSlug,
    this.listingType,
    this.geoZoneSlugs,
    this.listingId,
    this.vacancyCount,
    this.rentCount,
    this.saleCount,
    this.propertyTypeLabel,
    this.imageUrl,
  });

  final SearchSuggestionKind kind;
  final SearchSuggestionGroup group;
  final SearchResultTab tab;
  final SearchResultSection section;
  final String title;
  final String subtitle;
  final String? titleTh;
  final String? titleEn;
  final String? projectName;
  final String? projectSlug;
  final String? listingType;
  final List<String>? geoZoneSlugs;
  final String? listingId;
  final int? vacancyCount;
  final int? rentCount;
  final int? saleCount;
  final String? propertyTypeLabel;
  final String? imageUrl;
}
