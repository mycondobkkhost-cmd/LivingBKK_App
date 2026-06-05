import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: 'assets/env');
    } catch (_) {
      // Demo mode when .env missing
    }
  }

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get isConfigured {
    final url = supabaseUrl;
    final key = supabaseAnonKey;
    if (url.isEmpty || key.isEmpty) return false;
    if (url.contains('YOUR_PROJECT') || url.contains('xxxxxxxx')) return false;
    if (_isPlaceholder(key)) return false;
    // JWT anon (eyJ…) หรือ publishable key ใหม่ (sb_publishable_…)
    return key.startsWith('eyJ') || key.startsWith('sb_publishable_');
  }

  static bool _isPlaceholder(String value) =>
      value.contains('your_') ||
      value.contains('YOUR_') ||
      value.endsWith('...') ||
      value == 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static bool get hasMapsKey =>
      googleMapsApiKey.isNotEmpty && !googleMapsApiKey.contains('YOUR_');

  /// URL หลักของเว็บแอป (ใช้ในลิงก์แชร์) — ไม่มี trailing slash
  /// ตัวอย่าง: https://livingbkk.netlify.app
  static String get webBaseUrl {
    final v = (dotenv.env['WEB_BASE_URL'] ?? '').trim();
    if (v.isEmpty) return '';
    return v.replaceAll(RegExp(r'/+$'), '');
  }

  /// ลิงก์แชร์ทรัพย์ — ใช้ WEB_BASE_URL หรือ path สัมพัทธ์
  static String listingSharePath(String listingId) => '/listing/$listingId';

  static String listingShareUrl(String listingId, {String? origin}) {
    final base = webBaseUrl;
    final path = listingSharePath(listingId);
    if (base.isNotEmpty) return '$base$path';
    final o = (origin ?? '').replaceAll(RegExp(r'/+$'), '');
    if (o.isNotEmpty) return '$o$path';
    return path;
  }

  static String _legalUrlFromEnv(String key, String pathSuffix) {
    final explicit = (dotenv.env[key] ?? '').trim();
    if (explicit.isNotEmpty) return explicit;
    final base = webBaseUrl;
    if (base.isEmpty) return '';
    return '$base$pathSuffix';
  }

  /// URL สาธารณะสำหรับ App Store Connect — ตั้ง PRIVACY_POLICY_URL หรือใช้ WEB_BASE_URL/legal/privacy.html
  static String get privacyPolicyUrl =>
      _legalUrlFromEnv('PRIVACY_POLICY_URL', '/legal/privacy.html');

  /// URL เงื่อนไขการใช้บริการ — ตั้ง TERMS_OF_SERVICE_URL หรือใช้ WEB_BASE_URL/legal/terms.html
  static String get termsOfServiceUrl =>
      _legalUrlFromEnv('TERMS_OF_SERVICE_URL', '/legal/terms.html');

  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  /// ช่วงทดลอง: กดเข้าตามบทบาทได้โดยไม่ต้องรหัส — ตั้ง `TRIAL_MODE=false` เมื่อเปิดใช้จริง
  static bool get trialMode {
    final v = (dotenv.env['TRIAL_MODE'] ?? 'true').trim().toLowerCase();
    return v != 'false' && v != '0' && v != 'off' && v != 'no';
  }

  /// เปิดให้เข้าแอปโดยไม่ต้องรหัส (บัญชีทดลอง) — ปิดเมื่อ production พร้อม
  static bool get allowPasswordlessLogin {
    final v = (dotenv.env['ALLOW_PASSWORDLESS_LOGIN'] ?? 'true').trim().toLowerCase();
    return trialMode || (v != 'false' && v != '0' && v != 'off' && v != 'no');
  }

  static bool get firebaseEnabled {
    if (_isPlaceholder(firebaseApiKey) ||
        _isPlaceholder(firebaseAppId) ||
        _isPlaceholder(firebaseMessagingSenderId) ||
        _isPlaceholder(firebaseProjectId)) {
      return false;
    }
    return firebaseApiKey.isNotEmpty &&
        firebaseAppId.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty &&
        firebaseProjectId.isNotEmpty;
  }

  /// Client config from assets/env (no checked-in google-services.json required for dev).
  static FirebaseOptions? get firebaseOptions {
    if (!firebaseEnabled) return null;
    return FirebaseOptions(
      apiKey: firebaseApiKey,
      appId: firebaseAppId,
      messagingSenderId: firebaseMessagingSenderId,
      projectId: firebaseProjectId,
    );
  }
}
