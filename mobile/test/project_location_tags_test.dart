import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/data/bangkok_projects.dart';
import 'package:livingbkk/utils/project_location_tags.dart';

void main() {
  test('hyde sukhumvit — auto transit only, zones as suggestions', () {
    final d = ProjectLocationTags.detect(
      lat: 13.740274,
      lng: 100.557423,
      district: 'วัฒนา',
      htmlOrDesc: 'สถานีนานา และสถานีอโศก และ MRT สุขุมวิท',
    );
    final auto = d.autoSelected.map((t) => t.label).toList();
    final suggest = d.suggestions.map((t) => t.label).toList();

    expect(auto.any((l) => l.contains('นานา')), isTrue);
    expect(auto.any((l) => l.contains('อโศก')), isTrue);
    expect(auto, isNot(contains('BTS อารีย์')));
    expect(suggest.any((l) => l.contains('สุขุมวิทตอนต้น') || l.contains('อโศก')), isTrue);
    expect(suggest.any((l) => l.contains('วัฒนา')), isTrue);
  });

  group('POV sample projects', () {
    final samples = [
      BangkokProjects.bootstrap.firstWhere((p) => p.slug == 'hyde-sukhumvit-11'),
      BangkokProjects.bootstrap.firstWhere((p) => p.slug == 'ashton-asoke'),
      BangkokProjects.bootstrap.firstWhere((p) => p.slug == 'true-thonglor'),
      BangkokProjects.bootstrap.firstWhere((p) => p.slug == 'm-neighborhood-ari'),
      BangkokProjects.bootstrap.firstWhere((p) => p.slug == 'u-delight-bangna'),
      BangkokProjects.bootstrap.firstWhere((p) => p.slug == 'lumpini-place-rama9'),
    ];

    for (final p in samples) {
      test('${p.nameTh} (${p.district})', () {
        final d = ProjectLocationTags.detect(
          lat: p.lat,
          lng: p.lng,
          district: p.district,
          existingBts: p.bts,
        );
        // ignore: avoid_print
        print('\n=== ${p.nameTh} ===');
        // ignore: avoid_print
        print('AUTO: ${d.autoSelected.map((t) => t.label).join(' | ')}');
        // ignore: avoid_print
        print('SUGGEST: ${d.suggestions.map((t) => t.label).join(' | ')}');
        expect(d.autoSelected, isNotEmpty);
      });
    }
  });
}
