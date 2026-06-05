import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/local_prefs_service.dart';

/// ควบคุมว่าเข้าแอปได้หรือยัง — ต้องล็อกอินหรือสมัครสมาชิก
class SessionGate extends ChangeNotifier {
  SessionGate();

  static SessionGate? instance;

  static const _prefKey = 'session_gate_mode';

  bool _loaded = false;

  bool get loaded => _loaded;

  bool get canEnterApp => AuthService.instance.isSignedIn;

  Future<void> load() async {
    await LocalPrefsService.instance.getString(_prefKey);
    _loaded = true;
    notifyListeners();
  }

  Future<void> markAuthenticated() async {
    await LocalPrefsService.instance.setString(_prefKey, 'auth');
    notifyListeners();
  }

  Future<void> resetToWelcome() async {
    await LocalPrefsService.instance.remove(_prefKey);
    notifyListeners();
  }
}
