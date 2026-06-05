import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';

enum AppButtonVariant { primary, accent, outlined, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.accent,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.outlined || variant == AppButtonVariant.ghost
                  ? p.primary
                  : p.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: height <= 44 ? 13 : 15,
                ),
              ),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.accent => FilledButton(
          onPressed: loading ? null : onPressed,
          style: AppTheme.pillFilledFor(p),
          child: child,
        ),
      AppButtonVariant.primary => FilledButton(
          onPressed: loading ? null : onPressed,
          style: AppTheme.pillPrimaryFor(p),
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: AppTheme.pillOutlinedFor(p),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
    };

    if (!expand) return SizedBox(height: height, child: button);
    return SizedBox(width: double.infinity, height: height, child: button);
  }
}
