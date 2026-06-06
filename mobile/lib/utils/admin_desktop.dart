import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ความกว้างขั้นต่ำสำหรับ layout แอดมินแบบ split-pane บนคอม
const kAdminDesktopMinWidth = 900.0;

const kAdminInboxPaneWidth = 380.0;

bool isAdminPath(String path) => path.startsWith('/admin');

bool isAdminConsolePath(String path) =>
    path == '/admin/console' || path.startsWith('/admin/console/');

/// หลังบ้านบน Web — กรอบ iPhone เหมือนหน้าหลักยูส (ยกเว้น console / desktop)
/// ใส่ `?desktop=1` ถ้าต้องการเต็มจอบนคอม
bool adminShellFullWidth(
  String path, {
  Map<String, String> query = const {},
}) {
  if (!isAdminPath(path)) return false;
  if (!kIsWeb) return true;
  if (query['desktop'] == '1') return true;
  if (isAdminConsolePath(path)) return true;
  return false;
}

bool isAdminDesktopLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= kAdminDesktopMinWidth;
}

/// เปิด console บนเว็บแทนหน้าแชทมือถือ
bool shouldUseAdminConsole(String path) =>
    kIsWeb && path.startsWith('/admin/chat/');
