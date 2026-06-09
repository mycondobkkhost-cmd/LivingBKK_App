import 'vault_asset.dart';

class RegistryEditEvent {
  const RegistryEditEvent({
    required this.actor,
    required this.action,
    required this.at,
  });

  final String actor;
  final String action;
  final DateTime at;
}

class RegistryAssetRecordMeta {
  const RegistryAssetRecordMeta({
    required this.recordedBy,
    required this.recordedAt,
    this.ownerName,
    required this.chatTag,
  });

  final String recordedBy;
  final DateTime recordedAt;
  final String? ownerName;
  /// รหัสแท็กในแชท — RXT / IMP-xxx
  final String chatTag;

  static RegistryAssetRecordMeta fromDetail(VaultAssetDetail detail) {
    final p = detail.payload;
    final sum = detail.summary;
    final recordedBy = p['recorded_by']?.toString() ??
        p['owner_display_name']?.toString() ??
        'ระบบนำเข้า';
    final recordedAt = DateTime.tryParse(p['recorded_at']?.toString() ?? '') ??
        DateTime.tryParse(p['synced_at']?.toString() ?? '') ??
        detail.capturedAt ??
        sum.updatedAt ??
        DateTime.now();
    final owner = p['owner_display_name']?.toString() ??
        p['poster_name']?.toString() ??
        p['display_name']?.toString();
    final chatTag = sum.listingCode ??
        p['chat_tag']?.toString() ??
        sum.displayCode;
    return RegistryAssetRecordMeta(
      recordedBy: recordedBy,
      recordedAt: recordedAt,
      ownerName: owner,
      chatTag: chatTag,
    );
  }

  static List<RegistryEditEvent> historyFromPayload(Map<String, dynamic> payload) {
    final raw = payload['edit_history'];
    if (raw is! List) return [];
    final out = <RegistryEditEvent>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final actor = item['actor']?.toString() ?? 'ระบบ';
      final action = item['action']?.toString() ?? '';
      final at = DateTime.tryParse(item['at']?.toString() ?? '') ?? DateTime.now();
      if (action.isEmpty) continue;
      out.add(RegistryEditEvent(actor: actor, action: action, at: at));
    }
    return out;
  }
}
