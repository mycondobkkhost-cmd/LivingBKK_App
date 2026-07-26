import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../config/demand_board_menu_config.dart';
import '../../config/post_listing_menu_config.dart';
import '../../data/property_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../navigation/post_listing_navigation.dart';
import '../../state/search_session_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_palette.dart';
import '../../theme/fb_feed_chrome.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/listing_navigation.dart';
import '../property_type_more_sheet.dart';

/// เมนูด่วนหน้าแรก — โมดูลฟีดกะทัดรัดแบบ Facebook
class HomeQuickMenu extends StatelessWidget {
  const HomeQuickMenu({
    super.key,
    required this.roleController,
    required this.searchSession,
    required this.isAgent,
    this.onMapSearch,
    this.showBoard = true,
    this.showCategories = true,
  });

  final UserRoleController roleController;
  final SearchSessionController searchSession;
  final bool isAgent;
  final VoidCallback? onMapSearch;
  final bool showBoard;
  final bool showCategories;

  static const _propertySlugs = PropertyCatalog.homePrimarySlugs;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final services =
        showBoard ? _buildServiceItems(context, s, p) : const <_ShortcutTileData>[];
    final properties =
        showCategories ? _buildPropertyItems(context, s, p) : const <_QuickItem>[];

    if (services.isEmpty && properties.isEmpty) {
      return const SizedBox.shrink();
    }

    return FbFeedCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (services.isNotEmpty) _ShortcutRow(items: services, palette: p),
          if (services.isNotEmpty && properties.isNotEmpty)
            const Divider(height: 1, thickness: 1, color: FbFeedChrome.hairline),
          if (properties.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
              child: _CategoryRow(items: properties, palette: p),
            ),
        ],
      ),
    );
  }

  List<_ShortcutTileData> _buildServiceItems(
    BuildContext context,
    AppStrings s,
    AppPalette p,
  ) {
    final out = <_ShortcutTileData>[];

    if (onMapSearch != null) {
      out.add(_ShortcutTileData(
        title: s.homeShortcutMapTitle,
        subtitle: s.homeShortcutMapSubtitle,
        icon: CupertinoIcons.map_fill,
        tint: LivingBkkBrand.brandRed,
        onTap: onMapSearch,
      ));
    }

    if (DemandBoardMenuConfig.showHomeQuickBoard(roleController)) {
      out.add(_ShortcutTileData(
        title: s.homeShortcutBoardTitle,
        subtitle: s.homeShortcutBoardSubtitle,
        icon: CupertinoIcons.speaker_2_fill,
        tint: LivingBkkBrand.accentOrange,
        onTap: () => DemandBoardNavigation.openBoardFeed(context, fromHome: true),
      ));
    }

    if (DemandBoardMenuConfig.showHomeQuickRequirement(roleController)) {
      out.add(_ShortcutTileData(
        title: s.homeShortcutAgentTitle,
        subtitle: s.homeShortcutAgentSubtitle,
        icon: CupertinoIcons.person_crop_circle_badge_checkmark,
        tint: const Color(0xFF31A24C),
        onTap: () => DemandBoardNavigation.openBoardLooking(context, fromHome: true),
      ));
    }

    return out;
  }

  List<_QuickItem> _buildPropertyItems(
    BuildContext context,
    AppStrings s,
    AppPalette p,
  ) {
    final out = <_QuickItem>[];

    for (final slug in _propertySlugs) {
      final cat = PropertyCatalog.bySlug(slug);
      if (cat == null) continue;
      out.add(_QuickItem(
        label: cat.label(s.isEnglish),
        icon: _propertyIcon(slug),
        tint: _propertyTint(slug),
        onTap: () => ListingNavigation.openCategory(context, slug: slug, isAgent: isAgent),
      ));
    }

    out.add(_QuickItem(
      label: s.homePropertyOthers,
      icon: CupertinoIcons.square_grid_2x2_fill,
      tint: FbFeedChrome.secondaryText,
      onTap: () {
        PropertyTypeMoreSheet.show(
          context,
          searchSession: searchSession,
          onCategoryPicked: (picked) {
            Navigator.of(context).pop();
            ListingNavigation.openCategory(context, slug: picked, isAgent: isAgent);
          },
        );
      },
    ));

    return out;
  }

  static IconData _propertyIcon(String slug) => switch (slug) {
        'condo' => CupertinoIcons.building_2_fill,
        'house' => CupertinoIcons.house_fill,
        'land' => CupertinoIcons.tree,
        'townhome' => Icons.other_houses_rounded,
        _ => CupertinoIcons.square_grid_2x2_fill,
      };

  static Color _propertyTint(String slug) => switch (slug) {
        'condo' => LivingBkkBrand.brandRed,
        'house' => LivingBkkBrand.accentOrange,
        'land' => const Color(0xFF31A24C),
        'townhome' => const Color(0xFFF7B928),
        _ => FbFeedChrome.secondaryText,
      };
}

