import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shell/main_shell_scope.dart';
import '../services/in_app_notification_hub.dart';

/// สลับแท็บ MainShell — ใช้ได้ทั้งใน shell และจากหน้าที่ push ทับ (เช่น browse)
abstract final class ShellTabNavigation {
  static int currentIndex = 0;

  static void goToTab(BuildContext context, int index) {
    currentIndex = index;
    final scope = MainShellScope.maybeOf(context);
    if (scope != null) {
      scope.selectTab(index);
      return;
    }
    InAppNotificationHub.instance.requestShellTab(index);
    context.go('/');
  }
}
