import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/bangkok_transit_lines.dart';
import '../../data/popular_areas.dart';
import '../../data/property_catalog.dart';
import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../services/brand_service.dart';
import '../../services/home_sections_builder.dart';
import '../../state/locale_controller.dart';
import '../../state/search_session_controller.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../theme/living_bkk_brand.dart';
import '../home_listing_rail.dart';
import '../living_bkk_logo.dart';
import '../perspective_dropdown_chip.dart';
import '../../utils/listing_navigation.dart';
import '../../config/demand_board_menu_config.dart';
import '../../navigation/demand_board_navigation.dart';
import '../post_listing_promo_banner.dart';
import '../property_manage_banner.dart';
import '../property_type_more_sheet.dart';
import '../smart_search_bar.dart';
import '../../config/post_listing_menu_config.dart';
import '../../navigation/post_listing_navigation.dart';
import '../../shell/main_shell_scope.dart';
import '../../features/search/search_discovery_page.dart';
import '../../models/search_filters.dart';

/// หน้าแรก — layout อ้างอิง LivingInsider-style + ธีมม่วง LivingBKK
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

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: _HeroBlock(
            p: p,
            s: s,
            roleController: widget.roleController,
            localeController: widget.localeController,
            onOpenNotifications:
                widget.onOpenNotifications ?? widget.onOpenProfile,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LiLayout.pagePadding,
              12,
              LiLayout.pagePadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchCard(
                  filters: widget.filters,
                  onFiltersChanged: widget.onFiltersChanged,
                  onMapSearch: widget.onOpenMapSearch,
                  onOpenProject: widget.onOpenProject,
                  onOpenDiscovery: () => _openSearchDiscovery(context),
                ),
                  if (widget.onOpenFilters != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: widget.onOpenFilters,
                          icon: Icon(
                            Icons.tune,
                            size: 18,
                            color: widget.filters.hasActiveFilters
                                ? p.primary
                                : p.textSecondary,
                          ),
                          label: Text(
                            widget.filters.hasActiveFilters
                                ? s.filtersActive
                                : s.advancedFilters,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.filters.hasActiveFilters
                                  ? p.primary
                                  : p.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: PostListingPromoBanner(roleController: widget.roleController),
        ),
        SliverToBoxAdapter(
          child: PropertyManageBanner(roleController: widget.roleController),
        ),
        SliverToBoxAdapter(
          child: _PropertyTypeCard(
            p: p,
            s: s,
            searchSession: widget.searchSession,
            isAgent: widget.isAgentPerspective,
            onOpenFilters: widget.onOpenFilters,
          ),
        ),
        SliverToBoxAdapter(
          child: _QuickActionCards(
            p: p,
            s: s,
            roleController: widget.roleController,
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
                showCoAgentStrip: widget.isAgentPerspective,
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
                showCoAgentStrip: widget.isAgentPerspective,
                onTapListing: widget.onTapListing ?? (_) {},
                onViewAll: () => widget.onViewAllSection?.call(section),
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
              child: HomeListingRail(
                title: s.isEnglish ? section.titleEn : section.titleTh,
                items: section.items,
                accentIndex: section.accentIndex,
                showCoAgentStrip: widget.isAgentPerspective,
                onTapListing: widget.onTapListing ?? (_) {},
                onViewAll: () => widget.onViewAllSection?.call(section),
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 108)),
      ],
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({
    required this.p,
    required this.s,
    required this.roleController,
    required this.localeController,
    this.onOpenNotifications,
  });

  final AppPalette p;
  final AppStrings s;
  final UserRoleController roleController;
  final LocaleController localeController;
  final VoidCallback? onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.primary.withOpacity(0.22),
            p.accent.withOpacity(0.12),
            p.background,
          ],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: LiLayout.pagePadding,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ListenableBuilder(
                    listenable: localeController,
                    builder: (context, _) => LivingBkkLogo(
                      size: LivingBkkLogoSize.lg,
                      onGradient: true,
                      isEnglish: localeController.isEnglish,
                    ),
                  ),
                ),
              ),
              PerspectiveDropdownChip(
                controller: roleController,
                localeController: localeController,
              ),
              const SizedBox(width: 6),
              Material(
                color: p.surface,
                shape: const CircleBorder(),
                elevation: 2,
                shadowColor: p.cardShadow,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: Icon(Icons.notifications_outlined, color: p.primary, size: 22),
                  onPressed: onOpenNotifications,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: localeController,
            builder: (context, _) {
              final brand = BrandService.instance.settings;
              return Text(
                brand.tagline(localeController.isEnglish),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: GoogleFonts.prompt(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: LivingBkkBrand.loginSubSloganColor.withOpacity(0.95),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.filters,
    this.onFiltersChanged,
    this.onMapSearch,
    this.onOpenProject,
    this.onOpenDiscovery,
  });

  final SearchFilters filters;
  final ValueChanged<SearchFilters>? onFiltersChanged;
  final VoidCallback? onMapSearch;
  final void Function(String projectName, {String? projectSlug})? onOpenProject;
  final VoidCallback? onOpenDiscovery;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: p.primary.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: p.primary.withOpacity(0.18),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onOpenDiscovery,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: IgnorePointer(
          child: SmartSearchBar(
            filters: filters,
            onFiltersChanged: onFiltersChanged ?? (_) {},
            style: SearchBarStyle.airbnb,
            onMapSearch: onMapSearch,
            onOpenProject: onOpenProject,
          ),
        ),
      ),
    );
  }
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
          null, // others → เปิดตัวกรอง
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
                  border: selected
                      ? Border.all(color: tint, width: 2)
                      : null,
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
                  fontSize: 10,
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

