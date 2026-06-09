import 'dart:convert';

import 'package:flutter/services.dart';

import '../utils/geo_distance.dart';

/// จุดสนใจ (มหาลัย / รพ. / landmark) — โหลดจาก search_zone_catalog.json
class SearchPoiEntry {
  const SearchPoiEntry({
    required this.id,
    required this.category,
    required this.titleTh,
    required this.titleEn,
    required this.lat,
    required this.lng,
    required this.matchRadiusKm,
    this.aliases = const [],
    this.geoZoneSlugs = const [],
    this.confidence = 'coords',
  });

  final String id;
  final String category;
  final String titleTh;
  final String titleEn;
  final double lat;
  final double lng;
  final double matchRadiusKm;
  final List<String> aliases;
  final List<String> geoZoneSlugs;
  final String confidence;
}

abstract final class SearchPoiCatalog {
  static List<SearchPoiEntry> _entries = [];
  static bool _loaded = false;

  static List<SearchPoiEntry> get entries => List.unmodifiable(_entries);

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/search_zone_catalog.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final out = <SearchPoiEntry>[];
      for (final key in ['education', 'landmarks']) {
        for (final e in (data[key] as List? ?? [])) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final lat = (m['lat'] as num?)?.toDouble();
          final lng = (m['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;
          out.add(SearchPoiEntry(
            id: m['id'] as String,
            category: key == 'education' ? 'education' : 'landmark',
            titleTh: m['title_th'] as String? ?? '',
            titleEn: m['title_en'] as String? ?? '',
            lat: lat,
            lng: lng,
            matchRadiusKm: (m['match_radius_km'] as num?)?.toDouble() ?? 2.0,
            aliases: (m['aliases'] as List?)?.map((x) => x.toString()).toList() ?? const [],
            geoZoneSlugs: (m['geo_zone_slugs'] as List?)
                    ?.map((x) => x.toString())
                    .toList() ??
                const [],
            confidence: m['confidence'] as String? ?? (key == 'landmarks' ? 'suggest' : 'coords'),
          ));
        }
      }
      _entries = out;
      _loaded = true;
    } catch (_) {
      _entries = [];
      _loaded = true;
    }
  }

  static void seedForTests(List<SearchPoiEntry> entries) {
    _entries = entries;
    _loaded = true;
  }

  static List<SearchPoiEntry> nearCoordinates(
    double lat,
    double lng, {
    double? maxKm,
  }) {
    final hits = <SearchPoiEntry>[];
    for (final e in _entries) {
      final km = haversineKm(lat, lng, e.lat, e.lng);
      final limit = maxKm ?? e.matchRadiusKm;
      if (km <= limit) hits.add(e);
    }
    hits.sort((a, b) {
      final da = haversineKm(lat, lng, a.lat, a.lng);
      final db = haversineKm(lat, lng, b.lat, b.lng);
      return da.compareTo(db);
    });
    return hits;
  }

  static List<SearchPoiEntry> fromText(String? text) {
    if (text == null || text.trim().isEmpty) return [];
    final hay = text.toLowerCase();
    final out = <SearchPoiEntry>[];
    for (final e in _entries) {
      final names = [
        e.titleTh.toLowerCase(),
        e.titleEn.toLowerCase(),
        ...e.aliases.map((a) => a.toLowerCase()),
      ];
      if (names.any((n) => n.length >= 2 && hay.contains(n))) {
        out.add(e);
      }
    }
    return out;
  }
}
