import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/utils/rental_pii_guard.dart';

void main() {
  test('wouldBlock detects Thai phone', () {
    expect(RentalPiiGuard.wouldBlock('โทร 081-234-5678'), isTrue);
    expect(RentalPiiGuard.wouldBlock('นัดดูห้องพรุ่งนี้'), isFalse);
  });

  test('wouldBlock detects Line id', () {
    expect(RentalPiiGuard.wouldBlock('Line id: @myline123'), isTrue);
  });

  test('wouldBlock detects external url', () {
    expect(RentalPiiGuard.wouldBlock('ดูรูป https://example.com/x'), isTrue);
  });
}
