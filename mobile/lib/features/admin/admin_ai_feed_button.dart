import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/admin_ai_feed_service.dart';
import 'admin_ai_feed_sheet.dart';

/// ปุ่ม ✨ AI Feed สำหรับ AppBar หลังบ้าน
class AdminAiFeedAppBarButton extends StatelessWidget {
  const AdminAiFeedAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListenableBuilder(
      listenable: AdminAiFeedService.instance,
      builder: (context, _) {
        final count = AdminAiFeedService.instance.openCount;
        return IconButton(
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Icon(Icons.auto_awesome),
          ),
          tooltip: s.adminAiFeedTitle,
          onPressed: () => showAdminAiFeedSheet(context),
        );
      },
    );
  }
}
