import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/data/bangkok_projects.dart';
import 'package:livingbkk/services/project_catalog.dart';

void main() {
  test('search finds bootstrap project by Thai name', () {
    final hits = ProjectCatalog.instance.search('ทรู');
    expect(hits.any((p) => p.slug == 'true-thonglor'), isTrue);
  });

  test('search finds thru thonglor by full Thai name', () {
    final hits = ProjectCatalog.instance.search('ทรู ทองหล่อ');
    expect(hits.any((p) => p.slug == 'true-thonglor'), isTrue);
  });

  test('search finds project by English partial', () {
    final hits = ProjectCatalog.instance.search('life');
    expect(hits, isNotEmpty);
  });

  test('search returns empty for single character', () {
    expect(ProjectCatalog.instance.search('l'), isEmpty);
  });
}
