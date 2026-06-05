import '../data/bangkok_projects.dart';
import '../data/bangkok_transit_stations.dart';
import '../data/popular_areas.dart';
import '../l10n/app_strings.dart';
import '../utils/geo_zone_match.dart';
import '../utils/localized_content.dart';
import '../models/listing_public.dart';
import '../models/search_filters.dart';
import '../models/search_suggestion.dart';
import 'listing_repository.dart';
import 'places_service.dart';
import 'project_catalog.dart';
import 'search_display_catalog.dart';
import 'supabase_service.dart';

class SearchPreviewItem {
  const SearchPreviewItem({required this.label, required this.value});
  final String label;
  final String value;
}

class SearchService {
  final _listings = ListingRepository();
  final _places = PlacesService();
  List<ListingPublic>? _cache;

  Future<List<ListingPublic>> _allListings() async {
    _cache ??= await _listings.fetchPublished();
    return _cache!;
  }

  void invalidateCache() => _cache = null;

  Future<({Map<String, dynamic> filters, List<SearchPreviewItem> preview})>
      parseQuery(String query, {bool isEnglish = false}) async {
    if (!SupabaseService.isReady) {
      return _demoParse(query, isEnglish: isEnglish);
    }

    final res = await SupabaseService.client!.functions.invoke(
      'smart-search-parse',
      body: {'query': query},
    );

    final data = res.data as Map<String, dynamic>;
    final preview = (data['preview'] as List? ?? [])
        .map((e) => SearchPreviewItem(
              label: e['label'] as String,
              value: e['value'] as String,
            ))
        .toList();

    return (
      filters: data['filters'] as Map<String, dynamic>? ?? {},
      preview: preview,
    );
  }

  bool _hasProjectSuggestion(
    List<SearchSuggestion> list, {
    String? slug,
    String? name,
  }) {
    return list.any(
      (s) =>
          s.kind == SearchSuggestionKind.project &&
          ((slug != null && slug.isNotEmpty && s.projectSlug == slug) ||
              (name != null && name.isNotEmpty && s.projectName == name)),
    );
  }

  bool _hasSimilarSuggestion(List<SearchSuggestion> list, SearchSuggestion s) {
    return list.any(
      (x) =>
          x.kind == s.kind &&
          ((s.projectSlug != null &&
                  s.projectSlug!.isNotEmpty &&
                  x.projectSlug == s.projectSlug) ||
              x.title == s.title),
    );
  }

  List<String> _geoZonesForQuery(String qLower) {
    final zones = <String>{};
    for (final area in PopularAreas.all) {
      final th = area.nameTh.toLowerCase();
      final en = area.nameEn.toLowerCase();
      if (qLower.contains(th) ||
          qLower.contains(en) ||
          th.contains(qLower) ||
          en.contains(qLower)) {
        zones.add(area.slug);
      }
    }
    const extra = <String, String>{
      'ทองหล่อ': 'thonglor',
      'thong': 'thonglor',
      'thonglor': 'thonglor',
      'อโศก': 'asok',
      'asok': 'asok',
      'สุขุมวิท': 'sukhumvit',
      'sukhumvit': 'sukhumvit',
      'บางนา': 'bangna',
      'bang na': 'bangna',
      'bangna': 'bangna',
      'อารีย์': 'ari',
      'ari': 'ari',
      'สีลม': 'silom',
      'silom': 'silom',
      'ลาดพร้าว': 'ladprao',
      'ladprao': 'ladprao',
    };
    for (final entry in extra.entries) {
      if (qLower.contains(entry.key)) zones.add(entry.value);
    }
    return zones.toList();
  }

  bool _textMatchesQuery(String qLower, String? th, String? en, {List<String>? aliases}) {
    final hay = [
      th?.toLowerCase(),
      en?.toLowerCase(),
      ...?aliases?.map((a) => a.toLowerCase()),
    ].whereType<String>().join(' ');
    if (hay.isEmpty) return false;
    final tokens = qLower.split(RegExp(r'\s+')).where((t) => t.length >= 2).toList();
    if (tokens.isEmpty) return hay.contains(qLower);
    return tokens.every(hay.contains);
  }

  bool _projectNameMatches(String qLower, BangkokProject p) {
    return _textMatchesQuery(
      qLower,
      p.nameTh,
      p.nameEn,
      aliases: p.aliases,
    );
  }

