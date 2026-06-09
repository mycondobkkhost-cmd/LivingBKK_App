import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/listing_public.dart';
import '../../models/listing_route_extra.dart';
import '../../theme/li_layout.dart';
import '../../widgets/listing_grid.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

class HomeSectionListPage extends StatelessWidget {
  const HomeSectionListPage({
    super.key,
    required this.title,
    required this.items,
    required this.isAgent,
  });

  final String title;
  final List<ListingPublic> items;
  final bool isAgent;

  @override
  Widget build(BuildContext context) {
    return ConsumerPageShell(
      title: title,
      onBack: () => context.pop(),
      body: ListingGrid(
        items: items,
        showCoAgentStrip: isAgent,
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: PageSafeInsets.padLTRB(
          context,
          left: LiLayout.pagePadding,
          top: LiLayout.pagePadding,
          right: LiLayout.pagePadding,
          bottom: LiLayout.pagePadding,
          addHomeIndicator: false,
        ),
        onTapListing: (item) => context.push(
          '/listing/${item.id}',
          extra: ListingRouteExtra(listing: item, isAgent: isAgent),
        ),
      ),
    );
  }
}
