import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/demand_board_feed_tab.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';

/// แท็บฟีด / จับคู่ / ที่ฉันหา — pill + ไอคอน (สไตล์ Looking Feed)
class DemandBoardFeedTabs extends StatelessWidget {
  const DemandBoardFeedTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    this.showMineTab = true,
    this.matchCount,
  });

  final DemandBoardFeedTab selected;
  final ValueChanged<DemandBoardFeedTab> onChanged;
  final bool showMineTab;
  final int? matchCount;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final tabs = <_TabSpec>[
      _TabSpec(
        tab: DemandBoardFeedTab.feed,
        icon: Icons.campaign_outlined,
        label: s.demandBoardTabFeed,
      ),
      _TabSpec(
        tab: DemandBoardFeedTab.matches,
        icon: Icons.home_work_outlined,
        label: s.demandBoardTabMatches,
        badge: matchCount,
      ),
      if (showMineTab)
        _TabSpec(
          tab: DemandBoardFeedTab.mine,
          icon: Icons.manage_search_outlined,
          label: s.demandBoardTabMySearch,
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _FeedPill(
              spec: tabs[i],
              active: selected == tabs[i].tab,
              onTap: () => onChanged(tabs[i].tab),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.tab,
    required this.icon,
    required this.label,
    this.badge,
  });

  final DemandBoardFeedTab tab;
  final IconData icon;
  final String label;
  final int? badge;
}

class _FeedPill extends StatelessWidget {
  const _FeedPill({
    required this.spec,
    required this.active,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = active ? Colors.white : p.primary;
    final badge = spec.badge;

    return Material(
      color: active ? null : p.surface,
      elevation: active ? 0 : 0,
      shadowColor: p.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        side: BorderSide(
          color: active ? Colors.transparent : p.primary.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Ink(
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: [p.primary, p.accent.withOpacity(0.88)],
                  )
                : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(spec.icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                spec.label,
                style: TextStyle(
                  fontSize: LiLayout.homeCardSubtitle,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (badge != null && badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withOpacity(0.22)
                        : p.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
