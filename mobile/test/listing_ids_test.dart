import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/utils/listing_ids.dart';

void main() {
  test('isListingUuid accepts valid v4 uuid', () {
    expect(
      isListingUuid('a1b2c3d4-e5f6-4789-a012-3456789abcde'),
      isTrue,
    );
  });

  test('isListingUuid rejects demo slug ids', () {
    expect(isListingUuid('demo-aspire-sukhumvit-48-0'), isFalse);
    expect(isListingUuid(null), isFalse);
    expect(isListingUuid(''), isFalse);
  });

  test('listingIdForBackend filters non-uuid', () {
    expect(
      listingIdForBackend('demo-aspire-sukhumvit-48-0'),
      isNull,
    );
    expect(
      listingIdForBackend('a1b2c3d4-e5f6-4789-a012-3456789abcde'),
      'a1b2c3d4-e5f6-4789-a012-3456789abcde',
    );
  });
}
