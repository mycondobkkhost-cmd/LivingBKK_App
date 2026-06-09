import '../models/listing_public.dart';
import '../models/listing_transaction_types.dart';

/// ราคาที่แสดงตามบริบทแท็บเช่า/ขาย — ประกาศเช่า+ขายใช้ price_net=เช่า, price_sale_net=ขาย
abstract final class ListingPriceHelpers {
  static bool isDual(String? listingType) =>
      ListingTransactionTypes.isRentAndSale(listingType);

  static double effectivePrice(
    ListingPublic listing, {
    String? browseFilter,
  }) {
    if (isDual(listing.listingType)) {
      final rentSide = browseFilter != ListingTransactionTypes.sale;
      return displayAmount(
        listing,
        browseFilter: browseFilter,
        rentSide: rentSide,
      );
    }
    final rentSide = ListingTransactionTypes.isRent(listing.listingType);
    return displayAmount(
      listing,
      browseFilter: browseFilter,
      rentSide: rentSide,
    );
  }

  static bool showPerMonth(
    ListingPublic listing, {
    String? browseFilter,
  }) {
    if (isDual(listing.listingType)) {
      return browseFilter != ListingTransactionTypes.sale;
    }
    return ListingTransactionTypes.isRent(listing.listingType);
  }

  static bool showDualPrices(ListingPublic listing) =>
      isDual(listing.listingType) &&
      listing.priceSaleNet != null &&
      listing.priceSaleNet! > 0;

  static double _saleFullPrice(ListingPublic listing) {
    if (isDual(listing.listingType)) {
      return listing.priceSaleNet ?? listing.priceNet;
    }
    return listing.priceNet;
  }

  /// ราคาแสดงบนการ์ด — ใช้โปรโมชั่นถ้ามีและต่ำกว่าราคาเต็ม
  static double displayAmount(
    ListingPublic listing, {
    String? browseFilter,
    required bool rentSide,
  }) {
    if (rentSide) {
      final promo = listing.promoPriceNet;
      if (promo != null && promo > 0 && promo < listing.priceNet) return promo;
      return listing.priceNet;
    }
    final full = _saleFullPrice(listing);
    final promo = listing.promoSalePriceNet;
    if (promo != null && promo > 0 && promo < full) return promo;
    return full;
  }

  static double? strikethroughAmount(
    ListingPublic listing, {
    String? browseFilter,
    required bool rentSide,
  }) {
    if (rentSide) {
      final promo = listing.promoPriceNet;
      if (promo != null && promo > 0 && promo < listing.priceNet) {
        return listing.priceNet;
      }
      return null;
    }
    final full = _saleFullPrice(listing);
    final promo = listing.promoSalePriceNet;
    if (promo != null && promo > 0 && promo < full) return full;
    return null;
  }
}
