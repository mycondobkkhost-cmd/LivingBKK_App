import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/demo_listings_factory.dart';
import '../../l10n/app_strings.dart';
import '../../models/listing_route_extra.dart';
import '../../services/favorites_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/listing_card.dart';
import '../../theme/li_layout.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

class SavedListingsPage extends StatefulWidget {
  const SavedListingsPage({super.key});

  @override
  State<SavedListingsPage> createState() => _SavedListingsPageState();
}

class _SavedListingsPageState extends State<SavedListingsPage> {
  @override
  void initState() {
    super.initState();
    FavoritesService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ids = FavoritesService.instance.ids;
    final all = DemoListingsFactory.cached;
    final saved = all.where((l) => ids.contains(l.id)).toList();

    return ConsumerPageShell(
      title: s.savedListingsTitle,
      safeBottomBody: false,
      body: saved.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: AppTheme.primary.withOpacity(0.7)),
                    const SizedBox(height: 16),
                    Text(
                      s.savedListingsEmpty,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.savedListingsHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: PageSafeInsets.padLTRB(
                context,
                left: LiLayout.pagePadding,
                top: LiLayout.pagePadding,
                right: LiLayout.pagePadding,
                bottom: 16,
                addHomeIndicator: false,
              ),
              itemCount: saved.length,
              itemBuilder: (context, i) {
                final item = saved[i];
                return ListingCard(
                  listing: item,
                  style: ListingCardStyle.list,
                  onTap: () => context.push(
                    '/listing/${item.id}',
                    extra: ListingRouteExtra(listing: item),
                  ),
                );
              },
            ),
    );
  }
}
