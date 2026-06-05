import 'package:flutter/foundation.dart';

import '../services/local_prefs_service.dart';

/// Preferred Stock — เอเจนท์เก็บทรัพย์ที่สนใจ (แทน iStock แบบจ่าย)
class PreferredStockService extends ChangeNotifier {
  PreferredStockService._();
  static final instance = PreferredStockService._();

  static const _key = 'preferred_stock_ids';
  static const _notesKey = 'preferred_stock_notes';

  final _ids = <String>[];
  final _notes = <String, String>{};
  bool _loaded = false;

  List<String> get ids => List.unmodifiable(_ids);

  Future<void> load() async {
    if (_loaded) return;
    _ids
      ..clear()
      ..addAll(await LocalPrefsService.instance.getStringList(_key));
    final raw = await LocalPrefsService.instance.getJsonMap(_notesKey);
    _notes
      ..clear()
      ..addAll(raw?.map((k, v) => MapEntry(k, v.toString())) ?? {});
    _loaded = true;
    notifyListeners();
  }

  bool contains(String listingId) => _ids.contains(listingId);

  String? noteFor(String listingId) => _notes[listingId];

  Future<bool> toggle(String listingId) async {
    await load();
    if (_ids.contains(listingId)) {
      _ids.remove(listingId);
      _notes.remove(listingId);
    } else {
      _ids.insert(0, listingId);
    }
    await _persist();
    notifyListeners();
    return _ids.contains(listingId);
  }

  Future<void> setNote(String listingId, String note) async {
    await load();
    if (!_ids.contains(listingId)) return;
    if (note.trim().isEmpty) {
      _notes.remove(listingId);
    } else {
      _notes[listingId] = note.trim();
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await LocalPrefsService.instance.setStringList(_key, _ids);
    await LocalPrefsService.instance.setJsonMap(_notesKey, _notes);
  }
}
