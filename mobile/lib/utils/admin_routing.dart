import 'package:flutter/foundation.dart';

/// หน้าแรกของแอดมินหลังล็อกอิน — Web ใช้ console, มือถือใช้ศูนย์แอดมินเต็ม
String adminHomePath({bool? preferConsole}) {
  final useConsole = preferConsole ?? kIsWeb;
  return useConsole ? '/admin/console' : '/admin';
}

bool isAdminRoute(String path) => path.startsWith('/admin');
