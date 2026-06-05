import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/env.dart';
import '../services/auth_service.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// แถบโหมดทดลอง — แสดงนอกหน้าแรก
class TrialModeBanner extends StatelessWidget {
  const TrialModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Env.trialMode) return const SizedBox.shrink();

    final s = AppStrings.of(context);

    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;
        if (auth.isTrialSignedIn) return const SizedBox.shrink();

        return Material(
          color: AppTheme.warningLight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.science_outlined, size: 18, color: AppTheme.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.trialBannerText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/login'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    foregroundColor: AppTheme.cta,
                  ),
                  child: Text(s.enter, style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
