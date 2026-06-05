import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../data/bangkok_projects.dart';
import '../utils/localized_content.dart';
import '../utils/metro_region.dart';

class PlaceSearchHit {
  const PlaceSearchHit({
    required this.name,
    required this.subtitle,
    this.projectSlug,
    this.lat,
    this.lng,
    this.placeId,
  });

  final String name;
  final String subtitle;
  final String? projectSlug;
  final double? lat;
  final double? lng;
  final String? placeId;
}

/// ค้นหาโครงการ — ฐานข้อมูลในแอป + Google Places (เมื่อมี API key)
class PlacesService {
  Future<List<PlaceSearchHit>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final hits = <PlaceSearchHit>[];
    final seen = <String>{};

    for (final p in MetroRegion.filterProjects(BangkokProjects.search(q))) {
      final key = p.slug;
      if (seen.add(key)) {
        hits.add(
          PlaceSearchHit(
            name: p.displayBilingual,
            subtitle: p.bts ?? p.district,
            projectSlug: p.slug,
            lat: p.lat,
            lng: p.lng,
          ),
        );
      }
    }

    if (Env.hasMapsKey) {
      try {
        final google = await _googleTextSearch('$q condo bangkok thailand');
        for (final g in google) {
          if (seen.add(g.placeId ?? g.name)) {
            hits.add(g);
          }
        }
      } catch (_) {
        // ใช้เฉพาะฐานข้อมูลในแอป
      }
    }

    return hits.take(12).toList();
  }

  Future<List<PlaceSearchHit>> _googleTextSearch(String query) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      {
        'query': query,
        'key': Env.googleMapsApiKey,
        'language': 'th',
        'region': 'th',
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) return [];

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['status'] != 'OK' && body['status'] != 'ZERO_RESULTS') {
      return [];
    }

    final results = body['results'] as List? ?? [];
    return results.take(6).map((raw) {
      final m = raw as Map<String, dynamic>;
      final loc = m['geometry']?['location'] as Map<String, dynamic>?;
      final name = m['name'] as String? ?? '';
      final addr = m['formatted_address'] as String? ?? '';
      return PlaceSearchHit(
        name: name,
        subtitle: addr,
        lat: (loc?['lat'] as num?)?.toDouble(),
        lng: (loc?['lng'] as num?)?.toDouble(),
        placeId: m['place_id'] as String?,
      );
    }).toList();
  }
}
