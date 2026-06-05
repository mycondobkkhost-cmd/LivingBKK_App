import 'dart:math';

import '../models/listing_public.dart';

/// ระยะทาง Haversine (กม.)
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _rad(double deg) => deg * pi / 180;

/// เรียงทรัพย์ตามระยะจากจุดอ้างอิง
List<ListingPublic> sortByDistance(
  List<ListingPublic> listings, {
  required double lat,
  required double lng,
  double maxKm = 15,
}) {
  final scored = <({ListingPublic listing, double km})>[];
  for (final l in listings) {
    if (l.lat == null || l.lng == null) continue;
    final km = haversineKm(lat, lng, l.lat!, l.lng!);
    if (km <= maxKm) scored.add((listing: l, km: km));
  }
  scored.sort((a, b) => a.km.compareTo(b.km));
  return scored.map((e) => e.listing).toList();
}
