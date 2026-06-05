import '../models/listing_public.dart';
import '../services/listing_activity_service.dart';
import '../services/platform_settings_service.dart';

/// เรียงทรัพย์สำหรับหน้ารายการ — แนะนำ 4 อันดับแรก แล้วตามด้วยอัปเดตล่าสุด
class ListingBrowseSorter {
  static double score(ListingPublic l, List<String> zones) {
    final activity = ListingActivityService.instance;
    final cfg = PlatformSettingsService.instance.exclusive;
    var s = ListingActivityService.seedPopularity(l.id).toDouble();
    s += activity.viewCount(l.id) * 5;
    if (zones.isNotEmpty && activity.listingInUserZones(l, zones)) {
      s += 25;
    }
    if (l.ownerExclusiveMandate) s += cfg.ownerFeedBoost.toDouble();
    if (l.agentExclusive) s += cfg.agentFeedBoost.toDouble();
    final bumped = l.lastBumpAt ?? l.effectiveUpdatedAt;
    final hours = DateTime.now().difference(bumped).inHours;
    if (hours < 12) s += 20;
    else if (hours < 48) s += 10;
    return s;
  }

  static List<ListingPublic> ranked(List<ListingPublic> items) {
    final zones = ListingActivityService.instance.topGeoZones();
    final copy = List<ListingPublic>.from(items);
    copy.sort((a, b) => score(b, zones).compareTo(score(a, zones)));
    return copy;
  }

  static List<ListingPublic> byRecentCode(List<ListingPublic> items) {
    final copy = List<ListingPublic>.from(items);
    copy.sort((a, b) => b.listingCode.compareTo(a.listingCode));
    return copy;
  }

  /// 4 แนะนำ + ที่เหลือเรียงตาม listing code (proxy อัปเดตล่าสุด)
  static List<ListingPublic> browseOrder(List<ListingPublic> items) {
    if (items.length <= 4) return ranked(items);
    final rankedAll = ranked(items);
    final top = rankedAll.take(4).toList();
    final topIds = top.map((e) => e.id).toSet();
    final rest = byRecentCode(items.where((l) => !topIds.contains(l.id)).toList());
    return [...top, ...rest];
  }
}
