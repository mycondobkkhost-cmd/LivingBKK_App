import 'package:flutter/material.dart';

import '../../theme/living_bkk_brand.dart';
import '../../theme/profile_shell_theme.dart';

class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.iconColor,
    this.iconBackground,
    this.accentChevron = false,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? iconColor;
  final Color? iconBackground;
  final bool accentChevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final textPrimary = destructive
        ? LivingBkkBrand.brandRed
        : ProfileShellTheme.textPrimary(context);
    final textSecondary = ProfileShellTheme.textSecondary(context);
    final iconFg = iconColor ??
        (destructive ? LivingBkkBrand.brandRed : textPrimary);
    final iconBg = iconBackground ??
        (destructive
            ? LivingBkkBrand.brandRedTint
            : ProfileShellTheme.badgeBackground(context));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconFg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (showChevron && onTap != null)
                accentChevron
                    ? Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: LivingBkkBrand.brandRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: textSecondary.withOpacity(0.7),
                        size: 22,
                      ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileMenuDivider extends StatelessWidget {
  const ProfileMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 66,
      endIndent: 16,
      color: ProfileShellTheme.divider(context),
    );
  }
}

/// การ์ดกลุ่มเมนูแบบ Pantip — หัวข้อ + รายการในพื้นขาวมุมโค้ง
class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({
    super.key,
    this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = ProfileShellTheme.palette(context);
    final tiles = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      tiles.add(children[i]);
      if (i < children.length - 1) {
        tiles.add(const ProfileMenuDivider());
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title!,
              style: TextStyle(
                color: ProfileShellTheme.textSecondary(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: isDark ? Border.all(color: p.border) : null,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? p.cardShadow
                    : Colors.black.withOpacity(0.04),
                blurRadius: isDark ? 16 : 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(children: tiles),
          ),
        ),
      ],
    );
  }
}
