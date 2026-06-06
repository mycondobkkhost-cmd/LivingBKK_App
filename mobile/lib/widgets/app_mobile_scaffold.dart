import 'package:flutter/material.dart';

import '../shell/main_shell_scope.dart';
import '../utils/page_safe_insets.dart';

/// Scaffold มาตรฐาน — รองรับ iPhone เมื่อเปิดนอก MainShell
class AppMobileScaffold extends StatelessWidget {
  const AppMobileScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.safeBottomBody = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final bool safeBottomBody;

  @override
  Widget build(BuildContext context) {
    final inShell = MainShellScope.maybeOf(context) != null;
    final needsBottom = safeBottomBody &&
        !inShell &&
        bottomNavigationBar == null &&
        PageSafeInsets.bottom(context) > 0;

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: needsBottom
          ? SafeArea(top: false, bottom: true, child: body)
          : body,
    );
  }
}
