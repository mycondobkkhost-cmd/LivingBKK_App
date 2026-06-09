import '../data/bangkok_geo_zone_tags.dart';
import '../data/bangkok_transit_station_coords.dart';
import '../data/search_poi_catalog.dart';
import 'geo_distance.dart';
import 'search_tag_ids.dart';
import 'transit_proximity.dart';

class ProjectSearchTagEnrichResult {
  const ProjectSearchTagEnrichResult({
    required this.searchTagSlugs,
    required this.nearbyTransitLabels,
    this.btsStation,
    this.extraAliases = const [],
    this.primaryGeoZoneSlug,
    this.status = 'auto_ok',
    this.meta = const {},
  });

  final List<String> searchTagSlugs;
  final List<String> nearbyTransitLabels;
  final String? btsStation;
  final List<String> extraAliases;
  final String? primaryGeoZoneSlug;
  final String status;
  final Map<String, dynamic> meta;
}

/// แท็กมาตรฐานระดับ A/B เท่านั้น — ไม่ใช้ AI
///
/// A = พิกัด (สถานี ≤850m, โซนศูนย์กลาง, POI confidence=coords)
/// B = ชื่อโครงการยืนยันด้วยพิกัด (เช่น ทรู+ทองหล่อ)
abstract final class ProjectSearchTagEnrich {
  static const autoTransitKm = 0.85;
  static const textVerifyKm = 1.5;
  static const nameTrueMaxKm = 1.5;

