import 'package:flutter/foundation.dart';

import '../models/profile_tag.dart';
import 'auth_service.dart';

/// แท็กโปรไฟล์นัดดู — in-memory (รอ migration DB)
class ProfileTagService extends ChangeNotifier {
  ProfileTagService._();
  static final instance = ProfileTagService._();

  final _tags = <String, ProfileTag>{};
  int _seq = 200;

  int get count => _tags.length;

  String? get _userId => AuthService.instance.effectiveUserId ?? 'demo-user';

  List<ProfileTag> tagsForUser({
    String? userId,
    ProfileTagRole? role,
  }) {
    final uid = userId ?? _userId;
    final list = _tags.values
        .where((t) => t.ownerUserId == uid)
        .where((t) => role == null || t.role == role)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  ProfileTag? tagById(String id) => _tags[id];

  ProfileTag? tagByCode(String code) {
    for (final t in _tags.values) {
      if (t.code == code) return t;
    }
    return null;
  }

  ProfileTag? latestTag({
    String? userId,
    required ProfileTagRole role,
  }) {
    final list = tagsForUser(userId: userId, role: role);
    return list.isEmpty ? null : list.first;
  }

  ProfileTag createTag({
    required ProfileTagRole role,
    required Map<String, String> snapshot,
    String? subjectDisplayName,
    String? userId,
    ProfileTag? basedOn,
  }) {
    final uid = userId ?? _userId!;
    final version = basedOn != null ? basedOn.version + 1 : 1;
    final code = '${role.codePrefix}-2026-${_seq.toString().padLeft(6, '0')}';
    _seq++;
    final label = version > 1 ? '$code v$version' : code;
    final tag = ProfileTag(
      id: 'tag-${DateTime.now().microsecondsSinceEpoch}',
      code: code,
      role: role,
      version: version,
      label: label,
      snapshot: Map<String, String>.from(snapshot),
      ownerUserId: uid,
      createdAt: DateTime.now(),
      subjectDisplayName: subjectDisplayName,
    );
    _tags[tag.id] = tag;
    notifyListeners();
    return tag;
  }

  void registerDemoTag(ProfileTag tag) {
    _tags[tag.id] = tag;
    final parts = tag.code.split('-');
    final n = int.tryParse(parts.last) ?? 0;
    if (n >= _seq) _seq = n + 1;
  }

  /// ล้างแท็ก in-memory — ใช้ตอนรีเซ็ตเคสทดลอง
  void resetDemo() {
    _tags.clear();
    _seq = 200;
    notifyListeners();
  }

  List<ProfileTag> allTags() {
    return _tags.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<ProfileTag> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allTags();
    return _tags.values.where((t) {
      return t.code.toLowerCase().contains(q) ||
          t.label.toLowerCase().contains(q) ||
          (t.subjectDisplayName ?? '').toLowerCase().contains(q) ||
          t.snapshot.values.any((v) => v.toLowerCase().contains(q));
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
