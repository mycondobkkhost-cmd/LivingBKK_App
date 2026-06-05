import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/listing_create_rules.dart';

void main() {
  group('requiresLocationLink', () {
    test('โครงการในระบบ — ไม่บังคับ', () {
      expect(
        ListingCreateRules.requiresLocationLink(
          scope: ListingLocationScope.catalogProject,
          propertyTypeDb: 'house',
        ),
        isFalse,
      );
    });

    test('คอนโดกรอกเอง — ไม่บังคับ', () {
      expect(
        ListingCreateRules.requiresLocationLink(
          scope: ListingLocationScope.customProject,
          propertyTypeDb: 'condo',
        ),
        isFalse,
      );
    });

    test('บ้านนอกโครงการ — บังคับ', () {
      expect(
        ListingCreateRules.requiresLocationLink(
          scope: ListingLocationScope.standalone,
          propertyTypeDb: 'house',
        ),
        isTrue,
      );
    });
  });

  group('isValidLocationUrl', () {
    test('รับ https Google Maps', () {
      expect(
        ListingCreateRules.isValidLocationUrl(
          'https://maps.google.com/?q=13.7,100.5',
        ),
        isTrue,
      );
    });

    test('ปฏิเสธว่าง', () {
      expect(ListingCreateRules.isValidLocationUrl(''), isFalse);
    });
  });
}
