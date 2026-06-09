import 'package:flutter/foundation.dart';

import '../services/local_prefs_service.dart';

/// มุมมองหลังบ้านบนเว็บ (สลับได้เฉพาะ [kIsWeb])
///
/// - [desktop] — ใช้งานบนคอมเต็มจอจริง (sidebar + แผงเนื้อหา)
/// - [mobile] — เลย์เอาต์แบบมือถือ (เมนู ☰ ไม่มี sidebar)
///
/// แอปติดตั้งบนโทรศัพท์ใช้เลย์เอาต์แอปเสมอ ไม่มีสวิตช์นี้
enum AdminViewportMode {
  desktop,
  mobile,
}

class AdminViewportController extends ChangeNotifier {
  static const _prefsKey = 'admin_viewport_mode';

  static AdminViewportController? instance;

  AdminViewportMode _mode = AdminViewportMode.desktop;

  AdminViewportMode get mode => _mode;

  bool get isDesktop => _mode == AdminViewportMode.desktop;

  Future<void> load() async {
    final raw = await LocalPrefsService.instance.getString(_prefsKey);
    _mode = switch (raw) {
      'mobile' => AdminViewportMode.mobile,
      'desktop' => AdminViewportMode.desktop,
      _ => AdminViewportMode.desktop,
    };
    notifyListeners();
  }

  Future<void> setMode(AdminViewportMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await LocalPrefsService.instance.setString(
      _prefsKey,
      mode == AdminViewportMode.mobile ? 'mobile' : 'desktop',
    );
  }

  String label(bool isEnglish) => switch (_mode) {
        AdminViewportMode.desktop => isEnglish ? 'Full desktop' : 'คอมเต็มจอ',
        AdminViewportMode.mobile => isEnglish ? 'App view' : 'แบบแอป',
      };
}
