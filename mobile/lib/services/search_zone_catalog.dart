import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/bangkok_geo_zone_tags.dart';
import '../data/bangkok_projects.dart';
import '../data/bangkok_transit_station_coords.dart';
import '../data/bangkok_transit_stations.dart';
import '../data/popular_areas.dart';
import '../models/search_zone_catalog_entry.dart';
import 'project_catalog.dart';

/// สมุดทำเล/รถไฟฟ้า/โครงการ/สถานศึกษา สำหรับ multi-select filter
class SearchZoneCatalog extends ChangeNotifier {
  SearchZoneCatalog._();

  static final SearchZoneCatalog instance = SearchZoneCatalog._();

  static const _assetPath = 'assets/data/search_zone_catalog.json';

  final List<SearchZoneCatalogEntry> _entries = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<SearchZoneCatalogEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    if (!_loaded) {
      _entries.clear();
      _seedLocations();
      _seedTransit();
      await _seedEducationFromJson();
      await _seedLandmarksFromJson();
      ProjectCatalog.instance.addListener(_refreshProjects);
      _loaded = true;
    }
    _refreshProjects();
    notifyListeners();
  }

  void _refreshProjects() {
    _entries.removeWhere((e) => e.category == 'project');
    final projects = ProjectCatalog.instance.projects;
    final source = projects.isNotEmpty ? projects : BangkokProjects.all;
    for (final p in source) {
      _entries.add(entryFromProject(p));
    }
  }

  static SearchZoneCatalogEntry entryFromProject(BangkokProject p) {
    return SearchZoneCatalogEntry(
      id: p.slug,
      category: 'project',
      titleTh: p.nameTh,
      titleEn: p.nameEn,
      geoZoneSlugs: p.geoZoneId != null ? [p.geoZoneId!] : const [],
      lat: p.lat,
      lng: p.lng,
      matchRadiusKm: 0.8,
      projectSlug: p.slug,
      aliases: [
        ...p.aliases,
        if (p.bts != null && p.bts!.isNotEmpty) p.bts!,
        p.district,
      ],
    );
  }

  void _seedLocations() {
    final seen = <String>{};
    for (final z in BangkokGeoZoneTags.all) {
      if (!seen.add(z.slug)) continue;
      _entries.add(SearchZoneCatalogEntry(
        id: z.slug,
        category: 'location',
        titleTh: z.labelTh,
        titleEn: z.labelEn,
        geoZoneSlugs: [z.slug],
        lat: z.centerLat,
        lng: z.centerLng,
        matchRadiusKm: z.maxKmFromZoneCenter,
        aliases: [
          ...z.stationNamesTh,
          ...z.aliases,
        ],
      ));
    }
    for (final a in PopularAreas.all) {
      if (!seen.add(a.slug)) continue;
      _entries.add(SearchZoneCatalogEntry(
        id: a.slug,
        category: 'location',
        titleTh: a.nameTh,
        titleEn: a.nameEn,
        geoZoneSlugs: [a.slug],
        aliases: [
          a.subtitleTh,
          a.subtitleEn,
        ],
      ));
    }
  }

  void _seedTransit() {
    final aliasByLabel = <String, List<String>>{
      for (final s in BangkokTransitStations.all)
        s.nameTh: s.aliases,
    };
    for (final st in BangkokTransitStationCoords.all) {
      final id = _transitId(st.system, st.nameEn);
      final labelTh = st.labelTh;
      _entries.add(SearchZoneCatalogEntry(
        id: id,
        category: 'transit',
        titleTh: labelTh,
        titleEn: st.labelEn,
        geoZoneSlugs: st.geoZoneSlugs,
        lat: st.lat,
        lng: st.lng,
        matchRadiusKm: 1.2,
        aliases: aliasByLabel[labelTh] ?? const [],
      ));
    }
  }

  Future<void> _seedLandmarksFromJson() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in (data['landmarks'] as List? ?? [])) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        _entries.add(SearchZoneCatalogEntry(
          id: m['id'] as String,
          category: 'landmark',
          titleTh: m['title_th'] as String? ?? '',
          titleEn: m['title_en'] as String? ?? '',
          geoZoneSlugs: (m['geo_zone_slugs'] as List?)
                  ?.map((x) => x.toString())
                  .toList() ??
              const [],
          lat: (m['lat'] as num?)?.toDouble(),
          lng: (m['lng'] as num?)?.toDouble(),
          matchRadiusKm: (m['match_radius_km'] as num?)?.toDouble() ?? 1.5,
          aliases: (m['aliases'] as List?)?.map((x) => x.toString()).toList() ?? const [],
        ));
      }
    } catch (e) {
      debugPrint('SearchZoneCatalog landmarks load: $e');
    }
  }

  Future<void> _seedEducationFromJson() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in (data['education'] as List? ?? [])) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        _entries.add(SearchZoneCatalogEntry(
          id: m['id'] as String,
          category: 'education',
          titleTh: m['title_th'] as String? ?? '',
          titleEn: m['title_en'] as String? ?? '',
          lat: (m['lat'] as num?)?.toDouble(),
          lng: (m['lng'] as num?)?.toDouble(),
          matchRadiusKm: (m['match_radius_km'] as num?)?.toDouble() ?? 2.0,
          aliases: (m['aliases'] as List?)?.map((x) => x.toString()).toList() ?? const [],
        ));
      }
    } catch (e) {
      debugPrint('SearchZoneCatalog education load: $e');
    }
  }

  static String _transitId(String system, String nameEn) {
    final sys = system.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final name = nameEn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return '$sys-$name'.replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }

  List<SearchZoneCatalogEntry> byCategory(String category) =>
      _entries.where((e) => e.category == category).toList();

  /// ทำเลยอดฮิต — แนะนำแบบแท็ก (ไม่ใช่ checkbox)
  List<SearchZoneCatalogEntry> popularEntries({
    int limit = 8,
    Set<String> excludeIds = const {},
  }) {
    final out = <SearchZoneCatalogEntry>[];
    for (final a in PopularAreas.all) {
      if (excludeIds.contains(a.slug)) continue;
      final entry = byId(a.slug);
      if (entry != null && entry.category == 'location') {
        out.add(entry);
      }
      if (out.length >= limit) break;
    }
    return out;
  }

  SearchZoneCatalogEntry? byId(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  String labelFor({
    required String category,
    required String id,
    required bool isEnglish,
  }) {
    final entry = byId(id);
    if (entry != null) return entry.label(isEnglish);
    if (category == 'project') {
      for (final p in ProjectCatalog.instance.projects) {
        if (p.slug == id) return isEnglish ? p.nameEn : p.nameTh;
      }
    }
    return id.replaceAll('-', ' ');
  }

  static bool _isPlaceCategory(String category) =>
      category == 'location' ||
      category == 'landmark' ||
      category == 'transit' ||
      category == 'education';

  /// Autocomplete — จองโควต้าทำเลก่อน แล้วค่อยโครงการ
  List<SearchZoneCatalogEntry> search(
    String query, {
    String? category,
    int limit = 24,
    Set<String> excludeIds = const {},
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final places = <SearchZoneCatalogEntry>[];
    final projects = <SearchZoneCatalogEntry>[];
    final placeCap =
        category == 'project' ? 0 : (limit / 2).ceil().clamp(4, 10);

    for (final e in _entries) {
      if (category != null && e.category != category) continue;
      if (excludeIds.contains(e.id)) continue;
      if (!_entryMatchesQuery(e, q)) continue;
      if (_isPlaceCategory(e.category)) {
        if (places.length < placeCap) places.add(e);
      } else if (e.category == 'project') {
        final projectCap =
            category == 'project' ? limit : limit - places.length;
        if (projects.length < projectCap) projects.add(e);
      }
      if (places.length + projects.length >= limit) break;
    }

    return [...places, ...projects].take(limit).toList();
  }

  bool _entryMatchesQuery(SearchZoneCatalogEntry e, String q) {
    bool transitLike(String a) {
      final s = a.toLowerCase().trim();
      return s.startsWith('bts ') ||
          s.startsWith('mrt ') ||
          s.startsWith('arl ') ||
          s.startsWith('gold ');
    }

    if (e.category == 'project') {
      // ชื่อ / slug + aliases ชื่อโครงการ (ไม่ใช้ alias แบบสถานี)
      final hay = [
        e.titleTh.toLowerCase(),
        e.titleEn.toLowerCase(),
        e.id.toLowerCase().replaceAll('-', ' '),
        if (e.projectSlug != null)
          e.projectSlug!.toLowerCase().replaceAll('-', ' '),
        ...e.aliases.where((a) => !transitLike(a)).map((a) => a.toLowerCase()),
      ];
      return hay.any((h) => h.isNotEmpty && h.contains(q));
    }

    final hay = [
      e.titleTh.toLowerCase(),
      e.titleEn.toLowerCase(),
      e.id.toLowerCase().replaceAll('-', ' '),
      ...e.aliases.map((a) => a.toLowerCase()),
    ];
    return hay.any((h) => h.isNotEmpty && h.contains(q));
  }

  /// รวมผล local + cloud — คงทำเลไว้ด้านบน · โครงการต้องตรงชื่อจริง
  Future<List<SearchZoneCatalogEntry>> searchWithProjects(
    String query, {
    Set<String> excludeIds = const {},
    int limit = 24,
  }) async {
    final local = search(query, excludeIds: excludeIds, limit: limit);
    if (query.trim().length < 2) return local;

    final q = query.trim().toLowerCase();
    final places = local.where((e) => _isPlaceCategory(e.category)).toList();
    final projects = local.where((e) => e.category == 'project').toList();

    final online = await ProjectCatalog.instance.searchOnline(query);
    final seen = {
      ...local.map((e) => e.id),
      ...excludeIds,
    };
    for (final p in online) {
      if (seen.contains(p.slug)) continue;
      final entry = entryFromProject(p);
      if (!_entryMatchesQuery(entry, q)) continue;
      projects.add(entry);
      seen.add(p.slug);
      if (places.length + projects.length >= limit) break;
    }

    return [...places, ...projects].take(limit).toList();
  }
}
