import 'package:flutter/foundation.dart';

import '../services/local_prefs_service.dart';

/// My Note — โน้ตส่วนตัวต่อประกาศ (เจ้าของ/เอเจนท์)
class ListingNotesService extends ChangeNotifier {
  ListingNotesService._();
  static final instance = ListingNotesService._();

  static const _key = 'listing_owner_notes_v1';

  final _notes = <String, String>{};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await LocalPrefsService.instance.getJsonMap(_key);
    _notes
      ..clear()
      ..addAll(raw?.map((k, v) => MapEntry(k, v.toString())) ?? {});
    _loaded = true;
    notifyListeners();
  }

  String? noteFor(String listingId) => _notes[listingId];

  Future<void> setNote(String listingId, String note) async {
    await load();
    if (note.trim().isEmpty) {
      _notes.remove(listingId);
    } else {
      _notes[listingId] = note.trim();
    }
    await LocalPrefsService.instance.setJsonMap(_key, _notes);
    notifyListeners();
  }
}
