import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

enum AppBadgeTone { primary, accent, success, warning, neutral }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.primary,
    this.icon,
  });

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg) = switch (tone) {
      AppBadgeTone.primary => (p.primaryLight, p.primary),
      AppBadgeTone.accent => (p.accent.withOpacity(0.15), p.accent),
      AppBadgeTone.success => (p.success.withOpacity(0.15), p.success),
      AppBadgeTone.warning => (p.warning.withOpacity(0.15), p.warning),
      AppBadgeTone.neutral => (p.surfaceVariant, p.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}
