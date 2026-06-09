import 'package:flutter/material.dart';

import '../services/in_app_notification_hub.dart';

/// แจ้งเตือนด้านบน — ใช้แบนเนอร์กลางแอป (ทำงานทั้งหน้าบ้านและหลังบ้าน)
abstract final class AppNotice {
  static const Duration duration = Duration(seconds: 7);

  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? foregroundColor,
    bool topBanner = false,
  }) {
    if (message.trim().isEmpty) return;
    if (topBanner) {
      InAppNotificationHub.instance.showMessage(
        message,
        displayDuration: duration,
      );
      return;
    }
    snack(context, message);
  }

  static void snack(BuildContext context, String message) {
    if (message.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void error(BuildContext context, String message) {
    snack(context, message);
  }
}
