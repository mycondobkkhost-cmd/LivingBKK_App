import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/contact/property_chat_page.dart';
import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../services/favorites_service.dart';
import '../../services/listing_activity_service.dart';
import '../../services/platform_settings_service.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_typography.dart';
import '../../theme/li_layout.dart';
import '../../utils/listing_price_helpers.dart';
import '../../utils/localized_content.dart';
import '../design_system/property_card_image_pager.dart';

/// การ์ดประกาศเต็มความกว้าง — สไตล์ LivingInsider (Spotlight · ติดต่อบนรูป · สเปกครบ)
class HomeSpotlightCard extends StatelessWidget {
  const HomeSpotlightCard({
    super.key,
    required this.listing,
    this.onTap,
    this.highlightRecommended = false,
    this.showCoAgentStrip = false,
  });

  final ListingPublic listing;
  final VoidCallback? onTap;
  final bool highlightRecommended;
  final bool showCoAgentStrip;

  static const double imageRadius = 16;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final en = s.isEnglish;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(imageRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(imageRadius),
              child: AspectRatio(
                aspectRatio: LiLayout.homePromoAspect,
                child: _SpotlightImage(
                  listing: listing,
                  highlightRecommended: highlightRecommended,
                  showCoAgentStrip: showCoAgentStrip,
                  contactLabel: s.homeCardContact,
                  onTap: onTap,
                  onContact: () => openPropertyChat(context, listing),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 12, 2, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TagRow(listing: listing, s: s, p: p),
                  const SizedBox(height: 8),
                  Text(
                    listing.localizedTitle(en),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: HomeTypography.listingTitleStyle(p),
                  ),
                  const SizedBox(height: 6),
                  _LocationLine(listing: listing, s: s, p: p, en: en),
                  const SizedBox(height: 8),
                  _SpecGrid(listing: listing, s: s, p: p, en: en),
                  const SizedBox(height: 10),
                  _PriceBlock(listing: listing, s: s, p: p),
                  const SizedBox(height: 8),
                  _CardFooter(listing: listing, s: s, p: p),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightImage extends StatelessWidget {
  const _SpotlightImage({
    required this.listing,
    required this.highlightRecommended,
    required this.showCoAgentStrip,
    required this.contactLabel,
    this.onTap,
    required this.onContact,
  });

  final ListingPublic listing;
  final bool highlightRecommended;
  final bool showCoAgentStrip;
  final String contactLabel;
  final VoidCallback? onTap;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;

    return ListenableBuilder(
      listenable: PlatformSettingsService.instance,
      builder: (context, _) {
        final activity = ListingActivityService.instance;
        final showSpotlight = highlightRecommended || listing.isFeedExclusive;
        final showHot = highlightRecommended &&
            activity.isHotListing(
              listing.id,
              demoEstimate: ListingActivityService.useDemoHotEstimate,
            );

        final overlay = Stack(
          fit: StackFit.expand,
          children: [
            if (showSpotlight)
              Positioned(
                top: 10,
                left: 10,
                child: _SpotlightBadge(label: s.homeSpotlightBadge),
              ),
            if (showCoAgentStrip && listing.coAgentEligible)
              Positioned(
                top: 10,
                left: showSpotlight ? 108 : 10,
                child: _CoAgentPill(label: s.coAgentEligible),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: _FavoriteHeart(listingId: listing.id),
            ),
            if (showHot)
              Positioned(
                top: 48,
                right: 10,
                child: _HotPill(label: s.listingHotLabel),
              ),
            Positioned(
              left: 10,
              bottom: 10,
              child: _BrandAvatar(listing: listing),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: _ContactPill(
                label: contactLabel,
                onTap: onContact,
              ),
            ),
          ],
        );

        if (listing.imageUrls.length > 1) {
          return PropertyCardImagePager(
            imageUrls: listing.imageUrls,
            placeholder: _placeholder(p),
            overlay: overlay,
            onTap: onTap,
          );
        }

        return GestureDetector(
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
              overlay,
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder(AppPalette p) {
    return ColoredBox(
      color: p.primaryLight,
      child: Icon(Icons.apartment, size: 48, color: p.primary.withOpacity(0.45)),
    );
  }
}

class _SpotlightBadge extends StatelessWidget {
  const _SpotlightBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.push_pin_rounded, size: 13, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoAgentPill extends StatelessWidget {
  const _CoAgentPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HotPill extends StatelessWidget {
  const _HotPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A00), Color(0xFFE53935)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 11, height: 1)),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandAvatar extends StatelessWidget {
  const _BrandAvatar({required this.listing});

  final ListingPublic listing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = listing.localizedProjectName(
          AppStrings.of(context).isEnglish,
        ) ??
        listing.listingCode;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: p.primaryLight,
        child: Text(
          label.characters.take(1).toString().toUpperCase(),
          style: TextStyle(
            color: p.primary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ContactPill extends StatelessWidget {
  const _ContactPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteHeart extends StatelessWidget {
  const _FavoriteHeart({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesService.instance,
      builder: (context, _) {
        final fav = FavoritesService.instance.isFavorite(listingId);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => FavoritesService.instance.toggle(listingId),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                fav ? Icons.favorite : Icons.favorite_border,
                size: 24,
                color: fav ? const Color(0xFFFF5B8A) : Colors.white,
                shadows: const [
                  Shadow(color: Colors.black45, blurRadius: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.listing,
    required this.s,
    required this.p,
  });

  final ListingPublic listing;
  final AppStrings s;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _tag(s.propertyTypeChip(listing.propertyType), p.primary, Colors.white),
        _tag(
          s.listingTransactionLabel(listing.listingType),
          p.primary.withOpacity(0.12),
          p.primary,
        ),
      ],
    );
  }

  Widget _tag(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({
    required this.listing,
    required this.s,
    required this.p,
    required this.en,
  });

  final ListingPublic listing;
  final AppStrings s;
  final AppPalette p;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final project = listing.localizedProjectName(en);
    final district = listing.localizedDistrict(en);
    final label = project ?? district;
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 15, color: p.primary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeTypography.locationLineStyle(p).copyWith(
              fontWeight: FontWeight.w500,
              color: p.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpecGrid extends StatelessWidget {
  const _SpecGrid({
    required this.listing,
    required this.s,
    required this.p,
    required this.en,
  });

  final ListingPublic listing;
  final AppStrings s;
  final AppPalette p;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: '฿',
      decimalDigits: 0,
    );
    final items = <Widget>[];

    if (listing.areaSqm != null && listing.areaSqm! > 0) {
      final sqm = listing.areaSqm!.round();
      final perSqm = (listing.priceNet / listing.areaSqm!).round();
      items.add(_spec(
        Icons.square_foot_outlined,
        s.sqmShort(sqm),
        sub: s.pricePerSqm(fmt.format(perSqm)),
        subColor: p.primary,
        p: p,
      ));
    }
    final floor = listing.localizedFloorRange(en);
    if (floor != null && floor.isNotEmpty) {
      items.add(_spec(Icons.stairs_outlined, floor, p: p));
    }
    if (listing.bedrooms != null) {
      items.add(_spec(
        Icons.bed_outlined,
        listing.bedrooms == 0 ? s.filterStudio : s.bedCount(listing.bedrooms!),
        p: p,
      ));
    }
    if (listing.bathrooms != null) {
      items.add(_spec(
        Icons.bathtub_outlined,
        s.bathCount(listing.bathrooms!),
        p: p,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: items,
    );
  }

  Widget _spec(
    IconData icon,
    String label, {
    String? sub,
    Color? subColor,
    required AppPalette p,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: p.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: HomeTypography.specChipStyle(p).copyWith(fontWeight: FontWeight.w500),
        ),
        if (sub != null) ...[
          const SizedBox(width: 4),
          Text(
            '($sub)',
            style: HomeTypography.specChipStyle(p).copyWith(
              fontWeight: FontWeight.w600,
              color: subColor ?? p.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.listing,
    required this.s,
    required this.p,
  });

  final ListingPublic listing;
  final AppStrings s;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: '฿',
      decimalDigits: 0,
    );
    final isRent = ListingPriceHelpers.showPerMonth(listing);
    final strike = ListingPriceHelpers.strikethroughAmount(
      listing,
      rentSide: isRent,
    );
    final price = fmt.format(ListingPriceHelpers.effectivePrice(listing));

    return Text.rich(
      TextSpan(
        children: [
          if (strike != null) ...[
            TextSpan(
              text: fmt.format(strike),
              style: HomeTypography.priceStrikeStyle(p),
            ),
            const TextSpan(text: ' '),
          ],
          TextSpan(
            text: price,
            style: HomeTypography.priceStyle(p),
          ),
          if (isRent)
            TextSpan(
              text: ' ${s.perMonth}',
              style: HomeTypography.perMonthStyle(p),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({
    required this.listing,
    required this.s,
    required this.p,
  });

  final ListingPublic listing;
  final AppStrings s;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final views = ListingActivityService.instance.viewCount(listing.id);

    return Row(
      children: [
        Expanded(
          child: Text(
            s.listingCardBoostedAgo(listing.effectiveUpdatedAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeTypography.metaStyle(p),
          ),
        ),
        Icon(Icons.auto_awesome, size: 12, color: p.textSecondary),
        const SizedBox(width: 3),
        Text(
          s.listingViewsCompact(views),
          style: HomeTypography.metaStyle(p, weight: FontWeight.w500),
        ),
      ],
    );
  }
}
