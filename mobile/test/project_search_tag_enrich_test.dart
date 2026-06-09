import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/data/bangkok_projects.dart';
import 'package:livingbkk/data/search_poi_catalog.dart';
import 'package:livingbkk/utils/project_search_tag_enrich.dart';

void main() {
  setUp(() {
    SearchPoiCatalog.seedForTests([
      const SearchPoiEntry(
        id: 'edu-srinakharinwirot',
        category: 'education',
        titleTh: 'ม.ศรีนครินทร',
        titleEn: 'SWU',
        lat: 13.7455,
        lng: 100.5652,
        matchRadiusKm: 2.0,
        geoZoneSlugs: ['thonglor'],
      ),
      const SearchPoiEntry(
        id: 'landmark-rca',
        category: 'landmark',
        titleTh: 'RCA',
        titleEn: 'RCA',
        lat: 13.7475,
        lng: 100.5795,
        matchRadiusKm: 1.5,
        geoZoneSlugs: ['thonglor'],
      ),
    ]);
  });

  test('ทรู ทองหล่อ — auto BTS + zone + name', () {
    final p = BangkokProjects.bootstrap.firstWhere((x) => x.slug == 'true-thonglor');
    final r = ProjectSearchTagEnrich.enrich(
      lat: p.lat,
      lng: p.lng,
      nameTh: p.nameTh,
      nameEn: p.nameEn,
      slug: p.slug,
      district: p.district,
      existingBts: p.bts,
      existingAliases: p.aliases,
    );

    expect(r.status, 'auto_ok');
    expect(r.searchTagSlugs, contains('thonglor'));
    expect(r.searchTagSlugs, contains('bts-thong-lo'));
    expect(r.nearbyTransitLabels.any((l) => l.contains('ทองหล่อ')), isTrue);
    expect(r.searchTagSlugs, isNot(contains('asok')));
  });

  test('marketing text far station — warning only, still auto_ok', () {
    final r = ProjectSearchTagEnrich.enrich(
      lat: 13.724627,
      lng: 100.577777,
      descriptionTh: 'ใกล้ MRT สุขุมวิท และ BTS เอกมัย',
    );
    expect(r.status, 'auto_ok');
    expect(r.meta['text_warnings'], isNotNull);
    expect(r.searchTagSlugs, contains('bts-thong-lo'));
  });

  test('invalid coords → missing_coords', () {
    final r = ProjectSearchTagEnrich.enrich(lat: 0, lng: 0);
    expect(r.status, 'missing_coords');
    expect(r.searchTagSlugs, isEmpty);
  });
}
