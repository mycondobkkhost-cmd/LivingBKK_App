import '../data/bangkok_transit_station_coords.dart';
import 'geo_distance.dart';

class NearbyTransitHit {
  const NearbyTransitHit({
    required this.station,
    required this.distanceKm,
    required this.walkMeters,
    required this.source,
  });

  final TransitStationCoord station;
  final double distanceKm;
  final int walkMeters;
  final String source;
}

abstract final class TransitProximity {
  /// ระยะเดินโดยประมาณจากระยะเส้นตรง (กม.) × 1.35
  static int estimateWalkMeters(double km) => (km * 1350).round();

  static List<NearbyTransitHit> fromCoordinates(
    double lat,
    double lng, {
    double maxKm = 1.0,
    int limit = 5,
  }) {
    final hits = <NearbyTransitHit>[];
    for (final s in BangkokTransitStationCoords.all) {
      final km = haversineKm(lat, lng, s.lat, s.lng);
      if (km > maxKm) continue;
      hits.add(
        NearbyTransitHit(
          station: s,
          distanceKm: km,
          walkMeters: estimateWalkMeters(km),
          source: 'coords',
        ),
      );
    }
    hits.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return hits.take(limit).toList();
  }

  /// จับชื่อสถานีจากข้อความ (รายละเอียด / เว็บภายนอก)
  static List<String> labelsFromText(String? text) => labelsFromTextStrict(text);

  /// จับชื่อสถานีจากข้อความ — ใช้ word boundary ลด false positive (เช่น Ari จากคำอื่น)
  static List<String> labelsFromTextStrict(String? text) {
    if (text == null || text.trim().isEmpty) return [];
    final hay = text.toLowerCase();
    final found = <String>[];
    for (final s in BangkokTransitStationCoords.all) {
      final th = s.nameTh.toLowerCase();
      final en = s.nameEn.toLowerCase();
      if (_textMentionsStation(hay, th) ||
          _textMentionsStation(hay, en) ||
          hay.contains('${s.system.toLowerCase()} $th') ||
          hay.contains('${s.system.toLowerCase()} $en')) {
        found.add(s.labelTh);
      }
    }
    return _dedupeLabels(found);
  }

  static bool _textMentionsStation(String hay, String name) {
    if (name.length < 2) return false;
    if (name.runes.every((r) => r <= 127)) {
      final re = RegExp(r'(?<![a-z])${RegExp.escape(name)}(?![a-z])', caseSensitive: false);
      return re.hasMatch(hay);
    }
    return hay.contains(name);
  }

  static List<String> mergeLabels({
    required double lat,
    required double lng,
    String? htmlOrDesc,
    String? existing,
    double maxKm = 1.0,
    int limit = 5,
  }) {
    final merged = <String>[];
    void add(String label) {
      final t = label.trim();
      if (t.isEmpty) return;
      if (!merged.any((e) => e == t)) merged.add(t);
    }

    for (final h in fromCoordinates(lat, lng, maxKm: maxKm, limit: limit)) {
      add(h.station.labelTh);
    }
    for (final l in labelsFromText(htmlOrDesc)) {
      add(l);
    }
    if (existing != null) {
      for (final part in existing.split(RegExp(r'[·|,/]'))) {
        add(part.trim());
      }
    }
    return merged.take(limit).toList();
  }

  static String formatBtsField(List<String> labels) => labels.join(' · ');

  static List<String> extraAliases(List<String> labels) {
    final out = <String>[];
    for (final label in labels) {
      out.add(label);
      final stripped = label.replaceFirst(RegExp(r'^(BTS|MRT|ARL|Gold)\s+'), '');
      if (stripped != label) out.add(stripped);
    }
    return out;
  }

  static List<String> _dedupeLabels(List<String> labels) {
    final out = <String>[];
    for (final l in labels) {
      if (!out.contains(l)) out.add(l);
    }
    return out;
  }
}
