import 'dart:html' as html;

/// Web — แจ้งเตือน OS ผ่าน Browser Notifications API (demo / PWA)
Future<bool> requestSystemPushPermission() async {
  if (!html.Notification.supported) return false;
  if (html.Notification.permission == 'granted') return true;
  if (html.Notification.permission == 'denied') return false;
  final perm = await html.Notification.requestPermission();
  return perm == 'granted';
}

Future<void> showSystemPushNotification({
  required String title,
  required String body,
  String? tag,
}) async {
  if (!html.Notification.supported) return;
  if (html.Notification.permission != 'granted') {
    final ok = await requestSystemPushPermission();
    if (!ok) return;
  }
  html.Notification(title, body: body, tag: tag);
}
