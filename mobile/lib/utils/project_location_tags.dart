import '../data/bangkok_geo_zone_tags.dart';
import '../data/bangkok_transit_station_coords.dart';
import 'geo_distance.dart';
import 'transit_proximity.dart';

enum ProjectTagKind { transit, zone, district }

class ProjectTag {
  const ProjectTag({
    required this.label,
    required this.kind,
    this.source = '',
  });

  final String label;
  final ProjectTagKind kind;
  final String source;

  static ProjectTag transit(String label, {String source = 'coords'}) =>
      ProjectTag(label: label, kind: ProjectTagKind.transit, source: source);

  static ProjectTag zone(String label, {String source = 'zone'}) =>
      ProjectTag(label: label, kind: ProjectTagKind.zone, source: source);

  static ProjectTag district(String name, {String source = 'district'}) =>
      ProjectTag(
        label: name.startsWith('เขต ') ? name : 'เขต $name',
        kind: ProjectTagKind.district,
        source: source,
      );

  @override
  bool operator ==(Object other) =>
      other is ProjectTag && other.label == label && other.kind == kind;

  @override
  int get hashCode => Object.hash(label, kind);
}

class ProjectTagDetection {
  const ProjectTagDetection({
    this.autoSelected = const [],
    this.suggestions = const [],
  });

  final List<ProjectTag> autoSelected;
  final List<ProjectTag> suggestions;

  List<String> get allLabels => [
        for (final t in autoSelected) t.label,
        for (final t in suggestions) t.label,
      ];
}

abstract final class ProjectLocationTags {
  static const zonePrefix = 'โซน ';
  static const districtPrefix = 'เขต ';

  /// แท็กจากพิกัดเท่านั้น — ใส่ให้อัตโนมัติตอนดึงข้อมูล
  static List<ProjectTag> transitFromCoords(
    double lat,
    double lng, {
    double maxKm = 0.85,
    int limit = 4,
  }) {
    return [
      for (final h in TransitProximity.fromCoordinates(lat, lng, maxKm: maxKm, limit: limit))
        ProjectTag.transit(
          h.station.labelTh,
          source: 'coords ${(h.distanceKm * 1000).round()}m',
        ),
    ];
  }

  /// สถานีจากข้อความ — แนะนำเท่านั้น (ไม่ auto-select)
  static List<ProjectTag> transitFromText(String? text) {
    return [
      for (final l in TransitProximity.labelsFromTextStrict(text))
        ProjectTag.transit(l, source: 'text'),
    ];
  }

  static List<ProjectTag> zonesFromTransit(List<ProjectTag> transitTags) {
    final names = transitTags
        .map((t) => t.label.replaceFirst(RegExp(r'^(BTS|MRT|ARL|Gold)\s+'), ''))
        .toSet();
    final out = <ProjectTag>[];
    for (final z in BangkokGeoZoneTags.all) {
      if (z.stationNamesTh.any(names.contains)) {
        out.add(ProjectTag.zone('$zonePrefix${z.labelTh}', source: z.slug));
      }
    }
    return out;
  }

  static List<ProjectTag> zonesFromCoords(double lat, double lng) {
    final out = <ProjectTag>[];
    for (final z in BangkokGeoZoneTags.all) {
      final cLat = z.centerLat;
      final cLng = z.centerLng;
      if (cLat == null || cLng == null) continue;
      final km = haversineKm(lat, lng, cLat, cLng);
      if (km <= z.maxKmFromZoneCenter) {
        out.add(ProjectTag.zone('$zonePrefix${z.labelTh}', source: '${z.slug} ${(km * 1000).round()}m'));
      }
    }
    return out;
  }

  static ProjectTag? districtTag(String? district) {
    final d = district?.trim();
    if (d == null || d.isEmpty || d == 'กรุงเทพฯ') return null;
    return ProjectTag.district(d);
  }

