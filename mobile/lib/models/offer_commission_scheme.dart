/// รูปแบบค่าคอมที่ผู้เสนอเลือกในฟอร์มเสนอทรัพย์ / ลงประกาศ
abstract final class OfferCommissionScheme {
  static const custom = 'custom';

  // ── เจ้าของทรัพย์ · ขาย ──
  static const ownerSale3Pct = 'sale_3pct';
  static const ownerSale4Pct = 'sale_4pct';
  static const ownerSale5Pct = 'sale_5pct';
  static const ownerSaleNetSelfAdd = 'sale_net_self_add';

  // ── เจ้าของทรัพย์ · เช่า ──
  static const ownerRent1MoPer1Yr = 'rent_1mo_per_1yr';

  // ── โคเอเจนซี่ · ขาย ──
  static const coSale1_5Pct = 'co_sale_1_5pct';
  static const coSale2Pct = 'co_sale_2pct';
  static const coSaleNetSelfAdd = 'co_sale_net_self_add';

  // ── โคเอเจนซี่ · เช่า ──
  static const coRentHalfMo1Yr = 'co_rent_half_mo_1yr';
  static const coRent70Pct = 'co_rent_70pct';
  static const coRent100Pct = 'co_rent_100pct';

  /// Legacy codes (ข้อเสนอเก่า)
  static const legacyRent1MoPer2Yr = 'rent_1mo_per_2yr';
  static const legacySale2Pct = 'sale_2pct';

  static bool isOwnerCapacity(String capacity) =>
      capacity == 'owner_direct_100';

  static bool isCoAgentCapacity(String capacity) =>
      capacity == 'co_agent_50_50';

  static List<String> optionsFor({
    required String transactionType,
    required String offererCapacity,
  }) {
    final isSale = transactionType == 'sale';
    if (isOwnerCapacity(offererCapacity)) {
      if (isSale) {
        return [
          ownerSale3Pct,
          ownerSale4Pct,
          ownerSale5Pct,
          ownerSaleNetSelfAdd,
          custom,
        ];
      }
      return [ownerRent1MoPer1Yr, custom];
    }
    if (isCoAgentCapacity(offererCapacity)) {
      if (isSale) {
        return [
          coSale1_5Pct,
          coSale2Pct,
          coSaleNetSelfAdd,
          custom,
        ];
      }
      return [
        coRentHalfMo1Yr,
        coRent70Pct,
        coRent100Pct,
        custom,
      ];
    }
    return const [];
  }

  static bool requiresNote(String scheme) => scheme == custom;

  /// ขาย / ขายฝาก — ใช้โครงสร้างคอมแบบขาย
  static bool isSaleListing(String? listingType) =>
      listingType == 'sale' || listingType == 'sale_installment';

  static bool isDualListing(String? listingType) =>
      listingType == 'rent_and_sale';

  static String transactionForListing(String listingType) {
    if (isDualListing(listingType)) return 'sale';
    return isSaleListing(listingType) ? 'sale' : listingType;
  }

  static String capacityForPoster({required bool isAgentPoster}) =>
      isAgentPoster ? 'co_agent_50_50' : 'owner_direct_100';

  static List<String> optionsForListing({
    required String listingType,
    required bool isAgentPoster,
  }) =>
      optionsFor(
        transactionType: transactionForListing(listingType),
        offererCapacity: capacityForPoster(isAgentPoster: isAgentPoster),
      );

  static bool isNetSelfAdd(String? scheme) =>
      scheme == ownerSaleNetSelfAdd || scheme == coSaleNetSelfAdd;

  /// เปอร์เซ็นต์จากราคาขาย (ถ้ามี)
  static double? salePercent(String? scheme) {
    switch (scheme) {
      case ownerSale3Pct:
        return 3;
      case ownerSale4Pct:
        return 4;
      case ownerSale5Pct:
        return 5;
      case coSale1_5Pct:
        return 1.5;
      case coSale2Pct:
        return 2;
      case legacySale2Pct:
        return 2;
      default:
        return null;
    }
  }

  /// ค่าคอมเช่าโดยประมาณจากค่าเช่ารายเดือน (บาท)
  static double? rentCommissionEstimate({
    required String? scheme,
    required double monthlyRent,
    int leaseMonths = 12,
  }) {
    switch (scheme) {
      case ownerRent1MoPer1Yr:
      case legacyRent1MoPer2Yr:
        return monthlyRent * leaseMonths / 12;
      case coRentHalfMo1Yr:
        return monthlyRent * leaseMonths / 24;
      case coRent70Pct:
        return monthlyRent * 0.7;
      case coRent100Pct:
        return monthlyRent;
      default:
        return null;
    }
  }
}
