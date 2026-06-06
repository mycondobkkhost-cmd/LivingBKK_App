import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/bangkok_transit_lines.dart';
import '../../data/popular_areas.dart';
import '../../data/property_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../features/notifications/notification_center_sheet.dart';
import '../../services/home_sections_builder.dart';
import '../../state/locale_controller.dart';
import '../../state/search_session_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../theme/living_bkk_brand.dart';
import '../home_listing_rail.dart';
import '../../utils/listing_navigation.dart';
import '../property_type_more_sheet.dart';
import 'home_promo_carousel.dart';
import 'home_quick_menu.dart';
import 'home_sticky_search_header.dart';
import '../../features/search/search_discovery_page.dart';
import '../../models/search_filters.dart';

/// หน้าแรก — premium Robinhood-style · ประกาศแนะนำ above the fold
class HomeBrowseLayout extends StatefulWidget {
  const HomeBrowseLayout({
    super.key,
    required this.roleController,
    required this.searchSession,
    required this.localeController,
    required this.filters,
    required this.listings,
    required this.sections,
    required this.isAgentPerspective,
    this.onFiltersChanged,
    this.onOpenFilters,
    this.onOpenProfile,
    this.onOpenMapSearch,
    this.onOpenNotifications,
    this.onTapListing,
    this.onViewAllSection,
    this.onOpenProject,
    this.onAreaTap,
    this.onTransitLineTap,
    this.selectedAreaSlug,
    this.selectedTransitSlug,
  });

  final UserRoleController roleController;
  final SearchSessionController searchSession;
  final LocaleController localeController;
  final SearchFilters filters;
  final List<ListingPublic> listings;
  final List<HomeFeedSection> sections;
  final bool isAgentPerspective;
  final ValueChanged<SearchFilters>? onFiltersChanged;
  final VoidCallback? onOpenFilters;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenMapSearch;
  final VoidCallback? onOpenNotifications;
  final void Function(ListingPublic)? onTapListing;
  final void Function(HomeFeedSection)? onViewAllSection;
  final void Function(String projectName, {String? projectSlug})? onOpenProject;
  final void Function(String slug)? onAreaTap;
  final void Function(BangkokTransitLine line)? onTransitLineTap;
  final String? selectedAreaSlug;
  final String? selectedTransitSlug;

  @override
  State<HomeBrowseLayout> createState() => _HomeBrowseLayoutState();
}

class _HomeBrowseLayoutState extends State<HomeBrowseLayout> {
  int _locationTab = 0;

