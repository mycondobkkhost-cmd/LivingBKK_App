import '../data/property_catalog.dart';
import '../models/demand_post.dart';
import '../models/listing_public.dart';
import '../utils/geo_zone_match.dart';

/// จับคู่ประกาศบอร์ดกับ MyStock (ประกาศของผู้ใช้)
class DemandMyStockMatchService {
  DemandMyStockMatchService._();
  static final DemandMyStockMatchService instance = DemandMyStockMatchService._();

  static const minMatchScore = 42;

  bool postMatchesStock(DemandPost post, List<ListingPublic> stock) {
    return bestScore(post, stock) >= minMatchScore;
  }

  int bestScore(DemandPost post, List<ListingPublic> stock) {
    var best = 0;
    for (final l in stock) {
      final s = score(post, l);
      if (s > best) best = s;
    }
    return best;
  }

  ListingPublic? bestListing(DemandPost post, List<ListingPublic> stock) {
    ListingPublic? pick;
    var best = 0;
    for (final l in stock) {
      final s = score(post, l);
      if (s > best) {
        best = s;
        pick = l;
      }
    }
    if (best < minMatchScore) return null;
    return pick;
  }

  Map<String, int> scoreMap(
    Iterable<DemandPost> posts,
    List<ListingPublic> stock,
  ) {
    final out = <String, int>{};
    for (final p in posts) {
      final s = bestScore(p, stock);
      if (s >= minMatchScore) out[p.id] = s;
    }
    return out;
  }

  int score(DemandPost post, ListingPublic listing) {
    if (!_transactionMatches(post, listing)) return 0;

    var s = 20;

    if (_propertyMatches(post.propertyType, listing.propertyType)) {
      s += 18;
    } else {
      s += 5;
    }

    if (_zoneMatches(post, listing)) {
      s += 22;
    }

    if (post.maxPriceNet != null && listing.priceNet > 0) {
      final max = post.maxPriceNet!;
      final min = post.minPriceNet ?? 0;
      if (listing.priceNet >= min && listing.priceNet <= max) {
        s += 22;
      } else if (listing.priceNet <= max * 1.1) {
        s += 10;
      } else {
        s -= 8;
      }
    } else if (listing.priceNet > 0) {
      s += 6;
    }

    if (post.minAreaSqm != null && listing.areaSqm != null) {
      if (listing.areaSqm! >= post.minAreaSqm!) {
        s += 12;
      } else if (listing.areaSqm! >= post.minAreaSqm! * 0.88) {
        s += 5;
      }
    }

    if (_projectMatches(post, listing)) {
      s += 10;
    }

    return s;
  }

  bool _transactionMatches(DemandPost post, ListingPublic listing) {
    final want = post.transactionType;
    final have = listing.listingType;
    if (want == have) return true;
    if (want == 'sale' && (have == 'sale' || have == 'sale_installment')) {
      return true;
    }
    return false;
  }

  bool _propertyMatches(String postType, String listingType) {
    if (postType == listingType) return true;
    if (postType == 'townhouse' && listingType == 'house') return true;
    if (postType == 'house' && listingType == 'townhouse') return true;
    final postSlug = _slugForDb(postType);
    final listSlug = _slugForDb(listingType);
    return postSlug != null && postSlug == listSlug;
  }

  String? _slugForDb(String dbType) {
    for (final c in PropertyCatalog.categories) {
      if (c.dbValue == dbType) return c.slug;
    }
    return null;
  }

  bool _zoneMatches(DemandPost post, ListingPublic listing) {
    final listingHay =
        '${listing.district ?? ''} ${listing.projectName ?? ''} ${listing.title}'
            .toLowerCase();

    for (final zone in post.zones) {
      final z = zone.trim().toLowerCase();
      if (z.length >= 2 && listingHay.contains(z)) return true;
      if (listing.geoZoneSlug != null &&
          z.contains(listing.geoZoneSlug!.replaceAll('-', ' '))) {
        return true;
      }
    }

    if (listing.geoZoneSlug != null) {
      final zoneHay = post.zones.join(' ').toLowerCase();
      final slug = listing.geoZoneSlug!.replaceAll('-', '');
      if (zoneHay.contains(slug) || zoneHay.contains(listing.geoZoneSlug!)) {
        return true;
      }
      if (listingMatchesGeoZones(
        slugs: [listing.geoZoneSlug!],
        district: listing.district,
        projectName: listing.projectName,
        title: post.title,
      )) {
        return true;
      }
    }

    final pref = post.preferredProject?.trim().toLowerCase();
    if (pref != null &&
        pref.isNotEmpty &&
        listingHay.contains(pref)) {
      return true;
    }

    if (post.zones.isEmpty && (pref == null || pref.isEmpty)) {
      return listingHay.trim().isNotEmpty;
    }
    return false;
  }

  bool _projectMatches(DemandPost post, ListingPublic listing) {
    final pref = post.preferredProject?.trim();
    if (pref == null || pref.isEmpty) return false;
    final hay = '${listing.projectName ?? ''} ${listing.title}'.toLowerCase();
    return hay.contains(pref.toLowerCase());
  }
}
