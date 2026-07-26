import 'package:flutter/material.dart';

import '../../state/search_session_controller.dart';
import '../../theme/living_bkk_brand.dart';
import '../home_search_filter_chips.dart';

/// แถบตัวกรองติดใต้ช่องค้นหา (pinned) — เช่า/ซื้อ แบบ Shopee
class HomeStickyFilterChipsSliver extends StatelessWidget {
  const HomeStickyFilterChipsSliver({
    super.key,
    required this.session,
    required this.onOpenFilters,
    this.hasActiveFilters = false,
  });

  final SearchSessionController session;
  final VoidCallback onOpenFilters;
  final bool hasActiveFilters;

  static const double barHeight = 44;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeStickyFilterDelegate(
        height: barHeight,
        child: Material(
          color: LivingBkkBrand.pageBackgroundOf(context),
          elevation: 0.5,
          shadowColor: Colors.black26,
          child: HomeSearchFilterChips(
            session: session,
            onOpenFilters: onOpenFilters,
            hasActiveFilters: hasActiveFilters,
          ),
        ),
      ),
    );
  }
}

class _HomeStickyFilterDelegate extends SliverPersistentHeaderDelegate {
  _HomeStickyFilterDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, width: double.infinity, child: child);
  }

  @override
  bool shouldRebuild(covariant _HomeStickyFilterDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}
