import 'package:flutter/foundation.dart';

import 'local_prefs_service.dart';

/// รายการโปรด (persist ในเครื่อง)
class FavoritesService extends ChangeNotifier {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const _key = 'favorite_listing_ids';

  final _ids = <String>{};
  bool _loaded = false;

  bool isFavorite(String listingId) => _ids.contains(listingId);

  Set<String> get ids => Set.unmodifiable(_ids);

  Future<void> load() async {
    if (_loaded) return;
    _ids.addAll(await LocalPrefsService.instance.getStringSet(_key));
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String listingId) async {
    await load();
    if (_ids.contains(listingId)) {
      _ids.remove(listingId);
    } else {
      _ids.add(listingId);
    }
    await LocalPrefsService.instance.setStringSet(_key, _ids);
    notifyListeners();
  }
}
