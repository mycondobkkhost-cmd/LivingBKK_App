import '../l10n/app_strings.dart';

/// วิธีเปิดห้องเมื่อมีลูกค้านัดดู — เก็บใน `listings.viewing_access` (jsonb)
class ListingViewingAccess {
  const ListingViewingAccess({
    this.followUpLater = true,
    this.modes = const {},
    this.ownerNoticeDays,
    this.note,
  });

  /// ยังไม่ระบุครบ — ทีมสอบถามเมื่อมีคำขอนัดดู
  final bool followUpLater;

  /// `owner_open` | `juristic_key` | `mailbox_key`
  final Set<String> modes;

  /// 1 หรือ 2 เมื่อเลือก owner_open
  final int? ownerNoticeDays;

  final String? note;

  static const modeOwnerOpen = 'owner_open';
  static const modeJuristicKey = 'juristic_key';
  static const modeMailboxKey = 'mailbox_key';

  bool get hasAnyMode => modes.isNotEmpty;

  /// ค่าเริ่มต้น (สอบถามภายหลังอย่างเดียว) — ไม่ต้องแสดงซ้ำใน UI
  bool get hasStoredPref =>
      hasAnyMode || (note != null && note!.trim().isNotEmpty) || !followUpLater;

  bool get isEmpty => !hasStoredPref;

  ListingViewingAccess copyWith({
    bool? followUpLater,
    Set<String>? modes,
    int? ownerNoticeDays,
    bool clearOwnerNoticeDays = false,
    String? note,
  }) {
    return ListingViewingAccess(
      followUpLater: followUpLater ?? this.followUpLater,
      modes: modes ?? this.modes,
      ownerNoticeDays:
          clearOwnerNoticeDays ? null : (ownerNoticeDays ?? this.ownerNoticeDays),
      note: note ?? this.note,
    );
  }

  factory ListingViewingAccess.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ListingViewingAccess();
    final rawModes = json['modes'];
    final modes = <String>{};
    if (rawModes is List) {
      for (final m in rawModes) {
        final s = m.toString();
        if (s.isNotEmpty) modes.add(s);
      }
    }
    return ListingViewingAccess(
      followUpLater: json['follow_up_later'] as bool? ?? true,
      modes: modes,
      ownerNoticeDays: (json['owner_notice_days'] as num?)?.toInt(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'follow_up_later': followUpLater,
        'modes': modes.toList()..sort(),
        if (ownerNoticeDays != null) 'owner_notice_days': ownerNoticeDays,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };

  /// สรุปสั้นสำหรับแอดมิน / ประกาศของฉัน
  String summary(AppStrings s) {
    if (followUpLater && !hasAnyMode && (note == null || note!.trim().isEmpty)) {
      return s.viewingAccessSummaryFollowUp;
    }
    final parts = <String>[];
    if (modes.contains(modeOwnerOpen)) {
      parts.add(s.viewingAccessSummaryOwnerOpen(ownerNoticeDays ?? 2));
    }
    if (modes.contains(modeJuristicKey)) {
      parts.add(s.viewingAccessSummaryJuristic);
    }
    if (modes.contains(modeMailboxKey)) {
      parts.add(s.viewingAccessSummaryMailbox);
    }
    if (followUpLater) parts.add(s.viewingAccessSummaryMayFollowUp);
    final base = parts.isEmpty ? s.viewingAccessSummaryFollowUp : parts.join(' · ');
    final n = note?.trim();
    if (n != null && n.isNotEmpty) return '$base — $n';
    return base;
  }
}
