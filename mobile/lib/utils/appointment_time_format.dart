import '../models/appointment.dart';

/// แสดงเวลานัด — เอาเฉพาะเวลาเริ่ม (ไม่แสดงช่วงสิ้นสุด)
String formatAppointmentDisplayTime(String timeSlot) {
  final t = timeSlot.trim();
  if (t.isEmpty) return t;
  final range = RegExp(r'^(\d{1,2}:\d{2})\s*-\s*\d{1,2}:\d{2}').firstMatch(t);
  if (range != null) {
    final start = range.group(1)!;
    return t.contains('น.') ? '$start น.' : start;
  }
  return t;
}

/// วันเวลานัดจากวันที่ + time_slot
DateTime? appointmentScheduledDateTime(DateTime date, String timeSlot) {
  final display = formatAppointmentDisplayTime(timeSlot);
  final cleaned = display.replaceAll('น.', '').trim();
  final parts = cleaned.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0].trim());
  final minute = int.tryParse(parts[1].replaceAll(RegExp(r'\D'), '').trim());
  if (hour == null || minute == null) return null;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

/// วัน (อังคาร) ที่ 9/6/2569 — สำหรับข้อความยืนยันนัดลูกค้า
String formatAppointmentCustomerDateLine(DateTime date, {required bool isEn}) {
  if (isEn) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final wd = days[date.weekday - 1];
    return '$wd ${date.day}/${date.month}/${date.year}';
  }
  const days = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];
  final y = date.year + 543;
  return 'วัน (${days[date.weekday - 1]}) ที่ ${date.day}/${date.month}/$y';
}

extension AppointmentTimeDisplay on Appointment {
  String get displayTimeSlot => formatAppointmentDisplayTime(timeSlot);

  DateTime? get scheduledDateTime =>
      appointmentScheduledDateTime(scheduledDate, timeSlot);
}