  static ProjectSearchTagEnrichResult enrich({
    required double lat,
    required double lng,
    String? district,
    String? nameTh,
    String? nameEn,
    String? slug,
    String? descriptionTh,
    String? existingBts,
    List<String> existingAliases = const [],
    List<String> existingSlugs = const [],
  }) {
    if (!_coordsPlausible(lat, lng)) {
      return const ProjectSearchTagEnrichResult(
        searchTagSlugs: [],
        nearbyTransitLabels: [],
        status: 'missing_coords',
        meta: {'reason': 'invalid_coords'},
      );
    }

    final slugSet = <String>{};
    final labelSet = <String>{};
    final sources = <Map<String, dynamic>>[];
    final textWarnings = <String>[];
    final reviewReasons = <String>[];

    void addSlug(String id, {required String source, int? distanceM}) {
      if (id.isEmpty || slugSet.contains(id)) return;
      slugSet.add(id);
      sources.add({
        'id': id,
        'source': source,
        if (distanceM != null) 'distance_m': distanceM,
      });
    }

    // ── A: สถานีรถไฟฟ้าจากพิกัด ──
    final transitHits = TransitProximity.fromCoordinates(
      lat,
      lng,
      maxKm: autoTransitKm,
      limit: 4,
    );
    for (final h in transitHits) {
      addSlug(
        SearchTagIds.transit(h.station.system, h.station.nameEn),
        source: 'A_transit',
        distanceM: h.walkMeters,
      );
      labelSet.add(h.station.labelTh);
      for (final z in h.station.geoZoneSlugs) {
        addSlug(z, source: 'A_transit_zone', distanceM: h.walkMeters);
      }
    }

    // ── A: โซนจากศูนย์กลาง (ไม่ใช่จาก POI โดยไม่เช็คระยะ) ──
    String? primaryZone;
    var bestZoneKm = double.infinity;
    for (final z in BangkokGeoZoneTags.all) {
      final cLat = z.centerLat;
      final cLng = z.centerLng;
      if (cLat == null || cLng == null) continue;
      final km = haversineKm(lat, lng, cLat, cLng);
      if (km <= z.maxKmFromZoneCenter) {
        addSlug(z.slug, source: 'A_zone', distanceM: (km * 1000).round());
        if (km < bestZoneKm) {
          bestZoneKm = km;
          primaryZone = z.slug;
        }
      }
    }

    // ── A: POI ที่มี confidence coords เท่านั้น ──
    for (final poi in SearchPoiCatalog.nearCoordinates(lat, lng)) {
      if (poi.confidence != 'coords') continue;
      final km = haversineKm(lat, lng, poi.lat, poi.lng);
      if (km <= poi.matchRadiusKm) {
        addSlug(poi.id, source: 'A_poi', distanceM: (km * 1000).round());
      }
    }

    // ── B: ชื่อโครงการ (ทรู/True + ยืนยันพิกัดทองหล่อ) ──
    final nameHay = [
      nameTh,
      nameEn,
      slug?.replaceAll('-', ' '),
      ...existingAliases,
    ].whereType<String>().join(' ').toLowerCase();

    if (nameHay.contains('ทรู') || nameHay.contains('true')) {
      if (primaryZone == 'thonglor' || _nearStation(lat, lng, 'ทองหล่อ', nameTrueMaxKm)) {
        addSlug('thonglor', source: 'B_name');
        if (slug != null && slug.isNotEmpty) addSlug(slug, source: 'B_project');
      } else {
        reviewReasons.add('name_true_but_far_from_thonglor');
      }
    }

    // ข้อความ marketing — บันทึก warning เท่านั้น ไม่ใส่แท็ก / ไม่ทำ needs_review
    for (final label in TransitProximity.labelsFromTextStrict(descriptionTh)) {
      final station = _stationByLabel(label);
      if (station == null) continue;
      final km = haversineKm(lat, lng, station.lat, station.lng);
      if (km > textVerifyKm) {
        textWarnings.add('marketing_${label}_${(km * 1000).round()}m');
      }
    }

    for (final h in transitHits) {
      labelSet.add(h.station.labelTh);
    }

    final labels = _mergeLabels(labelSet.toList());
    final extraAliases = _extraAliases(labels);

    if (slug != null && slug.isNotEmpty) {
      slugSet.add(slug);
    }

    final hasAB =
        transitHits.isNotEmpty || primaryZone != null || slugSet.length > 1;

    final status = reviewReasons.isNotEmpty
        ? 'needs_review'
        : !hasAB
            ? 'needs_review'
            : 'auto_ok';

    return ProjectSearchTagEnrichResult(
      searchTagSlugs: slugSet.toList(),
      nearbyTransitLabels: labels,
      btsStation: _formatBts(labels),
      extraAliases: extraAliases,
      primaryGeoZoneSlug: primaryZone,
      status: status,
      meta: {
        'tier': 'AB_only',
        'sources': sources,
        if (textWarnings.isNotEmpty) 'text_warnings': textWarnings,
        if (reviewReasons.isNotEmpty) 'review_reasons': reviewReasons,
        'enriched_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  static List<String> _mergeLabels(List<String> raw) {
    final out = <String>[];
    for (final l in raw) {
      final t = l.trim();
      if (t.isEmpty || out.contains(t)) continue;
      out.add(t);
    }
    return out;
  }

  static String? _formatBts(List<String> labels) {
    final transit = labels
        .where((l) =>
            l.startsWith('BTS ') ||
            l.startsWith('MRT ') ||
            l.startsWith('ARL ') ||
            l.startsWith('Gold '))
        .toList();
    if (transit.isEmpty) return null;
    return transit.join(' · ');
  }

  static List<String> _extraAliases(List<String> labels) {
    final out = <String>[];
    for (final label in labels) {
      out.add(label);
      final stripped = label.replaceFirst(RegExp(r'^(BTS|MRT|ARL|Gold)\s+'), '');
      if (stripped != label) out.add(stripped);
    }
    return out.toSet().toList();
  }

  static bool _coordsPlausible(double lat, double lng) {
    return lat > 5 && lat < 21 && lng > 97 && lng < 106;
  }

  static bool _nearStation(double lat, double lng, String nameTh, double maxKm) {
    for (final s in BangkokTransitStationCoords.all) {
      if (s.nameTh != nameTh) continue;
      return haversineKm(lat, lng, s.lat, s.lng) <= maxKm;
    }
    return false;
  }

  static TransitStationCoord? _stationByLabel(String labelTh) {
    for (final s in BangkokTransitStationCoords.all) {
      if (s.labelTh == labelTh) return s;
    }
    return null;
  }
}
