import 'package:flutter/material.dart';

import '../models/listing_public.dart';
import 'browse_listing_row_card.dart';

/// รายการทรัพย์แนวนอน — ใช้ในหน้าหมวดหมู่/ค้นหา
class BrowseListingList extends StatelessWidget {
  const BrowseListingList({
    super.key,
    required this.items,
    required this.onTapListing,
    this.showFavorite = true,
    this.browseFilter,
    this.highlightRecommendedIds = const {},
  });

  final List<ListingPublic> items;
  final void Function(ListingPublic listing) onTapListing;
  final bool showFavorite;
  final String? browseFilter;
  final Set<String> highlightRecommendedIds;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          BrowseListingRowCard(
            listing: items[i],
            showFavorite: showFavorite,
            browseFilter: browseFilter,
            highlightRecommended: highlightRecommendedIds.contains(items[i].id),
            onTap: () => onTapListing(items[i]),
          ),
        ],
      ],
    );
  }
}
