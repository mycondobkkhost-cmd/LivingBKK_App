import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/listing_public.dart';
import '../../models/listing_route_extra.dart';
import '../../theme/li_layout.dart';
import '../../widgets/listing_card.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(LiLayout.pagePadding),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          return ListingCard(
            listing: item,
            style: ListingCardStyle.feed,
            showCoAgentStrip: isAgent,
            onTap: () => context.push(
              '/listing/${item.id}',
              extra: ListingRouteExtra(listing: item, isAgent: isAgent),
            ),
          );
        },
      ),
    );
  }
}
