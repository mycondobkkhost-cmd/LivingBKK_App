import 'package:flutter/material.dart';

import '../models/listing_public.dart';
import '../theme/li_layout.dart';
import 'design_system/app_property_card.dart';
import 'home_listing_rail.dart';

/// แสดงทรัพย์แบบ 2 คอลัมน์ — การ์ด compact สไตล์หน้าแรก
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

  static double cellWidth(BuildContext context, {double? horizontalPadding}) {
    final pad = horizontalPadding ?? LiLayout.pagePadding;
    final w = MediaQuery.sizeOf(context).width;
    return (w - 2 * pad - gap) / columns;
  }

  static double cellAspectRatio(BuildContext context, {double? horizontalPadding}) {
    final cw = cellWidth(context, horizontalPadding: horizontalPadding);
    final h = HomeListingRail.compactCardHeight(cw);
    return cw / h;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final cw = cellWidth(context, horizontalPadding: horizontalPadding);

    return GridView.builder(
      controller: scrollController,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        childAspectRatio: cellAspectRatio(
          context,
          horizontalPadding: horizontalPadding,
        ),
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final checked = selectedIds.contains(item.id);
        final card = AppPropertyCard(
          listing: item,
          width: cw,
          compactBody: true,
          showCoAgentStrip: showCoAgentStrip,
          showFavorite: showFavorite && !selectionMode,
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
      },
    );
  }
}
