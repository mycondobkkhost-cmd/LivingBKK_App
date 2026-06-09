import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/listing_public.dart';
import '../services/favorites_service.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../utils/listing_price_helpers.dart';
import '../utils/localized_content.dart';

/// การ์ดรายการทรัพย์แบบแนวนอน (หมวดหมู่/ค้นหา) — รูป 3:2 แนวนอนซ้าย · รายละเอียดขวา
class BrowseListingRowCard extends StatelessWidget {
  const BrowseListingRowCard({
    super.key,
    required this.listing,
    this.onTap,
    this.showFavorite = true,
    this.highlightRecommended = false,
    this.browseFilter,
  });

  final ListingPublic listing;
  final VoidCallback? onTap;
  final bool showFavorite;
  final bool highlightRecommended;
  final String? browseFilter;

  static const double _imageWidthRatio = 0.42;
  static const double _minImageWidth = 140;
  static const double _maxImageWidth = 210;
  static const double _imageAspect = 3 / 2;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final en = s.isEnglish;

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageW = (constraints.maxWidth * _imageWidthRatio)
            .clamp(_minImageWidth, _maxImageWidth);
        final imageH = imageW / _imageAspect;

        return Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: p.border.withOpacity(0.85)),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ListingThumb(
                        listing: listing,
                        s: s,
                        width: imageW,
                        height: imageH,
                        showExclusive: highlightRecommended ||
                            listing.isFeedExclusive,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ListingBody(
                          listing: listing,
                          s: s,
                          p: p,
                          en: en,
                          showFavorite: showFavorite,
                          browseFilter: browseFilter,
                        ),
                      ),
                    ],
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

class _ListingThumb extends StatelessWidget {
  const _ListingThumb({
    required this.listing,
    required this.s,
    required this.width,
    required this.height,
    required this.showExclusive,
  });

  final ListingPublic listing;
  final AppStrings s;
  final double width;
  final double height;
  final bool showExclusive;