  void _openSearchDiscovery(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => SearchDiscoveryPage(
          filters: widget.filters,
          isAgent: widget.isAgentPerspective,
          onFiltersChanged: widget.onFiltersChanged ?? (_) {},
          onOpenProject: widget.onOpenProject,
          onMapSearch: widget.onOpenMapSearch,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final recommended = widget.sections.where((e) => e.id == 'recommended').toList();
    final latest = widget.sections.where((e) => e.id == 'latest').toList();
    final others = widget.sections
        .where((e) => e.id != 'recommended' && e.id != 'latest')
        .toList();

    return ColoredBox(
      color: LivingBkkBrand.pageBackground,
      child: ScrollConfiguration(
        behavior: const _HomeBrowseScrollBehavior(),
        child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        HomeStickySearchHeader(
          roleController: widget.roleController,
          localeController: widget.localeController,
          filters: widget.filters,
          onFiltersChanged: widget.onFiltersChanged,
          onMapSearch: widget.onOpenMapSearch,
          onOpenProject: widget.onOpenProject,
          onOpenSearch: () => _openSearchDiscovery(context),
          onOpenFilters: widget.onOpenFilters,
          onOpenNotifications: widget.onOpenNotifications ??
              () => NotificationCenterSheet.show(
                    context,
                    roleController: widget.roleController,
                    localeController: widget.localeController,
                  ),
        ),
        SliverToBoxAdapter(
          child: HomePromoCarousel(localeController: widget.localeController),
        ),
        SliverToBoxAdapter(
          child: HomeQuickMenu(
            roleController: widget.roleController,
            searchSession: widget.searchSession,
            isAgent: widget.isAgentPerspective,
            onMapSearch: widget.onOpenMapSearch,
          ),
        ),
        if (recommended.isEmpty && widget.sections.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(s.noListings, style: TextStyle(color: p.textSecondary)),
            ),
          )
        else ...[
          for (final section in recommended)
            SliverToBoxAdapter(
              child: HomeListingRail(
                title: s.isEnglish ? section.titleEn : section.titleTh,
                items: section.items,
                accentIndex: section.accentIndex,
                highlightRecommended: true,
                showCoAgentStrip: widget.isAgentPerspective,
                onTapListing: widget.onTapListing ?? (_) {},
                onViewAll: () => widget.onViewAllSection?.call(section),
              ),
            ),
          for (final section in latest)
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -14),
                child: HomeListingRail(
                  title: s.isEnglish ? section.titleEn : section.titleTh,
                  items: section.items,
                  accentIndex: section.accentIndex,
                  topInset: 0,
                  showCoAgentStrip: widget.isAgentPerspective,
                  onTapListing: widget.onTapListing ?? (_) {},
                  onViewAll: () => widget.onViewAllSection?.call(section),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _LocationTabHeader(
              p: p,
              s: s,
              selected: _locationTab,
              onChanged: (i) => setState(() => _locationTab = i),
            ),
          ),
          SliverToBoxAdapter(
            child: _locationTab == 0
                ? _TopAreaCarousel(
                    p: p,
                    s: s,
                    selectedSlug: widget.selectedAreaSlug,
                    onAreaTap: widget.onAreaTap,
                  )
                : _TransitLineCarousel(
                    p: p,
                    s: s,
                    selectedSlug: widget.selectedTransitSlug,
                    onLineTap: widget.onTransitLineTap,
                  ),
          ),
          for (final section in others)
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -10),
                child: HomeListingRail(
                  title: s.isEnglish ? section.titleEn : section.titleTh,
                  items: section.items,
                  accentIndex: section.accentIndex,
                  topInset: 0,
                  showCoAgentStrip: widget.isAgentPerspective,
                  onTapListing: widget.onTapListing ?? (_) {},
                  onViewAll: () => widget.onViewAllSection?.call(section),
                ),
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 72)),
      ],
        ),
      ),
    );
  }
}

