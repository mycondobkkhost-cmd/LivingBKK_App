import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/utils/transit_proximity.dart';

void main() {
  test('hyde sukhumvit finds multiple nearby stations', () {
    final labels = TransitProximity.mergeLabels(
      lat: 13.740274,
      lng: 100.557423,
      htmlOrDesc: 'สถานีนานา และสถานีอโศก และ MRT สุขุมวิท',
    );
    expect(labels, isNotEmpty);
    expect(labels.any((l) => l.contains('นานา')), isTrue);
    expect(labels.any((l) => l.contains('อโศก')), isTrue);
    expect(labels.any((l) => l.contains('สุขุมวิท')), isTrue);
  });
}
