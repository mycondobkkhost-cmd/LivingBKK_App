import 'package:flutter/material.dart';

import '../../utils/shell_tab_navigation.dart';
import '../design_system/app_shell_bottom_nav.dart';

/// แถบเมนูล่างบนหน้านอก MainShell — แสดงผลเหมือนหน้าหลักทุกประการ
class ConsumerBottomNav extends StatelessWidget {
  const ConsumerBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShellBottomNav(
      index: ShellTabNavigation.currentIndex,
      onChanged: (i) => ShellTabNavigation.goToTab(context, i),
    );
  }
}
