import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';

enum MyListingsFilter { online, pending, archived, other }

extension MyListingsFilterX on MyListingsFilter {
  String label(AppStrings s, int count) {
    switch (this) {
      case MyListingsFilter.online:
        return s.myListingsFilterOnline(count);
      case MyListingsFilter.pending:
        return s.myListingsFilterPending(count);
      case MyListingsFilter.archived:
        return s.myListingsFilterArchived(count);
      case MyListingsFilter.other:
        return s.myListingsFilterOther(count);
    }
  }
}

/// แถบกรองสถานะ — สไตล์ MyStock (กะทัดรัด)
class MyListingsFilterBar extends StatelessWidget {
  const MyListingsFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.counts,
    this.expiringSoonCount = 0,
    this.onExpiringBannerTap,
  });

  final MyListingsFilter filter;
  final ValueChanged<MyListingsFilter> onFilterChanged;
  final Map<MyListingsFilter, int> counts;
  final int expiringSoonCount;
  final VoidCallback? onExpiringBannerTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.textSecondary.withOpacity(0.18)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<MyListingsFilter>(
                    value: filter,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more, size: 20),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    items: MyListingsFilter.values.map((f) {
                      final n = counts[f] ?? 0;
                      return DropdownMenuItem(
                        value: f,
                        child: Text(f.label(s, n)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) onFilterChanged(v);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _IconBox(icon: Icons.swap_vert, tooltip: s.myListingsSortHint),
            const SizedBox(width: 4),
            _IconBox(icon: Icons.tune, tooltip: s.filters),
          ],
        ),
        if (expiringSoonCount > 0 && filter == MyListingsFilter.online) ...[
          const SizedBox(height: 6),
          Material(
            color: LivingBkkBrand.piterOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onExpiringBannerTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: LivingBkkBrand.piterOrange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.myListingsExpiringSoonBanner(expiringSoonCount),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LivingBkkBrand.piterOrange,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: LivingBkkBrand.piterOrange),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {},
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.textSecondary.withOpacity(0.18)),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
        ),
      ),
    );
  }
}
