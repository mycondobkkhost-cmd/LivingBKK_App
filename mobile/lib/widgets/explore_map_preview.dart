import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/li_layout.dart';
import 'listings_map.dart';
import '../../models/listing_public.dart';
import '../../l10n/app_strings.dart';
import 'design_system/app_button.dart';

/// Map preview section with open full-screen CTA
class ExploreMapPreview extends StatelessWidget {
  const ExploreMapPreview({
    super.key,
    required this.listings,
    required this.onOpenFullMap,
    this.loading = false,
  });

  final List<ListingPublic> listings;
  final VoidCallback onOpenFullMap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 20, LiLayout.pagePadding, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.exploreMapSectionTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            s.exploreMapSectionSubtitle,
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            child: SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (loading)
                    ColoredBox(
                      color: p.surfaceVariant,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else
                    IgnorePointer(
                      child: ListingsMap(
                        listings: listings,
                        showPriceOnMarker: true,
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                        ),
                      ),
                      child: AppButton(
                        label: s.exploreOpenMap,
                        icon: Icons.fullscreen,
                        onPressed: onOpenFullMap,
                        expand: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
