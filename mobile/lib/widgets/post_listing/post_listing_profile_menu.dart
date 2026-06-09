import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/post_listing_menu_config.dart';
import '../../l10n/app_strings.dart';
import '../../navigation/post_listing_navigation.dart';
import '../../services/auth_service.dart';
import '../../state/user_role_controller.dart';
import '../profile/profile_menu_tile.dart';

/// เมนูโพส์ประกาศในโปรไฟล์ — อ่านรายการจาก [PostListingMenuConfig]
class PostListingProfileMenu extends StatelessWidget {
  const PostListingProfileMenu({
    super.key,
    required this.roleController,
  });

  final UserRoleController roleController;

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.isSignedIn) {
      return const SizedBox.shrink();
    }

    final s = AppStrings.of(context);
    final entries = PostListingMenuConfig.profileEntries(s);
    final showAll = PostListingMenuConfig.showsFor(roleController);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < entries.length; i++)
          if (showAll || entries[i].id == 'create' || entries[i].id == 'cared') ...[
            ProfileMenuTile(
              icon: entries[i].icon,
              title: entries[i].title,
              subtitle: entries[i].subtitle ??
                  (!showAll && entries[i].id == 'create'
                      ? s.t(
                          'สลับมุมมองเป็นเจ้าของ/นายหน้าเพื่อจัดการประกาศ',
                          'Switch to owner/broker view to manage listings',
                        )
                      : null),
              onTap: () => _onEntry(context, entries[i]),
            ),
            const ProfileMenuDivider(),
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
