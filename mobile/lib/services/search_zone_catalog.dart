import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/bangkok_geo_zone_tags.dart';
import '../data/bangkok_projects.dart';
import '../data/bangkok_transit_station_coords.dart';
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
      ));
    }
  }

  void _seedTransit() {
    for (final st in BangkokTransitStationCoords.all) {
      final id = _transitId(st.system, st.nameEn);
      _entries.add(SearchZoneCatalogEntry(
        id: id,
        category: 'transit',
        titleTh: st.labelTh,
        titleEn: st.labelEn,
        geoZoneSlugs: st.geoZoneSlugs,
        lat: st.lat,
        lng: st.lng,
        matchRadiusKm: 1.2,
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

  /// Autocomplete for tag search — prefix/substring match on titles + aliases.
  List<SearchZoneCatalogEntry> search(
    String query, {
    String? category,
    int limit = 15,
    Set<String> excludeIds = const {},
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final results = <SearchZoneCatalogEntry>[];
    for (final e in _entries) {
      if (category != null && e.category != category) continue;
      if (excludeIds.contains(e.id)) continue;
      if (_entryMatchesQuery(e, q)) {
        results.add(e);
        if (results.length >= limit) break;
      }
    }
    results.sort((a, b) {
      if (a.category == 'project' && b.category != 'project') return -1;
      if (a.category != 'project' && b.category == 'project') return 1;
      return 0;
    });
    return results;
  }

  bool _entryMatchesQuery(SearchZoneCatalogEntry e, String q) {
    final hay = [
      e.titleTh.toLowerCase(),
      e.titleEn.toLowerCase(),
      e.id.toLowerCase().replaceAll('-', ' '),
      if (e.projectSlug != null) e.projectSlug!.toLowerCase().replaceAll('-', ' '),
      ...e.aliases.map((a) => a.toLowerCase()),
    ];
    return hay.any((h) => h.isNotEmpty && h.contains(q));
  }

  /// รวมผล local + cloud สำหรับโครงการ
  Future<List<SearchZoneCatalogEntry>> searchWithProjects(
    String query, {
    Set<String> excludeIds = const {},
    int limit = 15,
  }) async {
    final local = search(query, excludeIds: excludeIds, limit: limit);
    if (query.trim().length < 2) return local;

    final online = await ProjectCatalog.instance.searchOnline(query);
    final seen = {...local.map((e) => e.id), ...excludeIds};
    final merged = [...local];
    for (final p in online) {
      if (seen.contains(p.slug)) continue;
      merged.add(entryFromProject(p));
      seen.add(p.slug);
      if (merged.length >= limit) break;
    }
    merged.sort((a, b) {
      if (a.category == 'project' && b.category != 'project') return -1;
      if (a.category != 'project' && b.category == 'project') return 1;
      return 0;
    });
    return merged.take(limit).toList();
  }
}
