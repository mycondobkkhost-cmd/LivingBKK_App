import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_perspective.dart';
import '../state/locale_controller.dart';
import '../state/user_role_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// 「คุณคือ」— dropdown ใต้โลโก้ แสดงคำอธิบายเต็มเมื่อเลือก
class PerspectiveSelectorRow extends StatelessWidget {
  const PerspectiveSelectorRow({
    super.key,
    required this.controller,
    required this.localeController,
    this.compact = false,
  });

  final UserRoleController controller;
  final LocaleController localeController;
  final bool compact;

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, localeController]),
      builder: (context, _) {
        final current = controller.perspective;
        final s = AppStrings(localeController.isEnglish);
        final p = context.palette;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  s.perspectiveLabel,
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: p.border),
                      boxShadow: [
                        BoxShadow(
                          color: p.cardShadow.withOpacity(0.6),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AppPerspective>(
                        value: current,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.primary),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        dropdownColor: p.surface,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                        selectedItemBuilder: (context) => [
                          for (final item in _perspectives)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                s.perspectiveChipShort(_key(item)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        items: [
                          for (final item in _perspectives)
                            DropdownMenuItem(
                              value: item,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) controller.setPerspective(v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                s.perspectiveFeedDescription(_key(current)),
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  height: 1.45,
                  color: p.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
