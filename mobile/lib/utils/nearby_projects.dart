import '../data/bangkok_projects.dart';
import '../services/project_catalog.dart';
import 'geo_distance.dart';

class NearbyProjectHit {
  const NearbyProjectHit({
    required this.project,
    required this.distanceKm,
  });

  final BangkokProject project;
  final double distanceKm;
}

/// โครงการใกล้จุดอ้างอิง — เรียงจากใกล้สุด (ไม่รวมโครงการเดิม)
List<NearbyProjectHit> nearbyProjects({
  required BangkokProject origin,
  Iterable<BangkokProject>? candidates,
  String? excludeSlug,
  int limit = 10,
  double maxKm = 8,
}) {
  final source = candidates ?? ProjectCatalog.instance.projects;
  final pool = source.isNotEmpty ? source : BangkokProjects.all;
  final exclude = excludeSlug ?? origin.slug;

  final hits = <NearbyProjectHit>[];
  for (final p in pool) {
    if (p.slug == exclude) continue;
    final km = haversineKm(origin.lat, origin.lng, p.lat, p.lng);
    if (km > maxKm) continue;
    hits.add(NearbyProjectHit(project: p, distanceKm: km));
  }
  hits.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  if (hits.length > limit) return hits.sublist(0, limit);
  return hits;
}
