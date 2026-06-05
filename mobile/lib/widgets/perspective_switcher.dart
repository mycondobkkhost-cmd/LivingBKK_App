import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_perspective.dart';
import '../state/user_role_controller.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';

/// ดรอปดาวน์มุมมอง — แบบ LivingInsider (กะทัดรัดในแถบหัว)
class PerspectiveDropdown extends StatelessWidget {
  const PerspectiveDropdown({
    super.key,
    required this.controller,
    this.compact = false,
  });

  final UserRoleController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.perspective;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (!compact)
                  Text(
                    s.whoAreYou,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (!compact) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: LiLayout.searchFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AppPerspective>(
                        isExpanded: true,
                        value: p,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        items: AppPerspective.values
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text(
                                  v.label(s.isEnglish),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) controller.setPerspective(v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (p == AppPerspective.agent)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  s.agentCoOnlyHint,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary.withOpacity(0.85),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// @deprecated ใช้ [PerspectiveDropdown] แทน
class PerspectiveSwitcher extends StatelessWidget {
  const PerspectiveSwitcher({super.key, required this.controller});

  final UserRoleController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LiLayout.pagePadding,
        6,
        LiLayout.pagePadding,
        4,
      ),
      child: PerspectiveDropdown(controller: controller),
    );
  }
}
