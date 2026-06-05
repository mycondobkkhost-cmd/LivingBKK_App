/// ประเภทประกาศที่รองรับ — ไม่มี เซ้ง / ขายดาวน์
abstract final class ListingTransactionTypes {
  static const rent = 'rent';
  static const sale = 'sale';

  /// ขายฝาก
  static const saleInstallment = 'sale_installment';

  /// ใช้ในฟอร์มลงประกาศ (ลำดับแสดง)
  static const createFormOrder = [rent, sale, saleInstallment];

  static bool isRent(String? type) => type == rent;

  static bool isSaleFamily(String? type) =>
      type == sale || type == saleInstallment;

  static bool isSupported(String? type) =>
      type != null && createFormOrder.contains(type);

  /// แท็บ「ซื้อ」บนหน้าแรก = ขาย + ขายฝาก
  static bool matchesBrowseFilter(String? filterType, String listingType) {
    if (filterType == null) return true;
    if (filterType == sale) return isSaleFamily(listingType);
    return filterType == listingType;
  }
}
