import 'package:flutter/material.dart';

import '../services/local_prefs_service.dart';

/// ภาษาแสดงผลในแอป (ไทย / อังกฤษ)
class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  /// ให้ service ที่ไม่มี BuildContext อ่านภาษาปัจจุบัน
  static LocaleController? instance;

  Locale _locale = const Locale('th');

  Locale get locale => _locale;
  bool get isEnglish => _locale.languageCode == 'en';

  Future<void> load() async {
    final code = await LocalPrefsService.instance.getString(_prefsKey);
    if (code == 'en' || code == 'th') {
      _locale = Locale(code!);
      notifyListeners();
    }
  }

  Future<void> setEnglish(bool english) async {
    final next = english ? const Locale('en') : const Locale('th');
    if (next == _locale) return;
    _locale = next;
    await LocalPrefsService.instance.setString(_prefsKey, next.languageCode);
    notifyListeners();
  }

  void toggle() => setEnglish(!isEnglish);
}
