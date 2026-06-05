import 'package:flutter/material.dart';

import '../config/demand_board_menu_config.dart';
import '../l10n/app_strings.dart';
import '../navigation/demand_board_navigation.dart';
import '../state/user_role_controller.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';

/// แถบ「จัดการความต้องการ」— แสดงเมื่อมุมมองลูกค้า (หาซื้อ/เช่า)
class CustomerRequirementBanner extends StatelessWidget {
  const CustomerRequirementBanner({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  Widget build(BuildContext context) {
    if (!DemandBoardMenuConfig.showRequirementBanner(roleController)) {
      return const SizedBox.shrink();
    }

    final s = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LiLayout.pagePadding,
        4,
        LiLayout.pagePadding,
        8,
      ),
      child: Material(
        color: AppTheme.accentDeepLight,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => DemandBoardNavigation.openMyRequirements(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentDeep.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.manage_search_outlined,
                    color: AppTheme.accentDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.requirementManageTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.requirementManageHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      DemandBoardNavigation.openCreateRequirement(context),
                  child: Text(s.requirementCreateCta, style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
