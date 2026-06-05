import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';

/// Bottom nav — elevated bar with selected pill (follows light / dark theme)
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final items = [
      _NavItem(s.navHome, Icons.search_outlined, Icons.search, 0),
      _NavItem(s.navSaved, Icons.favorite_border, Icons.favorite, 1),
      _NavItem(s.navBoard, Icons.campaign_outlined, Icons.campaign, 2),
      _NavItem(s.navMessages, Icons.chat_bubble_outline, Icons.chat_bubble, 3),
      _NavItem(s.navProfile, Icons.person_outline, Icons.person, 4),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(
          top: BorderSide(
            color: isLight ? p.border : p.divider,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: p.navShadow,
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
          if (isLight)
            BoxShadow(
              color: p.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: Row(
            children: [
              for (final item in items)
                _item(
                  context: context,
                  palette: p,
                  isLight: isLight,
                  item: item,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({
    required BuildContext context,
    required AppPalette palette,
    required bool isLight,
    required _NavItem item,
  }) {
    final selected = index == item.index;
    final selectedColor = palette.primary;
    final unselectedColor = palette.textSecondary.withOpacity(0.72);
    final color = selected ? selectedColor : unselectedColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(item.index),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          splashColor: palette.primary.withOpacity(0.12),
          highlightColor: palette.primary.withOpacity(0.06),
          child: AnimatedContainer(
            duration: AppTheme.animNormal,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? palette.primaryLight.withOpacity(isLight ? 1 : 0.42)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: selected
                  ? Border.all(
                      color: palette.primary.withOpacity(isLight ? 0.18 : 0.28),
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.05 : 1,
                  duration: AppTheme.animFast,
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    size: selected ? 24 : 22,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    height: 1.1,
                    letterSpacing: selected ? 0.1 : 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon, this.index);
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int index;
}
