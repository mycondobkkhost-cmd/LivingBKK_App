import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';

/// ชีทเลือกบนบอร์ด — ดูประกาศอนุมัติแล้ว / ส่งประกาศให้ทีมอนุมัติ
abstract final class DemandCreatePostSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _Sheet(),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.demandCreatePostSheetTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _PolicyBanner(text: s.demandBoardHubSubtitle),
              const SizedBox(height: 8),
              Text(
                s.demandBoardHubPolicyNote,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _OptionTile(
                icon: Icons.campaign_rounded,
                iconBg: LivingBkkBrand.brandRedTint,
                iconColor: LivingBkkBrand.brandRed,
                title: s.demandBoardHubFeedTitle,
                subtitle: s.demandBoardHubFeedBody,
                onTap: () {
                  Navigator.pop(context);
                  DemandBoardNavigation.openBoardFeed(context);
                },
              ),
              const SizedBox(height: 10),
              _OptionTile(
                icon: Icons.manage_search_rounded,
                iconBg: const Color(0xFFFFF0E6),
                iconColor: LivingBkkBrand.accentOrange,
                title: s.demandBoardHubLookingTitle,
                subtitle: s.demandBoardHubLookingBody,
                onTap: () {
                  Navigator.pop(context);
                  DemandBoardNavigation.openBoardLooking(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyBanner extends StatelessWidget {
  const _PolicyBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LivingBkkBrand.brandRedTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LivingBkkBrand.brandRed.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: LivingBkkBrand.brandRed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: LivingBkkBrand.brandRedDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LivingBkkBrand.pageBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
