/// Native (iOS/Android) — push นอกแอปผ่าน FCM จาก Edge Function
Future<bool> requestSystemPushPermission() async => false;

Future<void> showSystemPushNotification({
  required String title,
  required String body,
  String? tag,
}) async {}
