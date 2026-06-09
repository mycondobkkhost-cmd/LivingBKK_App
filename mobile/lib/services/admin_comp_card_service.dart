import 'package:flutter/foundation.dart';

import '../data/demo_cast_catalog.dart';
import '../models/admin_comp_card.dart';
import '../models/demo_cast_persona.dart';
import '../models/profile_tag.dart';
import 'local_prefs_service.dart';
import 'profile_tag_service.dart';

/// คอมพ์การ์ดทีมงาน + แท็ก PR ที่ผูกไว้
class AdminCompCardService extends ChangeNotifier {
  AdminCompCardService._();
  static final instance = AdminCompCardService._();

  static const _prefsKey = 'admin_comp_cards_v1';

  final _byProfileId = <String, AdminCompCard>{};
  bool _loaded = false;

  List<AdminCompCard> get all => _byProfileId.values
      .where((c) => c.active)
      .toList()
    ..sort((a, b) => a.roleLabelTh.compareTo(b.roleLabelTh));

  AdminCompCard? byProfileId(String? id) {
    if (id == null || id.isEmpty) return null;
    return _byProfileId[id];
  }

  AdminCompCard? byTagCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final upper = code.toUpperCase();
    for (final c in _byProfileId.values) {
      if (c.tagCode.toUpperCase() == upper) return c;
    }
    return null;
  }

  AdminCompCard? byCastId(String? castId) {
    if (castId == null || castId.isEmpty) return null;
    for (final c in _byProfileId.values) {
      if (c.castId == castId) return c;
    }
    return null;
  }

  Future<void> ensureSeeded({bool force = false}) async {
    if (_loaded && !force && _byProfileId.isNotEmpty) return;
    await LocalPrefsService.instance.init();
    if (!force) {
      final raw = await LocalPrefsService.instance.getJsonList(_prefsKey);
      if (raw.isNotEmpty) {
        for (final row in raw) {
          final card = AdminCompCard.fromJson(Map<String, dynamic>.from(row));
          _byProfileId[card.memberProfileId] = card;
          _ensureTagForCard(card);
        }
        _loaded = true;
        return;
      }
    }
    _seedFromCatalog();
    await _persist();
    _loaded = true;
    notifyListeners();
  }

  void _seedFromCatalog() {
    _byProfileId.clear();
    var seq = 300;
    final staff = DemoCastCatalog.all
        .where((p) => p.kind.isBackOfficeStaff)
        .toList();
    for (final p in staff) {
      final card = _cardForPersona(p, seq++);
      _byProfileId[card.memberProfileId] = card;
      _ensureTagForCard(card);
    }
  }

  AdminCompCard _cardForPersona(DemoCastPersona p, int seq) {
    final code = 'PR-2026-${seq.toString().padLeft(6, '0')}';
    final tagId = 'comp-tag-${p.profileId}';
    return AdminCompCard(
      memberProfileId: p.profileId,
      castId: p.castId,
      roleLabelTh: p.roleLabelTh,
      roleLabelEn: p.roleLabelEn,
      displayNameTh: p.displayNameTh,
      displayNameEn: p.displayNameEn,
      tagId: tagId,
      tagCode: code,
      phone: p.phone,
      agencyName: 'RealXtate',
    );
  }

  void _ensureTagForCard(AdminCompCard card) {
    final existing = ProfileTagService.instance.tagByCode(card.tagCode);
    if (existing != null) return;
    final tag = ProfileTag(
      id: card.tagId,
      code: card.tagCode,
      role: ProfileTagRole.coAgentPresenter,
      version: 1,
      label: card.tagCode,
      snapshot: {
        'displayName': card.displayNameTh,
        'agencyName': card.agencyName,
        if (card.licenseNo != null && card.licenseNo!.isNotEmpty)
          'licenseNo': card.licenseNo!,
        if (card.phone != null && card.phone!.isNotEmpty) 'phone': card.phone!,
        'role': card.roleLabelTh,
      },
      ownerUserId: card.memberProfileId,
      createdAt: DateTime.now(),
      subjectDisplayName: card.displayNameTh,
    );
    ProfileTagService.instance.registerDemoTag(tag);
  }

  Future<AdminCompCard> refreshTag(AdminCompCard card) async {
    final snap = <String, String>{
      'displayName': card.displayNameTh,
      'agencyName': card.agencyName,
      'role': card.roleLabelTh,
      if (card.licenseNo != null && card.licenseNo!.isNotEmpty)
        'licenseNo': card.licenseNo!,
      if (card.phone != null && card.phone!.isNotEmpty) 'phone': card.phone!,
    };
    final old = ProfileTagService.instance.tagByCode(card.tagCode);
    final tag = ProfileTagService.instance.createTag(
      role: ProfileTagRole.coAgentPresenter,
      snapshot: snap,
      subjectDisplayName: card.displayNameTh,
      userId: card.memberProfileId,
      basedOn: old,
    );
    final next = card.copyWith(tagId: tag.id, tagCode: tag.code);
    _byProfileId[card.memberProfileId] = next;
    await _persist();
    notifyListeners();
    return next;
  }

  Future<void> updateCard(AdminCompCard card) async {
    _byProfileId[card.memberProfileId] = card;
    _ensureTagForCard(card);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await LocalPrefsService.instance.setJsonList(
      _prefsKey,
      _byProfileId.values.map((c) => c.toJson()).toList(),
    );
  }

  void resetDemo() {
    _byProfileId.clear();
    _loaded = false;
    notifyListeners();
  }
}
