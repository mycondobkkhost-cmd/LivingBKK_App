import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../services/favorites_service.dart';
import '../../services/listing_activity_service.dart';
import '../../services/platform_settings_service.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../utils/localized_content.dart';
import 'app_badge.dart';
import 'property_card_image_pager.dart';

/// Premium property card — ราคาบนรูป · สเปก/โครงการ/หัวข้อใต้รูป (แท็กทำเลอยู่หน้ารายละเอียด)
class AppPropertyCard extends StatelessWidget {
  const AppPropertyCard({
    super.key,
    required this.listing,
    this.onTap,
    this.showCoAgentStrip = false,
    this.width,
    this.showFavorite = true,
    this.enableImageSwipe = true,
    this.railScrollController,
    this.onImageDragStart,
    this.onImageDragEnd,
    this.compactBody = false,
    this.railCompact = false,
    this.highlightRecommended = false,
  });

  final ListingPublic listing;
  final VoidCallback? onTap;
  final bool showCoAgentStrip;
  final double? width;
  final bool showFavorite;
  final bool enableImageSwipe;
  final ScrollController? railScrollController;
  final VoidCallback? onImageDragStart;
  final VoidCallback? onImageDragEnd;
  /// ใช้บน HomeListingRail — ลด padding กันชนขอบล่าง
  final bool compactBody;
  /// แถวหน้าแรกแบบ PropertyHub — หัวข้อ + ทำเลอย่างเดียว
  final bool railCompact;
  /// ประกาศแนะนำ — ริบบิ้น Exclusive + ป้ายความนิยม
  final bool highlightRecommended;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = AppStrings.of(context);

    return SizedBox(
      width: width ?? double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final body = _CardBody(
            listing: listing,
            compactBody: compactBody,
            railCompact: railCompact,
            showCoAgentStrip: showCoAgentStrip,
            onTap: onTap,
          );
          final cardW = width ?? constraints.maxWidth;

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [AppTheme.cardShadowFor(p)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: compactBody ? 4 / 3 : 16 / 9,
                    child: enableImageSwipe && listing.imageUrls.length > 1
                        ? PropertyCardImagePager(
                            imageUrls: listing.imageUrls,
                            placeholder: _placeholder(p),
                            overlay: _ImageOverlay(
                              listing: listing,
                              showFavorite: showFavorite,
                              highlightRecommended: highlightRecommended,
                              compact: compactBody || railCompact,
                            ),
                            railScrollController: railScrollController,
                            railStep: cardW + 10,
                            onImageDragStart: onImageDragStart,
                            onImageDragEnd: onImageDragEnd,
                            onTap: onTap,
                          )
                        : GestureDetector(
                            onTap: onTap,
                            behavior: HitTestBehavior.opaque,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (listing.imageUrls.isNotEmpty)
                                  Image.network(
                                    listing.imageUrls.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholder(p),
                                  )
                                else
                                  _placeholder(p),
                                _ImageOverlay(
                                  listing: listing,
                                  showFavorite: showFavorite,
                                  highlightRecommended: highlightRecommended,
                                  compact: compactBody || railCompact,
                                ),
                              ],
                            ),
                          ),
                  ),
                  body,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder(AppPalette p) {
    return Container(
      color: p.primaryLight,
      child: Icon(Icons.apartment, size: 48, color: p.primary.withOpacity(0.5)),
    );
  }
}

class _ImageOverlay extends StatelessWidget {
  const _ImageOverlay({
    required this.listing,
    required this.showFavorite,
    required this.highlightRecommended,
    this.compact = false,
  });

  final ListingPublic listing;
  final bool showFavorite;
  final bool highlightRecommended;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    // แถวประกาศแนะนำ = ทรัพย์ Exclusive หาได้เฉพาะแอปนี้
    final showExclusiveRibbon = highlightRecommended;

    return ListenableBuilder(
      listenable: PlatformSettingsService.instance,
      builder: (context, _) {
        final activity = ListingActivityService.instance;
        final showHot = highlightRecommended &&
            activity.isHotListing(
              listing.id,
              demoEstimate: ListingActivityService.useDemoHotEstimate,
            );

        return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        if (showExclusiveRibbon)
          _ExclusiveRibbon(compact: compact),
        if (showFavorite)
          Positioned(
            top: compact ? 6 : 8,
            right: compact ? 6 : 8,
            child: _FavoriteHeart(listingId: listing.id, compact: compact),
          ),
        if (showHot)
          Positioned(
            right: compact ? 6 : 8,
            top: showFavorite ? (compact ? 38 : 46) : (compact ? 6 : 8),
            child: _HotBadge(label: s.listingHotLabel),
          ),
        Positioned(
          left: compact ? 6 : 8,
          bottom: compact ? 6 : 8,
          child: _ImagePriceBadge(
            listing: listing,
            perMonthLabel: s.perMonth,
            compact: compact,
          ),
        ),
      ],
        );
      },
    );
  }
}

