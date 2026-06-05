import '../data/property_catalog.dart';
import '../models/listing_public.dart';
import '../models/search_filters.dart';
import 'listing_activity_service.dart';
import 'preferred_stock_service.dart';

class HomeFeedSection {
  const HomeFeedSection({
    required this.id,
    required this.titleTh,
    required this.titleEn,
    required this.items,
    this.accentIndex = 0,
  });

  final String id;
  final String titleTh;
  final String titleEn;
  final List<ListingPublic> items;
  final int accentIndex;
}

class HomeSectionsBuilder {
  List<HomeFeedSection> build({
    required List<ListingPublic> all,
    required SearchFilters sessionFilters,
    required bool isAgent,
    String? categorySlug,
    List<ListingPublic>? nearMe,
    List<ListingPublic>? recentlyViewed,
    List<ListingPublic>? preferredStock,
  }) {
    final type = sessionFilters.listingType;
    final categoryDb = PropertyCatalog.dbValueForSlug(categorySlug);
    var pool = all.where((l) {
      if (type != null && l.listingType != type) return false;
      if (categoryDb != null && l.propertyType != categoryDb) return false;
      if (isAgent && !l.coAgentEligible) return false;
      return true;
    }).toList();

    if (pool.isEmpty) pool = List<ListingPublic>.from(all);

    final zones = ListingActivityService.instance.topGeoZones();
    final sections = <HomeFeedSection>[];
    var accent = 0;

    final recommended = _ranked(pool, zones).take(12).toList();
    if (recommended.isNotEmpty) {
      sections.add(
        HomeFeedSection(
          id: 'recommended',
          titleTh: 'ประกาศแนะนำ',
          titleEn: 'Recommended for you',
          items: recommended,
          accentIndex: accent++,
        ),
      );
    }

    if (recentlyViewed != null && recentlyViewed.isNotEmpty) {
      sections.add(
        HomeFeedSection(
          id: 'recently_viewed',
          titleTh: 'ดูล่าสุด',
          titleEn: 'Recently viewed',
          items: recentlyViewed.take(12).toList(),
          accentIndex: accent++,
        ),
      );
    }

    if (nearMe != null && nearMe.isNotEmpty) {
      sections.add(
        HomeFeedSection(
          id: 'near_me',
          titleTh: 'ใกล้ฉัน',
          titleEn: 'Near you',
          items: nearMe.take(12).toList(),
          accentIndex: accent++,
        ),
      );
    }

    if (isAgent && preferredStock != null && preferredStock.isNotEmpty) {
      sections.add(
        HomeFeedSection(
          id: 'preferred_stock',
          titleTh: 'สต็อกที่เก็บไว้',
          titleEn: 'Preferred stock',
          items: preferredStock.take(12).toList(),
          accentIndex: accent++,
        ),
      );
    }

    final latest = List<ListingPublic>.from(pool)
      ..sort((a, b) => b.listingCode.compareTo(a.listingCode));
    sections.add(
      HomeFeedSection(
        id: 'latest',
        titleTh: 'ประกาศอัปเดทล่าสุด',
        titleEn: 'Latest listings',
        items: latest.take(12).toList(),
        accentIndex: accent++,
      ),
    );

    if (zones.isNotEmpty) {
      final popular = pool
          .where((l) => ListingActivityService.instance.listingInUserZones(l, zones))
          .toList()
        ..sort((a, b) => _score(b, zones).compareTo(_score(a, zones)));
      if (popular.isNotEmpty) {
        sections.add(
          HomeFeedSection(
            id: 'popular_area',
            titleTh: 'ยอดนิยมในพื้นที่คุณ',
            titleEn: 'Popular in your areas',
            items: popular.take(12).toList(),
            accentIndex: accent++,
          ),
        );
      }
    }

    if (isAgent) {
      final co = pool.where((l) => l.coAgentEligible).take(10).toList();
      if (co.isNotEmpty) {
        sections.add(
          HomeFeedSection(
            id: 'co_agent',
            titleTh: 'ทรัพย์รับโคนายหน้า',
            titleEn: 'Co-broker listings',
            items: co,
            accentIndex: accent++,
          ),
        );
      }

      final ownerNew = List<ListingPublic>.from(
        all.where((l) => l.coAgentEligible),
      )..sort((a, b) => b.listingCode.compareTo(a.listingCode));
      if (ownerNew.isNotEmpty) {
        sections.add(
          HomeFeedSection(
            id: 'owner_stock_new',
            titleTh: 'สต็อก Owner ใหม่',
            titleEn: 'New owner stock',
            items: ownerNew.take(10).toList(),
            accentIndex: accent++,
          ),
        );
      }
    }

    final prices = pool.map((e) => e.priceNet).toList()..sort();
    if (prices.length >= 4) {
      final median = prices[prices.length ~/ 2];
      final affordable = pool.where((l) => l.priceNet <= median * 1.05).take(10).toList();
      if (affordable.isNotEmpty) {
        sections.add(
          HomeFeedSection(
            id: 'affordable',
            titleTh: 'ราคาเข้าถึงง่าย',
            titleEn: 'Budget-friendly',
            items: affordable,
            accentIndex: accent++,
          ),
        );
      }
    }

    return sections;
  }

  List<ListingPublic> resolvePreferredStock(
    List<ListingPublic> all,
    PreferredStockService preferred,
  ) {
    final byId = {for (final l in all) l.id: l};
    return preferred.ids
        .map((id) => byId[id])
        .whereType<ListingPublic>()
        .toList();
  }

  List<ListingPublic> _ranked(List<ListingPublic> pool, List<String> zones) {
    final copy = List<ListingPublic>.from(pool);
    copy.sort((a, b) => _score(b, zones).compareTo(_score(a, zones)));
    return copy;
  }

  double _score(ListingPublic l, List<String> zones) {
    final activity = ListingActivityService.instance;
    var s = ListingActivityService.seedPopularity(l.id).toDouble();
    s += activity.viewCount(l.id) * 5;
    if (zones.isNotEmpty && activity.listingInUserZones(l, zones)) {
      s += 25;
    }
    return s;
  }
}