class _QuickActionCards extends StatelessWidget {
  const _QuickActionCards({
    required this.p,
    required this.s,
    required this.roleController,
  });

  final AppPalette p;
  final AppStrings s;
  final UserRoleController roleController;


  @override
  Widget build(BuildContext context) {
    final topCards = <_QuickCardData>[
      if (DemandBoardMenuConfig.showHomeQuickRequirement(roleController))
        _QuickCardData(
          title: s.homeQuickHelperTitle,
          subtitle: s.homeQuickHelperBody,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF10B981).withOpacity(0.18),
              const Color(0xFFD1FAE5),
            ],
          ),
          accent: const Color(0xFF059669),
          icon: Icons.manage_search_rounded,
          onTap: () => DemandBoardNavigation.openCreateRequirement(context),
        ),
      if (PostListingMenuConfig.showHomeQuickPost(roleController))
        _QuickCardData(
          title: s.homeQuickOwnerTitle,
          subtitle: s.homeQuickOwnerBody,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              p.primary.withOpacity(0.14),
              p.primaryLight,
            ],
          ),
          accent: p.primary,
          icon: Icons.campaign_outlined,
          onTap: () => PostListingNavigation.openCreateWithAuthGate(context),
        ),
      if (DemandBoardMenuConfig.showHomeQuickBoard(roleController))
        _QuickCardData(
          title: s.homeQuickBoardTitle,
          subtitle: s.homeQuickBoardBody,
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF59E0B).withOpacity(0.2),
              const Color(0xFFFEF3C7),
            ],
          ),
          accent: const Color(0xFFD97706),
          icon: Icons.forum_outlined,
          onTap: () => DemandBoardNavigation.openBoardTab(context),
        ),
    ];

    final manageCard = PostListingMenuConfig.showsFor(roleController)
        ? _QuickCardData(
            title: s.homeQuickManageTitle,
            subtitle: s.homeQuickManageBody,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.primary, p.accent.withOpacity(0.92)],
            ),
            accent: p.primary,
            icon: Icons.dashboard_customize_rounded,
            onTap: () => PostListingNavigation.openMyListings(context),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 6, LiLayout.pagePadding, 4),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < topCards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _QuickCard(
                      data: topCards[i],
                      palette: p,
                      onTap: topCards[i].onTap,
                      compact: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (manageCard != null) ...[
            const SizedBox(height: 10),
            _FeaturedQuickCard(
              data: manageCard,
              palette: p,
              onTap: manageCard.onTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickCardData {
  const _QuickCardData({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accent,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color accent;
  final IconData icon;
  final VoidCallback? onTap;
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.data,
    required this.palette,
    this.onTap,
    this.compact = false,
  });

  final _QuickCardData data;
  final AppPalette palette;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            gradient: data.gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: data.accent.withOpacity(0.28)),
            boxShadow: [AppTheme.cardShadowFor(palette)],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(data.icon, size: compact ? 20 : 24, color: data.accent),
                SizedBox(height: compact ? 6 : 8),
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 11 : 13,
                    height: 1.15,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: compact ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    height: 1.25,
                    color: palette.textSecondary,
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

class _FeaturedQuickCard extends StatelessWidget {
  const _FeaturedQuickCard({
    required this.data,
    required this.palette,
    this.onTap,
  });

  final _QuickCardData data;
  final AppPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            gradient: data.gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: palette.accent.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white.withOpacity(0.85)),
              ],
            ),
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
      padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 16, LiLayout.pagePadding, 10),
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
        padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 0, LiLayout.pagePadding, 16),
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
        padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 0, LiLayout.pagePadding, 16),
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
