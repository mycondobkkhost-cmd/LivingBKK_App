import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/listing_public.dart';
import 'package:livingbkk/utils/listing_price_helpers.dart';
import 'package:livingbkk/utils/localized_content.dart';
import 'package:livingbkk/widgets/design_system/app_map_marker.dart';

ListingPublic _dual() => const ListingPublic(
      id: 'dual-1',
      listingCode: 'RXT-1',
      listingType: 'rent_and_sale',
      title: 'Dual unit',
      priceNet: 25000,
      priceSaleNet: 4500000,
      bedrooms: 1,
    );

void main() {
  test('ประกาศเช่า+ขายบนแท็บเช่าใช้ราคาเช่าต่อเดือน', () {
    final l = _dual();
    expect(
      ListingPriceHelpers.effectivePrice(l, browseFilter: 'rent'),
      25000,
    );
    expect(
      ListingPriceHelpers.showPerMonth(l, browseFilter: 'rent'),
      isTrue,
    );
    expect(
      formatMapMarkerPrice(25000, isRent: true, isEnglish: false),
      '฿25k/ด',
    );
  });

  test('ประกาศเช่า+ขายบนแท็บซื้อใช้ราคาขาย ไม่ติด /เดือน', () {
    final l = _dual();
    expect(
      ListingPriceHelpers.effectivePrice(l, browseFilter: 'sale'),
      4500000,
    );
    expect(
      ListingPriceHelpers.showPerMonth(l, browseFilter: 'sale'),
      isFalse,
    );
    expect(
      formatMapMarkerPrice(4500000, isRent: false, isEnglish: false),
      '฿4.5M',
    );
  });

  test('การ์ด compact ไม่ติดป้ายขายอย่างเดียวเมื่อเป็นเช่า+ขาย', () {
    expect(_dual().localizedCompactCardHeading(false), 'เช่า+ขาย 1 นอน');
    expect(_dual().localizedCompactCardHeading(true), 'Rent & sale · 1 bed');
  });
}
