import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/search_filters.dart';
import '../../services/auth_service.dart';
import '../../theme/app_palette.dart';
import '../../state/locale_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/living_bkk_brand.dart';
import '../notification_bell_button.dart';
import '../search_filter_chips.dart';
import '../typewriter_hint_label.dart';

/// หัวหน้าแรก — ยินดีต้อนรับ + โหมดรับโค + ค้นหา (sticky)
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

  static const double hPad = 12;
  static const double topContentPad = 4;
  /// แถวยินดีต้อนรับ + ปุ่มขวา
  static const double toolbarHeight = 48;
  static const double searchHeight = 44;
  static const double zoneChipsHeight = 34;
  static const double zoneChipsGap = 6;
  static const double blockGap = 8;
  static const double bottomPad = 12;

  /// ลดช่องว่างแดงด้านบนลง 30% (เทียบ safe area + padding เดิม)
  static const double headerGapReduction = 0.30;

  /// ดึงแถว toolbar ลงเพิ่มจากค่าที่ลดแล้ว
  static const double headerTopRelax = 8;

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
  static double _zoneChipsExtra({required bool hasZoneChips}) =>
      hasZoneChips ? zoneChipsGap + zoneChipsHeight : 0;

  static double collapsedBodyHeight({bool hasZoneChips = false}) =>
      headerContentTopPad +
      searchHeight +
      _zoneChipsExtra(hasZoneChips: hasZoneChips) +
      bottomPad;

  static double expandedBodyHeight({bool hasZoneChips = false}) =>
      headerContentTopPad +
      toolbarHeight +
      headerBlockGap +
      searchHeight +
      _zoneChipsExtra(hasZoneChips: hasZoneChips) +
      bottomPad;

  @override
  Widget build(BuildContext context) {
    final inset = topInset(context);
    final topSpacer = headerTopSpacer(inset);
    final showZoneChips =
        filters.hasZoneFilters && onFiltersChanged != null;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeHeaderDelegate(
        topSpacer: topSpacer,
        minHeight: topSpacer + collapsedBodyHeight(hasZoneChips: showZoneChips),
        maxHeight: topSpacer + expandedBodyHeight(hasZoneChips: showZoneChips),
        showZoneChips: showZoneChips,
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
    required this.showZoneChips,
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
  final bool showZoneChips;
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
    final zoneChipsCallback = onFiltersChanged;
    final collapsedBody =
        HomeStickySearchHeader.collapsedBodyHeight(hasZoneChips: showZoneChips);
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
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(14),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LivingBkkBrand.homeHeaderBlockGradientOf(context),
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
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showZoneChips && zoneChipsCallback != null) ...[
                                SizedBox(
                                  height: HomeStickySearchHeader.zoneChipsHeight,
                                  child: SearchFilterChips(
                                    filters: filters,
                                    onFiltersChanged: zoneChipsCallback,
                                  ),
                                ),
                                const SizedBox(
                                  height: HomeStickySearchHeader.zoneChipsGap,
                                ),
                              ],
                              SizedBox(
                                height: HomeStickySearchHeader.searchHeight,
                                width: double.infinity,
                                child: _SearchCapsule(
                                  filters: filters,
                                  onOpenSearch: onOpenSearch,
                                  onMapSearch: onMapSearch,
                                  onOpenFilters: onOpenFilters,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (t > 0.02)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: toolbarH,
                            child: ClipRect(
                              child: Opacity(
                                opacity: t,
                                child: _ToolbarRow(
                                  filters: filters,
                                  onFiltersChanged: onFiltersChanged,
                                  onOpenNotifications: onOpenNotifications,
                                  toolbarHeight: toolbarH,
                                ),
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
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return topSpacer != oldDelegate.topSpacer ||
        minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        showZoneChips != oldDelegate.showZoneChips ||
        filters != oldDelegate.filters;
  }
}

/// ยินดีต้อนรับ + ชื่อผู้ใช้
class _WelcomeBlock extends StatelessWidget {
  const _WelcomeBlock({
    required this.greeting,
    required this.name,
    required this.height,
  });

  final String greeting;
  final String name;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarRow extends StatelessWidget {
  const _ToolbarRow({
    required this.filters,
    required this.onOpenNotifications,
    required this.toolbarHeight,
    this.onFiltersChanged,
  });

  final SearchFilters filters;
  final ValueChanged<SearchFilters>? onFiltersChanged;
  final VoidCallback onOpenNotifications;
  final double toolbarHeight;

  static const double _actionSize = 34;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final coOn = filters.coAgentEligibleOnly == true;

    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final name = AuthService.instance.displayName;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _WelcomeBlock(
                greeting: s.homeHeaderGreeting,
                name: name,
                height: toolbarHeight,
              ),
            ),
            _CoAgentIdeasChip(
              active: coOn,
              label:
                  coOn ? s.homeCoAgentIdeasChipActive : s.homeCoAgentIdeasChip,
              tooltip: s.homeCoAgentIdeasHint,
              onTap: onFiltersChanged == null
                  ? null
                  : () {
                      onFiltersChanged!(
                        coOn
                            ? filters.copyWith(clearCoAgent: true)
                            : filters.copyWith(coAgentEligibleOnly: true),
                      );
                    },
            ),
            const SizedBox(width: 6),
            _HeaderIconButton(
              size: _actionSize,
              icon: Icons.favorite_border_rounded,
              onTap: () => context.push('/saved-listings'),
            ),
            const SizedBox(width: 4),
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
      },
    );
  }
}

class _CoAgentIdeasChip extends StatelessWidget {
  const _CoAgentIdeasChip({
    required this.active,
    required this.label,
    required this.tooltip,
    this.onTap,
  });

  final bool active;
  final String label;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? Colors.white : Colors.white.withOpacity(0.16);
    final fg = active ? LivingBkkBrand.brandRed : Colors.white;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active
                      ? Icons.visibility_rounded
                      : Icons.visibility_outlined,
                  size: 15,
                  color: fg,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1,
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.size,
    required this.icon,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 19, color: Colors.white),
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
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final hasActive = filters.hasActiveFilters;
    final query = filters.query?.trim();
    final hasQuery = query != null && query.isNotEmpty;
    final radius = BorderRadius.circular(HomeStickySearchHeader.searchHeight / 2);
    final hasActions = onMapSearch != null || onOpenFilters != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: LivingBkkBrand.warmCardShadow(opacity: 0.12),
      ),
      child: Material(
        color: p.surface,
        elevation: 0,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: LivingBkkBrand.brandRed.withOpacity(0.08),
              width: 1,
            ),
          ),
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
                          color: p.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: hasQuery
                              ? Text(
                                  query,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.2,
                                    fontWeight: FontWeight.w600,
                                    color: p.textPrimary,
                                  ),
                                )
                              : TypewriterHintLabel(
                                  fullText: s.searchDiscoveryTypewriterHint,
                                  cacheKey: 'home_search_capsule',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.2,
                                    fontWeight: FontWeight.w400,
                                    color: p.textSecondary,
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
        ),
      ),
    );
  }
}

class _CapsuleDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 1,
      height: 24,
      color: p.border,
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
    final p = context.palette;
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
            color: showBadge ? p.primary : p.textSecondary,
          ),
        ),
      ),
    );
  }
}
