import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/listing_public.dart';
import '../theme/fb_feed_chrome.dart';
import 'design_system/marketplace_listing_card.dart';

/// เซกชันประกาศหน้าแรก — โมดูลฟีด Facebook + กริด 2 คอลัมน์
class HomeListingRail extends StatelessWidget {
  const HomeListingRail({
    super.key,
    required this.title,
    required this.items,
    required this.onTapListing,
    required this.onViewAll,
    this.showCoAgentStrip = false,
    this.accentIndex = 0,
    this.highlightRecommended = false,
    this.topInset = 0,
    this.previewCount = 4,
  });

  final String title;
  final List<ListingPublic> items;
  final void Function(ListingPublic) onTapListing;
  final VoidCallback onViewAll;
  final bool showCoAgentStrip;
  final int accentIndex;
  final bool highlightRecommended;
  final double topInset;
  final int previewCount;

  static const cardGap = 6.0;
  static const columns = 2;

  static double cardWidthFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final available = w - 24;
    return (available - cardGap) / columns;
  }

  static double compactCardHeight(double cardWidth) =>
      MarketplaceListingCard.estimatedHeight(cardWidth);

  static double railHeightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
    return MarketplaceListingCard.estimatedHeight(
      cardWidthFor(context),
      textScale: scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (items.isEmpty) return const SizedBox.shrink();

    final preview = items.take(previewCount).toList();

    return FbFeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: FbFeedChrome.sectionHeaderPadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FbFeedChrome.sectionTitleStyle,
                  ),
                ),
                InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.viewAll,
                          style: const TextStyle(
                            color: FbFeedChrome.secondaryText,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: FbFeedChrome.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                for (var i = 0; i < preview.length; i += columns) ...[
                  if (i > 0) const SizedBox(height: cardGap),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: MarketplaceListingCard(
                          listing: preview[i],
                          highlightRecommended: highlightRecommended,
                          showCoAgentStrip: showCoAgentStrip,
                          onTap: () => onTapListing(preview[i]),
                        ),
                      ),
                      const SizedBox(width: cardGap),
                      Expanded(
                        child: i + 1 < preview.length
                            ? MarketplaceListingCard(
                                listing: preview[i + 1],
                                highlightRecommended: highlightRecommended,
                                showCoAgentStrip: showCoAgentStrip,
                                onTap: () => onTapListing(preview[i + 1]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// แถวเลื่อนแนวนอน — อัปเดตวันนี้ / flash strip
class HomeListingHScroll extends StatelessWidget {
  const HomeListingHScroll({
    super.key,
    required this.title,
    required this.items,
    required this.onTapListing,
    required this.onViewAll,
    this.accentIndex = 0,
    this.cardWidth = 148,
  });

  final String title;
  final List<ListingPublic> items;
  final void Function(ListingPublic) onTapListing;
  final VoidCallback onViewAll;
  final int accentIndex;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (items.isEmpty) return const SizedBox.shrink();
    final preview = items.take(12).toList();

    return FbFeedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: FbFeedChrome.sectionHeaderPadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FbFeedChrome.sectionTitleStyle,
                  ),
                ),
                InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.viewAll,
                          style: const TextStyle(
                            color: FbFeedChrome.secondaryText,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: FbFeedChrome.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MarketplaceListingCard.estimatedHeight(
              cardWidth,
              textScale: MediaQuery.textScalerOf(context).scale(1),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: preview.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final listing = preview[i];
                return SizedBox(
                  width: cardWidth,
                  child: MarketplaceListingCard(
                    listing: listing,
                    width: cardWidth,
                    livingCover: true,
                    onTap: () => onTapListing(listing),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
