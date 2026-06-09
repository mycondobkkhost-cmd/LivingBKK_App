import '../models/listing_public.dart';

/// เรียงทรัพย์สำหรับหน้ารายการ — Exclusive อัปเดตล่าสุด 4 อันดับแรก แล้วที่เหลือตามอัปเดตล่าสุด
class ListingBrowseSorter {
  static int _byRecentUpdate(ListingPublic a, ListingPublic b) =>
      b.effectiveUpdatedAt.compareTo(a.effectiveUpdatedAt);

  static List<ListingPublic> byRecentUpdate(List<ListingPublic> items) {
    final copy = List<ListingPublic>.from(items);
    copy.sort(_byRecentUpdate);
    return copy;
  }

  /// Exclusive ที่อัปเดตล่าสุด (ตรงชุดที่กรองแล้ว) 4 อันดับ → ที่เหลือเรียงอัปเดตล่าสุด
  static List<ListingPublic> browseOrder(List<ListingPublic> items) {
    if (items.isEmpty) return items;

    final exclusive = items.where((l) => l.isFeedExclusive).toList()
      ..sort(_byRecentUpdate);
    final top = exclusive.take(4).toList();
    final topIds = top.map((e) => e.id).toSet();

    final rest = items.where((l) => !topIds.contains(l.id)).toList()
      ..sort(_byRecentUpdate);

    return [...top, ...rest];
  }
}
