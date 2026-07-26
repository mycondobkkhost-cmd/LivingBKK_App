import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../services/favorites_service.dart';
import '../../services/listing_activity_service.dart';
import '../../theme/app_palette.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/listing_price_helpers.dart';
import '../../utils/localized_content.dart';

/// การ์ดประกาศกริด 2 คอลัมน์แนว Shopee — intrinsic height + รูปมีชีวิต
class MarketplaceListingCard extends StatelessWidget {
  const MarketplaceListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.width,
    this.showFavorite = true,
    this.showCoAgentStrip = false,
    this.highlightRecommended = false,
    this.livingCover = true,
  });

  final ListingPublic listing;
  final VoidCallback? onTap;
  final double? width;
  final bool showFavorite;
  final bool showCoAgentStrip;
  final bool highlightRecommended;

  /// สไลด์รูปอัตโนมัติ + Ken Burns เบาๆ
  final bool livingCover;

  /// ประมาณความสูงสำหรับ ListView แนวนอน / กริด
  static double estimatedHeight(double cardWidth, {double textScale = 1}) {
    final scale = textScale.clamp(1.0, 1.35);
    return cardWidth / imageAspectRatio + 98 * scale;
  }

  /// กว้าง:สูง ของรูป — แน่นขึ้นเล็กน้อยแบบ marketplace
  static const double imageAspectRatio = 1.08;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = AppStrings.of(context);
    final en = s.isEnglish;

    return Material(
      color: p.surface,
      elevation: 0.35,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: imageAspectRatio,
              child: _ImageBlock(
                listing: listing,
                showFavorite: showFavorite,
                highlightRecommended: highlightRecommended,
                showCoAgent: showCoAgentStrip && listing.coAgentEligible,
                hotLabel: s.listingHotLabel,
                living: livingCover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 3, 5, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PriceRow(
                    listing: listing,
                    perMonthLabel: s.perMonth,
                  ),
                  const SizedBox(height: 2),
                  _TitleLine(
                    listing: listing,
                    isEnglish: en,
                    recommended: highlightRecommended,
                    recommendedLabel: s.marketplaceRecommendedBadge,
                  ),
                  const SizedBox(height: 2),
                  _PromoTags(
                    listing: listing,
                    s: s,
                    highlightRecommended: highlightRecommended,
                  ),
                  const SizedBox(height: 2),
                  _LocationLine(listing: listing, isEnglish: en, palette: p),
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
    required this.highlightRecommended,
    required this.showCoAgent,
    required this.hotLabel,
    required this.living,
  });

  final ListingPublic listing;
  final bool showFavorite;
  final bool highlightRecommended;
  final bool showCoAgent;
  final String hotLabel;
  final bool living;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final showHot = highlightRecommended &&
        ListingActivityService.instance.isHotListing(
          listing.id,
          demoEstimate: ListingActivityService.useDemoHotEstimate,
        );
    final specs = listing
        .listingCardSpecItems(AppStrings.of(context))
        .map((e) => e.label)
        .take(2)
        .join(' · ');

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
        if (highlightRecommended)
          const Positioned(
            top: 0,
            left: 0,
            child: ColoredBox(
              color: LivingBkkBrand.brandRed,
              child: Padding(
                padding: EdgeInsets.fromLTRB(6, 3, 7, 3),
                child: Text(
                  'Exclusive',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
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
        if (showHot)
          Positioned(
            top: showFavorite ? 32 : 4,
            right: 4,
            child: _HotPulseBadge(label: hotLabel),
          ),
        if (showCoAgent || specs.isNotEmpty)
          Positioned(
            left: 4,
            right: 4,
            bottom: 4,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x99000000),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: Text(
                    showCoAgent
                        ? (specs.isEmpty ? 'Co-Agent' : 'Co · $specs')
                        : specs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder(AppPalette p) => ColoredBox(
        color: p.primaryLight,
        child: Icon(Icons.apartment, color: p.primary.withOpacity(0.4)),
      );
}

/// สไลด์รูปแบบ ecommerce — เลื่อนข้างเสมอ · จังหวะแบบคลื่นไม่พร้อมกัน
class _LivingCover extends StatefulWidget {
  const _LivingCover({required this.urls, required this.seed});

  final List<String> urls;
  final String seed;

  /// ดูรูปค้างก่อนเลื่อน (ms) — คงที่ทั้งแอป เพื่อจังหวะคลื่นนิ่ง
  static const int dwellMs = 3600;

  /// จำนวนช่องเฟส — การ์ดในช่องต่างกันจะไม่กระพริบพร้อมกัน
  static const int waveSlots = 7;

  /// ระยะสไลด์ด้านข้าง
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

  /// เฟสเริ่มต้นแบบคลื่น — deterministic แต่กระจายใน viewport
  Duration get _initialDelay {
    final slot = _seedHash() % _LivingCover.waveSlots;
    final step = _LivingCover.dwellMs ~/ _LivingCover.waveSlots;
    // +200ms กันยิงตอนเฟรมแรกหลังโหลด
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
    // พักเมื่อแท็บ/ทิศทางไม่แอคทีฟ (เลื่อนออกนอกจอในบางเคส)
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
    } catch (_) {
      // ignore disposed mid-animation
    }
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
          // ลูปไม่จำกัด — เลื่อนไปข้างหน้าเสมอ เหมือน Shopee / Lazada
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

/// จุดใต้รูป — สไตล์ ecommerce (จุดแอคทีฟยาวขึ้นเล็กน้อย)
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

class _HotPulseBadge extends StatefulWidget {
  const _HotPulseBadge({required this.label});

  final String label;

  @override
  State<_HotPulseBadge> createState() => _HotPulseBadgeState();
}

class _HotPulseBadgeState extends State<_HotPulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Transform.scale(
          scale: 1 + t * 0.06,
          child: Opacity(opacity: 0.82 + t * 0.18, child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LivingBkkBrand.ctaGradient,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: LivingBkkBrand.brandRed.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
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

class _TitleLine extends StatelessWidget {
  const _TitleLine({
    required this.listing,
    required this.isEnglish,
    required this.recommended,
    required this.recommendedLabel,
  });

  final ListingPublic listing;
  final bool isEnglish;
  final bool recommended;
  final String recommendedLabel;

  @override
  Widget build(BuildContext context) {
    final title = listing.displayHeadline(isEnglish);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recommended) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: LivingBkkBrand.brandRed,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              child: Text(
                recommendedLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: context.palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.listing,
    required this.perMonthLabel,
  });

  final ListingPublic listing;
  final String perMonthLabel;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: '฿',
      decimalDigits: 0,
    );
    final isRent = ListingPriceHelpers.showPerMonth(listing);
    final display = ListingPriceHelpers.displayAmount(
      listing,
      rentSide: isRent,
    );
    final strike = ListingPriceHelpers.strikethroughAmount(
      listing,
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
              fontSize: 14,
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

class _PromoTags extends StatelessWidget {
  const _PromoTags({
    required this.listing,
    required this.s,
    required this.highlightRecommended,
  });

  final ListingPublic listing;
  final AppStrings s;
  final bool highlightRecommended;

  @override
  Widget build(BuildContext context) {
    final tags = <(String, Color, Color)>[
      (
        s.listingTransactionLabel(listing.listingType),
        LivingBkkBrand.brandRedTint,
        LivingBkkBrand.brandRedDark,
      ),
      if (highlightRecommended)
        (
          s.netPriceBadge,
          const Color(0xFFFFF3E8),
          LivingBkkBrand.accentOrange,
        ),
    ];

    return SizedBox(
      height: 16,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final t in tags)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.$2,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: t.$3.withOpacity(0.2)),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Text(
                    t.$1,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: t.$3,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({
    required this.listing,
    required this.isEnglish,
    required this.palette,
  });

  final ListingPublic listing;
  final bool isEnglish;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final project = listing.localizedProjectName(isEnglish);
    final district = listing.localizedDistrict(isEnglish);
    final place = (project != null && project.isNotEmpty)
        ? project
        : (district ?? '');
    if (place.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 11,
          color: LivingBkkBrand.accentOrange,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            place,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: palette.textSecondary,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
