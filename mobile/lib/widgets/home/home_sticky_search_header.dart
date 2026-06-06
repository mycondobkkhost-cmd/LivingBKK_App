import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';
import '../../models/search_filters.dart';
import '../../theme/app_palette.dart';
import '../../shell/main_shell_scope.dart';
import '../../state/locale_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/living_bkk_brand.dart';
import '../notification_bell_button.dart';
import '../proppiter_brand_hero.dart';
import '../perspective_dropdown_chip.dart';

/// หัวหน้าแรก — gradient ม่วงนุ่ม + toolbar + ค้นหา (sticky)
class HomeStickySearchHeader extends StatelessWidget {
  const HomeStickySearchHeader({
    super.key,
    required this.roleController,
    required this.localeController,
    required this.onOpenSearch,
    required this.onOpenNotifications,
    required this.filters,
    this.onFiltersChanged,
    this.onMapSearch,
    this.onOpenProject,
    this.onOpenFilters,
  });

  final UserRoleController roleController;
  final LocaleController localeController;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenNotifications;
  final SearchFilters filters;
  final ValueChanged<SearchFilters>? onFiltersChanged;
  final VoidCallback? onMapSearch;
  final void Function(String projectName, {String? projectSlug})? onOpenProject;
  final VoidCallback? onOpenFilters;

  static const double hPad = 16;
  static const double topContentPad = 6;
  static const double toolbarHeight = 52;
  static const double searchHeight = 48;
  static const double blockGap = 10;
  static const double bottomPad = 14;

  /// ลดช่องว่างม่วงด้านบนลง 30% (เทียบ safe area + padding เดิม)
  static const double headerGapReduction = 0.30;

  /// ดึงแถว toolbar ลงเพิ่มจากค่าที่ลดแล้ว
  static const double headerTopRelax = 10;

  static double topInset(BuildContext context) {
    final mq = MediaQuery.of(context);
    return mq.viewPadding.top > 0 ? mq.viewPadding.top : mq.padding.top;
  }

  static double _scaleGap(double value) =>
      value * (1 - headerGapReduction);

  /// ช่องว่าง safe area ด้านบน — เหลือ 70% ของเดิม + relax
  static double headerTopSpacer(double inset) {
    if (inset <= 0) return _scaleGap(topContentPad) + headerTopRelax;
    return _scaleGap(inset) + headerTopRelax;
  }

  static double get headerContentTopPad => _scaleGap(topContentPad);

  static double get headerBlockGap => _scaleGap(blockGap);

  /// ความสูง body ใต้ spacer บน — ต้องตรงกับ delegate ทุก pixel
  static double collapsedBodyHeight() =>
      headerContentTopPad + searchHeight + bottomPad;

  static double expandedBodyHeight() =>
      headerContentTopPad +
      toolbarHeight +
      headerBlockGap +
      searchHeight +
      bottomPad;

