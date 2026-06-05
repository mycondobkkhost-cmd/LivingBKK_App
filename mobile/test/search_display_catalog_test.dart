import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/search_suggestion.dart';
import 'package:livingbkk/services/search_display_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('suggest thru uses bilingual title format', () async {
    final cat = SearchDisplayCatalog.instance;
    await cat.load();
    if (!cat.isLoaded) return;

    final hits = cat.suggest('ทรู');
    final thru = hits.where((s) => s.title.contains('ทรู ทองหล่อ')).toList();
    expect(thru, isNotEmpty);
    expect(thru.first.title, contains('('));
    expect(thru.first.title, contains('THRU'));
  });

  test('suggest life excludes unrelated locations', () async {
    final cat = SearchDisplayCatalog.instance;
    await cat.load();
    if (!cat.isLoaded) return;

    final hits = cat.suggest('life');
    expect(hits, isNotEmpty);
    expect(hits.any((s) => s.title.toLowerCase().contains('life')), isTrue);
    expect(hits.any((s) => s.title == 'Bangkok'), isFalse);
    expect(hits.any((s) => s.title == 'Bang Na'), isFalse);
  });

  test('suggest ห returns huai khwang entries when index loaded', () async {
    final cat = SearchDisplayCatalog.instance;
    await cat.load();
    if (!cat.isLoaded) {
      // asset อาจไม่มีใน test env — ข้าม
      return;
    }
    final hits = cat.suggest('ห');
    expect(hits, isNotEmpty);
    expect(
      hits.any(
        (s) =>
            s.kind == SearchSuggestionKind.location &&
            s.title.contains('ห้วยขวาง'),
      ),
      isTrue,
    );
  });
}
