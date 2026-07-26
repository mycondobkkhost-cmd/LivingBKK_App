import 'package:flutter/foundation.dart';

import '../services/local_prefs_service.dart';

/// กรอบจำลองมือถือบนเว็บ — สำหรับทดสอบ UI หลังบ้าน
///
/// Layout จริงอิงอุปกรณ์ผ่าน [useAdminDesktopLayout] ใน `admin_desktop.dart`
/// ค่านี้เปิดเฉพาะกรอบ iPhone กลางจอเมื่อทดสอบบนคอม
class AdminViewportController extends ChangeNotifier {
  static const _prefsKey = 'admin_phone_frame_preview';

  static AdminViewportController? instance;

  bool _phoneFramePreview = false;

  bool get phoneFramePreview => _phoneFramePreview;

  Future<void> load() async {
    final raw = await LocalPrefsService.instance.getString(_prefsKey);
    _phoneFramePreview = raw == '1';
    notifyListeners();
  }

  Future<void> setPhoneFramePreview(bool enabled) async {
    if (_phoneFramePreview == enabled) return;
    _phoneFramePreview = enabled;
    notifyListeners();
    await LocalPrefsService.instance.setString(
      _prefsKey,
      enabled ? '1' : '0',
    );
  }

  Future<void> togglePhoneFramePreview() =>
      setPhoneFramePreview(!_phoneFramePreview);

  String label(bool isEnglish) => _phoneFramePreview
      ? (isEnglish ? 'Phone frame on' : 'กรอบมือถือเปิด')
      : (isEnglish ? 'Phone frame off' : 'กรอบมือถือปิด');
}
