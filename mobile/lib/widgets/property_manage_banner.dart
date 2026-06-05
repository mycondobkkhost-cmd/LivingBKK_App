import 'package:flutter/material.dart';
import '../config/post_listing_menu_config.dart';
import '../l10n/app_strings.dart';
import '../navigation/post_listing_navigation.dart';
import '../state/user_role_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';

/// แถบ「จัดการทรัพย์」— แสดงเมื่อมุมมองเจ้าของหรือเอเจนซี่
class PropertyManageBanner extends StatelessWidget {
  const PropertyManageBanner({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  Widget build(BuildContext context) {
    if (!PostListingMenuConfig.showsFor(roleController)) {
      return const SizedBox.shrink();
    }

    final s = AppStrings.of(context);
    final p = context.palette;
    final isOwner = roleController.isOwner;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LiLayout.pagePadding,
        4,
        LiLayout.pagePadding,
        8,
      ),
      child: Material(
        color: p.primaryLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: () => PostListingNavigation.openMyListings(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: p.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOwner ? Icons.home_work_outlined : Icons.handshake_outlined,
                    color: p.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.propertyManageTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOwner ? s.propertyManageOwnerHint : s.propertyManageAgentHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: p.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (PostListingMenuConfig.showsFor(roleController))
                  TextButton(
                    onPressed: () =>
                        PostListingNavigation.openCreateWithAuthGate(context),
                    child: Text(
                      s.postListing,
                      style: TextStyle(fontSize: 12, color: p.primary),
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: p.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
