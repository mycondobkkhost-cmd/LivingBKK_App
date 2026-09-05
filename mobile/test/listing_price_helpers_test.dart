import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/listing_public.dart';
import 'package:livingbkk/models/listing_transaction_types.dart';
import 'package:livingbkk/utils/listing_price_helpers.dart';

ListingPublic _listing({
  required String type,
  required double priceNet,
  double? priceSaleNet,
  double? promoPriceNet,
  double? promoSalePriceNet,
}) {
  return ListingPublic(
    id: 'id-$type',
    listingCode: 'RXT-TEST',
    listingType: type,
    title: 'Test',
    priceNet: priceNet,
    priceSaleNet: priceSaleNet,
    promoPriceNet: promoPriceNet,
    promoSalePriceNet: promoSalePriceNet,
  );
}

void main() {
  test('โปรเช่าใช้ราคาโปรเมื่อต่ำกว่าราคาเต็ม', () {
    final l = _listing(
      type: ListingTransactionTypes.rent,
      priceNet: 30000,
      promoPriceNet: 25000,
    );
    expect(
      ListingPriceHelpers.effectivePrice(
        l,
        browseFilter: ListingTransactionTypes.rent,
      ),
      25000,
    );
    expect(
      ListingPriceHelpers.strikethroughAmount(l, rentSide: true),
      30000,
    );
  });

  test('ประกาศเช่า+ขายใช้ราคาขายฝั่งแท็บซื้อ', () {
    final l = _listing(
      type: ListingTransactionTypes.rentAndSale,
      priceNet: 25000,
      priceSaleNet: 4500000,
      promoSalePriceNet: 4200000,
    );
    expect(
      ListingPriceHelpers.effectivePrice(
        l,
        browseFilter: ListingTransactionTypes.sale,
      ),
      4200000,
    );
    expect(
      ListingPriceHelpers.effectivePrice(
        l,
        browseFilter: ListingTransactionTypes.rent,
      ),
      25000,
    );
  });
}