  @override
  Widget build(BuildContext context) {
    final inset = topInset(context);
    final topSpacer = headerTopSpacer(inset);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeHeaderDelegate(
        topSpacer: topSpacer,
        minHeight: topSpacer + collapsedBodyHeight(),
        maxHeight: topSpacer + expandedBodyHeight(),
        roleController: roleController,
        localeController: localeController,
        filters: filters,
        onFiltersChanged: onFiltersChanged,
        onOpenSearch: onOpenSearch,
        onOpenNotifications: onOpenNotifications,
        onMapSearch: onMapSearch,
        onOpenProject: onOpenProject,
        onOpenFilters: onOpenFilters,
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({
    required this.topSpacer,
    required this.minHeight,
    required this.maxHeight,
    required this.roleController,
    required this.localeController,
    required this.filters,
    required this.onOpenSearch,
    required this.onOpenNotifications,
    this.onFiltersChanged,
    this.onMapSearch,
    this.onOpenProject,
    this.onOpenFilters,
  });

  final double topSpacer;
  final double minHeight;
  final double maxHeight;
  final UserRoleController roleController;
  final LocaleController localeController;
  final SearchFilters filters;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenNotifications;
  final ValueChanged<SearchFilters>? onFiltersChanged;
  final VoidCallback? onMapSearch;
  final void Function(String projectName, {String? projectSlug})? onOpenProject;
  final VoidCallback? onOpenFilters;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapsedBody = HomeStickySearchHeader.collapsedBodyHeight();
    final expandedBody = maxExtent - topSpacer;
    final range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final t = (1 - (shrinkOffset / range)).clamp(0.0, 1.0);
    final toolbarH = HomeStickySearchHeader.toolbarHeight * t;
    // ล็อกความสูงขั้นต่ำ — กัน search ถูก clip ตอน scroll
    final bodyH = (maxExtent - shrinkOffset - topSpacer)
        .clamp(collapsedBody, expandedBody);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LivingBkkBrand.homeHeaderBlockGradient,
        ),
        child: Column(
          children: [
            SizedBox(height: topSpacer),
            SizedBox(
              height: bodyH,
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  HomeStickySearchHeader.hPad,
                  HomeStickySearchHeader.headerContentTopPad,
                  HomeStickySearchHeader.hPad,
                  HomeStickySearchHeader.bottomPad,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ค้นหา — ติดล่างเสมอ (sticky collapsed state)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: HomeStickySearchHeader.searchHeight,
                        width: double.infinity,
                        child: _SearchCapsule(
                          filters: filters,
                          onOpenSearch: onOpenSearch,
                          onMapSearch: onMapSearch,
                          onOpenFilters: onOpenFilters,
                        ),
                      ),
                    ),
                    // Toolbar — หายไปเมื่อ scroll ลง
                    if (t > 0.02)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: toolbarH,
                        child: Opacity(
                          opacity: t,
                          child: _ToolbarRow(
                            roleController: roleController,
                            localeController: localeController,
                            onOpenNotifications: onOpenNotifications,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return topSpacer != oldDelegate.topSpacer ||
        minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        filters != oldDelegate.filters;
  }
}

/// Lockup P + PROPPITER (PNG) บน + สโลเกนล่าง
class _HomeHeaderBrandBlock extends StatelessWidget {
  const _HomeHeaderBrandBlock();

  @override
  Widget build(BuildContext context) {
    return const ProppiterBrandHero(
      size: ProppiterBrandHeroSize.compact,
      showSlogan: false,
    );
  }
}

class _ToolbarRow extends StatelessWidget {
  const _ToolbarRow({
    required this.roleController,
    required this.localeController,
    required this.onOpenNotifications,
  });

  final UserRoleController roleController;
  final LocaleController localeController;
  final VoidCallback onOpenNotifications;

  static const double _actionSize = 36;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Transform.translate(
            offset: const Offset(10, -7),
            child: const _HomeHeaderBrandBlock(),
          ),
        ),
        PerspectiveDropdownChip(
          controller: roleController,
          localeController: localeController,
          onPurpleHeader: true,
          compact: true,
          mini: true,
        ),
        const SizedBox(width: 6),
        _actionIcon(
          icon: Icons.favorite_border_rounded,
          onTap: () => MainShellScope.maybeOf(context)?.selectTab(1),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: _actionSize,
          height: _actionSize,
          child: NotificationBellButton(
            compact: true,
            onPressed: onOpenNotifications,
            onPurple: true,
          ),
        ),
      ],
    );
  }

  Widget _actionIcon({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: _actionSize,
          height: _actionSize,
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _SearchCapsule extends StatelessWidget {
  const _SearchCapsule({
    required this.filters,
    required this.onOpenSearch,
    this.onMapSearch,
    this.onOpenFilters,
  });

  final SearchFilters filters;
  final VoidCallback onOpenSearch;
  final VoidCallback? onMapSearch;
  final VoidCallback? onOpenFilters;

  static const double _actionSize = 40;
  static const double _leftPad = 14;
  static const double _rightPad = 8;
  static const Color _dividerColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final hasActive = filters.hasActiveFilters;
    final query = filters.query?.trim();
    final hasQuery = query != null && query.isNotEmpty;
    final radius = BorderRadius.circular(HomeStickySearchHeader.searchHeight / 2);
    final hasActions = onMapSearch != null || onOpenFilters != null;

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpenSearch,
              child: Padding(
                padding: const EdgeInsets.only(left: _leftPad, right: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: LivingBkkBrand.homeHeaderBlockColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasQuery ? query! : s.searchHintProjects,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: hasQuery ? FontWeight.w600 : FontWeight.w400,
                          color: hasQuery ? p.textPrimary : p.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasActions) ...[
            _CapsuleDivider(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onMapSearch != null)
                  _CapsuleAction(
                    icon: Icons.map_outlined,
                    tooltip: s.mapSearchShort,
                    onTap: onMapSearch!,
                  ),
                if (onMapSearch != null && onOpenFilters != null)
                  _CapsuleDivider(),
                if (onOpenFilters != null)
                  _CapsuleAction(
                    icon: Icons.tune_rounded,
                    tooltip: s.advancedFilters,
                    onTap: onOpenFilters!,
                    showBadge: hasActive,
                  ),
              ],
            ),
            const SizedBox(width: _rightPad),
          ],
        ],
      ),
    );
  }
}

class _CapsuleDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: _SearchCapsule._dividerColor,
    );
  }
}

class _CapsuleAction extends StatelessWidget {
  const _CapsuleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _SearchCapsule._actionSize,
      height: _SearchCapsule._actionSize,
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Badge(
          isLabelVisible: showBadge,
          smallSize: 8,
          backgroundColor: LivingBkkBrand.accentOrange,
          child: Icon(
            icon,
            size: 22,
            color: showBadge
                ? LivingBkkBrand.homeHeaderBlockColor
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
