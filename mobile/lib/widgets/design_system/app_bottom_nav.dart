import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_avatar.dart';

/// Bottom nav — Apple standard tab bar (49 pt) + safe area ติดขอบล่าง
abstract final class AppBottomNavMetrics {
  /// ความสูงแถบไอคอน + ข้อความ (49 + 34 pt)
  static const double tabBarHeight = 83;
  /// Safe area ล่าง (34 + 34 pt)
  static const double defaultSafeBottom = 68;
  /// เลื่อนไอคอน+ข้อความขึ้นจากกึ่งกลางแถบ
  static const double iconLift = 17;
  static const double iconScale = 1.15;
  static const double iconSizeSelected = 26.45;
  static const double iconSizeDefault = 25.3;
  static const double profileAvatarSize = 27.6;
  static const double profileAvatarIconSize = 16.1;

  static double safeBottomInset(BuildContext context) {
    return MediaQuery.viewPaddingOf(context).bottom;
  }

  /// รวมจากขอบล่างสุด = 83 + safe area (เช่น 151 pt บน iPhone preview)
  static double totalHeight(BuildContext context) {
    return tabBarHeight + safeBottomInset(context);
  }
}

abstract final class AppBottomNavColors {
  static const activeOrange = Color(0xFFE85A00);
  static const activeOrangeDark = Color(0xFFFF7A33);
  static const inactiveLight = Color(0xFF4B5563);
  static const inactiveDark = Color(0xFF9CA3AF);
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    this.contactBadgeCount = 0,
    this.myListingsBadgeCount = 0,
    this.profileAvatarUrl,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final int contactBadgeCount;
  final int myListingsBadgeCount;
  final String? profileAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final safeBottom = AppBottomNavMetrics.safeBottomInset(context);

    final items = [
      _NavItem(s.navHome, Icons.search_outlined, Icons.search, 0),
      _NavItem(s.navMyListings, Icons.home_work_outlined, Icons.home_work, 1),
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
            color: p.navShadow.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: AppBottomNavMetrics.tabBarHeight,
            child: ClipRect(
              child: Transform.translate(
                offset: const Offset(0, -AppBottomNavMetrics.iconLift),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      for (final item in items)
                        _item(
                          context: context,
                          palette: p,
                          isLight: isLight,
                          item: item,
                          badgeCount: item.index == 3
                              ? contactBadgeCount
                              : item.index == 1
                                  ? myListingsBadgeCount
                                  : 0,
                          profileAvatarUrl:
                              item.index == 4 ? profileAvatarUrl : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // พื้นทึบต่อเนื่องใต้แถบ 49 pt — home indicator อยู่ในโซนนี้
          SizedBox(height: safeBottom),
        ],
      ),
    );
  }

  Widget _item({
    required BuildContext context,
    required AppPalette palette,
    required bool isLight,
    required _NavItem item,
    int badgeCount = 0,
    String? profileAvatarUrl,
  }) {
    final selected = index == item.index;
    final selectedColor = isLight
        ? AppBottomNavColors.activeOrange
        : AppBottomNavColors.activeOrangeDark;
    final unselectedColor =
        isLight ? AppBottomNavColors.inactiveLight : AppBottomNavColors.inactiveDark;
    final color = selected ? selectedColor : unselectedColor;
    final isProfileTab = item.index == 4;
    final showProfilePhoto =
        isProfileTab && profileAvatarUrl != null && profileAvatarUrl.isNotEmpty;

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () => onChanged(item.index),
            splashColor: selectedColor.withOpacity(0.1),
            highlightColor: selectedColor.withOpacity(0.05),
            child: SizedBox(
              height: double.infinity,
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Badge(
                isLabelVisible: badgeCount > 0,
                label: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(fontSize: 9),
                ),
                backgroundColor: AppTheme.error,
                child: showProfilePhoto
                    ? ProfileAvatar(
                        imageUrl: profileAvatarUrl,
                        size: AppBottomNavMetrics.profileAvatarSize,
                        iconSize: AppBottomNavMetrics.profileAvatarIconSize,
                        selected: selected,
                        ringColor: selected ? selectedColor : null,
                      )
                    : Icon(
                        selected ? item.activeIcon : item.icon,
                        size: selected
                            ? AppBottomNavMetrics.iconSizeSelected
                            : AppBottomNavMetrics.iconSizeDefault,
                        color: color,
                      ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                  height: 1.0,
                  letterSpacing: selected ? -0.1 : 0,
                ),
              ),
            ],
              ),
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
