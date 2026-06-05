import 'package:flutter/foundation.dart';

import '../models/listing_public.dart';
import '../utils/geo_zone_match.dart';
import 'local_prefs_service.dart';

/// บันทึกทรัพย์ที่ผู้ใช้เปิดดู + analytics + ดูล่าสุด
class ListingActivityService extends ChangeNotifier {
  ListingActivityService._();
  static final instance = ListingActivityService._();

  static const _recentKey = 'recently_viewed_ids';
  static const _analyticsKey = 'listing_analytics_v1';
  static const maxRecent = 20;

  final _viewCounts = <String, int>{};
  final _zoneScores = <String, int>{};
  final _recentIds = <String>[];
  final _detailViews = <String, int>{};
  final _shareClicks = <String, int>{};
  final _chatStarts = <String, int>{};
  bool _loaded = false;

  void recordView(ListingPublic listing) {
    _viewCounts[listing.id] = (_viewCounts[listing.id] ?? 0) + 1;
    _detailViews[listing.id] = (_detailViews[listing.id] ?? 0) + 1;
    final zone = listing.geoZoneSlug ?? inferGeoZoneSlug(listing);
    if (zone != null) {
      _zoneScores[zone] = (_zoneScores[zone] ?? 0) + 1;
    }
    _pushRecent(listing.id);
    _persistAnalytics();
    notifyListeners();
  }

  void recordShare(String listingId) {
    _shareClicks[listingId] = (_shareClicks[listingId] ?? 0) + 1;
    _persistAnalytics();
    notifyListeners();
  }

  void recordChatStart(String listingId) {
    _chatStarts[listingId] = (_chatStarts[listingId] ?? 0) + 1;
    _persistAnalytics();
    notifyListeners();
  }

  Future<void> load() async {
    if (_loaded) return;
    _recentIds.addAll(await LocalPrefsService.instance.getStringList(_recentKey));
    final raw = await LocalPrefsService.instance.getJsonMap(_analyticsKey);
    if (raw != null) {
      _detailViews.addAll(_intMap(raw['detail_views']));
      _shareClicks.addAll(_intMap(raw['share_clicks']));
      _chatStarts.addAll(_intMap(raw['chat_starts']));
    }
    _loaded = true;
    notifyListeners();
  }

  int viewCount(String listingId) =>
      _detailViews[listingId] ?? _viewCounts[listingId] ?? 0;

  int shareCount(String listingId) => _shareClicks[listingId] ?? 0;

  int chatCount(String listingId) => _chatStarts[listingId] ?? 0;

  List<String> recentlyViewedIds({int limit = 12}) {
    return _recentIds.take(limit).toList();
  }

  List<ListingPublic> recentlyViewed(List<ListingPublic> pool, {int limit = 12}) {
    final byId = {for (final l in pool) l.id: l};
    return _recentIds
        .map((id) => byId[id])
        .whereType<ListingPublic>()
        .take(limit)
        .toList();
  }

  List<String> topGeoZones({int limit = 3}) {
    final entries = _zoneScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const [];
    return entries.take(limit).map((e) => e.key).toList();
  }

  bool listingInUserZones(ListingPublic listing, List<String> zones) {
    if (zones.isEmpty) return false;
    final slug = listing.geoZoneSlug ?? inferGeoZoneSlug(listing);
    if (slug != null && zones.contains(slug)) return true;
    return listingMatchesGeoZones(
      slugs: zones,
      district: listing.district,
      projectName: listing.projectName,
      title: listing.title,
    );
  }

  static int seedPopularity(String id) {
    var h = 0;
    for (final c in id.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return 1 + (h % 40);
  }

  void _pushRecent(String listingId) {
    _recentIds.remove(listingId);
    _recentIds.insert(0, listingId);
    if (_recentIds.length > maxRecent) {
      _recentIds.removeRange(maxRecent, _recentIds.length);
    }
    LocalPrefsService.instance.setStringList(_recentKey, _recentIds);
  }

  Future<void> _persistAnalytics() async {
    await LocalPrefsService.instance.setJsonMap(_analyticsKey, {
      'detail_views': _detailViews,
      'share_clicks': _shareClicks,
      'chat_starts': _chatStarts,
    });
  }

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  }
}

String? inferGeoZoneSlug(ListingPublic listing) {
  const order = [
    'thonglor',
    'asok',
    'sukhumvit',
    'bangna',
    'nonthaburi',
    'pathum-thani',
    'samut-prakan',
  ];
  for (final slug in order) {
    if (listingMatchesGeoZones(
      slugs: [slug],
      district: listing.district,
      projectName: listing.projectName,
      title: listing.title,
    )) {
      return slug;
    }
  }
  return 'bangkok-all';
}
