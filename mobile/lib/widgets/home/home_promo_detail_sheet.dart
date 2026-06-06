import 'package:flutter/material.dart';

import '../../config/home_promo_config.dart';
import 'home_promo_image.dart';
import '../../l10n/app_strings.dart';
import '../../shell/main_shell_scope.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';

class HomePromoDetailSheet extends StatelessWidget {
  const HomePromoDetailSheet({
    super.key,
    required this.promo,
    required this.isEnglish,
  });

  final HomePromoItem promo;
  final bool isEnglish;

  static Future<void> show(
    BuildContext context, {
    required HomePromoItem promo,
    required bool isEnglish,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HomePromoDetailSheet(promo: promo, isEnglish: isEnglish),
    );
  }

  void _contactTeam(BuildContext context) {
    Navigator.of(context).pop();
    MainShellScope.maybeOf(context)?.selectTab(3);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.of(context).promoContactTeamHint),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: p.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: AspectRatio(
                      aspectRatio: HomePromoConfig.imageAspectRatio,
                      child: HomePromoImage(promo: promo, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    promo.title(isEnglish),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    promo.detail(isEnglish),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: p.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final bullet in promo.bullets(isEnglish))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 20, color: p.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bullet,
                              style: TextStyle(
                                fontSize: LiLayout.homeCardTitle,
                                color: p.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _contactTeam(context),
                    icon: const Icon(Icons.support_agent_rounded, size: 20),
                    label: Text(s.promoContactTeam),
                    style: FilledButton.styleFrom(
                      backgroundColor: p.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
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
