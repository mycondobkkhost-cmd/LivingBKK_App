import 'package:flutter/foundation.dart';

import '../models/chat_room.dart';
import 'chat_repository.dart';
import 'local_prefs_service.dart';

/// ชื่อแชทที่แอดมินตั้งเอง — cache ในเครื่อง + sync Supabase ถ้ามี
class AdminChatLabelService extends ChangeNotifier {
  AdminChatLabelService._();
  static final instance = AdminChatLabelService._();

  static const _prefsKey = 'admin_chat_display_names';

  final _labels = <String, String>{};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final map = await LocalPrefsService.instance.getJsonMap(_prefsKey);
    if (map != null) {
      for (final e in map.entries) {
        final v = e.value?.toString().trim();
        if (v != null && v.isNotEmpty) _labels[e.key] = v;
      }
    }
    _loaded = true;
  }

  String? labelFor(String roomId) => _labels[roomId];

  void applyToRoom(ChatRoom room) {
    final fromDb = room.adminDisplayName?.trim();
    if (fromDb != null && fromDb.isNotEmpty) {
      _labels[room.id] = fromDb;
      return;
    }
    final cached = _labels[room.id];
    if (cached != null) room.adminDisplayName = cached;
  }

  Future<void> setLabel(String roomId, String? name) async {
    await ensureLoaded();
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _labels.remove(roomId);
    } else {
      _labels[roomId] = trimmed;
    }
    await LocalPrefsService.instance.setJsonMap(_prefsKey, _labels);
    notifyListeners();

    try {
      await ChatRepository().updateAdminDisplayName(
        roomId,
        trimmed?.isEmpty ?? true ? null : trimmed,
      );
    } catch (e) {
      debugPrint('AdminChatLabelService sync: $e');
    }
  }
}
