import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.hint,
    this.onTap,
    this.onFilter,
    this.trailing,
    this.showFilter = true,
  });

  final String hint;
  final VoidCallback? onTap;
  final VoidCallback? onFilter;
  final Widget? trailing;
  final bool showFilter;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      shadowColor: p.cardShadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            color: p.surface,
            border: Border.all(color: p.border.withOpacity(0.7)),
            boxShadow: [AppTheme.cardShadowFor(p)],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.search, color: p.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: p.textSecondary,
                    ),
                  ),
                ),
                if (showFilter && onFilter != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.tune, color: p.textSecondary, size: 20),
                    onPressed: onFilter,
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
