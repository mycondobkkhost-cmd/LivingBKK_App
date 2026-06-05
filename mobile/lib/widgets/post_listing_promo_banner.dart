import 'package:flutter/material.dart';

import '../config/post_listing_menu_config.dart';
import '../l10n/app_strings.dart';
import '../navigation/post_listing_navigation.dart';
import '../state/user_role_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/living_bkk_brand.dart';
import '../theme/li_layout.dart';

/// แถบโฆษณาใต้ช่องค้นหา — ชวนลงประกาศฟรี (แสดงตาม [PostListingMenuConfig.showHomePromo])
class PostListingPromoBanner extends StatelessWidget {
  const PostListingPromoBanner({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  Widget build(BuildContext context) {
    if (!PostListingMenuConfig.showHomePromo(roleController)) {
      return const SizedBox.shrink();
    }

    final s = AppStrings.of(context);
    final p = context.palette;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor = isLight ? p.textPrimary : Colors.white;
    final bodyColor = isLight ? p.textSecondary : Colors.white.withOpacity(0.88);
    final iconColor = isLight ? p.primary : LivingBkkBrand.pink;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LiLayout.pagePadding,
        4,
        LiLayout.pagePadding,
        8,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        elevation: 0,
        child: InkWell(
          onTap: () => PostListingNavigation.openCreateWithAuthGate(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              gradient: isLight
                  ? LivingBkkBrand.promoGradientLight
                  : LivingBkkBrand.promoGradient,
              border: Border.all(
                color: isLight
                    ? p.primary.withOpacity(0.22)
                    : Colors.white.withOpacity(0.12),
              ),
              boxShadow: [AppTheme.cardShadowFor(p)],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.campaign_outlined, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.promoTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: titleColor,
                          ),
                        ),
                        Text(
                          s.promoBody,
                          style: TextStyle(
                            fontSize: 11,
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () =>
                        PostListingNavigation.openCreateWithAuthGate(context),
                    style: (isLight ? AppTheme.pillPrimaryFor(p) : AppTheme.pillFilledFor(p))
                        .copyWith(
                      visualDensity: VisualDensity.compact,
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      minimumSize: MaterialStateProperty.all(const Size(0, 36)),
                    ),
                    child: Text(s.promoCta, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
