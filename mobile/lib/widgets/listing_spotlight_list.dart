import 'package:flutter/material.dart';

import '../models/listing_public.dart';
import '../theme/li_layout.dart';
import 'home/home_spotlight_card.dart';

/// รายการประกาศแนวตั้ง — การ์ดเต็มความกว้างสไตล์ LivingInsider (ใช้ทุกหน้าฝั่งลูกค้า)
class ListingSpotlightList extends StatelessWidget {
  const ListingSpotlightList({
    super.key,
    required this.items,
    required this.onTapListing,
    this.showCoAgentStrip = false,
    this.highlightRecommended = false,
    this.highlightRecommendedIds = const {},
    this.selectionMode = false,
    this.selectedIds = const {},
    this.onToggleSelect,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.scrollController,
    this.itemGap = LiLayout.homeSectionGap,
  });

  final List<ListingPublic> items;
  final void Function(ListingPublic listing) onTapListing;
  final bool showCoAgentStrip;
  final bool highlightRecommended;
  final Set<String> highlightRecommendedIds;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String listingId)? onToggleSelect;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? scrollController;
  final double itemGap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      controller: scrollController,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: itemGap),
      itemBuilder: (context, i) {
        final item = items[i];
        final highlight = highlightRecommended ||
            highlightRecommendedIds.contains(item.id);
        final card = HomeSpotlightCard(
          listing: item,
          highlightRecommended: highlight,
          showCoAgentStrip: showCoAgentStrip,
          onTap: selectionMode
              ? () => onToggleSelect?.call(item.id)
              : () => onTapListing(item),
        );

        if (!selectionMode) return card;

        final checked = selectedIds.contains(item.id);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            card,
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: Colors.white.withOpacity(0.94),
                shape: const CircleBorder(),
                elevation: 2,
                child: Checkbox(
                  value: checked,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (_) => onToggleSelect?.call(item.id),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
