import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/admin_viewport_controller.dart';

/// ความกว้างขั้นต่ำสำหรับ layout แอดมินแบบ split-pane บนคอม
const kAdminDesktopMinWidth = 900.0;

const kAdminInboxPaneWidth = 380.0;

bool isAdminPath(String path) => path.startsWith('/admin');

bool isAdminConsolePath(String path) =>
    path == '/admin/console' || path.startsWith('/admin/console/');

/// หลังบ้านบนเว็บ — console / desktop เต็มจอ; โหมด「แบบแอป」ใช้กรอบ iPhone
bool adminShellFullWidth(
  String path, {
  Map<String, String> query = const {},
}) {
  if (!isAdminPath(path)) return false;
  if (!kIsWeb) return true;
  if (query['desktop'] == '1') return true;
  if (isAdminConsolePath(path)) return true;
  final mode = AdminViewportController.instance?.mode;
  if (mode == AdminViewportMode.mobile) return false;
  return true;
}

bool isAdminDesktopLayout(BuildContext context) => useAdminSplitPane(context);

/// แยก inbox | แชท (โหมดคอม)
bool useAdminSplitPane(BuildContext context) {
  if (kIsWeb) {
    return AdminViewportController.instance?.mode !=
        AdminViewportMode.mobile;
  }
  return MediaQuery.sizeOf(context).width >= kAdminDesktopMinWidth;
}

/// Sidebar ซ้าย + เลย์เอาต์กว้าง
bool useAdminWideShell(BuildContext context) {
  if (kIsWeb) {
    return AdminViewportController.instance?.mode !=
        AdminViewportMode.mobile;
  }
  return MediaQuery.sizeOf(context).width >= kAdminShellBreakpoint;
}

/// ใช้ใน admin_shell_scaffold — ค่าเดียวกับ breakpoint sidebar
const double kAdminShellBreakpoint = 900.0;

/// เปิด console บนเว็บแทนหน้าแชทมือถือ
bool shouldUseAdminConsole(String path) =>
    kIsWeb && path.startsWith('/admin/chat/');

/// ไอคอนแสดงโหมดที่กำลังใช้ (ไม่ใช่ปลายทางที่จะสลับไป)
IconData adminViewportModeIcon(AdminViewportMode mode) => switch (mode) {
      AdminViewportMode.mobile => Icons.smartphone_outlined,
      AdminViewportMode.desktop => Icons.desktop_windows_outlined,
    };
