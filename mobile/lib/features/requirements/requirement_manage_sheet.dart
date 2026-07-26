import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../models/customer_requirement.dart';
import '../../models/demand_post.dart';
import '../../services/customer_requirement_repository.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';

/// จัดการประกาศหาทรัพย์ของลูกค้า — ได้ทรัพย์แล้ว / ปิดประกาศ
Future<bool> showRequirementManageSheet(
  BuildContext context, {
  required ChatRoom room,
}) async {
  final req = CustomerRequirementRepository.instance.findForChatRoom(room);
  if (req == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).requirementManageNotFound)),
    );
    return false;
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _RequirementManageSheet(requirement: req),
  );
  return result == true;
}

class _RequirementManageSheet extends StatelessWidget {
  const _RequirementManageSheet({required this.requirement});

  final CustomerRequirement requirement;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final code = requirement.demandPostCode ?? requirement.id;
    final isClosed =
        requirement.status == 'closed' || requirement.status == 'fulfilled';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.requirementManageSheetTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.primaryLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.primary.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (code.isNotEmpty)
                    Text(
                      code,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.primary,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    requirement.localizedTitle(s.isEnglish),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    requirement.statusLabel(s.isEnglish),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isClosed) ...[
              Text(
                s.requirementManageAlreadyClosed,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: () => _confirm(
                  context,
                  title: s.requirementMarkFound,
                  body: s.requirementFulfilledConfirm,
                  onConfirm: () => CustomerRequirementRepository.instance
                      .markFulfilled(requirement.id),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(s.requirementMarkFound),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _confirm(
                  context,
                  title: s.requirementCloseSearch,
                  body: s.requirementCloseConfirm,
                  onConfirm: () => CustomerRequirementRepository.instance
                      .closeSearch(requirement.id),
                ),
                icon: const Icon(Icons.cancel_outlined),
                label: Text(s.requirementCloseSearch),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.t('ปิด', 'Close')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required Future<void> Function() onConfirm,
  }) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.t('ยกเลิก', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.t('ยืนยัน', 'Confirm')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await onConfirm();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.requirementManageSaved)),
    );
    Navigator.pop(context, true);
  }
}

/// สร้างความต้องการ demo จาก demand post (ใช้ตอนแชทฝั่งผู้รับในโหมดทดลอง)
void ensureDemoRequirementForPost(DemandPost post) {
  CustomerRequirementRepository.instance.ensureDemoForDemandPost(post);
}
