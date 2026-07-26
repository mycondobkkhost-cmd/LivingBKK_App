import 'package:flutter/material.dart';

import '../models/listing_public.dart';
import '../theme/li_layout.dart';
import 'design_system/mediated_listing_card.dart';

/// กริด 2 คอลัมน์แบบ masonry — รูปสูงเหลื่อมกัน (แนว iStock)
class ListingGrid extends StatelessWidget {
  const ListingGrid({
    super.key,
    required this.items,
    required this.onTapListing,
    this.showCoAgentStrip = false,
    this.showFavorite = true,
    this.selectionMode = false,
    this.selectedIds = const {},
    this.onToggleSelect,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.horizontalPadding,
    this.scrollController,
    this.highlightRecommended = false,
    this.highlightRecommendedIds = const {},
    this.browseFilter,
  });

  static const double gap = 8;
  static const int columns = 2;

  final List<ListingPublic> items;
  final void Function(ListingPublic listing) onTapListing;
  final bool showCoAgentStrip;
  final bool showFavorite;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String listingId)? onToggleSelect;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double? horizontalPadding;
  final ScrollController? scrollController;
  final bool highlightRecommended;
  final Set<String> highlightRecommendedIds;
  final String? browseFilter;

  static double cellWidth(BuildContext context, {double? horizontalPadding}) {
    final pad = horizontalPadding ?? LiLayout.pagePadding;
    final w = MediaQuery.sizeOf(context).width;
    return (w - 2 * pad - gap) / columns;
  }

  Widget _cardFor(BuildContext context, ListingPublic item, int index) {
    final aspect = MediatedListingCard.imageAspectForIndex(index);
    final checked = selectedIds.contains(item.id);
    final card = MediatedListingCard(
      listing: item,
      showFavorite: showFavorite && !selectionMode,
      showCoAgentStrip: showCoAgentStrip,
      highlightRecommended:
          highlightRecommended || highlightRecommendedIds.contains(item.id),
      browseFilter: browseFilter,
      imageAspectOverride: aspect,
      onTap: selectionMode
          ? () => onToggleSelect?.call(item.id)
          : () => onTapListing(item),
    );

    if (!selectionMode) return card;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.white.withOpacity(0.92),
            shape: const CircleBorder(),
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
  }

  Widget _masonryBody(BuildContext context) {
    final left = <Widget>[];
    final right = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      final tile = Padding(
        padding: const EdgeInsets.only(bottom: gap),
        child: _cardFor(context, items[i], i),
      );
      // คอลัมน์ซ้ายเริ่มด้วยการ์ดสูงกว่าเล็กน้อย → เหลื่อมกับขวา
      if (i.isEven) {
        left.add(tile);
      } else {
        right.add(tile);
      }
    }

    // ขวาเลื่อนลงเล็กน้อยให้รู้สึกเหลื่อมแบบตัวอย่าง
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: left,
          ),
        ),
        const SizedBox(width: gap),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: right,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final body = _masonryBody(context);

    if (shrinkWrap) {
      return Padding(padding: padding, child: body);
    }

    return ListView(
      controller: scrollController,
      physics: physics,
      padding: padding,
      children: [body],
    );
  }
}