  @override
  Widget build(BuildContext context) {
    final url =
        listing.imageUrls.isNotEmpty ? listing.imageUrls.first : null;
    const ribbonH = 22.0;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            else
              _placeholder(),
            Positioned(
              top: 0,
              left: 0,
              child: _TransactionRibbon(
                label: s.listingTransactionRibbonLabel(listing.listingType),
                listingType: listing.listingType,
              ),
            ),
            if (showExclusive)
              Positioned(
                top: ribbonH,
                left: 0,
                child: const _ExclusiveRibbon(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppTheme.primaryLight,
        child: Icon(Icons.apartment, color: AppTheme.primary.withOpacity(0.45)),
      );
}

class _TransactionRibbon extends StatelessWidget {
  const _TransactionRibbon({
    required this.label,
    required this.listingType,
  });

  final String label;
  final String? listingType;

  Color get _color {
    switch (listingType) {
      case 'rent':
        return const Color(0xFF1565C0);
      case 'sale':
        return const Color(0xFFE65100);
      case 'sale_installment':
        return const Color(0xFFBF360C);
      case 'rent_and_sale':
        return const Color(0xFF6A1B9A);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _color,
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _ExclusiveRibbon extends StatelessWidget {
  const _ExclusiveRibbon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(6)),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(7, 4, 9, 4),
        child: Text(
          'Exclusive',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _ListingBody extends StatelessWidget {
  const _ListingBody({
    required this.listing,
    required this.s,
    required this.p,
    required this.en,
    required this.showFavorite,
    required this.browseFilter,
  });

  final ListingPublic listing;
  final AppStrings s;
  final AppPalette p;
  final bool en;
  final bool showFavorite;
  final String? browseFilter;

  @override
  Widget build(BuildContext context) {
    final location = [
      listing.localizedProjectName(en) ?? listing.projectName,
      listing.localizedDistrict(en),
    ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                listing.localizedTitle(en),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: p.textPrimary,
                ),
              ),
            ),
            if (showFavorite) ...[
              const SizedBox(width: 4),
              _FavoriteHeart(listingId: listing.id),
            ],
          ],
        ),
        if (location.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 13, color: p.primary),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        _SpecChips(listing: listing, s: s, p: p),
        const SizedBox(height: 6),
        _PriceLine(
          listing: listing,
          s: s,
          p: p,
          browseFilter: browseFilter,
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(Icons.schedule, size: 11, color: p.textSecondary),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                '${s.listingBumpedLabel}: ${_updatedLabel(s)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: p.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _updatedLabel(AppStrings s) {
    final at = listing.lastBumpAt ?? listing.effectiveUpdatedAt;
    return s.listingUpdatedAgo(at);
  }
}

class _SpecChips extends StatelessWidget {
  const _SpecChips({
    required this.listing,
    required this.s,
    required this.p,
  });

  final ListingPublic listing;
  final AppStrings s;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[];
    if (listing.bedrooms != null) {
      labels.add(
        listing.bedrooms == 0
            ? (s.isEnglish ? 'Studio' : 'สตูดิโอ')
            : s.bedsShort(listing.bedrooms!),
      );
    }
    if (listing.bathrooms != null && listing.bathrooms! > 0) {
      labels.add(s.bathroomCardLabel(listing.bathrooms!));
    }
    if (listing.areaSqm != null && listing.areaSqm! > 0) {
      labels.add(s.sqmShort(listing.areaSqm!.round()));
    }
    if (labels.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final label in labels)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.inputFill,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: p.border.withOpacity(0.7)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.listing,
    required this.s,
    required this.p,
    required this.browseFilter,
  });

  final ListingPublic listing;
  final AppStrings s;
  final AppPalette p;
  final String? browseFilter;

  @override
  Widget build(BuildContext context) {
    final locale = s.isEnglish ? 'en_US' : 'th_TH';
    final fmt = NumberFormat.currency(locale: locale, symbol: '฿', decimalDigits: 0);

    if (ListingPriceHelpers.showDualPrices(listing)) {
      return _dualPrice(fmt, s);
    }
    final isRent = ListingPriceHelpers.showPerMonth(
      listing,
      browseFilter: browseFilter,
    );
    final strike = ListingPriceHelpers.strikethroughAmount(
      listing,
      browseFilter: browseFilter,
      rentSide: isRent,
    );
    final display = ListingPriceHelpers.effectivePrice(
      listing,
      browseFilter: browseFilter,
    );
    return _singlePrice(fmt, s, strike, display, isRent);
  }

  Widget _dualPrice(NumberFormat fmt, AppStrings s) {
    final rentStrike = ListingPriceHelpers.strikethroughAmount(
      listing,
      rentSide: true,
    );
    final rentDisplay = ListingPriceHelpers.displayAmount(
      listing,
      rentSide: true,
    );
    final saleStrike = ListingPriceHelpers.strikethroughAmount(
      listing,
      rentSide: false,
    );
    final saleDisplay = ListingPriceHelpers.displayAmount(
      listing,
      rentSide: false,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: _priceSpan(
              fmt.format(rentDisplay),
              rentStrike,
              fmt,
              s.perMonth,
            ),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: _priceSpan(
              fmt.format(saleDisplay),
              saleStrike,
              fmt,
              '',
            ),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _singlePrice(
    NumberFormat fmt,
    AppStrings s,
    double? strike,
    double display,
    bool isRent,
  ) {
    return Text.rich(
      TextSpan(
        children: _priceSpan(
          fmt.format(display),
          strike,
          fmt,
          isRent ? s.perMonth : '',
        ),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<InlineSpan> _priceSpan(
    String displayText,
    double? strike,
    NumberFormat fmt,
    String suffix,
  ) {
    final mainStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: p.primary,
      height: 1.1,
    );
    final strikeStyle = TextStyle(
      fontSize: 11,
      color: p.textSecondary,
      decoration: TextDecoration.lineThrough,
    );
    final suffixStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: p.primary,
    );
    return [
      if (strike != null) ...[
        TextSpan(text: fmt.format(strike), style: strikeStyle),
        const TextSpan(text: ' '),
      ],
      TextSpan(text: displayText, style: mainStyle),
      if (suffix.isNotEmpty) TextSpan(text: suffix, style: suffixStyle),
    ];
  }
}

class _FavoriteHeart extends StatefulWidget {
  const _FavoriteHeart({required this.listingId});

  final String listingId;

  @override
  State<_FavoriteHeart> createState() => _FavoriteHeartState();
}

class _FavoriteHeartState extends State<_FavoriteHeart> {
  @override
  void initState() {
    super.initState();
    FavoritesService.instance.load();
    FavoritesService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final fav = FavoritesService.instance.isFavorite(widget.listingId);
    return InkWell(
      onTap: () => FavoritesService.instance.toggle(widget.listingId),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          fav ? Icons.favorite : Icons.favorite_border,
          size: 20,
          color: fav ? Colors.redAccent : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