  bool _projectInZones(BangkokProject p, List<String> zones) {
    return listingMatchesGeoZones(
      slugs: zones,
      district: p.district,
      projectName: p.nameTh,
      title: p.nameEn,
    );
  }

  bool _listingInZones(ListingPublic l, List<String> zones) {
    return listingMatchesGeoZones(
      slugs: zones,
      district: l.district,
      projectName: l.projectName,
      title: l.title,
    );
  }

  String _countSubtitle(int rent, int sale, bool isEnglish) {
    if (isEnglish) return '$rent for rent | $sale for sale';
    return '$rent ประกาศเช่า | $sale ประกาศขาย';
  }

  String _propertyTypeLabel(String? type, bool isEnglish) {
    final raw = (type ?? 'condo').toLowerCase();
    if (isEnglish) {
      return switch (raw) {
        'condo' => 'Condo',
        'house' => 'House',
        'townhouse' => 'Townhouse',
        _ => 'Property',
      };
    }
    return switch (raw) {
      'condo' => 'คอนโด',
      'house' => 'บ้าน',
      'townhouse' => 'ทาวน์เฮาส์',
      _ => 'อสังหา',
    };
  }

  ({int rent, int sale}) _countsForZones(
    List<ListingPublic> all,
    List<String> zones,
  ) {
    var rent = 0;
    var sale = 0;
    for (final l in all) {
      if (!_listingInZones(l, zones)) continue;
      if (l.listingType == 'rent') {
        rent++;
      } else {
        sale++;
      }
    }
    return (rent: rent, sale: sale);
  }

  ({int rent, int sale}) _countsForProject(
    List<ListingPublic> all, {
    String? slug,
    String? name,
  }) {
    var rent = 0;
    var sale = 0;
    for (final l in all) {
      final match = (slug != null && slug.isNotEmpty && l.projectSlug == slug) ||
          (name != null && name.isNotEmpty && l.projectName == name);
      if (!match) continue;
      if (l.listingType == 'rent') {
        rent++;
      } else {
        sale++;
      }
    }
    return (rent: rent, sale: sale);
  }

  SearchSuggestion _projectSuggestion({
    required BangkokProject p,
    required SearchSuggestionGroup group,
    required bool isEnglish,
    required List<ListingPublic> all,
    int? units,
  }) {
    final counts = _countsForProject(all, slug: p.slug, name: p.nameTh);
    final typeLabel = _propertyTypeLabel(p.propertyType, isEnglish);
    return SearchSuggestion(
      kind: SearchSuggestionKind.project,
      group: group,
      tab: SearchResultTab.project,
      section: SearchResultSection.project,
      title: p.displayBilingual,
      titleTh: p.nameTh,
      titleEn: p.nameEn,
      subtitle: typeLabel,
      projectName: p.nameTh,
      projectSlug: p.slug,
      vacancyCount: units != null && units > 0 ? units : null,
      rentCount: counts.rent,
      saleCount: counts.sale,
      propertyTypeLabel: typeLabel,
    );
  }

  SearchSuggestion _projectFromListing({
    required String projectName,
    required List<ListingPublic> units,
    required SearchSuggestionGroup group,
    required bool isEnglish,
  }) {
    final first = units.first;
    final th = first.projectName ?? projectName;
    final en = first.projectNameEn ?? th;
    final typeLabel = _propertyTypeLabel(first.propertyType, isEnglish);
    var rent = 0;
    var sale = 0;
    for (final l in units) {
      if (l.listingType == 'rent') {
        rent++;
      } else {
        sale++;
      }
    }
    return SearchSuggestion(
      kind: SearchSuggestionKind.project,
      group: group,
      tab: SearchResultTab.project,
      section: SearchResultSection.project,
      title: bilingualProjectLabel(th, en),
      titleTh: th,
      titleEn: en,
      subtitle: typeLabel,
      projectName: th,
      projectSlug: first.projectSlug,
      vacancyCount: units.length,
      rentCount: rent,
      saleCount: sale,
      propertyTypeLabel: typeLabel,
    );
  }