/// ซ่อน scrollbar — ไม่ให้แถบเลื่อนทับโซน header ม่วง (โดยเฉพาะบน Web)
class _HomeBrowseScrollBehavior extends MaterialScrollBehavior {
  const _HomeBrowseScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class _PropertyTypeCard extends StatelessWidget {
  const _PropertyTypeCard({
    required this.p,
    required this.s,
    required this.searchSession,
    required this.isAgent,
    this.onOpenFilters,
  });

  final AppPalette p;
  final AppStrings s;
  final SearchSessionController searchSession;
  final bool isAgent;
  final VoidCallback? onOpenFilters;

  static const _displaySlugs = ['condo', 'house', 'land', 'townhome'];

  void _onCategoryTap(BuildContext context, String? slug) {
    if (slug == null) {
      PropertyTypeMoreSheet.show(
        context,
        searchSession: searchSession,
        onCategoryPicked: (picked) {
          Navigator.of(context).pop();
          ListingNavigation.openCategory(context, slug: picked, isAgent: isAgent);
        },
      );
      return;
    }
    ListingNavigation.openCategory(context, slug: slug, isAgent: isAgent);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: searchSession,
      builder: (context, _) {
        final selected = searchSession.categorySlug;
        final items = [
          ...PropertyCatalog.categories.where((c) => _displaySlugs.contains(c.slug)),
          null,
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 6, LiLayout.pagePadding, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [AppTheme.cardShadowFor(p)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final cat in items)
                  _typeItem(
                    p,
                    icon: _iconFor(cat?.slug),
                    label: cat?.label(s.isEnglish) ?? s.homePropertyOthers,
                    tint: _tintFor(cat?.slug, p),
                    selected: cat != null
                        ? selected == cat.slug
                        : PropertyTypeMoreSheet.isMoreSlug(selected),
                    onTap: () => _onCategoryTap(context, cat?.slug),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(String? slug) => switch (slug) {
        'condo' => Icons.apartment_rounded,
        'house' => Icons.home_rounded,
        'land' => Icons.landscape_rounded,
        'townhome' => Icons.other_houses_rounded,
        _ => Icons.grid_view_rounded,
      };

  Color _tintFor(String? slug, AppPalette p) => switch (slug) {
        'condo' => p.primary,
        'house' => const Color(0xFF4DA8FF),
        'land' => const Color(0xFF10B981),
        'townhome' => const Color(0xFFF59E0B),
        _ => p.accent,
      };

  Widget _typeItem(
    AppPalette p, {
    required IconData icon,
    required String label,
    required Color tint,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tint.withOpacity(selected ? 0.22 : 0.12),
                  shape: BoxShape.circle,
                  border: selected ? Border.all(color: tint, width: 2) : null,
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: LiLayout.homeCardSubtitle,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationTabHeader extends StatelessWidget {
  const _LocationTabHeader({
    required this.p,
    required this.s,
    required this.selected,
    required this.onChanged,
  });

  final AppPalette p;
  final AppStrings s;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 8, LiLayout.pagePadding, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: p.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Row(
          children: [
            Expanded(
              child: _tab(
                p,
                s.homeTabPopularAreas,
                selected == 0,
                () => onChanged(0),
              ),
            ),
            Expanded(
              child: _tab(
                p,
                s.homeTabTransitLines,
                selected == 1,
                () => onChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(AppPalette p, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animNormal,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(colors: [p.primary, p.accent.withOpacity(0.85)])
              : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          boxShadow: active
              ? [BoxShadow(color: p.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : p.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TopAreaCarousel extends StatelessWidget {
  const _TopAreaCarousel({
    required this.p,
    required this.s,
    this.selectedSlug,
    this.onAreaTap,
  });

  final AppPalette p;
  final AppStrings s;
  final String? selectedSlug;
  final void Function(String slug)? onAreaTap;

  @override
  Widget build(BuildContext context) {
    final areas = PopularAreas.all.take(6).toList();

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 0, LiLayout.pagePadding, 8),
        itemCount: areas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final area = areas[i];
          final selected = selectedSlug == area.slug;
          return _AreaTile(
            p: p,
            name: area.name(s.isEnglish),
            imageUrl: area.imageUrl,
            rank: i + 1,
            selected: selected,
            onTap: () => onAreaTap?.call(area.slug),
          );
        },
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.p,
    required this.name,
    required this.imageUrl,
    required this.rank,
    required this.selected,
    this.onTap,
  });

  final AppPalette p;
  final String name;
  final String imageUrl;
  final int rank;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: AppTheme.animNormal,
          width: 148,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: p.primary, width: 2.5) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: p.primaryLight),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.72)],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LivingBkkBrand.ctaGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Top $rank 🔥',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.15,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransitLineCarousel extends StatelessWidget {
  const _TransitLineCarousel({
    required this.p,
    required this.s,
    this.selectedSlug,
    this.onLineTap,
  });

  final AppPalette p;
  final AppStrings s;
  final String? selectedSlug;
  final void Function(BangkokTransitLine line)? onLineTap;

  @override
  Widget build(BuildContext context) {
    final lines = BangkokTransitLines.all;

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 0, LiLayout.pagePadding, 8),
        itemCount: lines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final line = lines[i];
          return _TransitLineTile(
            line: line,
            isEnglish: s.isEnglish,
            selected: selectedSlug == line.slug,
            onTap: () => onLineTap?.call(line),
          );
        },
      ),
    );
  }
}

class _TransitLineTile extends StatelessWidget {
  const _TransitLineTile({
    required this.line,
    required this.isEnglish,
    required this.selected,
    this.onTap,
  });

  final BangkokTransitLine line;
  final bool isEnglish;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textOnLine = line.color.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: AppTheme.animNormal,
          width: 156,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? line.color : line.color.withOpacity(0.45),
              width: selected ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: line.color.withOpacity(selected ? 0.35 : 0.18),
                blurRadius: selected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://picsum.photos/seed/livingbkk-${line.imageSeed}/800/480',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(color: line.color.withOpacity(0.35)),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      line.color.withOpacity(0.82),
                      line.color.withOpacity(0.55),
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    line.system(isEnglish),
                    style: TextStyle(
                      color: line.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      line.name(isEnglish),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textOnLine,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.15,
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      line.stations(isEnglish),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textOnLine.withOpacity(0.92),
                        fontSize: 10,
                        height: 1.25,
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
