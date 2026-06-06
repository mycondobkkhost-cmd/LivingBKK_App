import 'package:flutter/material.dart';

/// ห่อ GoRouter page — safe area แนวตั้งจัดใน [AppMobileScaffold] แล้ว
class MobileRouteShell extends StatelessWidget {
  const MobileRouteShell({
    super.key,
    required this.path,
    required this.child,
  });

  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
