import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/services/participant_360_search_service.dart';

void main() {
  test('RXT listing code is recognized', () async {
    final hits = await Participant360SearchService.instance.search(
      'RXT-2026-004522',
    );
    expect(
      hits.any((h) => h.kind == Participant360HitKind.listing),
      isTrue,
    );
  });
}
