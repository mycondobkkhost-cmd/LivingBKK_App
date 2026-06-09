import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/data/bangkok_projects.dart';
import 'package:livingbkk/utils/nearby_projects.dart';

void main() {
  test('nearbyProjects sorts by distance and excludes origin', () {
    final origin = BangkokProjects.bySlug('true-thonglor')!;
    final hits = nearbyProjects(
      origin: origin,
      candidates: BangkokProjects.bootstrap,
      limit: 5,
      maxKm: 5,
    );

    expect(hits, isNotEmpty);
    expect(hits.every((h) => h.project.slug != origin.slug), isTrue);
    for (var i = 1; i < hits.length; i++) {
      expect(
        hits[i].distanceKm >= hits[i - 1].distanceKm,
        isTrue,
        reason: 'should be sorted ascending by km',
      );
    }
  });
}
