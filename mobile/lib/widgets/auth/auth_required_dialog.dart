import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

/// ป้อปอัพกลางจอ — ปิดได้ ไม่บังคับเปลี่ยนหน้า
abstract final class AuthRequiredDialog {
  static Future<void> show(
    BuildContext context, {
    String? message,
    String? redirectRoute,
  }) {
    final s = AppStrings.of(context);
    final body = message ?? s.authRequiredBeforePost;
    final encoded = redirectRoute != null
        ? Uri.encodeComponent(redirectRoute)
        : null;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 40,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final route = encoded != null
                  ? '/signup?redirect=$encoded'
                  : '/signup';
              context.push(route);
            },
            child: Text(s.signUpTitle),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.cta,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              final route = encoded != null
                  ? '/login?redirect=$encoded'
                  : '/login';
              context.push(route);
            },
            child: Text(s.signInTitle),
          ),
        ],
      ),
    );
  }
}
