import 'local_prefs_service.dart';
import '../utils/admin_routing.dart';

/// เก็บปลายทางหลัง OAuth / ล็อกอินโซเชียล — กันหลุด `?redirect=` ตอนเด้งออกนอกแอป
abstract final class PendingAuthRedirect {
  static const _prefKey = 'pending_auth_redirect';

  static String? _memory;

  static String? peek() => _memory;

  static Future<void> hydrate() async {
    if (_memory != null) return;
    final stored = await LocalPrefsService.instance.getString(_prefKey);
    _memory = _safe(stored);
  }

  static Future<void> save(String? path) async {
    final safe = _safe(path);
    _memory = safe;
    if (safe == null) {
      await LocalPrefsService.instance.remove(_prefKey);
      return;
    }
    await LocalPrefsService.instance.setString(_prefKey, safe);
  }

  /// อ่านแล้วล้าง — ใช้ใน GoRouter (sync)
  static String? consume() {
    final value = _memory;
    _memory = null;
    // ignore: discarded_futures
    LocalPrefsService.instance.remove(_prefKey);
    return value;
  }

  static String? _safe(String? redirect) {
    if (redirect == null || redirect.isEmpty) return null;
    if (redirect.startsWith('//')) return null;
    final uri = Uri.tryParse(redirect);
    if (uri == null || uri.hasScheme) return null;
    final path = uri.path.isNotEmpty ? uri.path : redirect.split('?').first;
    if (!path.startsWith('/') || path.startsWith('//')) return null;
    if (isAdminRoute(path)) return null;
    return redirect;
  }
}
