import 'package:flutter/foundation.dart';

import '../models/registry_asset_metadata.dart';
import 'admin_repository.dart';
import 'listing_owner_repository.dart';
import 'platform_settings_service.dart';

/// ป้ายทับบนแผนที่/ฟีด (Phase 23)
enum RegistryDisplayOverlay { none, sold, notAvailable }

/// แท็กปฏิบัติการที่แอดมินติดบนทรัพย์
enum RegistryAdminTag {
  hot,
  exclusive,
  featured,
  verified,
  urgent,
  /// ติดต่อเจ้าของไม่ได้ — ย้ายไปคลังซ่อน
  ownerUnreachable,
}

class RegistryAssetOps {
  const RegistryAssetOps({
    this.tags = const {},
    this.overlay = RegistryDisplayOverlay.none,
    this.autoBumpEnabled = false,
    this.autoBumpHours = 6,
    this.adminNote = '',
    this.lastManualBumpAt,
  });

  final Set<RegistryAdminTag> tags;
  final RegistryDisplayOverlay overlay;
  final bool autoBumpEnabled;
  final int autoBumpHours;
  final String adminNote;
  final DateTime? lastManualBumpAt;

  RegistryAssetOps copyWith({
    Set<RegistryAdminTag>? tags,
    RegistryDisplayOverlay? overlay,
    bool? autoBumpEnabled,
    int? autoBumpHours,
    String? adminNote,
    DateTime? lastManualBumpAt,
  }) {
    return RegistryAssetOps(
      tags: tags ?? this.tags,
      overlay: overlay ?? this.overlay,
      autoBumpEnabled: autoBumpEnabled ?? this.autoBumpEnabled,
      autoBumpHours: autoBumpHours ?? this.autoBumpHours,
      adminNote: adminNote ?? this.adminNote,
      lastManualBumpAt: lastManualBumpAt ?? this.lastManualBumpAt,
    );
  }
}

/// สถานะปฏิบัติการต่อ entity — เก็บใน memory (รอคอลัมน์ DB รอบถัดไป)
class RegistryAssetOpsService extends ChangeNotifier {
  RegistryAssetOpsService._();
  static final instance = RegistryAssetOpsService._();

  final _store = <String, RegistryAssetOps>{};
  final _titleOverrides = <String, String>{};
  final _descriptionOverrides = <String, String>{};
  final _history = <String, List<RegistryEditEvent>>{};
  final _chatAccessGranted = <String, bool>{};
  final _chatAccessPending = <String, String>{};
  final _ownerRepo = ListingOwnerRepository();
  final _admin = AdminRepository();

  String _key(String entityType, String entityId) => '$entityType:$entityId';

  static bool tierCanChatDirect(String tier) =>
      tier == 'super' || tier == 'ceo';

  String? titleFor({
    required String entityType,
    required String entityId,
  }) =>
      _titleOverrides[_key(entityType, entityId)];

  String? descriptionFor({
    required String entityType,
    required String entityId,
  }) =>
      _descriptionOverrides[_key(entityType, entityId)];

  List<RegistryEditEvent> historyFor({
    required String entityType,
    required String entityId,
    List<RegistryEditEvent> seed = const [],
  }) {
    final live = _history[_key(entityType, entityId)] ?? const [];
    return [...seed, ...live];
  }

