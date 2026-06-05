import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../services/favorites_service.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/localized_content.dart';
import 'app_badge.dart';
import 'property_card_image_pager.dart';

/// Premium Airbnb-style property card — สไลด์รูปได้บน rail หน้าแรก
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
  /// ใช้บน HomeListingRail — ลด padding / ชื่อ 1 บรรทัด กันชนขอบล่าง
  final bool compactBody;

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
            showCoAgentStrip: showCoAgentStrip,
            onTap: onTap,
          );

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
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: enableImageSwipe && listing.imageUrls.length > 1
                        ? PropertyCardImagePager(
                            imageUrls: listing.imageUrls,
                            placeholder: _placeholder(p),
                            overlay: _imageOverlay(s, p),
                            railScrollController: railScrollController,
                            railStep: (width ?? 280) + 12,
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
                                if (_imageOverlay(s, p) != null) _imageOverlay(s, p)!,
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

  Widget? _imageOverlay(AppStrings s, AppPalette p) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showFavorite)
          Positioned(
            top: 10,
            right: 10,
            child: _FavoriteHeart(listingId: listing.id),
          ),
        Positioned(
          left: 10,
          bottom: 10,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (listing.isFeedExclusive)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AppBadge(
                    label: s.listingExclusiveBadge,
                    tone: AppBadgeTone.accent,
                  ),
                ),
              AppBadge(
                label: s.netPriceBadge,
                tone: AppBadgeTone.neutral,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder(AppPalette p) {
    return Container(
      color: p.primaryLight,
      child: Icon(Icons.apartment, size: 48, color: p.primary.withOpacity(0.5)),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.listing,
    required this.compactBody,
    required this.showCoAgentStrip,
    this.onTap,
  });

  final ListingPublic listing;
  final bool compactBody;
  final bool showCoAgentStrip;
  final VoidCallback? onTap;

  String _priceLabel(AppStrings s) {
    final locale = s.isEnglish ? 'en_US' : 'th_TH';
    final price = NumberFormat.currency(
      locale: locale,
      symbol: '฿',
      decimalDigits: 0,
    ).format(listing.priceNet);
    return '$price${listing.listingType == 'rent' ? s.perMonth : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = AppStrings.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          compactBody ? 8 : 12,
          12,
          compactBody ? 8 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _priceLabel(s),
              style: compactBody
                  ? AppTypography.price(p).copyWith(fontSize: 18, height: 1.1)
                  : AppTypography.price(p),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: compactBody ? 2 : 4),
            Text(
              listing.displayHeadline(s.isEnglish),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: compactBody ? 14 : 15,
                height: 1.2,
                color: p.textPrimary,
              ),
            ),
            if (listing.localizedDistrict(s.isEnglish)?.isNotEmpty ?? false) ...[
              SizedBox(height: compactBody ? 1 : 3),
              Text(
                listing.localizedDistrict(s.isEnglish)!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compactBody ? 12 : 13,
                  height: 1.2,
                  color: p.textSecondary,
                ),
              ),
            ],
            if (showCoAgentStrip && listing.coAgentEligible) ...[
              SizedBox(height: compactBody ? 4 : 8),
              AppBadge(label: s.coAgentEligible, tone: AppBadgeTone.primary),
            ],
          ],
        ),
      ),
    );
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
              padding: const EdgeInsets.all(8),
              child: Icon(
                fav ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: fav ? const Color(0xFFFF5B8A) : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
