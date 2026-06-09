import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/listing_transaction_types.dart';

void main() {
  test('แท็บซื้อรวม sale และ sale_installment', () {
    expect(ListingTransactionTypes.matchesBrowseFilter('sale', 'sale'), isTrue);
    expect(
      ListingTransactionTypes.matchesBrowseFilter('sale', 'sale_installment'),
      isTrue,
    );
    expect(ListingTransactionTypes.matchesBrowseFilter('sale', 'rent'), isFalse);
  });

  test('แท็บเช่าและซื้อรวม rent_and_sale', () {
    expect(
      ListingTransactionTypes.matchesBrowseFilter('rent', 'rent_and_sale'),
      isTrue,
    );
    expect(
      ListingTransactionTypes.matchesBrowseFilter('sale', 'rent_and_sale'),
      isTrue,
    );
  });

  test('createFormOrder มีเช่า+ขาย', () {
    expect(
      ListingTransactionTypes.createFormOrder,
      ['rent', 'sale', 'sale_installment', 'rent_and_sale'],
    );
  });
}
