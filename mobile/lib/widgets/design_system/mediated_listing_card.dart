import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../services/favorites_service.dart';
import '../../theme/app_palette.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/listing_price_helpers.dart';
import '../../utils/localized_content.dart';

/// การ์ดกริด 2 คอลัมน์นอกหน้าแรก — สไตล์ marketplace แนวอสังหา (ไม่โชว์ Owner)
class MediatedListingCard extends StatelessWidget {
  const MediatedListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.width,
    this.showFavorite = true,
    this.showCoAgentStrip = false,
    this.highlightRecommended = false,
    this.browseFilter,
    this.livingCover = true,
    this.imageAspectOverride,
  });

  final ListingPublic listing;
  final VoidCallback? onTap;
  final double? width;
  final bool showFavorite;
  /// โหมดเอเจนต์ — แสดงป้ายรับ Co-Agent ถ้าประกาศเปิดรับโค
  final bool showCoAgentStrip;
  final bool highlightRecommended;
  final String? browseFilter;
  final bool livingCover;
  /// override อัตราส่วนรูป (กว้าง/สูง) — ใช้ทำ masonry เหลื่อม
  final double? imageAspectOverride;

  /// กว้าง:สูง ของรูป — แนวตั้งสูงแบบ iStock (ต่ำกว่า 1 = สูงขึ้น)
  static const double imageAspectRatio = 0.78;

  /// จังหวะความสูงรูปแบบเหลื่อม — คอลัมน์ซ้าย/ขวาไม่เท่ากัน
  static double imageAspectForIndex(int index) {
    const variants = <double>[0.72, 0.88, 0.68, 0.82, 0.76, 0.92];
    return variants[index % variants.length];
  }

  /// ประมาณความสูงสำหรับ ListView / กริด
  static double estimatedHeight(
    double cardWidth, {
    double textScale = 1,
    double? aspectRatio,
  }) {
    final scale = textScale.clamp(1.0, 1.35);
    final aspect = aspectRatio ?? imageAspectRatio;
    return cardWidth / aspect + 158 * scale;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = AppStrings.of(context);
    final en = s.isEnglish;
    final showCo = showCoAgentStrip && listing.coAgentEligible;
    final aspect = imageAspectOverride ?? imageAspectRatio;

    return Material(
      color: p.surface,
      elevation: 0.25,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: aspect,
              child: _ImageBlock(
                listing: listing,
                showFavorite: showFavorite,
                living: livingCover,
                txnLabel: s.listingTransactionRibbonLabel(listing.listingType),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _PropertyTypePill(
                        label: s.propertyTypeChip(listing.propertyType),
                      ),
                      if (highlightRecommended) ...[
                        const SizedBox(width: 4),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: LivingBkkBrand.brandRedTint,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            child: Text(
                              s.marketplaceRecommendedBadge,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                color: LivingBkkBrand.brandRedDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  _PriceBlock(
                    listing: listing,
                    perMonthLabel: s.perMonth,
                    browseFilter: browseFilter,
                  ),
                  if (showCo) ...[
                    const SizedBox(height: 2),
                    Text(
                      s.coAgentEligible,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        color: LivingBkkBrand.accentOrange,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    listing.localizedTitle(en),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _LocationAgoRow(
                    listing: listing,
                    s: s,
                    palette: p,
                    isEnglish: en,
                  ),
                  const SizedBox(height: 5),
                  _SpecIconsRow(listing: listing, s: s, palette: p),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({
    required this.listing,
    required this.showFavorite,
    required this.living,
    required this.txnLabel,
  });

  final ListingPublic listing;
  final bool showFavorite;
  final bool living;
  final String txnLabel;

  Color _txnColor(String? type) {
    switch (type) {
      case 'rent':
        return const Color(0xFF1565C0);
      case 'sale':
        return LivingBkkBrand.brandRed;
      case 'sale_installment':
        return LivingBkkBrand.brandRedDark;
      case 'rent_and_sale':
        return LivingBkkBrand.accentOrange;
      default:
        return LivingBkkBrand.brandRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (listing.imageUrls.isNotEmpty)
          living
              ? _LivingCover(urls: listing.imageUrls, seed: listing.id)
              : Image.network(
                  listing.imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(p),
                )
        else
          _placeholder(p),
        Positioned(
          top: 0,
          left: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _txnColor(listing.listingType),
              borderRadius:
                  const BorderRadius.only(bottomRight: Radius.circular(6)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
              child: Text(
                txnLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
        if (showFavorite)
          Positioned(
            top: 4,
            right: 4,
            child: _FavHeart(listingId: listing.id),
          ),
      ],
    );
  }

  Widget _placeholder(AppPalette p) => ColoredBox(
        color: p.primaryLight,
        child: Icon(Icons.apartment, color: p.primary.withOpacity(0.4)),
      );
}

class _LivingCover extends StatefulWidget {
  const _LivingCover({required this.urls, required this.seed});

  final List<String> urls;
  final String seed;

  static const int dwellMs = 3600;
  static const int waveSlots = 7;
  static const Duration slideDuration = Duration(milliseconds: 360);

  @override
  State<_LivingCover> createState() => _LivingCoverState();
}

class _LivingCoverState extends State<_LivingCover> {
  static const int _loopBase = 500;

  late final PageController _page;
  late final int _startPage;
  Timer? _slideTimer;
  int _index = 0;
  bool _animating = false;

  int get _n => widget.urls.length;

  int _seedHash() {
    var h = 0;
    for (final c in widget.seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  Duration get _initialDelay {
    final slot = _seedHash() % _LivingCover.waveSlots;
    final step = _LivingCover.dwellMs ~/ _LivingCover.waveSlots;
    return Duration(milliseconds: 200 + slot * step);
  }

  @override
  void initState() {
    super.initState();
    final n = _n.clamp(1, 99);
    _startPage = _loopBase * n;
    _page = PageController(initialPage: _startPage);
    _index = 0;
    if (n > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _schedule(_initialDelay);
      });
    }
  }

  void _schedule(Duration delay) {
    _slideTimer?.cancel();
    if (_n < 2) return;
    _slideTimer = Timer(delay, _advance);
  }

  Future<void> _advance() async {
    if (!mounted || _n < 2 || !_page.hasClients || _animating) {
      _schedule(Duration(milliseconds: _LivingCover.dwellMs));
      return;
    }
    if (!TickerMode.of(context)) {
      _schedule(const Duration(milliseconds: 800));
      return;
    }

    _animating = true;
    final current = _page.page?.round() ?? _startPage;
    try {
      await _page.animateToPage(
        current + 1,
        duration: _LivingCover.slideDuration,
        curve: Curves.easeInOutCubic,
      );
    } catch (_) {}
    _animating = false;
    if (!mounted) return;
    _schedule(Duration(milliseconds: _LivingCover.dwellMs));
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _page.dispose();
    super.dispose();
  }

  Widget _image(String url, AppPalette p) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: p.primaryLight,
        child: Icon(Icons.apartment, color: p.primary.withOpacity(0.4)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final urls = widget.urls;
    if (urls.length == 1) return _image(urls.first, p);

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _page,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, page) {
            final i = page % _n;
            return _image(urls[i], p);
          },
          onPageChanged: (page) {
            final i = page % _n;
            if (i != _index && mounted) setState(() => _index = i);
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 5,
          child: IgnorePointer(
            child: _CoverDots(count: _n, index: _index),
          ),
        ),
      ],
    );
  }
}

class _CoverDots extends StatelessWidget {
  const _CoverDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: i == index ? 11 : 5,
            height: 3.5,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(i == index ? 0.95 : 0.42),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FavHeart extends StatefulWidget {
  const _FavHeart({required this.listingId});

  final String listingId;

  @override
  State<_FavHeart> createState() => _FavHeartState();
}

class _FavHeartState extends State<_FavHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0.85,
      upperBound: 1.15,
      value: 1,
    );
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    await _pop.forward();
    await _pop.reverse();
    FavoritesService.instance.toggle(widget.listingId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesService.instance,
      builder: (context, _) {
        final fav = FavoritesService.instance.isFavorite(widget.listingId);
        return ScaleTransition(
          scale: _pop,
          child: Material(
            color: Colors.black38,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    fav ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(fav),
                    size: 14,
                    color: fav ? const Color(0xFFFF5B8A) : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PropertyTypePill extends StatelessWidget {
  const _PropertyTypePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: LivingBkkBrand.brandRedTint,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: LivingBkkBrand.brandRedDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.listing,
    required this.perMonthLabel,
    this.browseFilter,
  });

  final ListingPublic listing;
  final String perMonthLabel;
  final String? browseFilter;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: '฿',
      decimalDigits: 0,
    );
    final isRent =
        ListingPriceHelpers.showPerMonth(listing, browseFilter: browseFilter);
    final display = ListingPriceHelpers.displayAmount(
      listing,
      browseFilter: browseFilter,
      rentSide: isRent,
    );
    final strike = ListingPriceHelpers.strikethroughAmount(
      listing,
      browseFilter: browseFilter,
      rentSide: isRent,
    );
    int? discountPct;
    if (strike != null && strike > 0 && display < strike) {
      discountPct = (((strike - display) / strike) * 100).round();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            fmt.format(display),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LivingBkkBrand.brandRed,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        if (isRent)
          Text(
            perMonthLabel,
            style: TextStyle(
              color: LivingBkkBrand.brandRed.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.05,
            ),
          ),
        if (strike != null) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              fmt.format(strike),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 10,
                decoration: TextDecoration.lineThrough,
                height: 1.05,
              ),
            ),
          ),
        ],
        if (discountPct != null && discountPct > 0) ...[
          const SizedBox(width: 3),
          Text(
            '-$discountPct%',
            style: const TextStyle(
              color: LivingBkkBrand.brandRed,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationAgoRow extends StatelessWidget {
  const _LocationAgoRow({
    required this.listing,
    required this.s,
    required this.palette,
    required this.isEnglish,
  });

  final ListingPublic listing;
  final AppStrings s;
  final AppPalette palette;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    final tags = listing.listingCardLocationTags(isEnglish);
    final location = tags.isNotEmpty
        ? tags.take(2).join(' · ')
        : (isEnglish
                ? (listing.districtEn ?? listing.district)
                : listing.district) ??
            '';
    final at = listing.lastBumpAt ?? listing.effectiveUpdatedAt;
    final ago = s.listingCardBoostedAgo(at);

    return Text(
      location.isEmpty ? ago : '$location · $ago',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        height: 1.2,
        color: palette.textSecondary,
      ),
    );
  }
}

class _SpecIconsRow extends StatelessWidget {
  const _SpecIconsRow({
    required this.listing,
    required this.s,
    required this.palette,
  });

  final ListingPublic listing;
  final AppStrings s;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label})>[];

    if (listing.areaSqm != null && listing.areaSqm! > 0) {
      items.add((
        icon: Icons.square_foot_outlined,
        label: '${listing.areaSqm!.round()}',
      ));
    }
    for (final e in listing.listingCardSpecItems(s)) {
      if (e.icon == Icons.stairs_outlined) {
        items.add(e);
        break;
      }
    }
    if (listing.bedrooms != null) {
      items.add((
        icon: Icons.bed_outlined,
        label: listing.bedrooms! == 0 ? 'S' : '${listing.bedrooms}',
      ));
    }
    if (listing.bathrooms != null && listing.bathrooms! > 0) {
      items.add((
        icon: Icons.bathtub_outlined,
        label: '${listing.bathrooms}',
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                '|',
                style: TextStyle(
                  fontSize: 10,
                  color: palette.border,
                  height: 1,
                ),
              ),
            ),
          Icon(items[i].icon, size: 12, color: palette.textSecondary),
          const SizedBox(width: 2),
          Text(
            items[i].label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: palette.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
