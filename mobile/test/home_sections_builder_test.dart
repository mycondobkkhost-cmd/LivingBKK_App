import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/listing_public.dart';
import 'package:livingbkk/models/listing_transaction_types.dart';
import 'package:livingbkk/models/search_filters.dart';
import 'package:livingbkk/services/home_sections_builder.dart';

ListingPublic _item({
  required String id,
  required String type,
  double price = 25000,
  double? sale,
}) {
  return ListingPublic(
    id: id,
    listingCode: 'T-$id',
    listingType: type,
    title: id,
    priceNet: price,
    priceSaleNet: sale,
  );
}

void main() {
  final builder = HomeSectionsBuilder();
  final dual = _item(
    id: 'dual',
    type: ListingTransactionTypes.rentAndSale,
    price: 25000,
    sale: 5200000,
  );
  final rentOnly = _item(id: 'rent', type: ListingTransactionTypes.rent);
  final saleOnly = _item(
    id: 'sale',
    type: ListingTransactionTypes.sale,
    price: 4800000,
  );

  List<String> _idsInLatest(List<HomeFeedSection> sections) {
    final latest = sections.firstWhere((s) => s.id == 'latest');
    return latest.items.map((e) => e.id).toList();
  }

  test('แท็บเช่าโชว์ประกาศเช่า+ขายในฟีดหน้าแรก', () {
    final sections = builder.build(
      all: [dual, rentOnly, saleOnly],
      sessionFilters: const SearchFilters(listingType: ListingTransactionTypes.rent),
      isAgent: false,
    );
    final ids = _idsInLatest(sections);
    expect(ids, containsAll(['dual', 'rent']));
    expect(ids, isNot(contains('sale')));
  });

  test('แท็บซื้อโชว์ประกาศเช่า+ขาย ไม่โชว์เช่าอย่างเดียว', () {
    final sections = builder.build(
      all: [dual, rentOnly, saleOnly],
      sessionFilters: const SearchFilters(listingType: ListingTransactionTypes.sale),
      isAgent: false,
    );
    final ids = _idsInLatest(sections);
    expect(ids, containsAll(['dual', 'sale']));
    expect(ids, isNot(contains('rent')));
  });
}