  static ProjectTagDetection detect({
    required double lat,
    required double lng,
    String? district,
    String? htmlOrDesc,
    String? existingBts,
    List<String> alreadySelected = const [],
  }) {
    final selected = transitFromCoords(lat, lng);
    final selectedLabels = selected.map((t) => t.label).toSet();
    final picked = alreadySelected.toSet();

    final suggestions = <ProjectTag>[];
    void suggest(ProjectTag tag) {
      if (picked.contains(tag.label)) return;
      if (selectedLabels.contains(tag.label)) return;
      if (suggestions.any((t) => t.label == tag.label)) return;
      suggestions.add(tag);
    }

    for (final t in transitFromText(htmlOrDesc)) {
      suggest(t);
    }
    if (existingBts != null) {
      for (final part in existingBts.split(RegExp(r'[·|,/]'))) {
        final p = part.trim();
        if (p.isEmpty) continue;
        suggest(ProjectTag.transit(p, source: 'existing'));
      }
    }

    final zonePool = [
      ...zonesFromTransit(selected),
      ...zonesFromCoords(lat, lng),
    ];
    for (final z in zonePool) {
      suggest(z);
    }

    final dTag = districtTag(district);
    if (dTag != null) suggest(dTag);

    // สถานีไกลกว่า — แนะนำเพิ่ม (ไม่ auto)
    for (final h in TransitProximity.fromCoordinates(lat, lng, maxKm: 1.2, limit: 8)) {
      if (selectedLabels.contains(h.station.labelTh)) continue;
      suggest(ProjectTag.transit(
        h.station.labelTh,
        source: 'near ${(h.distanceKm * 1000).round()}m',
      ));
    }

    return ProjectTagDetection(
      autoSelected: selected,
      suggestions: suggestions,
    );
  }

  static List<String> labelsFromTags(Iterable<ProjectTag> tags) =>
      tags.map((t) => t.label).toList();

  static List<String> mergeSelectedLabels(List<String> selected) {
    final out = <String>[];
    for (final l in selected) {
      final t = l.trim();
      if (t.isEmpty) continue;
      if (!out.contains(t)) out.add(t);
    }
    return out;
  }

  static List<String> transitOnlyLabels(List<String> labels) => labels
      .where((l) =>
          l.startsWith('BTS ') ||
          l.startsWith('MRT ') ||
          l.startsWith('ARL ') ||
          l.startsWith('Gold '))
      .toList();

  static String? formatBtsField(List<String> labels) {
    final transit = transitOnlyLabels(labels);
    if (transit.isEmpty) return null;
    return transit.join(' · ');
  }

  static List<String> extraAliases(List<String> labels) {
    final out = <String>[];
    for (final label in labels) {
      out.add(label);
      if (label.startsWith(zonePrefix)) {
        out.add(label.substring(zonePrefix.length));
      }
      if (label.startsWith(districtPrefix)) {
        out.add(label.substring(districtPrefix.length));
      }
      final stripped = label.replaceFirst(RegExp(r'^(BTS|MRT|ARL|Gold)\s+'), '');
      if (stripped != label) out.add(stripped);
    }
    return out;
  }

  static List<ProjectTag> tagsFromStored(List<String> stored, {String? district}) {
    final out = <ProjectTag>[];
    for (final raw in stored) {
      final l = raw.trim();
      if (l.isEmpty) continue;
      if (l.startsWith(zonePrefix)) {
        out.add(ProjectTag.zone(l, source: 'saved'));
      } else if (l.startsWith(districtPrefix)) {
        out.add(ProjectTag.district(l.substring(districtPrefix.length), source: 'saved'));
      } else {
        out.add(ProjectTag.transit(l, source: 'saved'));
      }
    }
    final d = districtTag(district);
    if (d != null && !out.any((t) => t.label == d.label)) {
      // district อาจอยู่ในฟิลด์แยก — ไม่บังคับใส่ใน list
    }
    return out;
  }
}
