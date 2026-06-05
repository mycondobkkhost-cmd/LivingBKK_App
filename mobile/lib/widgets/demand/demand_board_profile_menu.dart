import 'package:flutter/material.dart';

import '../../config/demand_board_menu_config.dart';
import '../../l10n/app_strings.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../services/auth_service.dart';
import '../../state/user_role_controller.dart';
import '../profile/profile_menu_tile.dart';

/// เมนูบอร์ดหาทรัพย์ในโปรไฟล์ — อ่านรายการจาก [DemandBoardMenuConfig]
class DemandBoardProfileMenu extends StatelessWidget {
  const DemandBoardProfileMenu({
    super.key,
    required this.roleController,
  });

  final UserRoleController roleController;

  @override
  Widget build(BuildContext context) {
    final entries = DemandBoardMenuConfig.profileEntries(
      AppStrings.of(context),
      roleController,
    );
    if (entries.isEmpty) return const SizedBox.shrink();
    if (!AuthService.instance.isSignedIn &&
        DemandBoardMenuConfig.showsRequirementsFor(roleController)) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          ProfileMenuTile(
            icon: entries[i].icon,
            title: entries[i].title,
            subtitle: entries[i].subtitle,
            onTap: () => DemandBoardNavigation.onProfileEntry(context, entries[i]),
          ),
          const ProfileMenuDivider(),
        ],
      ],
    );
  }
}
