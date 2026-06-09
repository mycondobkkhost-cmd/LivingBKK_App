import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  /// ลงประกาศจริง — ต้องมีบัญชี Supabase (โหมดทดลองไม่พอ)
  bool get canCreateListing => isRealSupabaseSession;

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
    // รอให้ผู้เรียกตั้ง role + navigate ก่อน — กัน router เด้งไป `/` ก่อนสิทธิ์แอดมินพร้อม
    Future.microtask(notifyListeners);
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

  static bool get _isNativeIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Native iOS: Sign in with Apple + `signInWithIdToken`.
  /// Web/Android: Supabase OAuth redirect.
  /// Returns `true` when a session is established in-process (native iOS).
  Future<bool> signInWithApple() async {
    if (_client == null) {
      throw Exception('ตั้งค่า Supabase ใน assets/env ก่อน');
    }
    _trial = null;

    if (_isNativeIos) {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Apple Sign In — ไม่ได้รับ identity token');
      }
      await _client!.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      await _syncProfileRole();
      await NotificationService.instance.registerIfPossible();
      notifyListeners();
      return true;
    }

    await _client!.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: _oauthRedirect,
    );
    return false;
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

  /// ลบบัญชีถาวร (Apple Guideline 5.1.1) — เรียก Edge Function delete-account
  Future<void> deleteAccount() async {
    if (_client == null || currentUser == null) {
      throw Exception('ต้องล็อกอินก่อนลบบัญชี');
    }
    if (isTrialSignedIn) {
      throw Exception('โหมดทดลอง — ไม่มีบัญชีจริงให้ลบ');
    }

    final res = await _client!.functions.invoke(
      'delete-account',
      body: {'confirm': true},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      if (data['ok'] == true) {
        await NotificationService.instance.clearOnSignOut();
        await _client!.auth.signOut();
        notifyListeners();
        return;
      }
      final err = data['error']?.toString() ?? 'delete_failed';
      throw Exception(err);
    }
    throw Exception('delete_failed');
  }

  Future<String?> fetchProfileRole() async {
    final access = await fetchProfileAccess();
    return access.role;
  }

  Future<({String? role, String? staffSlug})> fetchProfileAccess() async {
    if (isTrialSignedIn) {
      return (role: trialRole, staffSlug: null);
    }
    if (_client == null || currentUser == null) {
      return (role: null, staffSlug: null);
    }

    String? metaRole;
    final rawMeta = currentUser!.userMetadata?['role'];
    if (rawMeta is String && rawMeta.isNotEmpty) metaRole = rawMeta;

    String? metaSlug;
    final rawSlug = currentUser!.userMetadata?['staff_slug'];
    if (rawSlug is String && rawSlug.isNotEmpty) metaSlug = rawSlug;

    try {
      final row = await _client!
          .from('profiles')
          .select('role, staff_slug')
          .eq('id', currentUser!.id)
          .maybeSingle();
      final dbRole = row?['role'] as String?;
      final dbSlug = row?['staff_slug'] as String?;
      if (dbRole == 'admin') {
        return (role: dbRole, staffSlug: dbSlug ?? metaSlug);
      }
      if (metaRole == 'admin') {
        return (role: metaRole, staffSlug: dbSlug ?? metaSlug);
      }
      if (dbRole != null && dbRole.isNotEmpty) {
        return (role: dbRole, staffSlug: dbSlug ?? metaSlug);
      }
    } catch (_) {
      return (role: metaRole, staffSlug: metaSlug);
    }
    return (role: metaRole, staffSlug: metaSlug);
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
    if (msg.contains('admin_delete_blocked')) {
      return 'บัญชีผู้ดูแลระบบ — ติดต่อทีมเพื่อลบบัญชี';
    }
    if (msg.contains('confirmation_required')) {
      return 'ต้องยืนยันการลบบัญชี';
    }
    if (msg.contains('delete_failed') || msg.contains('delete-account')) {
      return 'ลบบัญชีไม่สำเร็จ — ลองใหม่หรือติดต่อ support';
    }
    return 'เข้าสู่ระบบไม่สำเร็จ: $error';
  }
}
