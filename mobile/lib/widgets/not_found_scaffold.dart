import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'app_mobile_scaffold.dart';

/// หน้า error สำหรับ route ที่ไม่พบข้อมูล — รองรับสลับภาษา
class NotFoundScaffold extends StatelessWidget {
  const NotFoundScaffold({super.key, required this.message});

  final String Function(AppStrings s) message;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AppMobileScaffold(
      body: Center(child: Text(message(s))),
    );
  }
}
