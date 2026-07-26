import 'demand_post.dart';
import 'listing_public.dart';

/// โหมดหน้าเสนอทรัพย์
enum SubmitOfferMode {
  /// แท็บแมทช์ทรัพย์ — เฉพาะรายการที่จับคู่ · ติ๊กส่ง
  stockPick,

  /// แท็บบอร์ด — เลือกจากของฉัน หรือกรอกใหม่
  boardFlexible,

  /// กรอกข้อมูลใหม่เท่านั้น
  manualOnly,
}

/// อาร์กิวเมนต์เปิดหน้าเสนอทรัพย์
class SubmitOfferRouteArgs {
  const SubmitOfferRouteArgs({
    required this.post,
    this.mode = SubmitOfferMode.manualOnly,
    this.matchedListings = const [],
    this.stockListings = const [],
  });

  final DemandPost post;
  final SubmitOfferMode mode;

  /// รายการจับคู่ (แท็บแมทช์ทรัพย์)
  final List<ListingPublic> matchedListings;

  /// ทรัพย์ใน「ของฉัน」ทั้งหมด (แท็บบอร์ด · เลือกจากมือ)
  final List<ListingPublic> stockListings;

  List<ListingPublic> get pickerListings {
    switch (mode) {
      case SubmitOfferMode.stockPick:
        return matchedListings;
      case SubmitOfferMode.boardFlexible:
        return stockListings;
      case SubmitOfferMode.manualOnly:
        return const [];
    }
  }
}
