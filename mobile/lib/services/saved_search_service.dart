import 'package:flutter/foundation.dart';

import '../models/search_filters.dart';
import '../services/local_prefs_service.dart';

class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.name,
    required this.filters,
    this.notifyEnabled = true,
    this.createdAt,
    this.lastNotifiedAt,
  });

  final String id;
  final String name;
  final SearchFilters filters;
  final bool notifyEnabled;
  final DateTime? createdAt;
  final DateTime? lastNotifiedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filters': filters.toJson(),
        'notify_enabled': notifyEnabled,
        'created_at': createdAt?.toIso8601String(),
        'last_notified_at': lastNotifiedAt?.toIso8601String(),
      };

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'การค้นหา',
      filters: SearchFilters.fromJson(
        Map<String, dynamic>.from(json['filters'] as Map? ?? {}),
      ),
      notifyEnabled: json['notify_enabled'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lastNotifiedAt: json['last_notified_at'] != null
          ? DateTime.tryParse(json['last_notified_at'] as String)
          : null,
    );
  }
}

/// บันทึกการค้นหา + แจ้งเตือนเมื่อมีทรัพย์ใหม่ (Notify Me ฟรี)
class SavedSearchService extends ChangeNotifier {
  SavedSearchService._();
  static final instance = SavedSearchService._();

  static const _key = 'saved_searches_v1';
  static const _seenKey = 'saved_search_seen_ids';

  final _items = <SavedSearch>[];
  final _seenListingIds = <String>{};
  bool _loaded = false;

  List<SavedSearch> get items => List.unmodifiable(_items);

  Future<void> load() async {
    if (_loaded) return;
    final raw = await LocalPrefsService.instance.getJsonList(_key);
    _items
      ..clear()
      ..addAll(raw.map(SavedSearch.fromJson));
    _seenListingIds.addAll(await LocalPrefsService.instance.getStringSet(_seenKey));
    _loaded = true;
    notifyListeners();
  }

  Future<SavedSearch> save({
    required String name,
    required SearchFilters filters,
    bool notifyEnabled = true,
  }) async {
    await load();
    final item = SavedSearch(
      id: 'ss-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      filters: filters,
      notifyEnabled: notifyEnabled,
      createdAt: DateTime.now(),
    );
    _items.insert(0, item);
    await _persist();
    notifyListeners();
    return item;
  }

  Future<void> remove(String id) async {
    await load();
    _items.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleNotify(String id, bool enabled) async {
    await load();
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final old = _items[idx];
    _items[idx] = SavedSearch(
      id: old.id,
      name: old.name,
      filters: old.filters,
      notifyEnabled: enabled,
      createdAt: old.createdAt,
      lastNotifiedAt: old.lastNotifiedAt,
    );
    await _persist();
    notifyListeners();
  }

  /// คืนรายการทรัพย์ใหม่ที่ match saved search (ยังไม่เคยแจ้ง)
  Future<List<({SavedSearch search, int matchCount})>> checkNewMatches({
    required List<dynamic> listings,
  }) async {
    await load();
    final results = <({SavedSearch search, int matchCount})>[];
    for (final search in _items.where((s) => s.notifyEnabled)) {
      var count = 0;
      for (final raw in listings) {
        final id = _listingId(raw);
        if (id == null || _seenListingIds.contains(id)) continue;
        if (search.filters.matchesListing(raw)) count++;
      }
      if (count > 0) results.add((search: search, matchCount: count));
    }
    return results;
  }

  Future<void> markListingsSeen(Iterable<String> ids) async {
    _seenListingIds.addAll(ids);
    await LocalPrefsService.instance.setStringSet(_seenKey, _seenListingIds);
  }

  Future<void> _persist() async {
    await LocalPrefsService.instance.setJsonList(
      _key,
      _items.map((e) => e.toJson()).toList(),
    );
  }

  String? _listingId(dynamic listing) {
    if (listing is Map) return listing['id'] as String?;
    try {
      return (listing as dynamic).id as String?;
    } catch (_) {
      return null;
    }
  }
}
