import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/search_filters.dart';
import 'package:livingbkk/utils/geo_distance.dart';
import 'package:livingbkk/utils/search_filter_match.dart';

void main() {
  group('matchesPinRadiusFilter', () {
    const pinLat = 13.7305;
    const pinLng = 100.5693;

    test('inactive when no pin set', () {
      const filters = SearchFilters();
      expect(
        matchesPinRadiusFilter(filters, lat: pinLat, lng: pinLng),
        isTrue,
      );
    });

    test('includes listing within radius', () {
      const filters = SearchFilters(
        pinLatitude: pinLat,
        pinLongitude: pinLng,
        radiusKm: 3,
      );
      // ~0.5 km north of Phrom Phong
      expect(
        matchesPinRadiusFilter(filters, lat: 13.735, lng: pinLng),
        isTrue,
      );
    });

    test('excludes listing outside radius', () {
      const filters = SearchFilters(
        pinLatitude: pinLat,
        pinLongitude: pinLng,
        radiusKm: 1,
      );
      // Mo Chit ~8+ km away
      expect(
        matchesPinRadiusFilter(filters, lat: 13.8027, lng: 100.5540),
        isFalse,
      );
    });

    test('excludes listing without coordinates', () {
      const filters = SearchFilters(
        pinLatitude: pinLat,
        pinLongitude: pinLng,
        radiusKm: 5,
      );
      expect(matchesPinRadiusFilter(filters), isFalse);
    });
  });

  test('haversine zero distance for same point', () {
    expect(haversineKm(13.73, 100.56, 13.73, 100.56), closeTo(0, 0.001));
  });
}
