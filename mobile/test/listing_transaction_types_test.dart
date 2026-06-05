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

  test('createFormOrder ไม่มีเซ้ง/ขายดาวน์', () {
    expect(ListingTransactionTypes.createFormOrder, ['rent', 'sale', 'sale_installment']);
  });
}
