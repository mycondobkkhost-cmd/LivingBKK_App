import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'pii_sanitizer.dart';

/// Phase 27e — บล็อก PII ในแชทกลุ่มเช่า + audit log (demo/prefs)
class RentalPiiAuditEntry {
  const RentalPiiAuditEntry({
    required this.leaseId,
    required this.channel,
    required this.preview,
    required this.blockedAt,
  });

  final String leaseId;
  final String channel;
  final String preview;
  final DateTime blockedAt;

  Map<String, dynamic> toJson() => {
        'lease_id': leaseId,
        'channel': channel,
        'preview': preview,
        'blocked_at': blockedAt.toIso8601String(),
      };

  factory RentalPiiAuditEntry.fromJson(Map<String, dynamic> j) {
    return RentalPiiAuditEntry(
      leaseId: j['lease_id']?.toString() ?? '',
      channel: j['channel']?.toString() ?? '',
      preview: j['preview']?.toString() ?? '',
      blockedAt: DateTime.tryParse(j['blocked_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class RentalPiiGuard {
  RentalPiiGuard._();

  static const _auditPrefsKey = 'rental_pii_audit_v1';
  static const maxAuditEntries = 50;

  static bool wouldBlock(String text) =>
      PiiSanitizer.containsBlockedContact(text);

  static Future<bool> checkAndAudit({
    required String leaseId,
    required String channel,
    required String text,
  }) async {
    if (!wouldBlock(text)) return true;
    await _recordBlock(
      leaseId: leaseId,
      channel: channel,
      preview: _preview(text),
    );
    return false;
  }

  static Future<List<RentalPiiAuditEntry>> recentAudit({int limit = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_auditPrefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      final out = <RentalPiiAuditEntry>[];
      for (final item in list) {
        if (item is Map) {
          out.add(RentalPiiAuditEntry.fromJson(
            Map<String, dynamic>.from(item),
          ));
        }
      }
      return out.take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _recordBlock({
    required String leaseId,
    required String channel,
    required String preview,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await recentAudit(limit: maxAuditEntries);
    final entry = RentalPiiAuditEntry(
      leaseId: leaseId,
      channel: channel,
      preview: preview,
      blockedAt: DateTime.now(),
    );
    final next = [entry, ...existing].take(maxAuditEntries).toList();
    await prefs.setString(
      _auditPrefsKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  static String _preview(String text) {
    final t = text.trim();
    if (t.length <= 80) return t;
    return '${t.substring(0, 77)}…';
  }
}
