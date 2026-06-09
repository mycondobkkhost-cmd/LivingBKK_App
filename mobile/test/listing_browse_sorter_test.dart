import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/listing_public.dart';
import 'package:livingbkk/utils/listing_browse_sorter.dart';

ListingPublic _listing(
  String id, {
  bool exclusive = false,
  DateTime? updatedAt,
}) {
  return ListingPublic(
    id: id,
    listingCode: 'RENT-$id',
    listingType: 'rent',
    title: 'Unit $id',
    priceNet: 10000,
    updatedAt: updatedAt,
    ownerExclusiveMandate: exclusive,
  );
}

void main() {
  test('browseOrder puts 4 newest exclusive first then rest by update', () {
    final now = DateTime(2026, 6, 8, 12);
    final items = [
      _listing('plain-old', updatedAt: now.subtract(const Duration(days: 10))),
      _listing('ex-1', exclusive: true, updatedAt: now.subtract(const Duration(hours: 1))),
      _listing('ex-2', exclusive: true, updatedAt: now.subtract(const Duration(hours: 2))),
      _listing('ex-3', exclusive: true, updatedAt: now.subtract(const Duration(hours: 3))),
      _listing('ex-4', exclusive: true, updatedAt: now.subtract(const Duration(hours: 4))),
      _listing('ex-5', exclusive: true, updatedAt: now.subtract(const Duration(hours: 5))),
      _listing('plain-new', updatedAt: now.subtract(const Duration(minutes: 30))),
    ];

    final ordered = ListingBrowseSorter.browseOrder(items);

    expect(ordered.take(4).map((e) => e.id).toList(),
        ['ex-1', 'ex-2', 'ex-3', 'ex-4']);
    expect(ordered.skip(4).map((e) => e.id).toList(),
        ['plain-new', 'ex-5', 'plain-old']);
  });
}
