import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/listing_public.dart';

void main() {
  test('อ่านรายละเอียดประกาศจาก description_public ของ Supabase view', () {
    final listing = ListingPublic.fromJson({
      'id': 'listing-1',
      'listing_code': 'PPTR-0001',
      'listing_type': 'rent',
      'title': 'คอนโดใกล้รถไฟฟ้า',
      'price_net': 18000,
      'property_type': 'condo',
      'description_public': 'รายละเอียดจากฐานข้อมูล',
    });

    expect(listing.description, 'รายละเอียดจากฐานข้อมูล');
  });
}
