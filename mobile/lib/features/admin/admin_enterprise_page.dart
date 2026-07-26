import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/admin_desktop.dart';

/// Padding มาตรฐานเนื้อหาใน Enterprise shell
EdgeInsets adminEnterprisePagePadding(BuildContext context) {
  final wide = useAdminWideShell(context);
  return EdgeInsets.fromLTRB(
    wide ? 16 : 12,
    wide ? 16 : 10,
    wide ? 16 : 12,
    16,
  );
}

/// หัวข้อหน้า — ใช้ร่วมทุกโซน
class AdminEnterprisePageHeader extends StatelessWidget {
  const AdminEnterprisePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.badge,
    this.badgeAlert = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final String? badge;
  final bool badgeAlert;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AdminTheme.text,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: AdminTheme.hint.copyWith(fontSize: 12)),
              ],
            ],
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (badgeAlert ? AppTheme.error : LivingBkkBrand.purplePrimary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (badgeAlert ? AppTheme.error : LivingBkkBrand.purplePrimary)
                    .withOpacity(0.3),
              ),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: badgeAlert ? AppTheme.error : LivingBkkBrand.purplePrimary,
              ),
            ),
          ),
        ],
        ...actions,
      ],
    );
  }
}

/// แถบสถิติกระชับ
class AdminEnterpriseStatStrip extends StatelessWidget {
  const AdminEnterpriseStatStrip({super.key, required this.items});

  final List<AdminEnterpriseStat> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((i) => _StatPill(item: i)).toList(),
    );
  }
}

class AdminEnterpriseStat {
  const AdminEnterpriseStat({
    required this.label,
    required this.value,
    this.icon,
    this.alert = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool alert;
  final VoidCallback? onTap;
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.item});

  final AdminEnterpriseStat item;

  @override
  Widget build(BuildContext context) {
    final color =
        item.alert ? AppTheme.error : LivingBkkBrand.purplePrimary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: item.alert
                  ? AppTheme.error.withOpacity(0.25)
                  : AdminTheme.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 14, color: color),
                  const SizedBox(width: 6),
                ],
                Text(
                  item.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// แบนเนอร์ข้อมูล/เตือน
class AdminEnterpriseBanner extends StatelessWidget {
  const AdminEnterpriseBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.tone = AdminEnterpriseBannerTone.info,
    this.onTap,
  });

  final String message;
  final IconData icon;
  final AdminEnterpriseBannerTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (tone) {
      AdminEnterpriseBannerTone.info =>
        (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), const Color(0xFFBFDBFE)),
      AdminEnterpriseBannerTone.warn =>
        (const Color(0xFFFFF7ED), const Color(0xFF9A3412), const Color(0xFFFED7AA)),
      AdminEnterpriseBannerTone.alert =>
        (AppTheme.error.withOpacity(0.08), AppTheme.error, AppTheme.error.withOpacity(0.25)),
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                      height: 1.4,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 18, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum AdminEnterpriseBannerTone { info, warn, alert }

/// กล่องเนื้อหาขาว
class AdminEnterprisePanel extends StatelessWidget {
  const AdminEnterprisePanel({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminTheme.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: AdminTheme.section.copyWith(fontSize: 13),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// แถวรายการมาตรฐาน
class AdminEnterpriseRecordTile extends StatelessWidget {
  const AdminEnterpriseRecordTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.alert = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final bool alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = alert ? AppTheme.error : LivingBkkBrand.purplePrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: alert
                    ? AppTheme.error.withOpacity(0.2)
                    : AdminTheme.border,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  leading ??
                      Icon(Icons.circle, size: 8, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AdminTheme.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing ?? const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip กรอง
class AdminEnterpriseFilterChip extends StatelessWidget {
  const AdminEnterpriseFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final color = selected ? LivingBkkBrand.purplePrimary : AdminTheme.textMuted;
    return FilterChip(
      label: Text(
        count != null ? '$label ($count)' : label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      backgroundColor: AdminTheme.surfaceMuted,
      selectedColor: LivingBkkBrand.purplePrimary.withOpacity(0.12),
      side: BorderSide(
        color: selected
            ? LivingBkkBrand.purplePrimary.withOpacity(0.4)
            : AdminTheme.border,
      ),
    );
  }
}

class AdminEnterpriseEmptyState extends StatelessWidget {
  const AdminEnterpriseEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AdminTheme.textFaint),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AdminTheme.hint.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// แถบค้นหา
class AdminEnterpriseSearchField extends StatelessWidget {
  const AdminEnterpriseSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged?.call(),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AdminTheme.caption,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: controller.text.isNotEmpty && onClear != null
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminTheme.border),
        ),
      ),
    );
  }
}
