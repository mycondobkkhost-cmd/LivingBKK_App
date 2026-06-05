import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/listing_public.dart';
import 'package:livingbkk/utils/listing_browse_sorter.dart';

ListingPublic _listing(String id, {String code = 'A', double price = 10000}) {
  return ListingPublic(
    id: id,
    listingCode: code,
    listingType: 'rent',
    title: 'Unit $id',
    priceNet: price,
  );
}

void main() {
  test('browseOrder puts 4 recommended first then rest by code', () {
    final items = [
      _listing('1', code: 'RENT-001'),
      _listing('2', code: 'RENT-002'),
      _listing('3', code: 'RENT-003'),
      _listing('4', code: 'RENT-004'),
      _listing('5', code: 'RENT-999'),
      _listing('6', code: 'RENT-998'),
    ];
    final ordered = ListingBrowseSorter.browseOrder(items);
    expect(ordered.length, 6);
    expect(ordered.take(4).map((e) => e.id).toSet().length, 4);
    expect(ordered.skip(4).every((e) => !ordered.take(4).contains(e)), isTrue);
  });
}
