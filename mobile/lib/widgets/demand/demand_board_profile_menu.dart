import 'package:flutter/material.dart';

import '../../config/demand_board_menu_config.dart';
import '../../l10n/app_strings.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../services/auth_service.dart';
import '../../state/user_role_controller.dart';
import '../../theme/living_bkk_brand.dart';
import '../profile/profile_menu_tile.dart';

/// เมนูบอร์ดหาทรัพย์ในโปรไฟล์ — อ่านรายการจาก [DemandBoardMenuConfig]
class DemandBoardProfileMenu extends StatelessWidget {
  const DemandBoardProfileMenu({
    super.key,
    required this.roleController,
    this.asTilesOnly = false,
  });

  final UserRoleController roleController;

  /// true = คืนเฉพาะ tile (ให้ [ProfileMenuSection] จัด divider)
  final bool asTilesOnly;

  List<Widget> buildTiles(BuildContext context) {
    final entries = DemandBoardMenuConfig.profileEntries(
      AppStrings.of(context),
      roleController,
    );
    if (entries.isEmpty) return const [];
    if (!AuthService.instance.isSignedIn &&
        DemandBoardMenuConfig.showsRequirementsFor(roleController)) {
      return const [];
    }

    return [
      for (final e in entries)
        ProfileMenuTile(
          icon: e.icon,
          title: e.title,
          subtitle: e.subtitle,
          iconColor: LivingBkkBrand.brandRed,
          iconBackground: LivingBkkBrand.brandRedTint,
          accentChevron: true,
          onTap: () => DemandBoardNavigation.onProfileEntry(context, e),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tiles = buildTiles(context);
    if (tiles.isEmpty) return const SizedBox.shrink();
    if (asTilesOnly) {
      return Column(mainAxisSize: MainAxisSize.min, children: tiles);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          tiles[i],
          if (i < tiles.length - 1) const ProfileMenuDivider(),
        ],
      ],
    );
  }
}
