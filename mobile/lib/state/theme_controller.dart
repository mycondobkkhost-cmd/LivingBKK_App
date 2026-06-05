import 'package:flutter/material.dart';

import '../services/local_prefs_service.dart';

/// ThemeMode preference — light / dark / system
class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'app_theme_mode';

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final raw = await LocalPrefsService.instance.getString(_prefsKey);
    _mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    final stored = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await LocalPrefsService.instance.setString(_prefsKey, stored);
    notifyListeners();
  }

  String label(bool isEnglish) => switch (_mode) {
        ThemeMode.light => isEnglish ? 'Light' : 'สว่าง',
        ThemeMode.dark => isEnglish ? 'Dark' : 'มืด',
        ThemeMode.system => isEnglish ? 'System' : 'ตามระบบ',
      };
}
