import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ความกว้างขั้นต่ำสำหรับ layout แอดมินแบบ split-pane บนคอม
const kAdminDesktopMinWidth = 900.0;

const kAdminInboxPaneWidth = 360.0;

const kAdminContextPaneMinWidth = 1050.0;

bool isAdminPath(String path) => path.startsWith('/admin');

bool isAdminConsolePath(String path) =>
    path == '/admin/console' || path.startsWith('/admin/console/');

/// โครงสร้างคอม (rail + subnav + เนื้อหาเต็ม) — เฉพาะเว็บบนจอกว้าง
///
/// - มือถือ / แท็บเล็ต / iPad (แอป native): โหมดมือถือเสมอ
/// - เว็บบนคอม (กว้างพอ): โหมดคอมเท่านั้น — ไม่มีสวิตช์สลับมือถือ
bool useAdminDesktopLayout(BuildContext context) {
  if (!kIsWeb) return false;
  return MediaQuery.sizeOf(context).width >= kAdminShellBreakpoint;
}

/// หลังบ้านบนเว็บ — ใช้พื้นที่เต็มจอ
bool adminShellFullWidth(
  String path, {
  Map<String, String> query = const {},
}) {
  return isAdminPath(path);
}

bool isAdminDesktopLayout(BuildContext context) => useAdminDesktopLayout(context);

/// แผง context ขวา (inbox | แชท | รายละเอียดเคส)
bool useAdminContextPane(BuildContext context) {
  if (!useAdminSplitPane(context)) return false;
  return MediaQuery.sizeOf(context).width >= kAdminContextPaneMinWidth;
}

/// แยก inbox | แชท (โหมดคอมบนเว็บ)
bool useAdminSplitPane(BuildContext context) {
  if (!useAdminDesktopLayout(context)) return false;
  return MediaQuery.sizeOf(context).width >= kAdminDesktopMinWidth;
}

/// แถบเมนูย่อย (subnav) — โหมดคอมบนเว็บเท่านั้น
bool useAdminSubnav(BuildContext context) => useAdminDesktopLayout(context);

/// @deprecated ใช้ [useAdminDesktopLayout]
bool useAdminWideShell(BuildContext context) => useAdminDesktopLayout(context);

/// ใช้ใน admin_shell_scaffold — breakpoint โครงสร้างคอมบนเว็บ
const double kAdminShellBreakpoint = 900.0;

/// เปิด console บนเว็บแทนหน้าแชทมือถือ
bool shouldUseAdminConsole(String path) =>
    kIsWeb && path.startsWith('/admin/chat/');
