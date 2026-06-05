import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/data/bangkok_projects.dart';
import 'package:livingbkk/utils/metro_region.dart';

void main() {
  test('bangkok project in metro bounds', () {
    final p = BangkokProjects.bootstrap.first;
    expect(MetroRegion.isMetroProject(p), isTrue);
  });

  test('chiang mai coords rejected', () {
    const p = BangkokProject(
      slug: 'test-cnx',
      nameTh: 'เทส เชียงใหม่',
      nameEn: 'Test Chiang Mai',
      district: 'เมืองเชียงใหม่',
      lat: 18.79,
      lng: 98.98,
    );
    expect(MetroRegion.isMetroProject(p), isFalse);
  });

  test('nonthaburi text accepted', () {
    const p = BangkokProject(
      slug: 'test-nt',
      nameTh: 'เทส นนทบุรี',
      nameEn: 'Test Nonthaburi',
      district: 'เมืองนนทบุรี',
      lat: 13.86,
      lng: 100.51,
    );
    expect(MetroRegion.isMetroProject(p), isTrue);
  });
}
