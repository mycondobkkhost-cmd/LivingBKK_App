import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import '../models/availability_contact_record.dart';

/// ตั้งเตือนซ้ำ + บันทึกการติดต่อเจ้าของ — เก็บต่อ listing
class AvailabilityFollowUpState {
  const AvailabilityFollowUpState({
    this.remindAt,
    this.note,
    this.snoozeCount = 0,
    this.contactedAt,
    this.contacts = const [],
    this.stoppedFollowUp = false,
    this.stopReason,
    this.stoppedAt,
  });

  final DateTime? remindAt;
  final String? note;
  final int snoozeCount;
  final DateTime? contactedAt;
  final List<AvailabilityContactRecord> contacts;
  final bool stoppedFollowUp;
  final String? stopReason;
  final DateTime? stoppedAt;

  int get contactCount => contacts.length;

  AvailabilityContactRecord? get lastContact =>
      contacts.isEmpty ? null : contacts.last;

  bool get isSnoozed {
    if (stoppedFollowUp) return false;
    final at = remindAt;
    if (at == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    return day.isAfter(today);
  }

  bool get isDueToday {
    if (stoppedFollowUp) return false;
    if (contactedAt != null && contacts.isEmpty) return false;
    final at = remindAt;
    if (at == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    return !day.isAfter(today);
  }

  Map<String, dynamic> toJson() => {
        if (remindAt != null) 'remind_at': remindAt!.toIso8601String(),
        if (note != null && note!.isNotEmpty) 'note': note,
        'snooze_count': snoozeCount,
        if (contactedAt != null) 'contacted_at': contactedAt!.toIso8601String(),
        'contacts': contacts.map((c) => c.toJson()).toList(),
        'stopped_follow_up': stoppedFollowUp,
        if (stopReason != null) 'stop_reason': stopReason,
        if (stoppedAt != null) 'stopped_at': stoppedAt!.toIso8601String(),
      };

  factory AvailabilityFollowUpState.fromJson(Map<String, dynamic> j) {
    final rawContacts = j['contacts'];
    var contacts = <AvailabilityContactRecord>[];
    if (rawContacts is List) {
      contacts = rawContacts
          .whereType<Map>()
          .map((m) => AvailabilityContactRecord.fromJson(
                Map<String, dynamic>.from(m),
              ))
          .toList();
    }
    final contactedAt = j['contacted_at'] != null
        ? DateTime.tryParse(j['contacted_at'].toString())
        : null;
    if (contacts.isEmpty && contactedAt != null) {
      contacts = [
        AvailabilityContactRecord(
          at: contactedAt,
          channel: AvailabilityContactChannel.inAppChat,
          note: 'ติดต่อผ่านระบบ',
        ),
      ];
    }
    return AvailabilityFollowUpState(
      remindAt: j['remind_at'] != null
          ? DateTime.tryParse(j['remind_at'].toString())
          : null,
      note: j['note']?.toString(),
      snoozeCount: (j['snooze_count'] as num?)?.toInt() ?? 0,
      contactedAt: contactedAt,
      contacts: contacts,
      stoppedFollowUp: j['stopped_follow_up'] == true,
      stopReason: j['stop_reason']?.toString(),
      stoppedAt: j['stopped_at'] != null
          ? DateTime.tryParse(j['stopped_at'].toString())
          : null,
    );
  }

  AvailabilityFollowUpState copyWith({
    DateTime? remindAt,
    String? note,
    int? snoozeCount,
    DateTime? contactedAt,
    List<AvailabilityContactRecord>? contacts,
    bool? stoppedFollowUp,
    String? stopReason,
    DateTime? stoppedAt,
    bool clearRemindAt = false,
    bool clearContactedAt = false,
  }) {
    return AvailabilityFollowUpState(
      remindAt: clearRemindAt ? null : (remindAt ?? this.remindAt),
      note: note ?? this.note,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      contactedAt:
          clearContactedAt ? null : (contactedAt ?? this.contactedAt),
      contacts: contacts ?? this.contacts,
      stoppedFollowUp: stoppedFollowUp ?? this.stoppedFollowUp,
      stopReason: stopReason ?? this.stopReason,
      stoppedAt: stoppedAt ?? this.stoppedAt,
    );
  }
}

class AvailabilityFollowUpService extends ChangeNotifier {
  AvailabilityFollowUpService._();
  static final AvailabilityFollowUpService instance =
      AvailabilityFollowUpService._();

  static const _prefsKey = 'availability_follow_up_v2';

  final _store = <String, AvailabilityFollowUpState>{};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_prefsKey);
    raw ??= prefs.getString('availability_follow_up_v1');
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw);
        if (map is Map) {
          for (final entry in map.entries) {
            if (entry.value is Map) {
              _store[entry.key.toString()] = AvailabilityFollowUpState.fromJson(
                Map<String, dynamic>.from(entry.value as Map),
              );
            }
          }
        }
      } catch (_) {}
    }
    await _seedDemoContactsIfNeeded();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _seedDemoContactsIfNeeded() async {
    if (!Env.adminDemoCases) return;
    const demoId = 'demo-avail-2';
    if (_store.containsKey(demoId)) return;
    final now = DateTime.now();
    _store[demoId] = AvailabilityFollowUpState(
      contacts: [
        AvailabilityContactRecord(
          at: now.subtract(const Duration(days: 3, hours: 2)),
          channel: AvailabilityContactChannel.externalPhone,
          note: 'โทรไม่รับ — ฝากข้อความ',
          actor: 'demo@realxtateth.com',
        ),
        AvailabilityContactRecord(
          at: now.subtract(const Duration(days: 1, hours: 5)),
          channel: AvailabilityContactChannel.inAppChat,
          note: 'ติดต่อผ่านระบบ',
          actor: 'demo@realxtateth.com',
        ),
      ],
      contactedAt: now.subtract(const Duration(days: 1, hours: 5)),
    );
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _store.map((k, v) => MapEntry(k, v.toJson())),
    );
    await prefs.setString(_prefsKey, encoded);
  }

  AvailabilityFollowUpState stateFor(String listingId) =>
      _store[listingId] ?? const AvailabilityFollowUpState();

  bool isDue(String listingId) => stateFor(listingId).isDueToday;

  int dueCount(Iterable<String> listingIds) {
    var n = 0;
    for (final id in listingIds) {
      if (id.isNotEmpty && isDue(id)) n++;
    }
    return n;
  }

  Future<void> snooze({
    required String listingId,
    required int days,
    String? note,
  }) async {
    await ensureLoaded();
    final cur = stateFor(listingId);
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day)
        .add(Duration(days: days));
    _store[listingId] = cur.copyWith(
      remindAt: target,
      note: note ?? cur.note,
      snoozeCount: cur.snoozeCount + 1,
      clearContactedAt: true,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> recordContact({
    required String listingId,
    required AvailabilityContactChannel channel,
    String? note,
    String? actor,
  }) async {
    await ensureLoaded();
    final cur = stateFor(listingId);
    final record = AvailabilityContactRecord(
      at: DateTime.now(),
      channel: channel,
      note: note,
      actor: actor,
    );
    final next = [...cur.contacts, record];
    _store[listingId] = cur.copyWith(
      contacts: next,
      contactedAt: record.at,
      clearRemindAt: true,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> markContacted(String listingId) async {
    await recordContact(
      listingId: listingId,
      channel: AvailabilityContactChannel.inAppChat,
      note: 'ติดต่อผ่านระบบ',
    );
  }

  Future<void> stopFollowUp({
    required String listingId,
    required String reason,
  }) async {
    await ensureLoaded();
    final cur = stateFor(listingId);
    _store[listingId] = cur.copyWith(
      stoppedFollowUp: true,
      stopReason: reason,
      stoppedAt: DateTime.now(),
      clearRemindAt: true,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> resetFollowUp(String listingId) async {
    await ensureLoaded();
    _store.remove(listingId);
    await _persist();
    notifyListeners();
  }
}
