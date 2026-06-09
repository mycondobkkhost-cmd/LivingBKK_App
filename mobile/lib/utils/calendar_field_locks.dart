import '../models/calendar_event.dart';

/// กฎ field lock — มนุษย์แก้แล้ว AI ห้ามทับ
abstract final class CalendarFieldLocks {
  static const human = 'human';

  static const editableFields = [
    'title',
    'description',
    'start_at',
    'end_at',
    'location_label',
    'owner_notes',
    'seeker_notes',
    'color_hint',
  ];

  static bool isLocked(Map<String, String> locks, String field) =>
      locks[field] == human;

  /// ล็อกฟิลด์ที่มนุษย์เปลี่ยนค่า
  static Map<String, String> lockChangedFields({
    required Map<String, String> existing,
    required Map<String, dynamic> before,
    required Map<String, dynamic> after,
  }) {
    final locks = Map<String, String>.from(existing);
    for (final field in editableFields) {
      final b = before[field];
      final a = after[field];
      if (b != a && a != null) {
        locks[field] = human;
      }
    }
    return locks;
  }

  static Map<String, dynamic> snapshot(CalendarEvent e) => {
        'title': e.title,
        'description': e.description,
        'start_at': e.startAt.toIso8601String(),
        'end_at': e.endAt.toIso8601String(),
        'location_label': e.locationLabel,
        'owner_notes': e.ownerNotes,
        'seeker_notes': e.seekerNotes,
        'color_hint': e.colorHint,
      };
}
