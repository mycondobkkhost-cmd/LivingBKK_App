/// ประเภทประกาศที่รองรับ — ไม่มี เซ้ง / ขายดาวน์
abstract final class ListingTransactionTypes {
  static const rent = 'rent';
  static const sale = 'sale';

  /// ขายฝาก
  static const saleInstallment = 'sale_installment';

  /// เช่า + ขายในประกาศเดียว — ปรากฏทั้งแท็บเช่าและซื้อ
  static const rentAndSale = 'rent_and_sale';

  /// ใช้ในฟอร์มลงประกาศ (ลำดับแสดง)
  static const createFormOrder = [rent, sale, saleInstallment, rentAndSale];

  static bool isRent(String? type) => type == rent;

  static bool isRentAndSale(String? type) => type == rentAndSale;

  static bool isSaleFamily(String? type) =>
      type == sale || type == saleInstallment;

  static bool hasSaleComponent(String? type) =>
      isSaleFamily(type) || isRentAndSale(type);

  static bool hasRentComponent(String? type) =>
      isRent(type) || isRentAndSale(type);

  static bool isSupported(String? type) =>
      type != null && createFormOrder.contains(type);

  /// แท็บ「ซื้อ」บนหน้าแรก = ขาย + ขายฝาก + เช่า+ขาย
  static bool matchesBrowseFilter(String? filterType, String listingType) {
    if (filterType == null) return true;
    if (filterType == sale) {
      return isSaleFamily(listingType) || isRentAndSale(listingType);
    }
    if (filterType == rent) {
      return isRent(listingType) || isRentAndSale(listingType);
    }
    return filterType == listingType;
  }
}