  SearchSuggestion _placeSuggestion({
    required String nameTh,
    required String nameEn,
    required List<String> geoZoneSlugs,
    required bool isEnglish,
    required SearchResultTab tab,
    required SearchResultSection section,
    required List<ListingPublic> all,
  }) {
    final counts = _countsForZones(all, geoZoneSlugs);
    return SearchSuggestion(
      kind: SearchSuggestionKind.location,
      group: SearchSuggestionGroup.location,
      tab: tab,
      section: section,
      titleTh: nameTh,
      titleEn: nameEn,
      title: bilingualProjectLabel(nameTh, nameEn),
      subtitle: _countSubtitle(counts.rent, counts.sale, isEnglish),
      geoZoneSlugs: geoZoneSlugs,
      rentCount: counts.rent,
      saleCount: counts.sale,
    );
  }

  Future<List<SearchSuggestion>> suggest(String query, {bool isEnglish = false}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final qLower = q.toLowerCase();

    await SearchDisplayCatalog.instance.load();

    if (q.length < 2) {
      return SearchDisplayCatalog.instance.suggest(q, isEnglish: isEnglish);
    }

    final all = await _allListings();
    final zones = _geoZonesForQuery(qLower);
    final transitHits = <SearchSuggestion>[];
    final locationHits = <SearchSuggestion>[];
    final nameMatches = <SearchSuggestion>[];
    final zoneProjects = <SearchSuggestion>[];
    final locations = <SearchSuggestion>[];

    void addProject(
      List<SearchSuggestion> bucket,
      SearchSuggestion hit,
    ) {
      if (!_hasSimilarSuggestion(bucket, hit)) bucket.add(hit);
    }

    int countUnits(BangkokProject p) => all
        .where((l) => l.projectName == p.nameTh || l.projectSlug == p.slug)
        .length;

    // 0) BTS/MRT แบบ Property Hub
    for (final st in BangkokTransitStations.search(q)) {
      addProject(
        transitHits,
        _placeSuggestion(
          nameTh: st.nameTh,
          nameEn: st.nameEn,
          geoZoneSlugs: st.geoZoneSlugs,
          isEnglish: isEnglish,
          tab: SearchResultTab.transit,
          section: SearchResultSection.btsMrt,
          all: all,
        ),
      );
    }

    // 0b) เขต + ถนน ในทำเลที่ match
    for (final slug in zones) {
      PopularArea? area;
      for (final a in PopularAreas.all) {
        if (a.slug == slug) {
          area = a;
          break;
        }
      }
      if (area != null) {
        addProject(
          locationHits,
          _placeSuggestion(
            nameTh: 'เขต${area.nameTh}',
            nameEn: '${area.nameEn} District',
            geoZoneSlugs: [slug],
            isEnglish: isEnglish,
            tab: SearchResultTab.location,
            section: SearchResultSection.location,
            all: all,
          ),
        );
      }
      if (slug == 'bangna') {
        addProject(
          transitHits,
          _placeSuggestion(
            nameTh: 'ถนนบางนา - ตราด',
            nameEn: 'Bangna-Trad Road',
            geoZoneSlugs: ['bangna'],
            isEnglish: isEnglish,
            tab: SearchResultTab.transit,
            section: SearchResultSection.road,
            all: all,
          ),
        );
      }
      if (slug == 'thonglor') {
        addProject(
          locationHits,
          _placeSuggestion(
            nameTh: 'ซอยทองหล่อ (สุขุมวิท 55)',
            nameEn: 'Soi Thong Lo (Sukhumvit 55)',
            geoZoneSlugs: ['thonglor'],
            isEnglish: isEnglish,
            tab: SearchResultTab.location,
            section: SearchResultSection.road,
            all: all,
          ),
        );
      }
    }

    // 1) โครงการชื่อตรงคำค้น — จาก Cloud/bootstrap
    for (final p in await ProjectCatalog.instance.searchOnline(q)) {
      if (!_projectNameMatches(qLower, p)) continue;
      addProject(
        nameMatches,
        _projectSuggestion(
          p: p,
          group: SearchSuggestionGroup.projectMatch,
          isEnglish: isEnglish,
          all: all,
          units: countUnits(p),
        ),
      );
    }

    // 2) โครงการจากประกาศ — รวมเป็นหนึ่งรายการต่อโครงการ (ไม่แสดงห้องเดี่ยว)
    final listingGroups = <String, List<ListingPublic>>{};
    for (final l in all) {
      final key = _projectKey(l);
      if (key == null) continue;
      final nameHit = _matchesQuery(qLower, key, l);
      final zoneHit = zones.isNotEmpty && _listingInZones(l, zones);
      if (!nameHit && !zoneHit) continue;
      listingGroups.putIfAbsent(key, () => []).add(l);
    }

    for (final entry in listingGroups.entries) {
      final units = entry.value;
      final first = units.first;
      final slug = first.projectSlug;
      BangkokProject? catalog;
      if (slug != null && slug.isNotEmpty) {
        for (final p in ProjectCatalog.instance.projects) {
          if (p.slug == slug) {
            catalog = p;
            break;
          }
        }
      }

      if (catalog != null) {
        final group = _projectNameMatches(qLower, catalog)
            ? SearchSuggestionGroup.projectMatch
            : SearchSuggestionGroup.projectInArea;
        final bucket = group == SearchSuggestionGroup.projectMatch
            ? nameMatches
            : zoneProjects;
        if (_hasProjectSuggestion(bucket, slug: catalog.slug, name: catalog.nameTh)) {
          continue;
        }
        addProject(
          bucket,
          _projectSuggestion(
            p: catalog,
            group: group,
            isEnglish: isEnglish,
            all: all,
            units: units.length,
          ),
        );
      } else {
        final nameHit = _textMatchesQuery(
          qLower,
          entry.key,
          units.first.projectNameEn,
        );
        final bucket =
            nameHit ? nameMatches : zoneProjects;
        if (_hasProjectSuggestion(bucket, name: entry.key, slug: slug)) continue;
        addProject(
          bucket,
          _projectFromListing(
            projectName: entry.key,
            units: units,
            group: nameHit
                ? SearchSuggestionGroup.projectMatch
                : SearchSuggestionGroup.projectInArea,
            isEnglish: isEnglish,
          ),
        );
      }
    }

    // 3) โครงการในทำเล (ชื่อไม่ตรง แต่อยู่ในโซน)
    if (zones.isNotEmpty) {
      for (final p in ProjectCatalog.instance.projects) {
        if (_projectNameMatches(qLower, p)) continue;
        if (!_projectInZones(p, zones)) continue;
        if (_hasProjectSuggestion(zoneProjects, slug: p.slug, name: p.nameTh) ||
            _hasProjectSuggestion(nameMatches, slug: p.slug, name: p.nameTh)) {
          continue;
        }
        addProject(
          zoneProjects,
          _projectSuggestion(
            p: p,
            group: SearchSuggestionGroup.projectInArea,
            isEnglish: isEnglish,
            all: all,
            units: countUnits(p),
          ),
        );
      }
    }

    // 4) ดัชนีแสดงผล — แยกโครงการชื่อตรง vs ในทำเล vs ทำเล
    for (final d in SearchDisplayCatalog.instance.suggest(q, isEnglish: isEnglish)) {
      if (d.kind == SearchSuggestionKind.location) {
        final zones = d.geoZoneSlugs ?? [];
        final counts = zones.isEmpty ? (rent: 0, sale: 0) : _countsForZones(all, zones);
        final bucket = d.tab == SearchResultTab.transit ? transitHits : locationHits;
        addProject(
          bucket,
          SearchSuggestion(
            kind: d.kind,
            group: d.group,
            tab: d.tab,
            section: d.section,
            title: d.title,
            titleTh: d.titleTh,
            titleEn: d.titleEn,
            subtitle: counts.rent + counts.sale > 0
                ? _countSubtitle(counts.rent, counts.sale, isEnglish)
                : d.subtitle,
            geoZoneSlugs: d.geoZoneSlugs,
            rentCount: counts.rent,
            saleCount: counts.sale,
          ),
        );
        continue;
      }
      if (d.kind != SearchSuggestionKind.project) continue;

      BangkokProject? catalog;
      if (d.projectSlug != null && d.projectSlug!.isNotEmpty) {
        for (final p in ProjectCatalog.instance.projects) {
          if (p.slug == d.projectSlug) {
            catalog = p;
            break;
          }
        }
      }

      final nameHit = catalog != null
          ? _projectNameMatches(qLower, catalog)
          : _textMatchesQuery(qLower, d.projectName, null);
      final inZone = catalog != null &&
          zones.isNotEmpty &&
          _projectInZones(catalog, zones);

      if (nameHit) {
        if (catalog != null) {
          addProject(
            nameMatches,
            _projectSuggestion(
              p: catalog,
              group: SearchSuggestionGroup.projectMatch,
              isEnglish: isEnglish,
              all: all,
              units: d.vacancyCount,
            ),
          );
        } else {
          addProject(nameMatches, d);
        }
      } else if (inZone) {
        if (catalog != null) {
          addProject(
            zoneProjects,
            _projectSuggestion(
              p: catalog,
              group: SearchSuggestionGroup.projectInArea,
              isEnglish: isEnglish,
              all: all,
              units: d.vacancyCount,
            ),
          );
        }
      }
    }

    // 5) ทรู ทองหล่อ seed
    if (qLower.contains('ทรู') || qLower.contains('thru')) {
      final thru = BangkokProjects.bySlug('true-thonglor');
      if (thru != null &&
          !_hasProjectSuggestion(nameMatches, slug: thru.slug, name: thru.nameTh)) {
        nameMatches.insert(
          0,
          _projectSuggestion(
            p: thru,
            group: SearchSuggestionGroup.projectMatch,
            isEnglish: isEnglish,
            all: all,
            units: countUnits(thru),
          ),
        );
      }
    }

    // 6) ทำเล — หลังโครงการเสมอ
    for (final slug in zones) {
      PopularArea? area;
      for (final a in PopularAreas.all) {
        if (a.slug == slug) {
          area = a;
          break;
        }
      }
      if (area == null) continue;
      if (locations.any((l) => l.geoZoneSlugs?.contains(slug) == true)) continue;
      addProject(
        locationHits,
        _placeSuggestion(
          nameTh: area.nameTh,
          nameEn: area.nameEn,
          geoZoneSlugs: [slug],
          isEnglish: isEnglish,
          tab: SearchResultTab.location,
          section: SearchResultSection.location,
          all: all,
        ),
      );
    }

    try {
      final placeHits = await _places.search(qLower);
      for (final hit in placeHits.take(5)) {
        if (hit.projectSlug != null) {
          if (_hasProjectSuggestion(nameMatches, slug: hit.projectSlug)) continue;
          final boot = BangkokProjects.bySlug(hit.projectSlug!);
          if (boot != null) {
            addProject(
              nameMatches,
              _projectSuggestion(
                p: boot,
                group: SearchSuggestionGroup.projectMatch,
                isEnglish: isEnglish,
                all: all,
                units: countUnits(boot),
              ),
            );
          }
        } else if (locations.length < 6) {
          addProject(
            locations,
            SearchSuggestion(
              kind: SearchSuggestionKind.location,
              group: SearchSuggestionGroup.location,
              title: hit.name,
              subtitle: hit.subtitle,
            ),
          );
        }
      }
    } catch (_) {}

    final projectHits = [
      ...nameMatches,
      ...zoneProjects,
    ];
    final merged = [
      ...transitHits,
      ...locationHits,
      ...projectHits.take(20),
      ...locations.take(4),
    ];

    if (merged.isEmpty) {
      return [
        SearchSuggestion(
          kind: SearchSuggestionKind.hint,
          group: SearchSuggestionGroup.hint,
          title: isEnglish ? 'Search "$query"' : 'ค้นหา "$query"',
          subtitle: isEnglish ? 'Show closest matches' : 'แสดงทรัพย์ที่ใกล้เคียงที่สุด',
        ),
      ];
    }

    return merged;
  }

