import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../theme/admin_theme.dart';

/// ตั้งชื่อแชทที่แอดมินเห็น (ไม่เปลี่ยนชื่อบัญชีลูกค้า)
Future<String?> showAdminChatRenameSheet(
  BuildContext context, {
  required ChatRoom room,
  String? suggestedName,
}) async {
  final s = context.s;
  final controller = TextEditingController(
    text: room.adminDisplayName ?? suggestedName ?? '',
  );

  final result = await showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.adminChatRenameTitle, style: AdminTheme.title),
            const SizedBox(height: 6),
            Text(s.adminChatRenameHint, style: AdminTheme.hint),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: s.adminChatRenameLabel,
                hintText: s.adminChatRenamePlaceholder,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (room.adminDisplayName != null &&
                    room.adminDisplayName!.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, ''),
                    child: Text(s.adminChatRenameClear),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(s.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(ctx, controller.text.trim()),
                  child: Text(s.save),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  if (result == null || !context.mounted) return null;

  final name = result.isEmpty ? null : result;
  await ChatService.instance.setAdminDisplayName(room, name);
  return name;
}
