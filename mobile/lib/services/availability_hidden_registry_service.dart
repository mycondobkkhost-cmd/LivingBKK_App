import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/availability_alert.dart';
import '../models/vault_asset.dart';

/// คลังซ่อน — ทรัพย์ที่ติดต่อเจ้าของไม่ได้ / หยุดติดตาม (ไม่แสดงในคลังหลัก)
class HiddenRegistryEntry {
  const HiddenRegistryEntry({
    required this.listingId,
    required this.listingCode,
    required this.title,
    required this.reason,
    required this.archivedAt,
    this.entityType = 'listing',
    this.entityId,
  });

  final String listingId;
  final String listingCode;
  final String title;
  final String reason;
  final DateTime archivedAt;
  final String entityType;
  final String? entityId;

  VaultAssetSummary toSummary() => VaultAssetSummary(
        id: listingId,
        entityType: entityType,
        entityId: entityId ?? listingId,
        listingId: listingId,
        listingCode: listingCode,
        titlePreview: title,
        capturedAt: archivedAt,
        updatedAt: archivedAt,
      );

  Map<String, dynamic> toJson() => {
        'listing_id': listingId,
        'listing_code': listingCode,
        'title': title,
        'reason': reason,
        'archived_at': archivedAt.toIso8601String(),
        'entity_type': entityType,
        if (entityId != null) 'entity_id': entityId,
      };

  factory HiddenRegistryEntry.fromJson(Map<String, dynamic> j) {
    return HiddenRegistryEntry(
      listingId: j['listing_id']?.toString() ?? '',
      listingCode: j['listing_code']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      reason: j['reason']?.toString() ?? '',
      archivedAt: DateTime.tryParse(j['archived_at']?.toString() ?? '') ??
          DateTime.now(),
      entityType: j['entity_type']?.toString() ?? 'listing',
      entityId: j['entity_id']?.toString(),
    );
  }

  factory HiddenRegistryEntry.fromAlert(
    AvailabilityAlertItem item, {
    required String reason,
  }) {
    return HiddenRegistryEntry(
      listingId: item.listingId,
      listingCode: item.listingCode,
      title: item.title,
      reason: reason,
      archivedAt: DateTime.now(),
      entityType: 'listing',
      entityId: item.listingId,
    );
  }
}

class AvailabilityHiddenRegistryService extends ChangeNotifier {
  AvailabilityHiddenRegistryService._();
  static final AvailabilityHiddenRegistryService instance =
      AvailabilityHiddenRegistryService._();

  static const _prefsKey = 'availability_hidden_registry_v1';

  final _entries = <String, HiddenRegistryEntry>{};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final item in list) {
            if (item is Map) {
              final e = HiddenRegistryEntry.fromJson(
                Map<String, dynamic>.from(item),
              );
              if (e.listingId.isNotEmpty) _entries[e.listingId] = e;
            }
          }
        }
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_entries.values.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  bool isHidden(String listingId) => _entries.containsKey(listingId);

  List<HiddenRegistryEntry> allEntries() =>
      _entries.values.toList()
        ..sort((a, b) => b.archivedAt.compareTo(a.archivedAt));

  List<VaultAssetSummary> hiddenSummaries() =>
      allEntries().map((e) => e.toSummary()).toList();

  Future<void> archive(HiddenRegistryEntry entry) async {
    await ensureLoaded();
    _entries[entry.listingId] = entry;
    await _persist();
    notifyListeners();
  }

  Future<void> restore(String listingId) async {
    await ensureLoaded();
    _entries.remove(listingId);
    await _persist();
    notifyListeners();
  }
}
