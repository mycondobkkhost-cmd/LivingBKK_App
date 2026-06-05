import 'package:flutter/foundation.dart';

import '../models/demand_post.dart';
import 'local_prefs_service.dart';

/// บันทึกประกาศบอร์ดหาทรัพย์ไว้ดูทีหลัง (persist ในเครื่อง + snapshot)
class DemandBoardFavoritesService extends ChangeNotifier {
  DemandBoardFavoritesService._();
  static final DemandBoardFavoritesService instance =
      DemandBoardFavoritesService._();

  static const _idsKey = 'demand_board_favorite_ids_v1';
  static const _snapshotsKey = 'demand_board_favorite_snapshots_v1';

  final List<String> _orderedIds = [];
  final Map<String, Map<String, dynamic>> _snapshots = {};
  bool _loaded = false;

  int get count => _orderedIds.length;

  bool isFavorite(String postId) => _orderedIds.contains(postId);

  List<String> get orderedIds => List.unmodifiable(_orderedIds);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = LocalPrefsService.instance;
    _orderedIds
      ..clear()
      ..addAll(await prefs.getStringList(_idsKey));
    _snapshots.clear();
    final raw = await prefs.getJsonMap(_snapshotsKey);
    if (raw != null) {
      for (final entry in raw.entries) {
        if (entry.value is Map) {
          _snapshots[entry.key] = Map<String, dynamic>.from(
            entry.value as Map,
          );
        }
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<bool> toggle(DemandPost post) async {
    await load();
    final added = !isFavorite(post.id);
    if (added) {
      _orderedIds.remove(post.id);
      _orderedIds.insert(0, post.id);
      _snapshots[post.id] = post.toJson();
    } else {
      _orderedIds.remove(post.id);
      _snapshots.remove(post.id);
    }
    await _persist();
    notifyListeners();
    return added;
  }

  Future<void> remove(String postId) async {
    await load();
    if (!_orderedIds.contains(postId)) return;
    _orderedIds.remove(postId);
    _snapshots.remove(postId);
    await _persist();
    notifyListeners();
  }

  /// รวมข้อมูลล่าสุดจากฟีด (ถ้ามี) กับ snapshot ที่บันทึกไว้
  List<DemandPost> resolvePosts(Iterable<DemandPost> currentFeed) {
    final byId = {for (final p in currentFeed) p.id: p};
    final out = <DemandPost>[];
    for (final id in _orderedIds) {
      final live = byId[id];
      if (live != null) {
        out.add(live);
        continue;
      }
      final snap = _snapshots[id];
      if (snap != null) {
        try {
          out.add(DemandPost.fromJson(snap));
        } catch (e) {
          debugPrint('DemandBoardFavoritesService snapshot parse: $e');
        }
      }
    }
    return out;
  }

  Future<void> _persist() async {
    final prefs = LocalPrefsService.instance;
    await prefs.setStringList(_idsKey, _orderedIds);
    await prefs.setJsonMap(_snapshotsKey, _snapshots);
  }
}