/// ป้าย Exclusive มุมซ้ายบนรูป — อังกฤษอย่างเดียว สไตล์ PropertyHub
class _ExclusiveRibbon extends StatelessWidget {
  const _ExclusiveRibbon({this.compact = false});

  final bool compact;

  static const _red = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: _red,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 7 : 8,
            compact ? 4 : 5,
            compact ? 9 : 10,
            compact ? 4 : 5,
          ),
          child: Text(
            'Exclusive',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 0.15,
            ),
          ),
        ),
      ),
    );
  }
}

/// ป้าย HOT — แสดงเมื่อวิว ≥ 100/ชม.
class _HotBadge extends StatelessWidget {
  const _HotBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF8A00),
            Color(0xFFFF3D00),
            Color(0xFFE53935),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5722).withOpacity(0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 4, 8, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🔥',
              style: TextStyle(fontSize: 13, height: 1),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                height: 1,
                shadows: [
                  Shadow(
                    color: Color(0x99000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePriceBadge extends StatelessWidget {
  const _ImagePriceBadge({
    required this.listing,
    required this.perMonthLabel,
    this.compact = false,
  });

  final ListingPublic listing;
  final String perMonthLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final price = NumberFormat.currency(
      locale: locale,
      symbol: '฿',
      decimalDigits: 0,
    ).format(listing.priceNet);
    final isRent = listing.listingType == 'rent';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 3 : 5,
        ),
        child: isRent
            ? Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    TextSpan(
                      text: ' $perMonthLabel',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: compact ? 9 : 10,
                        fontWeight: FontWeight.w600,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
              )
            : Text(
                price,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.listing,
    required this.compactBody,
    required this.railCompact,
    required this.showCoAgentStrip,
    this.onTap,
  });

  final ListingPublic listing;
  final bool compactBody;
  final bool railCompact;
  final bool showCoAgentStrip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = AppStrings.of(context);
    final en = s.isEnglish;
    final specs = listing.listingCardSpecItems(s);
    final project = listing.localizedProjectName(en);
    final district = listing.localizedDistrict(en);
    final hPad = railCompact ? 8.0 : (compactBody ? 10.0 : 12.0);
    final vPad = railCompact ? 6.0 : (compactBody ? 4.0 : 12.0);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!railCompact && specs.isNotEmpty) ...[
              _ListingSpecStrip(items: specs, palette: p, compact: compactBody),
              SizedBox(height: compactBody ? 4 : 6),
            ],
            if (!railCompact && project != null && project.isNotEmpty) ...[
              Text(
                project,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compactBody ? 11.5 : 12,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: p.textSecondary,
                ),
              ),
              SizedBox(height: compactBody ? 2 : 4),
            ],
            Text(
              listing.localizedTitle(en),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: railCompact ? 12.5 : (compactBody ? 13.5 : 14.5),
                height: 1.2,
                color: p.textPrimary,
              ),
            ),
            if (railCompact && district != null && district.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 12, color: p.primary),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      district,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.15,
                        color: p.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (!railCompact && showCoAgentStrip && listing.coAgentEligible) ...[
              SizedBox(height: compactBody ? 5 : 8),
              AppBadge(label: s.coAgentEligible, tone: AppBadgeTone.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListingSpecStrip extends StatelessWidget {
  const _ListingSpecStrip({
    required this.items,
    required this.palette,
    required this.compact,
  });

  final List<({IconData icon, String label})> items;
  final AppPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 12.0 : 13.0;
    final fontSize = compact ? 10.0 : 10.5;
    final gap = compact ? 8.0 : 10.0;

    return SizedBox(
      height: fontSize * 1.2 + 2,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Flexible(
              fit: FlexFit.loose,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].icon,
                    size: iconSize,
                    color: palette.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      items[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FavoriteHeart extends StatefulWidget {
  const _FavoriteHeart({required this.listingId, this.compact = false});

  final String listingId;
  final bool compact;

  @override
  State<_FavoriteHeart> createState() => _FavoriteHeartState();
}

class _FavoriteHeartState extends State<_FavoriteHeart> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesService.instance,
      builder: (context, _) {
        final fav = FavoritesService.instance.isFavorite(widget.listingId);
        return Material(
          color: Colors.black38,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => FavoritesService.instance.toggle(widget.listingId),
            child: Padding(
              padding: EdgeInsets.all(widget.compact ? 6 : 8),
              child: Icon(
                fav ? Icons.favorite : Icons.favorite_border,
                size: widget.compact ? 17 : 20,
                color: fav ? const Color(0xFFFF5B8A) : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
