import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../models/trial_persona.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

/// ล็อกอินจริง (Supabase) หรือบทบาททดลองใน memory (TRIAL_MODE)
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();
  factory AuthService() => instance;

  SupabaseClient? get _client => SupabaseService.client;

  TrialPersona? _trial;

  Stream<AuthState> get authStateChanges {
    if (_client == null) {
      return Stream.value(AuthState(AuthChangeEvent.signedOut, null));
    }
    return _client!.auth.onAuthStateChange;
  }

  User? get currentUser => _client?.auth.currentUser;

  bool get isTrialSignedIn => _trial != null;

  String? get trialRole => _trial?.role;

  String? get trialDisplayName => _trial?.displayName;

  bool get isTrialAdmin => trialRole == 'admin';

  /// ไม่ยิง insert/update จริง — UI ยังทำงานได้
  bool get trialSimulatesBackend => Env.trialMode && isTrialSignedIn;

  static const trialWriteHint =
      'โหมดทดลอง — ยังไม่บันทึกลงระบบจริง (ปิด TRIAL_MODE เมื่อพร้อม)';

  String? get effectiveUserId => _trial?.userId ?? currentUser?.id;

  String? get displayEmail =>
      _trial?.email ?? currentUser?.email ?? 'ผู้ใช้ทดสอบ (Demo)';

  bool get isSignedIn => isTrialSignedIn || currentUser != null;

  bool get isRealSupabaseSession => currentUser != null && !isTrialSignedIn;

  void bindAuthListener() {
    final c = _client;
    if (c == null) return;
    c.auth.onAuthStateChange.listen((data) {
      if (data.session != null) _trial = null;
      notifyListeners();
    });
  }

  /// บัญชีทดลองเดียว — สลับมุมมองที่หน้าแรก
  Future<void> signInAsTrial({String role = 'seeker'}) async {
    if (!Env.allowPasswordlessLogin) {
      throw Exception('ปิดการเข้าแบบไม่ต้องรหัสแล้ว — ใช้ล็อกอินด้วยอีเมล/รหัสผ่าน');
    }
    final persona = TrialPersona.byRole(role) ?? TrialPersona.personas.first;
    if (currentUser != null) {
      await NotificationService.instance.clearOnSignOut();
      await _client?.auth.signOut();
    }
    _trial = persona;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    if (_client == null) {
      throw Exception('ตั้งค่า Supabase ใน assets/env ก่อน');
    }
    _trial = null;
    await _client!.auth.signInWithPassword(email: email, password: password);
    await _syncProfileRole();
    await NotificationService.instance.registerIfPossible();
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? phone,
    String? displayName,
  }) async {
    if (_client == null) {
      throw Exception('ตั้งค่า Supabase ใน assets/env ก่อน');
    }
    _trial = null;
    await _client!.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'seeker',
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
      },
    );
    await _syncProfileRole();
    await NotificationService.instance.registerIfPossible();
    notifyListeners();
  }

  /// OTP เบอร์โทร — ต้องเปิด Phone provider ใน Supabase + SMS (Twilio ฯลฯ)
  Future<void> requestPhoneOtp(String phone) async {
    if (_client == null) {
      throw Exception('ตั้งค่า Supabase ใน assets/env ก่อน');
    }
    final normalized = phone.startsWith('+')
        ? phone.replaceAll(' ', '')
        : '+66${phone.replaceFirst(RegExp(r'^0'), '').replaceAll(' ', '')}';
    await _client!.auth.signInWithOtp(phone: normalized);
  }

  String get _oauthRedirect {
    final base = Env.webBaseUrl;
    if (base.isNotEmpty) return base;
    if (kIsWeb) return Uri.base.origin;
    return 'com.livingbkk.livingbkk://login-callback/';
  }

  Future<void> signInWithGoogle() async {
    if (_client == null) {
      throw Exception('ตั้งค่า Supabase ใน assets/env ก่อน');
    }
    _trial = null;
    await _client!.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _oauthRedirect,
    );
  }

  Future<void> signInWithFacebook() async {
    if (_client == null) {
      throw Exception('ตั้งค่า Supabase ใน assets/env ก่อน');
    }
    _trial = null;
    await _client!.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: _oauthRedirect,
    );
  }

  Future<void> resetPassword(String email) async {
    if (_client == null) {
      throw Exception('ตั้งค่า Supabase ใน assets/env ก่อน');
    }
    await _client!.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _oauthRedirect,
    );
  }

  Future<void> signOut() async {
    if (_trial != null) {
      _trial = null;
      notifyListeners();
      return;
    }
    await NotificationService.instance.clearOnSignOut();
    await _client?.auth.signOut();
    notifyListeners();
  }

  Future<String?> fetchProfileRole() async {
    if (isTrialSignedIn) return trialRole;
    if (_client == null || currentUser == null) return null;
    try {
      final row = await _client!
          .from('profiles')
          .select('role')
          .eq('id', currentUser!.id)
          .maybeSingle();
      return row?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// เฉพาะแอดมินระบบ — มุมมองลูกค้า/เอเจนซี่/เจ้าของสลับที่หน้าแรก ไม่เขียน DB
  Future<void> updateProfileRole(String role) async {
    if (_client == null || currentUser == null) return;
    if (role != 'admin') return;
    await _client!
        .from('profiles')
        .update({'role': role})
        .eq('id', currentUser!.id);
  }

  Future<void> _syncProfileRole() async {
    await fetchProfileRole();
  }

  static bool get authRequired => Env.isConfigured && !Env.trialMode;

  static String friendlyMessage(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('ปิดโหมดทดลอง')) {
      return 'ปิดโหมดทดลองแล้ว — ใช้ล็อกอินด้วยอีเมลและรหัสผ่าน';
    }
    if (msg.contains('invalid login') || msg.contains('invalid_credentials')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง — ลองสมัครใหม่หรือตรวจคำพิมพ์';
    }
    if (msg.contains('phone') && msg.contains('provider')) {
      return 'ยังไม่ได้เปิด SMS OTP ใน Supabase — ติดต่อทีมตั้งค่า Twilio';
    }
    if (msg.contains('email not confirmed')) {
      return 'ต้องยืนยันอีเมลก่อน — หรือปิด Confirm email ใน Supabase (ดู docs/เข้าใจ-ทดลอง-vs-ใช้จริง.md)';
    }
    if (msg.contains('user already registered')) {
      return 'อีเมลนี้สมัครแล้ว — กดเข้าสู่ระบบแทน';
    }
    if (msg.contains('password') && msg.contains('short')) {
      return 'รหัสผ่านสั้นเกินไป — ใช้อย่างน้อย 6 ตัว';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('failed host')) {
      return 'เน็ตหรือเซิร์ฟเวอร์ไม่ตอบ — ตรวจ Wi‑Fi / ฮอตสปอต';
    }
    if (msg.contains('ตั้งค่า supabase')) {
      return 'ยังไม่ต่อระบบหลังบ้าน — ดู docs/เข้าใจ-ทดลอง-vs-ใช้จริง.md';
    }
    return 'เข้าสู่ระบบไม่สำเร็จ: $error';
  }
}
