import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import 'admin_inbox_preview.dart';

/// ระดับความเร่งด่วนตามเวลารอตอบ (นาทีนับจากข้อความลูกค้าล่าสุด)
enum AdminInboxSlaLevel {
  ok,
  warn,
  critical,
}

class AdminInboxSla {
  const AdminInboxSla({
    required this.waitMinutes,
    required this.level,
    required this.since,
  });

  final int waitMinutes;
  final AdminInboxSlaLevel level;
  final DateTime since;

  static const warnMinutes = 15;
  static const criticalMinutes = 60;

  static AdminInboxSla? forRoom(ChatRoom room, {bool needsAttention = true}) {
    if (!needsAttention) return null;
    final since = AdminInboxPreview.previewMessageAtForRoom(room);
    final minutes = DateTime.now().difference(since).inMinutes;
    if (minutes < 1) return null;
    final level = minutes >= criticalMinutes
        ? AdminInboxSlaLevel.critical
        : (minutes >= warnMinutes
            ? AdminInboxSlaLevel.warn
            : AdminInboxSlaLevel.ok);
    return AdminInboxSla(
      waitMinutes: minutes,
      level: level,
      since: since,
    );
  }

  String label(AppStrings s) => s.adminInboxSlaWait(waitMinutes);

  Color get color => switch (level) {
        AdminInboxSlaLevel.ok => const Color(0xFF059669),
        AdminInboxSlaLevel.warn => const Color(0xFFD97706),
        AdminInboxSlaLevel.critical => const Color(0xFFDC2626),
      };
}