  SearchFilters filtersFromLegacy(Map<String, dynamic> legacy) {
    return SearchFilters(
      geoZoneSlugs: (legacy['geo_zone_slugs'] as List?)?.cast<String>(),
      maxPrice: (legacy['max_price_net'] as num?)?.toDouble(),
      minPrice: (legacy['min_price_net'] as num?)?.toDouble(),
      petAllowed: legacy['pet_allowed'] as bool?,
      propertyType: legacy['property_type'] as String?,
      listingType: legacy['listing_type'] as String?,
      projectName: legacy['project_name'] as String?,
      coAgentEligibleOnly: legacy['co_agent_eligible'] as bool?,
      investorCategory: legacy['investor_category'] as String?,
      minYield: (legacy['min_yield'] as num?)?.toDouble(),
      bedrooms: legacy['bedrooms'] as int?,
    );
  }

  SearchFilters mergeParsed({
    required SearchFilters current,
    required Map<String, dynamic> parsed,
    required String queryText,
  }) {
    final next = filtersFromLegacy(parsed);
    return current.copyWith(
      query: queryText.trim().isEmpty ? null : queryText.trim(),
      clearQuery: queryText.trim().isEmpty,
      listingType: next.listingType,
      propertyType: next.propertyType,
      minPrice: next.minPrice,
      maxPrice: next.maxPrice,
      bedrooms: next.bedrooms,
      projectName: next.projectName,
      geoZoneSlugs: next.geoZoneSlugs,
      petAllowed: next.petAllowed,
      coAgentEligibleOnly: next.coAgentEligibleOnly,
      investorCategory: next.investorCategory,
      minYield: next.minYield,
    );
  }

