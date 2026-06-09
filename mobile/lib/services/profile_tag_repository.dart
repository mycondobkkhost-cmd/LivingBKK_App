import 'package:flutter/foundation.dart';

import '../data/admin_demo_data.dart';
import '../models/profile_tag.dart';
import 'auth_service.dart';
import 'profile_tag_service.dart';
import 'supabase_service.dart';

/// แท็กโปรไฟล์ — DB-backed พร้อม fallback in-memory demo
class ProfileTagRepository extends ChangeNotifier {
  ProfileTagRepository._();
  static final ProfileTagRepository instance = ProfileTagRepository._();

  bool _loaded = false;

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  ProfileTagService get _demo => ProfileTagService.instance;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    if (_live) {
      await _hydrateFromDb();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _hydrateFromDb() async {
    final uid = AuthService.instance.effectiveUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      final rows = await SupabaseService.client!
          .from('profile_tags')
          .select()
          .eq('owner_user_id', uid)
          .order('created_at', ascending: false)
          .limit(100);

      final list = (rows as List)
          .whereType<Map>()
          .map((r) => _fromRow(Map<String, dynamic>.from(r)))
          .where((t) => t.id.isNotEmpty)
          .toList();

      if (list.isEmpty && AdminDemoData.enabled) return;

      for (final tag in list) {
        _demo.registerDemoTag(tag);
      }
    } catch (_) {}
  }

  List<ProfileTag> tagsForUser({
    String? userId,
    ProfileTagRole? role,
  }) {
    return _demo.tagsForUser(userId: userId, role: role);
  }

  ProfileTag? tagById(String id) => _demo.tagById(id);

  ProfileTag? tagByCode(String code) => _demo.tagByCode(code);

  ProfileTag? latestTag({
    String? userId,
    required ProfileTagRole role,
  }) =>
      _demo.latestTag(userId: userId, role: role);

  Future<ProfileTag> createTag({
    required ProfileTagRole role,
    required Map<String, String> snapshot,
    String? subjectDisplayName,
    String? userId,
    ProfileTag? basedOn,
  }) async {
    await ensureLoaded();
    final uid = userId ?? AuthService.instance.effectiveUserId ?? 'demo-user';

    if (_live) {
      final created = await _insertDb(
        role: role,
        snapshot: snapshot,
        subjectDisplayName: subjectDisplayName,
        userId: uid,
        basedOn: basedOn,
      );
      if (created != null) {
        _demo.registerDemoTag(created);
        notifyListeners();
        return created;
      }
    }

    final tag = _demo.createTag(
      role: role,
      snapshot: snapshot,
      subjectDisplayName: subjectDisplayName,
      userId: uid,
      basedOn: basedOn,
    );
    notifyListeners();
    return tag;
  }

  Future<ProfileTag?> _insertDb({
    required ProfileTagRole role,
    required Map<String, String> snapshot,
    String? subjectDisplayName,
    required String userId,
    ProfileTag? basedOn,
  }) async {
    try {
      final version = basedOn != null ? basedOn.version + 1 : 1;
      final seq = DateTime.now().microsecondsSinceEpoch % 1000000;
      final code =
          '${role.codePrefix}-2026-${seq.toString().padLeft(6, '0')}';
      final label = version > 1 ? '$code v$version' : code;

      final row = await SupabaseService.client!
          .from('profile_tags')
          .insert({
            'code': code,
            'role': _roleDb(role),
            'version': version,
            'label': label,
            'snapshot': snapshot,
            'owner_user_id': userId,
            if (subjectDisplayName != null)
              'subject_display_name': subjectDisplayName,
            if (basedOn != null) 'based_on_tag_id': basedOn.id,
          })
          .select()
          .single();

      if (row is! Map) return null;
      return _fromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  List<ProfileTag> search(String query) => _demo.search(query);

  ProfileTag _fromRow(Map<String, dynamic> row) {
    final roleRaw = row['role']?.toString() ?? '';
    final role = ProfileTagRole.values.firstWhere(
      (r) => _roleDb(r) == roleRaw,
      orElse: () => ProfileTagRole.seekerSelf,
    );
    final snapshotRaw = row['snapshot'];
    final snapshot = snapshotRaw is Map
        ? snapshotRaw.map((k, v) => MapEntry(k.toString(), v.toString()))
        : <String, String>{};

    return ProfileTag(
      id: row['id']?.toString() ?? '',
      code: row['code']?.toString() ?? '',
      role: role,
      version: (row['version'] as num?)?.toInt() ?? 1,
      label: row['label']?.toString() ?? '',
      snapshot: snapshot,
      ownerUserId: row['owner_user_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      subjectDisplayName: row['subject_display_name']?.toString(),
    );
  }

  String _roleDb(ProfileTagRole role) => switch (role) {
        ProfileTagRole.seekerSelf => 'seeker_self',
        ProfileTagRole.coAgentPresenter => 'co_agent_presenter',
        ProfileTagRole.clientSubject => 'client_subject',
      };
}
