import 'package:flutter/foundation.dart';

import 'in_app_notification_hub.dart';
import 'local_prefs_service.dart';

/// แจ้งเตือนเจ้าของก่อนวันว่าง (T-30 / T-15) — demo + local snooze
class ListingAvailabilityReminderService extends ChangeNotifier {
  ListingAvailabilityReminderService._();
  static final instance = ListingAvailabilityReminderService._();

  static const _snoozePrefix = 'avail_remind_snooze_';

  final List<Map<String, dynamic>> dueReminders = [];
  final Set<String> _snoozedIds = {};

  int? daysUntilAvailable(Map<String, dynamic> row) {
    if (row['status']?.toString() != 'archived') return null;
    if (row['listing_type']?.toString() != 'rent') return null;
    final raw = row['available_again']?.toString();
    if (raw == null || raw.isEmpty) return null;
    final again = DateTime.tryParse(raw);
    if (again == null) return null;
    final today = DateTime.now();
    final a = DateTime(again.year, again.month, again.day);
    final t = DateTime(today.year, today.month, today.day);
    return a.difference(t).inDays;
  }

  bool isReminderDue(Map<String, dynamic> row) {
    final days = daysUntilAvailable(row);
    if (days == null) return false;
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return false;

    if (days == 30) return true;
    if (days == 15 && _snoozedIds.contains(id)) return true;
    if (days > 0 && days < 15) return true;
    return false;
  }

  Future<void> scanOwnerListings(List<Map<String, dynamic>> rows) async {
    dueReminders.clear();
    _snoozedIds.clear();
    for (final row in rows) {
      final id = row['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        final snooze = await LocalPrefsService.instance.getString('$_snoozePrefix$id');
        if (snooze != null && snooze.isNotEmpty) _snoozedIds.add(id);
      }
    }

    for (final row in rows) {
      if (!isReminderDue(row)) continue;
      dueReminders.add(row);
      await _maybePushInApp(row);
    }
    notifyListeners();
  }

  Future<void> snoozeTo15Days(String listingId) async {
    await LocalPrefsService.instance.setString(
      '$_snoozePrefix$listingId',
      DateTime.now().toUtc().toIso8601String(),
    );
    _snoozedIds.add(listingId);
    notifyListeners();
  }

  Future<void> _maybePushInApp(Map<String, dynamic> row) async {
    final id = row['id']?.toString() ?? '';
    final days = daysUntilAvailable(row);
    if (id.isEmpty || days == null) return;

    final shownKey = 'avail_remind_shown_${id}_$days';
    final shown = await LocalPrefsService.instance.getString(shownKey);
    if (shown != null) return;

    final title = row['title']?.toString() ?? row['listing_code']?.toString() ?? '';
    final msg = days >= 30
        ? 'ประกาศ「$title」จะว่างในอีก $days วัน — เปิดแท็บของฉันเพื่อเลือกดำเนินการ'
        : 'ประกาศ「$title」จะว่างในอีก $days วัน — ยืนยันวันว่างหรือเผยแพร่ล่วงหน้า';

    InAppNotificationHub.instance.show(msg, countAsUnread: true);
    await LocalPrefsService.instance.setString(
      shownKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  static String formatAvailableDate(Map<String, dynamic> row) {
    final raw = row['available_again']?.toString();
    if (raw == null) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return '${d.day}/${d.month}/${d.year + 543}';
  }
}