  String? _projectKey(ListingPublic l) {
    if (l.projectSlug != null && l.projectSlug!.trim().isNotEmpty) {
      return l.projectSlug!.trim();
    }
    if (l.projectName != null && l.projectName!.trim().isNotEmpty) {
      return l.projectName!.trim();
    }
    return null;
  }

  bool _matchesQuery(String q, String? text, ListingPublic l) {
    final hay = [
      text?.toLowerCase(),
      l.title.toLowerCase(),
      l.projectName?.toLowerCase(),
      l.projectNameEn?.toLowerCase(),
      l.district?.toLowerCase(),
      l.listingCode.toLowerCase(),
    ].whereType<String>().join(' ');
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 1);
    return tokens.every((t) => hay.contains(t));
  }

  ({Map<String, dynamic> filters, List<SearchPreviewItem> preview})
      _demoParse(String query, {bool isEnglish = false}) {
    final s = AppStrings(isEnglish);
    final preview = <SearchPreviewItem>[];
    final filters = <String, dynamic>{};
    final q = query.toLowerCase();

    if (q.contains('ทองหล่อ') || q.contains('ทรู')) {
      preview.add(SearchPreviewItem(
        label: s.locationLabel,
        value: isEnglish ? 'Thonglor / Thru' : 'ทองหล่อ / ทรู',
      ));
      filters['geo_zone_slugs'] = ['thonglor'];
    }
    if (q.contains('สุขุมวิท') || q.contains('อโศก')) {
      preview.add(SearchPreviewItem(
        label: s.locationLabel,
        value: isEnglish ? 'Sukhumvit, Asok' : 'สุขุมวิท, อโศก',
      ));
      filters['geo_zone_slugs'] = ['sukhumvit', 'asok'];
    }
    if (q.contains('15') || q.contains('15k')) {
      preview.add(SearchPreviewItem(
        label: s.budgetLabel,
        value: isEnglish ? '≤ 15,000 THB/month' : '≤ 15,000 บาท/เดือน',
      ));
      filters['max_price_net'] = 15000;
    }
    if (q.contains('สัตว') || q.contains('เลี้ยง') || q.contains('pet')) {
      preview.add(SearchPreviewItem(
        label: s.petsLabel,
        value: s.filterLabelPetsAllowed,
      ));
      filters['pet_allowed'] = true;
    }
    if (q.contains('bmv') || q.contains('below market')) {
      preview.add(SearchPreviewItem(
        label: s.filterLabelInvestor,
        value: 'BMV',
      ));
      filters['investor_category'] = 'bmv';
    }
    if (q.contains('ผู้เช่า') || q.contains('พร้อมผู้เช่า') || q.contains('tenant')) {
      preview.add(SearchPreviewItem(
        label: s.filterLabelInvestor,
        value: isEnglish ? 'With tenant' : 'พร้อมผู้เช่า',
      ));
      filters['investor_category'] = 'with_tenant';
    }
    final yieldMatch = RegExp(r'yield\s*(\d+)|ผลตอบแทน\s*(\d+)').firstMatch(q);
    if (yieldMatch != null) {
      final pct = double.parse(yieldMatch.group(1) ?? yieldMatch.group(2)!);
      preview.add(SearchPreviewItem(label: 'Yield', value: '≥ $pct%'));
      filters['min_yield'] = pct;
    }

    return (filters: filters, preview: preview);
  }
}
