import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../config/demand_board_menu_config.dart';
import '../navigation/demand_board_navigation.dart';
import '../navigation/post_listing_navigation.dart';
import '../state/user_role_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';

/// ลงประกาศฟรี | บอกความต้องการ — ครึ่งซ้าย/ขวา คนละสี
class HomePromoActionRow extends StatelessWidget {
  const HomePromoActionRow({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LiLayout.pagePadding,
        8,
        LiLayout.pagePadding,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tile(
              palette: p,
              title: s.promoTitle,
              subtitle: s.promoBodyShort,
              icon: Icons.campaign_outlined,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.primary.withOpacity(0.12), p.primaryLight],
              ),
              accent: p.primary,
              onTap: () => PostListingNavigation.openCreateWithAuthGate(context),
            ),
          ),
          if (DemandBoardMenuConfig.showPromoRequirementTile(roleController)) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _Tile(
                palette: p,
                title: s.requirementTellTitle,
                subtitle: s.requirementTellBody,
                icon: Icons.manage_search_outlined,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    p.accent.withOpacity(0.14),
                    p.accent.withOpacity(0.06),
                  ],
                ),
                accent: p.accent,
                onTap: () =>
                    DemandBoardNavigation.openCreateRequirement(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accent,
    required this.onTap,
  });

  final AppPalette palette;
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: accent.withOpacity(0.22)),
            boxShadow: [AppTheme.cardShadowFor(palette)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: accent, size: 22),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: palette.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: palette.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
