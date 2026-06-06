/// เลขท้ายเบอร์โทร — ใช้รีเช็คข้อมูลซ้ำ (ไม่เก็บเบอร์เต็ม)
abstract final class PhoneSuffixUtil {
  static String normalize(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  static String? last4(String? phone) {
    final digits = normalize(phone ?? '');
    if (digits.length < 4) return null;
    return digits.substring(digits.length - 4);
  }

  static bool isValidLast4Input(String raw) {
    final d = normalize(raw);
    return d.length == 4;
  }

  static String formatLast4Input(String raw) {
    return normalize(raw).substring(0, normalize(raw).length.clamp(0, 4));
  }
}
