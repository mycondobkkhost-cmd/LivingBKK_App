import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rental_lease_service.dart';
import 'supabase_service.dart';

class RentalCronRunResult {
  const RentalCronRunResult({
    required this.remindersSent,
    required this.leasesChecked,
    required this.ranAt,
    this.viaEdge = false,
  });

  final int remindersSent;
  final int leasesChecked;
  final DateTime ranAt;
  final bool viaEdge;

  Map<String, dynamic> toJson() => {
        'reminders_sent': remindersSent,
        'leases_checked': leasesChecked,
        'ran_at': ranAt.toIso8601String(),
        'via_edge': viaEdge,
      };

  factory RentalCronRunResult.fromJson(Map<String, dynamic> j) {
    return RentalCronRunResult(
      remindersSent: (j['reminders_sent'] as num?)?.toInt() ?? 0,
      leasesChecked: (j['leases_checked'] as num?)?.toInt() ?? 0,
      ranAt: DateTime.tryParse(j['ran_at']?.toString() ?? '') ?? DateTime.now(),
      viaEdge: j['via_edge'] == true,
    );
  }
}

/// Phase 28 — รัน cron แจ้งชำระค่าเช่า (local demo หรือ Edge)
class RentalPaymentCronService {
  RentalPaymentCronService._();
  static final RentalPaymentCronService instance =
      RentalPaymentCronService._();

  static const _lastRunKey = 'rental_payment_cron_last_v1';

  Future<RentalCronRunResult?> lastRun() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastRunKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return RentalCronRunResult.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<RentalCronRunResult> runLocal({DateTime? onDate}) async {
    final sent = await RentalLeaseService.instance.runAllDueReminders(
      onDate: onDate,
    );
    final leases = RentalLeaseService.instance.allLeases
        .where((l) => l.isActive)
        .length;
    final result = RentalCronRunResult(
      remindersSent: sent,
      leasesChecked: leases,
      ranAt: DateTime.now(),
    );
    await _saveLastRun(result);
    return result;
  }

  Future<RentalCronRunResult> runViaEdge() async {
    if (!SupabaseService.isReady) {
      return runLocal();
    }
    try {
      final res = await SupabaseService.client!.functions.invoke(
        'rental-payment-cron',
      );
      final data = res.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final result = RentalCronRunResult(
          remindersSent: (map['reminders_sent'] as num?)?.toInt() ?? 0,
          leasesChecked: (map['leases_checked'] as num?)?.toInt() ?? 0,
          ranAt: DateTime.tryParse(map['ran_at']?.toString() ?? '') ??
              DateTime.now(),
          viaEdge: true,
        );
        await _saveLastRun(result);
        return result;
      }
    } catch (e) {
      debugPrint('rental-payment-cron edge failed, fallback local: $e');
    }
    return runLocal();
  }

  Future<void> _saveLastRun(RentalCronRunResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRunKey, jsonEncode(result.toJson()));
  }
}
