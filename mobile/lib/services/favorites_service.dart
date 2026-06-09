import 'package:flutter/foundation.dart';

import 'local_prefs_service.dart';

/// รายการโปรด (persist ในเครื่อง) — เก็บลำดับเวลาที่บันทึก
class FavoritesService extends ChangeNotifier {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const _key = 'favorite_listing_ids';

  final _orderedIds = <String>[];
  bool _loaded = false;

  bool isFavorite(String listingId) => _orderedIds.contains(listingId);

  Set<String> get ids => _orderedIds.toSet();

  /// ลำดับบันทึก — รายการแรกคือบันทึกก่อนสุด
  List<String> get orderedIds => List.unmodifiable(_orderedIds);

  Future<void> load() async {
    if (_loaded) return;
    _orderedIds
      ..clear()
      ..addAll(await LocalPrefsService.instance.getStringList(_key));
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String listingId) async {
    await load();
    if (_orderedIds.contains(listingId)) {
      _orderedIds.removeWhere((id) => id == listingId);
    } else {
      _orderedIds.add(listingId);
    }
    await _persist();
  }

  Future<void> removeMany(Iterable<String> listingIds) async {
    await load();
    final remove = listingIds.toSet();
    if (remove.isEmpty) return;
    _orderedIds.removeWhere(remove.contains);
    await _persist();
  }

  Future<void> _persist() async {
    await LocalPrefsService.instance.setStringList(_key, _orderedIds);
    notifyListeners();
  }
}
