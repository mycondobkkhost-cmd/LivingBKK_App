/// คู่มือ error สำหรับศูนย์รายงานแอดมิน — ไทย + แนวทางแก้
class ErrorCatalogEntry {
  const ErrorCatalogEntry({
    required this.key,
    required this.titleTh,
    required this.titleEn,
    required this.summaryTh,
    required this.summaryEn,
    required this.fixStepsTh,
    required this.fixStepsEn,
    this.severity = ErrorSeverity.medium,
  });

  final String key;
  final String titleTh;
  final String titleEn;
  final String summaryTh;
  final String summaryEn;
  final List<String> fixStepsTh;
  final List<String> fixStepsEn;
  final ErrorSeverity severity;
}

enum ErrorSeverity { low, medium, high, critical }

class ErrorCatalog {
  ErrorCatalog._();

  static const unknownKey = 'unknown';

  static final Map<String, ErrorCatalogEntry> _entries = {
    'supabase_auth_invalid': ErrorCatalogEntry(
      key: 'supabase_auth_invalid',
      titleTh: 'ล็อกอินไม่สำเร็จ',
      titleEn: 'Sign-in failed',
      summaryTh: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง หรือบัญชียังไม่ยืนยันอีเมล',
      summaryEn: 'Invalid credentials or email not confirmed',
      fixStepsTh: [
        'ลองสมัครบัญชีใหม่หรือรีเซ็ตรหัสผ่าน',
        'ใน Supabase → Auth → ปิด Confirm email ช่วงทดลอง',
        'ตรวจว่า seed หรือสมัครสำเร็จแล้ว',
      ],
      fixStepsEn: [
        'Try sign-up or password reset',
        'Supabase Auth → disable Confirm email for testing',
        'Verify account exists after seed/sign-up',
      ],
      severity: ErrorSeverity.medium,
    ),
    'supabase_network': ErrorCatalogEntry(
      key: 'supabase_network',
      titleTh: 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้',
      titleEn: 'Cannot reach server',
      summaryTh: 'อินเทอร์เน็ตขาด หรือ Supabase URL/key ผิด',
      summaryEn: 'Network issue or wrong Supabase URL/key',
      fixStepsTh: [
        'ตรวจ Wi‑Fi / สัญญาณมือถือ',
        'รัน ./scripts/sync-env.sh แล้ว build ใหม่',
        'เปิด Supabase Dashboard ว่าโปรเจกต์ยังทำงาน',
      ],
      fixStepsEn: [
        'Check network connection',
        'Run sync-env.sh and rebuild',
        'Verify Supabase project is active',
      ],
      severity: ErrorSeverity.high,
    ),
    'supabase_rls_denied': ErrorCatalogEntry(
      key: 'supabase_rls_denied',
      titleTh: 'ไม่มีสิทธิ์เข้าถึงข้อมูล',
      titleEn: 'Permission denied',
      summaryTh: 'กฎความปลอดภัย (RLS) ไม่อนุญาตการอ่าน/เขียน',
      summaryEn: 'Row-level security blocked the operation',
      fixStepsTh: [
        'ตรวจว่าล็อกอินด้วยบทบาทที่ถูกต้อง',
        'รัน supabase db push ให้ migration ครบ',
        'แอดมิน: ตรวจ policy ในตารางที่ error',
      ],
      fixStepsEn: [
        'Sign in with correct role',
        'Run supabase db push for latest migrations',
        'Admin: review RLS policies on affected table',
      ],
      severity: ErrorSeverity.high,
    ),
    'maps_key_missing': ErrorCatalogEntry(
      key: 'maps_key_missing',
      titleTh: 'แผนที่ Google ยังไม่ตั้งค่า',
      titleEn: 'Google Maps not configured',
      summaryTh: 'ไม่มี GOOGLE_MAPS_API_KEY — แอปใช้แผนที่สำรอง (OSM)',
      summaryEn: 'Missing API key — fallback map is used',
      fixStepsTh: [
        'ใส่ GOOGLE_MAPS_API_KEY ใน .env.local',
        'รัน ./scripts/sync-env.sh และ build ใหม่',
        'เปิด Maps API ใน Google Cloud Console',
      ],
      fixStepsEn: [
        'Set GOOGLE_MAPS_API_KEY in .env.local',
        'Run sync-env.sh and rebuild',
        'Enable Maps API in Google Cloud',
      ],
      severity: ErrorSeverity.low,
    ),
    'trial_mode_blocked': ErrorCatalogEntry(
      key: 'trial_mode_blocked',
      titleTh: 'โหมดทดลอง — ยังไม่บันทึก',
      titleEn: 'Trial mode — not saved',
      summaryTh: 'ผู้ใช้ทดลอง — การบันทึกถูกบล็อกตามนโยบาย',
      summaryEn: 'Trial user action was blocked by design',
      fixStepsTh: [
        'ถ้าต้องการบันทึกจริง: ตั้ง TRIAL_MODE=false',
        'ให้ผู้ใช้ล็อกอินจริง',
        'อธิบายผู้ใช้ว่าเป็นพฤติกรรมปกติของโหมดทดลอง',
      ],
      fixStepsEn: [
        'Set TRIAL_MODE=false for production',
        'Ask user to sign in for real',
        'Explain expected trial behavior to user',
      ],
      severity: ErrorSeverity.low,
    ),
    'listing_create_failed': ErrorCatalogEntry(
      key: 'listing_create_failed',
      titleTh: 'ลงประกาศไม่สำเร็จ',
      titleEn: 'Listing create failed',
      summaryTh: 'ข้อมูลไม่ครบ รูปอัปโหลดไม่ได้ หรือ moderation ปฏิเสธ',
      summaryEn: 'Validation, image upload, or moderation issue',
      fixStepsTh: [
        'ตรวจฟิลด์บังคับและราคา',
        'ลองอัปโหลดรูปใหม่ (ขนาดเล็กลง)',
        'แอดมิน: ดูแท็บ Moderation',
      ],
      fixStepsEn: [
        'Check required fields and price',
        'Retry smaller images',
        'Admin: check Moderation tab',
      ],
      severity: ErrorSeverity.medium,
    ),
    'image_upload_failed': ErrorCatalogEntry(
      key: 'image_upload_failed',
      titleTh: 'อัปโหลดรูปไม่สำเร็จ',
      titleEn: 'Image upload failed',
      summaryTh: 'Storage bucket หรือรูปใหญ่เกิน / รูปแบบไม่รองรับ',
      summaryEn: 'Storage or file size/format issue',
      fixStepsTh: [
        'ลดขนาดรูปก่อนอัปโหลด',
        'ตรวจ Supabase Storage policy',
        'ลองเครือข่ายอื่น',
      ],
      fixStepsEn: [
        'Resize image before upload',
        'Check Supabase Storage policies',
        'Try another network',
      ],
      severity: ErrorSeverity.medium,
    ),
    'chat_send_failed': ErrorCatalogEntry(
      key: 'chat_send_failed',
      titleTh: 'ส่งข้อความแชทไม่ได้',
      titleEn: 'Chat message failed',
      summaryTh: 'แชท backend หรือ Edge Function ไม่ตอบ',
      summaryEn: 'Chat backend or Edge Function error',
      fixStepsTh: [
        'รัน ./scripts/deploy-all.sh',
        'ตรวจ migration chat_backend',
        'แอดมิน: ดูแท็บแชท',
      ],
      fixStepsEn: [
        'Run deploy-all.sh',
        'Verify chat migrations',
        'Admin: check Chats tab',
      ],
      severity: ErrorSeverity.medium,
    ),
    'analytics_track_failed': ErrorCatalogEntry(
      key: 'analytics_track_failed',
      titleTh: 'ส่งสถิติไม่สำเร็จ',
      titleEn: 'Analytics track failed',
      summaryTh: 'ไม่กระทบผู้ใช้โดยตรง — ตัวเลขรายงานอาจไม่ครบ',
      summaryEn: 'Non-blocking — report numbers may be incomplete',
      fixStepsTh: [
        'Deploy analytics-track + rollup cron',
        'รัน db push migration analytics',
        'กด「รวมตัวเลขใหม่」ในแท็บรายงาน',
      ],
      fixStepsEn: [
        'Deploy analytics-track and rollup cron',
        'Run analytics migrations',
        'Press Refresh rollups in Reports',
      ],
      severity: ErrorSeverity.low,
    ),
    unknownKey: ErrorCatalogEntry(
      key: unknownKey,
      titleTh: 'ข้อผิดพลาดไม่ทราบชนิด',
      titleEn: 'Unknown error',
      summaryTh: 'ยังไม่มีคู่มือสำหรับ error นี้ — ดูข้อความดิบด้านล่าง',
      summaryEn: 'No catalog entry — see raw message below',
      fixStepsTh: [
        'จดเวลา + หน้าจอที่เกิด',
        'ลองรีเฟรชหรือล็อกอินใหม่',
        'ส่ง raw message ให้ทีม dev',
      ],
      fixStepsEn: [
        'Note time and screen',
        'Refresh or sign in again',
        'Send raw message to dev team',
      ],
      severity: ErrorSeverity.medium,
    ),
  };

  static ErrorCatalogEntry resolve(String? key) =>
      _entries[key ?? unknownKey] ?? _entries[unknownKey]!;

  static String classifyFromMessage(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login') ||
        m.contains('invalid_credentials') ||
        m.contains('email not confirmed')) {
      return 'supabase_auth_invalid';
    }
    if (m.contains('socket') ||
        m.contains('network') ||
        m.contains('failed host lookup') ||
        m.contains('connection')) {
      return 'supabase_network';
    }
    if (m.contains('row-level security') ||
        m.contains('permission denied') ||
        m.contains('42501')) {
      return 'supabase_rls_denied';
    }
    if (m.contains('trial') && m.contains('ไม่บันทึก')) {
      return 'trial_mode_blocked';
    }
    if (m.contains('storage') && m.contains('upload')) {
      return 'image_upload_failed';
    }
    if (m.contains('listing') && (m.contains('create') || m.contains('insert'))) {
      return 'listing_create_failed';
    }
    if (m.contains('chat')) {
      return 'chat_send_failed';
    }
    if (m.contains('analytics')) {
      return 'analytics_track_failed';
    }
    return unknownKey;
  }

  static List<ErrorCatalogEntry> get all =>
      _entries.values.where((e) => e.key != unknownKey).toList();
}
