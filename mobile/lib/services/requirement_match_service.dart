import '../models/customer_requirement.dart';
import '../models/listing_public.dart';
import '../data/property_catalog.dart';
import '../utils/geo_zone_match.dart';

/// Looking to Match — จับคู่ความต้องการกับประกาศในระบบ
class RequirementMatchService {
  RequirementMatchService._();
  static final instance = RequirementMatchService._();

  static const minScore = 45;

  List<ListingPublic> match({
    required CustomerRequirement req,
    required List<ListingPublic> pool,
    int limit = 12,
  }) {
    final scored = <({ListingPublic listing, int score})>[];
    for (final l in pool) {
      final s = _score(req, l);
      if (s >= minScore) scored.add((listing: l, score: s));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((e) => e.listing).toList();
  }

  int scoreFor(CustomerRequirement req, ListingPublic l) => _score(req, l);

  int _score(CustomerRequirement req, ListingPublic l) {
    var s = 0;

    final wantType = req.isSale ? 'sale' : 'rent';
    if (l.listingType == wantType) {
      s += 25;
    } else {
      return 0;
    }

    if (req.propertyTypes.isNotEmpty) {
      final dbValues = req.propertyTypes
          .map((s) => PropertyCatalog.dbValueForSlug(s) ?? s)
          .toSet();
      if (dbValues.contains(l.propertyType)) {
        s += 15;
      } else {
        s += 4;
      }
    } else if (req.propertyType == l.propertyType) {
      s += 15;
    } else {
      final db = PropertyCatalog.dbValueForSlug(req.propertyType);
      if (db != null && l.propertyType == db) s += 15;
    }

    if (_zoneMatch(req.zone, l)) {
      s += 20;
    }

    if (req.maxPriceNet != null) {
      final minP = req.minPriceNet ?? 0;
      final maxP = req.maxPriceNet!;
      if (l.priceNet >= minP && l.priceNet <= maxP) {
        s += 20;
      } else if (l.priceNet <= maxP * 1.08) {
        s += 8;
      } else {
        s -= 10;
      }
    }

    if (req.minAreaSqm != null && l.areaSqm != null) {
      if (l.areaSqm! >= req.minAreaSqm!) {
        s += 10;
      } else if (l.areaSqm! >= req.minAreaSqm! * 0.9) {
        s += 4;
      }
    }

    return s;
  }

  bool _zoneMatch(String zone, ListingPublic l) {
    if (zone.trim().isEmpty) return true;
    const slugs = [
      'thonglor',
      'asok',
      'sukhumvit',
      'bangna',
      'nonthaburi',
      'pathum-thani',
      'samut-prakan',
    ];
    for (final slug in slugs) {
      if (zone.toLowerCase().contains(slug.replaceAll('-', '')) ||
          zone.contains(slug)) {
        if (listingMatchesGeoZones(
          slugs: [slug],
          district: l.district,
          projectName: l.projectName,
          title: l.title,
        )) {
          return true;
        }
      }
    }
    return _zoneLooseMatch(zone, l);
  }

  bool _zoneLooseMatch(String zone, ListingPublic l) {
    final z = zone.toLowerCase();
    final hay = '${l.district ?? ''} ${l.projectName ?? ''} ${l.title}'.toLowerCase();
    return hay.contains(z) || z.split(RegExp(r'[\s,·]+')).any((p) => p.length > 2 && hay.contains(p));
  }
}
