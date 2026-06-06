import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_perspective.dart';
import '../state/locale_controller.dart';
import '../state/user_role_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// Dropdown เล็กๆ ข้างโลโก้ — ย่อเหลือชื่อบทบาท / เปิดเมนูแสดงคำอธิบายเต็ม
class PerspectiveDropdownChip extends StatelessWidget {
  const PerspectiveDropdownChip({
    super.key,
    required this.controller,
    required this.localeController,
    this.onPurpleHeader = false,
    this.compact = false,
    this.mini = false,
  });

  final UserRoleController controller;
  final LocaleController localeController;
  final bool onPurpleHeader;
  final bool compact;
  final bool mini;

  static const _perspectives = [
    AppPerspective.customer,
    AppPerspective.agent,
    AppPerspective.owner,
  ];

  AppPerspectiveKey _key(AppPerspective p) => switch (p) {
        AppPerspective.customer => AppPerspectiveKey.customer,
        AppPerspective.agent => AppPerspectiveKey.agent,
        AppPerspective.owner => AppPerspectiveKey.owner,
      };

  Future<void> _openMenu(BuildContext context, RenderBox anchor) async {
    final s = AppStrings(localeController.isEnglish);
    final p = context.palette;
    final origin = anchor.localToGlobal(Offset.zero);
    final selected = await showMenu<AppPerspective>(
      context: context,
      color: p.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + anchor.size.height + 4,
        origin.dx + anchor.size.width,
        origin.dy + anchor.size.height + 4,
      ),
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
      items: [
        for (final item in _perspectives)
          PopupMenuItem<AppPerspective>(
            value: item,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.perspectiveChipShort(_key(item)),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.perspectiveFeedDescription(_key(item)),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    if (selected != null) controller.setPerspective(selected);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, localeController]),
      builder: (context, _) {
        final current = controller.perspective;
        final s = AppStrings(localeController.isEnglish);
        final p = context.palette;

        final onPurple = onPurpleHeader;
        final captionColor = onPurple ? Colors.white70 : p.textSecondary;
        final labelColor = onPurple ? Colors.white : p.textPrimary;
        final dividerColor =
            onPurple ? Colors.white24 : p.border.withOpacity(0.75);
        final iconColor = onPurple ? Colors.white : p.primary;

        return Material(
          color: onPurple ? Colors.white.withOpacity(0.16) : p.surface,
          elevation: onPurple ? 0 : 1,
          shadowColor: p.cardShadow,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: Builder(
            builder: (chipContext) {
              return InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                onTap: () {
                  final box = chipContext.findRenderObject() as RenderBox?;
                  if (box != null) _openMenu(context, box);
                },
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: mini ? 148 : (compact ? 200 : 162),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    mini ? 8 : (compact ? 10 : 9),
                    mini ? 4 : (compact ? 5 : 7),
                    mini ? 2 : (compact ? 4 : 2),
                    mini ? 4 : (compact ? 5 : 7),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(
                      color: onPurple
                          ? Colors.white24
                          : p.border.withOpacity(0.8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!compact) ...[
                        Text(
                          s.perspectiveCaption,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                            color: captionColor,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          color: dividerColor,
                        ),
                      ],
                      Flexible(
                        child: Text(
                          s.perspectiveChipShort(_key(current)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: mini ? 12 : (compact ? 13 : 11),
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            color: labelColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.expand_more,
                        size: mini ? 16 : (compact ? 20 : 18),
                        color: iconColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
