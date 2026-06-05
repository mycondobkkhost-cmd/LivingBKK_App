/// ตัวเลือกสัญญาฝาก Exclusive — เจ้าของเท่านั้น
abstract final class ListingExclusiveOptions {
  static const ownerRentContractDays = [30, 60, 90];

  /// ขาย / ขายฝาก — วัน (90 = 3 เดือน, 180 = 6, 365 = 12)
  static const ownerSaleContractDays = [90, 180, 365];

  static List<int> contractDaysFor(String listingType) =>
      isSaleType(listingType) ? ownerSaleContractDays : ownerRentContractDays;

  static int defaultContractDays(String listingType) {
    if (listingType == 'rent') return 30;
    return 90;
  }

  static bool isSaleType(String listingType) =>
      listingType == 'sale' || listingType == 'sale_installment';

  static String contractLabel(int days, bool isEnglish, {required bool isSale}) {
    if (isSale) {
      switch (days) {
        case 90:
          return isEnglish ? '3 months' : '3 เดือน';
        case 180:
          return isEnglish ? '6 months' : '6 เดือน';
        case 365:
          return isEnglish ? '12 months' : '12 เดือน';
        default:
          break;
      }
    }
    if (isEnglish) return '$days days';
    return '$days วัน';
  }
}
