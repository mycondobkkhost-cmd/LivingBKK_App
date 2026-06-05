import 'dart:math' as math;

import 'package:latlong2/latlong.dart' as osm;

/// Grid-based clustering for map markers at low zoom.
class MapCluster<T> {
  const MapCluster({
    required this.center,
    required this.items,
  });

  final osm.LatLng center;
  final List<T> items;

  int get count => items.length;
}

typedef MapClusterLatLng<T> = ({T item, double lat, double lng});

List<MapCluster<T>> clusterByZoom<T>({
  required List<MapClusterLatLng<T>> points,
  required double zoom,
  int minPointsToCluster = 8,
  double clusterBelowZoom = 14,
}) {
  if (points.isEmpty) return [];
  if (zoom >= clusterBelowZoom || points.length < minPointsToCluster) {
    return points
        .map((p) => MapCluster(center: osm.LatLng(p.lat, p.lng), items: [p.item]))
        .toList();
  }

  // ~cell size in degrees; smaller zoom → larger cells
  final cell = 0.35 / math.pow(2, zoom.clamp(8, 16));

  final buckets = <String, List<MapClusterLatLng<T>>>{};
  for (final p in points) {
    final key =
        '${(p.lat / cell).floor()}_${(p.lng / cell).floor()}';
    buckets.putIfAbsent(key, () => []).add(p);
  }

  return buckets.values.map((group) {
    var lat = 0.0;
    var lng = 0.0;
    for (final p in group) {
      lat += p.lat;
      lng += p.lng;
    }
    final n = group.length;
    return MapCluster(
      center: osm.LatLng(lat / n, lng / n),
      items: group.map((e) => e.item).toList(),
    );
  }).toList();
}
