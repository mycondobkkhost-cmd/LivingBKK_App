import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/listing_public.dart';
import '../services/favorites_service.dart';
import '../utils/listing_price_helpers.dart';
import '../utils/localized_content.dart';
import '../utils/reference_codes.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';
import 'design_system/app_property_card.dart';

enum ListingCardStyle { full, compact, list, feed }

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.style = ListingCardStyle.full,
    this.showCoAgentStrip = false,
    this.onTap,
    this.showFavorite = true,
  });

  final ListingPublic listing;
  final ListingCardStyle style;
  final bool showCoAgentStrip;
  final VoidCallback? onTap;
  final bool showFavorite;

  String _priceLabel(AppStrings s) {
    final locale = s.isEnglish ? 'en_US' : 'th_TH';
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: '฿',
      decimalDigits: 0,
    );
    if (ListingPriceHelpers.showDualPrices(listing)) {
      return '${fmt.format(listing.priceNet)}${s.perMonth} · ${fmt.format(listing.priceSaleNet!)}';
    }
    final price = fmt.format(ListingPriceHelpers.effectivePrice(listing));
    return '$price${ListingPriceHelpers.showPerMonth(listing) ? s.perMonth : ''}';
  }

  Widget _metaRow(AppStrings s) {
    final parts = <String>[
      if (!ReferenceCodes.isSpecialListingCode(listing.listingCode))
        listing.listingCode,
      if (listing.bedrooms != null) s.bedsShort(listing.bedrooms!),
      if (listing.areaSqm != null) s.sqmShort(listing.areaSqm!.toInt()),
      s.listingTransactionLabel(listing.listingType),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
    );
  }

  Widget _image(double height) {
    final url = listing.imageUrls.isNotEmpty ? listing.imageUrls.first : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url != null)
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppTheme.primaryLight),
          )
        else
          Container(
            color: AppTheme.primaryLight,
            child: Center(
              child: Icon(Icons.apartment, size: 40, color: AppTheme.primary),
            ),
          ),
        if (showFavorite)
          Positioned(
            top: 8,
            right: 8,
            child: _FavoriteButton(listingId: listing.id),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (style == ListingCardStyle.feed || style == ListingCardStyle.compact) {
      return Padding(
        padding: style == ListingCardStyle.feed
            ? const EdgeInsets.only(bottom: 8)
            : EdgeInsets.zero,
        child: AppPropertyCard(
          listing: listing,
          compactBody: true,
          showCoAgentStrip: showCoAgentStrip,
          showFavorite: showFavorite,
          onTap: onTap,
        ),
      );
    }

    if (style == ListingCardStyle.list) {
      return Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 110,
            child: Row(
              children: [
                SizedBox(width: 120, child: _image(110)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _priceLabel(s),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          listing.displayHeadline(s.isEnglish),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        if (listing.localizedDistrict(s.isEnglish)?.isNotEmpty ?? false)
                          Text(
                            listing.localizedDistrict(s.isEnglish)!,
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (style == ListingCardStyle.compact) {
      return SizedBox(
        width: 200,
        height: 196,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 112, child: _image(112)),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _priceLabel(s),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.displayHeadline(s.isEnglish),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        listing.localizedDistrict(s.isEnglish) ?? '',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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

    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 140, child: _image(140)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _priceLabel(s),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.displayHeadline(s.isEnglish),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (listing.localizedDistrict(s.isEnglish)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        listing.localizedDistrict(s.isEnglish)!,
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (showCoAgentStrip && listing.coAgentEligible) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.coAgentOpen,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
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

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.listingId});

  final String listingId;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
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
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => FavoritesService.instance.toggle(widget.listingId),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            fav ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: fav ? Colors.redAccent : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
