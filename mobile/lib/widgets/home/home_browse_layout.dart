import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/bangkok_transit_lines.dart';
import '../../data/popular_areas.dart';
import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../features/notifications/notification_center_sheet.dart';
import '../../services/home_sections_builder.dart';
import '../../state/locale_controller.dart';
import '../../state/search_session_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../theme/fb_feed_chrome.dart';
import '../home_listing_rail.dart';
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
    final updatedToday =
        widget.sections.where((e) => e.id == 'updated_today').toList();
    final latest = widget.sections.where((e) => e.id == 'latest').toList();
    final others = widget.sections
        .where(
          (e) =>
              e.id != 'recommended' &&
              e.id != 'latest' &&
              e.id != 'updated_today',
        )
        .toList();
    final showPostFab =
        HomePostListingFab.visibleFor(widget.roleController);

    return ColoredBox(
      color: FbFeedChrome.background,
      child: Stack(
        children: [
          ScrollConfiguration(
            behavior: const _HomeBrowseScrollBehavior(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
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
                // ทางลัด → โฆษณา → หมวด → ทำเล → ประกาศ
                // (เช่า/ซื้อ/ตัวกรอง — เปิดจากไอคอนในช่องค้นหา)
                SliverToBoxAdapter(
                  child: HomeQuickMenu(
                    roleController: widget.roleController,
                    searchSession: widget.searchSession,
                    isAgent: widget.isAgentPerspective,
                    onMapSearch: widget.onOpenMapSearch,
                    showBoard: true,
                    showCategories: false,
                  ),
                ),
                SliverToBoxAdapter(
                  child: HomePromoCarousel(
                    localeController: widget.localeController,
                  ),
                ),
                SliverToBoxAdapter(
                  child: HomeQuickMenu(
                    roleController: widget.roleController,
                    searchSession: widget.searchSession,
                    isAgent: widget.isAgentPerspective,
                    onMapSearch: widget.onOpenMapSearch,
                    showBoard: false,
                    showCategories: true,
                  ),
                ),
                SliverToBoxAdapter(
                  child: FbFeedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: FbFeedChrome.sectionHeaderPadding,
                          child: Text(
                            s.homeTabPopularAreas,
                            style: FbFeedChrome.sectionTitleStyle,
                          ),
                        ),
                        _TopAreaCarousel(
                          p: p,
                          s: s,
                          selectedSlug: widget.selectedAreaSlug,
                          onAreaTap: widget.onAreaTap,
                        ),
                      ],
                    ),
                  ),
                ),
                if (recommended.isEmpty && widget.sections.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        s.noListings,
                        style: TextStyle(color: p.textSecondary),
                      ),
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
                  for (final section in updatedToday)
                    SliverToBoxAdapter(
                      child: HomeListingHScroll(
                        title: s.isEnglish ? section.titleEn : section.titleTh,
                        items: section.items,
                        accentIndex: section.accentIndex,
                        onTapListing: widget.onTapListing ?? (_) {},
                        onViewAll: () => widget.onViewAllSection?.call(section),
                      ),
                    ),
                  for (final section in latest)
                    SliverToBoxAdapter(
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
                  for (final section in others)
                    SliverToBoxAdapter(
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
                ],
                SliverToBoxAdapter(
                  child: SizedBox(height: showPostFab ? 96 : 72),
                ),
              ],
            ),
          ),
          if (showPostFab)
            Positioned(
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: HomePostListingFab(
                  roleController: widget.roleController,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ซ่อน scrollbar — ไม่ให้แถบเลื่อนทับโซน header แดง (โดยเฉพาะบน Web)
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
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemCount: areas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: AppTheme.animNormal,
          width: 118,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: selected ? Border.all(color: p.primary, width: 2) : null,
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
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.68),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: LivingBkkBrand.brandRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Top $rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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
