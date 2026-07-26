import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/utils/google_maps_share_url.dart';

void main() {
  group('GoogleMapsShareUrl.parseCoords', () {
    test('q=lat,lng', () {
      final hit = GoogleMapsShareUrl.parseCoords(
        'https://maps.google.com/?q=13.756330,100.501765',
      );
      expect(hit, isNotNull);
      expect(hit!.lat, closeTo(13.756330, 0.0001));
      expect(hit.lng, closeTo(100.501765, 0.0001));
    });

    test('@lat,lng', () {
      final hit = GoogleMapsShareUrl.parseCoords(
        'https://www.google.com/maps/@13.736717,100.523186,17z',
      );
      expect(hit, isNotNull);
      expect(hit!.lat, closeTo(13.736717, 0.0001));
      expect(hit.lng, closeTo(100.523186, 0.0001));
    });

    test('!3d !4d แม่นกว่า @', () {
      final hit = GoogleMapsShareUrl.parseCoords(
        'https://www.google.com/maps/place/Test/@13.70,100.50,17z/data=!3m1!4b1!4m6!3m5!1s0x0!8m2!3d13.736717!4d100.523186',
      );
      expect(hit, isNotNull);
      expect(hit!.lat, closeTo(13.736717, 0.0001));
      expect(hit.lng, closeTo(100.523186, 0.0001));
    });

    test('ดึงชื่อจาก /place/', () {
      final hit = GoogleMapsShareUrl.parseCoords(
        'https://www.google.com/maps/place/Indy+5+Bangna+Km.7/@13.70,100.50,17z/data=!3m1!4b1!4m6!3m5!1s0x0!8m2!3d13.736717!4d100.523186',
      );
      expect(hit, isNotNull);
      expect(hit!.placeName, 'Indy 5 Bangna Km.7');
    });

    test('ดึงชื่อไทยจาก /place/', () {
      final hit = GoogleMapsShareUrl.parseCoords(
        'https://www.google.com/maps/place/%E0%B8%AD%E0%B8%B4%E0%B8%99%E0%B8%94%E0%B8%B5%E0%B9%89+5+%E0%B8%9A%E0%B8%B2%E0%B8%87%E0%B8%99%E0%B8%B2/@13.70,100.50,17z/data=!3m1!4b1!4m6!3m5!1s0x0!8m2!3d13.736717!4d100.523186',
      );
      expect(hit, isNotNull);
      expect(hit!.placeName, contains('อินดี้'));
    });

    test('ปฏิเสธลิงก์ที่ไม่มีพิกัด', () {
      expect(
        GoogleMapsShareUrl.parseCoords(
          'https://www.google.com/maps/place/Some+Building',
        ),
        isNull,
      );
    });

    test('looksLikeMapsUrl', () {
      expect(
        GoogleMapsShareUrl.looksLikeMapsUrl(
          'https://maps.app.goo.gl/abc123',
        ),
        isTrue,
      );
      expect(
        GoogleMapsShareUrl.looksLikeMapsUrl('https://livinginsider.com/x'),
        isFalse,
      );
    });
  });
}
