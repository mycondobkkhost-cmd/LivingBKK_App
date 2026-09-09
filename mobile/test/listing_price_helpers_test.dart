import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/listing_public.dart';
import 'package:livingbkk/models/listing_transaction_types.dart';
import 'package:livingbkk/utils/listing_price_helpers.dart';

ListingPublic _dual() => const ListingPublic(
      id: 'dual-1',
      listingCode: 'T-DUAL',
      listingType: ListingTransactionTypes.rentAndSale,
      title: 'เช่า+ขาย',
      priceNet: 25000,
      priceSaleNet: 5200000,
    );

void main() {
  test('แท็บเช่าใช้ราคาเช่าของประกาศเช่า+ขาย', () {
    expect(
      ListingPriceHelpers.effectivePrice(
        _dual(),
        browseFilter: ListingTransactionTypes.rent,
      ),
      25000,
    );
  });

  test('แท็บซื้อใช้ราคาขายของประกาศเช่า+ขาย ไม่ใช้ราคาเช่า', () {
    expect(
      ListingPriceHelpers.effectivePrice(
        _dual(),
        browseFilter: ListingTransactionTypes.sale,
      ),
      5200000,
    );
  });

  test('งบซื้อ 2–5 ล้านต้องไม่ตัดประกาศเช่า+ขายที่ขาย 5.2 ล้านเพราะราคาเช่า 2.5 หมื่น', () {
    final p = ListingPriceHelpers.effectivePrice(
      _dual(),
      browseFilter: ListingTransactionTypes.sale,
    );
    expect(p >= 2000000, isTrue);
    expect(p <= 8000000, isTrue);
    expect(p < 2000000, isFalse);
  });
}
