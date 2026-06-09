import 'dart:html' as html;

/// Path จาก address bar จริง (แม่นกว่า Uri.base ใน embedded browser)
String webBrowserPath() {
  try {
    final path = html.window.location.pathname ?? '';
    if (path.isNotEmpty) return path;
    final hash = html.window.location.hash;
    if (hash.startsWith('#/')) {
      final raw = hash.substring(1);
      return Uri.parse(raw).path;
    }
  } catch (_) {}
  return Uri.base.path;
}
