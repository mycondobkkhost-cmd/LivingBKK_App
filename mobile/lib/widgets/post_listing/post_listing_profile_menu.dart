import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/post_listing_menu_config.dart';
import '../../l10n/app_strings.dart';
import '../../navigation/post_listing_navigation.dart';
import '../../services/auth_service.dart';
import '../../state/user_role_controller.dart';
import '../../theme/living_bkk_brand.dart';
import '../profile/profile_menu_tile.dart';

/// เมนูโพส์ประกาศในโปรไฟล์ — อ่านรายการจาก [PostListingMenuConfig]
class PostListingProfileMenu extends StatelessWidget {
  const PostListingProfileMenu({
    super.key,
    required this.roleController,
    this.asTilesOnly = false,
  });

  final UserRoleController roleController;

  /// true = คืนเฉพาะ tile (ให้ [ProfileMenuSection] จัด divider)
  final bool asTilesOnly;

  List<Widget> buildTiles(BuildContext context) {
    if (!AuthService.instance.isSignedIn) return const [];

    final s = AppStrings.of(context);
    final entries = PostListingMenuConfig.profileEntries(s);
    final showAll = PostListingMenuConfig.showsFor(roleController);

    return [
      for (final e in entries)
        if (showAll || e.id == 'create' || e.id == 'cared')
          ProfileMenuTile(
            icon: e.icon,
            title: e.title,
            subtitle: e.subtitle ??
                (!showAll && e.id == 'create'
                    ? s.t(
                        'สลับมุมมองเป็นเจ้าของ/นายหน้าเพื่อจัดการประกาศ',
                        'Switch to owner/broker view to manage listings',
                      )
                    : null),
            iconColor: LivingBkkBrand.accentOrange,
            iconBackground: const Color(0xFFFFF4E8),
            accentChevron: true,
            onTap: () => _onEntry(context, e),
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

  void _onEntry(BuildContext context, PostListingMenuEntry entry) {
    switch (entry.route) {
      case PostListingMenuConfig.createRoute:
        PostListingNavigation.openCreateWithAuthGate(context);
        break;
      case PostListingMenuConfig.myListingsRoute:
        if (!PostListingMenuConfig.showsFor(roleController)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.of(context).t(
                  'สลับมุมมองเป็นเจ้าของหรือนายหน้าก่อน',
                  'Switch to owner or broker view first',
                ),
              ),
            ),
          );
          return;
        }
        context.push(entry.route);
        break;
      default:
        context.push(entry.route);
    }
  }
}
