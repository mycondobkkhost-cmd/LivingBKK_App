import 'package:flutter/material.dart';

import '../../config/demand_board_menu_config.dart';
import '../../config/post_listing_menu_config.dart';
import '../../l10n/app_strings.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../navigation/post_listing_navigation.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';

/// เมนูบริการแนวนอน — กะทัดรัด + ฉากหลังกราฟิกเบาๆ
class HomeServiceGrid extends StatelessWidget {
  const HomeServiceGrid({
    super.key,
    required this.roleController,
    this.onMapSearch,
  });

  final UserRoleController roleController;
  final VoidCallback? onMapSearch;

  static const _cardWidth = 96.0;
  static const _cardHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final items = _buildItems(context, s, p);

    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: _cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: LiLayout.pagePadding),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _CompactServiceCard(
          data: items[i],
          palette: p,
          width: _cardWidth,
          height: _cardHeight,
        ),
      ),
    );
  }

  List<_ServiceItem> _buildItems(BuildContext context, AppStrings s, AppPalette p) {
    final out = <_ServiceItem>[
      _ServiceItem(
        id: 'map',
        title: s.homeServiceMapTitle,
        icon: Icons.map_rounded,
        tint: p.primary,
        bg: _ServiceBg.map,
        onTap: onMapSearch,
      ),
    ];

    if (PostListingMenuConfig.showHomeQuickPost(roleController)) {
      out.add(_ServiceItem(
        id: 'post',
        title: s.homeQuickOwnerTitle,
        icon: Icons.campaign_outlined,
        tint: p.accent,
        bg: _ServiceBg.post,
        onTap: () => PostListingNavigation.openCreateWithAuthGate(context),
      ));
    }

    if (DemandBoardMenuConfig.showHomeQuickRequirement(roleController)) {
      out.add(_ServiceItem(
        id: 'requirement',
        title: s.homeQuickHelperTitle,
        icon: Icons.manage_search_rounded,
        tint: const Color(0xFF10B981),
        bg: _ServiceBg.requirement,
        onTap: () => DemandBoardNavigation.openCreateRequirement(context),
      ));
    }

    if (DemandBoardMenuConfig.showHomeQuickBoard(roleController)) {
      out.add(_ServiceItem(
        id: 'board',
        title: s.homeQuickBoardTitle,
        icon: Icons.forum_outlined,
        tint: const Color(0xFFF59E0B),
        bg: _ServiceBg.board,
        onTap: () => DemandBoardNavigation.openBoardTab(context),
      ));
    }

    if (PostListingMenuConfig.showsFor(roleController)) {
      out.add(_ServiceItem(
        id: 'manage',
        title: s.homeQuickManageTitle,
        icon: Icons.dashboard_customize_rounded,
        tint: p.primary,
        bg: _ServiceBg.manage,
        onTap: () => PostListingNavigation.openMyListings(context),
      ));
    }

    return out;
  }
}

enum _ServiceBg { map, post, requirement, board, manage }

class _ServiceItem {
  const _ServiceItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.tint,
    required this.bg,
    this.onTap,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color tint;
  final _ServiceBg bg;
  final VoidCallback? onTap;
}

class _CompactServiceCard extends StatelessWidget {
  const _CompactServiceCard({
    required this.data,
    required this.palette,
    required this.width,
    required this.height,
  });

  final _ServiceItem data;
  final AppPalette palette;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final deco = _backgroundFor(data.bg, data.tint, p);

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border.withOpacity(0.7)),
              gradient: deco.gradient,
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  right: -6,
                  bottom: -8,
                  child: Icon(
                    data.icon,
                    size: 44,
                    color: data.tint.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(data.icon, size: 18, color: data.tint),
                      const Spacer(),
                      Text(
                        data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: p.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _BgStyle _backgroundFor(_ServiceBg bg, Color tint, AppPalette p) {
    return switch (bg) {
      _ServiceBg.map => _BgStyle(
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.primaryLight.withOpacity(0.55), p.surface],
          ),
        ),
      _ServiceBg.post => _BgStyle(
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tint.withOpacity(0.12), p.surface],
          ),
        ),
      _ServiceBg.requirement => _BgStyle(
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8FBF3), Color(0xFFFFFFFF)],
          ),
        ),
      _ServiceBg.board => _BgStyle(
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7E8), Color(0xFFFFFFFF)],
          ),
        ),
      _ServiceBg.manage => _BgStyle(
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.primaryLight.withOpacity(0.35), p.surface],
          ),
        ),
    };
  }
}

class _BgStyle {
  const _BgStyle(this.gradient);
  final Gradient gradient;
}