class _ShortcutTileData {
  const _ShortcutTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;
}

class _QuickItem {
  const _QuickItem({
    required this.label,
    required this.icon,
    required this.tint,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;
}

class HomePostListingFab extends StatefulWidget {
  const HomePostListingFab({
    super.key,
    required this.roleController,
  });

  final UserRoleController roleController;

  static bool visibleFor(UserRoleController roleController) =>
      PostListingMenuConfig.showHomeQuickPost(roleController);

  @override
  State<HomePostListingFab> createState() => _HomePostListingFabState();
}

class _HomePostListingFabState extends State<HomePostListingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;
  late final Animation<double> _floatY;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatY = Tween<double>(begin: 0, end: -3).animate(
      CurvedAnimation(parent: _float, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!HomePostListingFab.visibleFor(widget.roleController)) {
      return const SizedBox.shrink();
    }
    final s = AppStrings.of(context);

    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatY.value),
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => PostListingNavigation.openManageHub(context),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 16, 11),
            decoration: BoxDecoration(
              color: LivingBkkBrand.brandRed,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: LivingBkkBrand.brandRed.withOpacity(0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.plus_circle_fill,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  s.homeQuickOwnerTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: -0.3,
                    height: 1.1,
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

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.items,
    required this.palette,
  });

  final List<_ShortcutTileData> items;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 28, color: FbFeedChrome.hairline),
            Expanded(
              child: _ShortcutCell(data: items[i], palette: palette),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShortcutCell extends StatefulWidget {
  const _ShortcutCell({
    required this.data,
    required this.palette,
  });

  final _ShortcutTileData data;
  final AppPalette palette;

  @override
  State<_ShortcutCell> createState() => _ShortcutCellState();
}

class _ShortcutCellState extends State<_ShortcutCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        onHighlightChanged: (v) {
          if (_pressed != v) setState(() => _pressed = v);
        },
        child: ColoredBox(
          color: _pressed ? FbFeedChrome.chipFill : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: FbFeedChrome.chipFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(data.icon, size: 16, color: data.tint),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          letterSpacing: -0.2,
                          color: widget.palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        data.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          height: 1.1,
                          color: FbFeedChrome.secondaryText,
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
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.items,
    required this.palette,
  });

  final List<_QuickItem> items;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in items)
          Expanded(child: _CategoryCell(data: item, palette: palette)),
      ],
    );
  }
}

class _CategoryCell extends StatefulWidget {
  const _CategoryCell({
    required this.data,
    required this.palette,
  });

  final _QuickItem data;
  final AppPalette palette;

  @override
  State<_CategoryCell> createState() => _CategoryCellState();
}

class _CategoryCellState extends State<_CategoryCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        onHighlightChanged: (v) {
          if (_pressed != v) setState(() => _pressed = v);
        },
        child: ColoredBox(
          color: _pressed ? FbFeedChrome.chipFill : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: FbFeedChrome.chipFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(data.icon, size: 18, color: data.tint),
                ),
                const SizedBox(height: 4),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                    color: widget.palette.textPrimary,
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
