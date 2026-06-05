import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ความกว้างขั้นต่ำสำหรับ layout แอดมินแบบ split-pane บนคอม
const kAdminDesktopMinWidth = 900.0;

const kAdminInboxPaneWidth = 380.0;

bool isAdminPath(String path) => path.startsWith('/admin');

bool isAdminDesktopLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= kAdminDesktopMinWidth;
}

/// เปิด console บนเว็บแทนหน้าแชทมือถือ
bool shouldUseAdminConsole(String path) =>
    kIsWeb && path.startsWith('/admin/chat/');
