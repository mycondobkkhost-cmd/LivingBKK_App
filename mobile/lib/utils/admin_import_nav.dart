import 'package:flutter/material.dart';

import '../features/admin/admin_import_review_sheet.dart';

/// เปิดชีตแก้ไขนำเข้าจากคลังทรัพย์ / ลิงก์ภายใน
Future<void> openAdminImportReview(
  BuildContext context, {
  required String importId,
  VoidCallback? onChanged,
}) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, scrollController) => AdminImportReviewSheet(
        importId: importId,
        scrollController: scrollController,
        onChanged: onChanged ?? () {},
        onSwitchImport: (otherId) async {
          Navigator.of(ctx).pop();
          await openAdminImportReview(context, importId: otherId, onChanged: onChanged);
        },
      ),
    ),
  );
}
