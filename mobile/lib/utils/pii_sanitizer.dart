/// ตัดข้อมูลติดต่อลูกค้าก่อนส่งให้เจ้าของ/เอเจ้นท์ (กฎ blind intermediation)
class PiiSanitizer {
  static final _phoneRe = RegExp(
    r'(\+?66|0)[\s\-]?[0-9]{1,2}[\s\-]?[0-9]{3,4}[\s\-]?[0-9]{4}',
  );
  static final _lineRe = RegExp(
    r'(line\s*id|ไลน์|line)[\s:]*[@]?[a-z0-9._\-]{4,}',
    caseSensitive: false,
  );

  static String censorPhone(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return '***';
    return '${digits.substring(0, 2)}x-xxx-${digits.substring(digits.length - 4)}';
  }

  static Map<String, dynamic> sanitizeQualification(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    final out = <String, dynamic>{};
    const dropKeys = {
      'customer_phone_last4',
      'line_id',
      'line',
      'phone',
      'seeker_phone',
      'contact_phone',
      'lineId',
    };
    for (final e in raw.entries) {
      if (dropKeys.contains(e.key)) continue;
      final v = e.value;
      if (v is String) {
        out[e.key] = stripContactFromText(v);
      } else {
        out[e.key] = v;
      }
    }
    return out;
  }

  static String stripContactFromText(String text) {
    var t = text;
    t = t.replaceAll(_phoneRe, '[เบอร์ถูกซ่อน]');
    t = t.replaceAll(_lineRe, '[Line ถูกซ่อน]');
    return t.trim();
  }

  /// สรุปโปรไฟล์ลูกค้าสำหรับเจ้าของ — ไม่มีเบอร์/ไลน์เต็ม
  static String ownerSafeLeadSummary(
    Map<String, dynamic> lead, {
    String? viewingSchedule,
    String? appointmentDate,
    String? appointmentSlot,
  }) {
    final qual = sanitizeQualification(
      lead['qualification_json'] as Map<String, dynamic>?,
    );
    final lines = <String>[
      'ชื่อเล่น: ${lead['seeker_nickname'] ?? '—'}',
      'เบอร์: ${censorPhone(lead['seeker_phone']?.toString())}',
      if (lead['occupation'] != null) 'อาชีพ: ${lead['occupation']}',
      if (lead['move_plan'] != null) 'แผนย้ายเข้า: ${lead['move_plan']}',
      if (lead['contract_duration'] != null)
        'สัญญา: ${lead['contract_duration']}',
      if (lead['budget'] != null) 'งบ: ${lead['budget']}',
      if (viewingSchedule != null && viewingSchedule.isNotEmpty)
        'ลูกค้าขอนัด: $viewingSchedule',
      if (appointmentDate != null && appointmentSlot != null)
        'แอดมินเสนอนัด: $appointmentDate · $appointmentSlot',
    ];
    for (final e in qual.entries) {
      final label = e.key.replaceAll('_', ' ');
      final val = e.value?.toString() ?? '';
      if (val.isEmpty) continue;
      lines.add('$label: ${stripContactFromText(val)}');
    }
    return lines.join('\n');
  }
}
