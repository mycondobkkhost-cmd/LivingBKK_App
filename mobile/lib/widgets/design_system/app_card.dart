import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.margin,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = radius ?? AppTheme.radiusLg;
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    final card = AnimatedContainer(
      duration: AppTheme.animNormal,
      margin: margin,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: p.border.withOpacity(0.5)),
        boxShadow: [AppTheme.cardShadowFor(p)],
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: content),
            ),
    );

    return card;
  }
}
