import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/popular_areas.dart';
import '../l10n/app_strings.dart';
import '../models/listing_public.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';
import '../utils/geo_zone_match.dart';

/// ทำเลยอดฮิต — grid การ์ดภาพใหญ่แบบ RentHub กดเพื่อกรองตาม geo zone
class PopularAreasSection extends StatefulWidget {
  const PopularAreasSection({
    super.key,
    required this.onAreaTap,
    this.selectedSlug,
    this.listings = const [],
    this.pages = PopularAreas.pages,
  });

  final void Function(String slug) onAreaTap;
  final String? selectedSlug;
  final List<ListingPublic> listings;
  final List<PopularAreasPageLayout> pages;

  static const _rowGap = 10.0;
  static const _fullRowHeight = 128.0;
  static const _halfRowHeight = 120.0;
  static const _radius = 16.0;

  @override
  State<PopularAreasSection> createState() => _PopularAreasSectionState();
}

class _PopularAreasSectionState extends State<PopularAreasSection> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _countForArea(PopularArea area) {
    if (widget.listings.isEmpty) return 0;
    return widget.listings
        .where(
          (l) => listingMatchesGeoZones(
            slugs: [area.slug],
            district: l.district,
            projectName: l.projectName,
            title: l.title,
          ),
        )
        .length;
  }

  double _pageHeight(PopularAreasPageLayout page) {
    var h = 0.0;
    for (var i = 0; i < page.rows.length; i++) {
      h += page.rows[i].isFull
          ? PopularAreasSection._fullRowHeight
          : PopularAreasSection._halfRowHeight;
      if (i < page.rows.length - 1) h += PopularAreasSection._rowGap;
    }
    return h;
  }

  double get _maxPageHeight {
    if (widget.pages.isEmpty) return 0;
    return widget.pages.map(_pageHeight).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (widget.pages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LiLayout.pagePadding,
            20,
            LiLayout.pagePadding,
            8,
          ),
          child: Text(
            s.popularAreasTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.25,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 0, LiLayout.pagePadding, 12),
          child: Text(
            s.popularAreasHint,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ),
        SizedBox(
          height: _maxPageHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.pages.length,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (context, pageIdx) {
              final page = widget.pages[pageIdx];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: LiLayout.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var r = 0; r < page.rows.length; r++) ...[
                      if (r > 0) const SizedBox(height: PopularAreasSection._rowGap),
                      _buildRow(context, page.rows[r], s),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.pages.length > 1) ...[
          const SizedBox(height: 12),
          _PageDots(count: widget.pages.length, index: _pageIndex),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildRow(BuildContext context, PopularAreasRowLayout row, AppStrings s) {
    if (row.isFull) {
      final area = PopularAreas.bySlug(row.slugs.first);
      if (area == null) return const SizedBox.shrink();
      return _AreaCard(
        area: area,
        isEnglish: s.isEnglish,
        selected: widget.selectedSlug == area.slug,
        listingCount: _countForArea(area),
        height: PopularAreasSection._fullRowHeight,
        onTap: () => widget.onAreaTap(area.slug),
      );
    }

    return SizedBox(
      height: PopularAreasSection._halfRowHeight,
      child: Row(
        children: [
          for (var i = 0; i < row.slugs.length; i++) ...[
            if (i > 0) const SizedBox(width: PopularAreasSection._rowGap),
            Expanded(
              child: Builder(
                builder: (context) {
                  final area = PopularAreas.bySlug(row.slugs[i]);
                  if (area == null) return const SizedBox.shrink();
                  return _AreaCard(
                    area: area,
                    isEnglish: s.isEnglish,
                    selected: widget.selectedSlug == area.slug,
                    listingCount: _countForArea(area),
                    height: PopularAreasSection._halfRowHeight,
                    compact: true,
                    onTap: () => widget.onAreaTap(area.slug),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 8 : 7,
          height: active ? 8 : 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppTheme.primary : AppTheme.border,
          ),
        );
      }),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.isEnglish,
    required this.selected,
    required this.listingCount,
    required this.height,
    required this.onTap,
    this.compact = false,
  });

  final PopularArea area;
  final bool isEnglish;
  final bool selected;
  final int listingCount;
  final double height;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final countLabel = listingCount > 0
        ? s.popularAreaListingCount(listingCount)
        : s.popularAreaBrowse;

    return Semantics(
      button: true,
      selected: selected,
      label: area.name(isEnglish),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PopularAreasSection._radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PopularAreasSection._radius),
              border: selected
                  ? Border.all(color: AppTheme.primary, width: 2.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(selected ? 0.14 : 0.08),
                  blurRadius: selected ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  area.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.primaryLight,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.location_city,
                      size: compact ? 28 : 36,
                      color: AppTheme.primary.withOpacity(0.45),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.72),
                      ],
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                    ),
                  ),
                Positioned(
                  left: compact ? 12 : 16,
                  right: compact ? 12 : 16,
                  bottom: compact ? 12 : 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        area.name(isEnglish),
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 15 : 18,
                          height: 1.15,
                          shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        countLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