  /// วันที่แก้ไขล่าสุดจากประวัติแอดมิน (ถ้ามี)
  DateTime? lastAdminEditAt({
    required String entityType,
    required String entityId,
  }) {
    final events = historyFor(entityType: entityType, entityId: entityId);
    if (events.isEmpty) return null;
    return events.map((e) => e.at).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  bool hasChatAccess({
    required String entityType,
    required String entityId,
    required String adminTier,
  }) =>
      tierCanChatDirect(adminTier) ||
      (_chatAccessGranted[_key(entityType, entityId)] ?? false);

  bool hasPendingChatRequest({
    required String entityType,
    required String entityId,
  }) =>
      _chatAccessPending.containsKey(_key(entityType, entityId));

  void requestChatAccess({
    required String entityType,
    required String entityId,
    required String actor,
    required String reason,
  }) {
    final key = _key(entityType, entityId);
    _chatAccessPending[key] = reason;
    _appendHistory(
      key,
      RegistryEditEvent(
        actor: actor,
        action: 'ขอสิทธิ์คุยเจ้าของทรัพย์: $reason',
        at: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void grantChatAccess({
    required String entityType,
    required String entityId,
    required String actor,
  }) {
    final key = _key(entityType, entityId);
    _chatAccessGranted[key] = true;
    _chatAccessPending.remove(key);
    _appendHistory(
      key,
      RegistryEditEvent(
        actor: actor,
        action: 'อนุมัติสิทธิ์คุยเจ้าของทรัพย์',
        at: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void saveEdits({
    required String entityType,
    required String entityId,
    required String title,
    required String description,
    required String actor,
    String? previousTitle,
    String? previousDescription,
  }) {
    final key = _key(entityType, entityId);
    final changes = <String>[];
    final prevT = previousTitle ?? '';
    final prevD = previousDescription ?? '';
    if (title != prevT) {
      changes.add('หัวข้อ');
      _titleOverrides[key] = title;
    }
    if (description != prevD) {
      changes.add('คำอธิบาย');
      _descriptionOverrides[key] = description;
    }
    if (changes.isNotEmpty) {
      _appendHistory(
        key,
        RegistryEditEvent(
          actor: actor,
          action: 'แก้ไข ${changes.join(', ')}',
          at: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  void _appendHistory(String key, RegistryEditEvent event) {
    final list = List<RegistryEditEvent>.from(_history[key] ?? const []);
    list.add(event);
    _history[key] = list;
  }

  RegistryAssetOps opsFor({
    required String entityType,
    required String entityId,
  }) {
    return _store[_key(entityType, entityId)] ?? const RegistryAssetOps();
  }

  void _save(String key, RegistryAssetOps ops) {
    _store[key] = ops;
    notifyListeners();
  }

  void markOwnerUnreachable({
    required String entityType,
    required String entityId,
    required String actor,
    required String reason,
  }) {
    final key = _key(entityType, entityId);
    final cur = opsFor(entityType: entityType, entityId: entityId);
    final next = Set<RegistryAdminTag>.from(cur.tags)
      ..add(RegistryAdminTag.ownerUnreachable);
    _save(
      key,
      cur.copyWith(
        tags: next,
        overlay: RegistryDisplayOverlay.notAvailable,
      ),
    );
    _appendHistory(
      key,
      RegistryEditEvent(
        actor: actor,
        action: 'ติดต่อเจ้าของไม่ได้ — ย้ายคลังซ่อน: $reason',
        at: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void toggleTag({
    required String entityType,
    required String entityId,
    required RegistryAdminTag tag,
  }) {
    final key = _key(entityType, entityId);
    final cur = opsFor(entityType: entityType, entityId: entityId);
    final next = Set<RegistryAdminTag>.from(cur.tags);
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      next.add(tag);
    }
    _save(key, cur.copyWith(tags: next));
  }

  void setOverlay({
    required String entityType,
    required String entityId,
    required RegistryDisplayOverlay overlay,
  }) {
    final key = _key(entityType, entityId);
    final cur = opsFor(entityType: entityType, entityId: entityId);
    _save(key, cur.copyWith(overlay: overlay));
  }

  void setAutoBump({
    required String entityType,
    required String entityId,
    required bool enabled,
    int? hours,
  }) {
    final key = _key(entityType, entityId);
    final cur = opsFor(entityType: entityType, entityId: entityId);
    _save(
      key,
      cur.copyWith(
        autoBumpEnabled: enabled,
        autoBumpHours: hours ?? cur.autoBumpHours,
      ),
    );
  }

  void setNote({
    required String entityType,
    required String entityId,
    required String note,
  }) {
    final key = _key(entityType, entityId);
    final cur = opsFor(entityType: entityType, entityId: entityId);
    _save(key, cur.copyWith(adminNote: note));
  }

  Future<bool> manualBump({String? listingId}) async {
    if (listingId == null || listingId.isEmpty) return false;
    try {
      await _admin.adminBumpListing(listingId);
      return true;
    } catch (_) {
      try {
        await _ownerRepo.bumpListing(listingId);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  void recordManualBump({
    required String entityType,
    required String entityId,
  }) {
    final key = _key(entityType, entityId);
    final cur = opsFor(entityType: entityType, entityId: entityId);
    _save(key, cur.copyWith(lastManualBumpAt: DateTime.now()));
  }

  int defaultAutoBumpHours() {
    final cfg = PlatformSettingsService.instance.exclusive;
    return cfg.rentBumpHours;
  }
}
