import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/admin_routing.dart';
import '../../utils/admin_sign_out.dart';
import '../../widgets/admin_attention_badge.dart';
import 'admin_enterprise_zone.dart';
import 'admin_nav_model.dart';
import 'admin_template_theme.dart';

/// Sidebar มืดแบบแดชบอร์ดสะอาด — RealXtate Ops
class AdminTemplateSideMenu extends StatelessWidget {
  const AdminTemplateSideMenu({
    super.key,
    required this.config,
    required this.selected,
    required this.onSelect,
    this.tierLabel,
    this.onItemTap,
  });

  final AdminNavConfig config;
  final AdminNavId selected;
  final ValueChanged<AdminNavId> onSelect;
  final String? tierLabel;
  final VoidCallback? onItemTap;

  void _tap(BuildContext context, AdminNavId id) {
    onItemTap?.call();
    selectAdminNav(context, id, onSelect);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final isEn = s.isEnglish;

    return Material(
      color: AdminTemplateTheme.sidebarBg,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          ChatService.instance,
          AuthService.instance,
        ]),
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(tierLabel: tierLabel, s: s),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ...config.pinnedItems(s).map(
                          (item) => _MenuTile(
                            item: item,
                            selected: selected == item.id,
                            isEn: isEn,
                            onTap: () => _tap(context, item.id),
                          ),
                        ),
                    const SizedBox(height: 8),
                    for (final zone in adminVisibleZones(config)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
                        child: Text(
                          adminZoneLabel(zone, s).toUpperCase(),
                          style: AdminTemplateTheme.menuLabel(
                            selected: false,
                            section: true,
                          ),
                        ),
                      ),
                      for (final item in adminZoneNavItems(zone, config, s))
                        ..._menuTilesForItem(
                          context,
                          item,
                          selected: selected,
                          isEn: isEn,
                          onSelect: onSelect,
                          onItemTap: onItemTap,
                          indent: item.subIndent,
                        ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              _UserFooter(tierLabel: tierLabel, s: s),
              _FooterLink(
                icon: Icons.storefront_outlined,
                label: s.adminViewConsumerApp,
                onTap: () {
                  onItemTap?.call();
                  goConsumerApp(context);
                },
              ),
              _FooterLink(
                icon: Icons.logout_outlined,
                label: s.signOut,
                onTap: () {
                  onItemTap?.call();
                  performAdminSignOut(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}

List<Widget> _menuTilesForItem(
  BuildContext context,
  AdminNavItem item, {
  required AdminNavId selected,
  required bool isEn,
  required ValueChanged<AdminNavId> onSelect,
  required VoidCallback? onItemTap,
  int indent = 0,
}) {
  void tap(AdminNavId id) {
    onItemTap?.call();
    selectAdminNav(context, id, onSelect);
  }

  return [
    Padding(
      padding: EdgeInsets.only(left: indent * 12.0),
      child: _MenuTile(
        item: item,
        selected: selected == item.id,
        isEn: isEn,
        onTap: () => tap(item.id),
      ),
    ),
    for (final child in item.children)
      ..._menuTilesForItem(
        context,
        child,
        selected: selected,
        isEn: isEn,
        onSelect: onSelect,
        onItemTap: onItemTap,
        indent: indent + 1,
      ),
  ];
}

class _Header extends StatelessWidget {
  const _Header({this.tierLabel, required this.s});

  final String? tierLabel;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 16, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LivingBkkBrand.ctaGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: LivingBkkBrand.brandRed.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              'RX',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LivingBkkBrand.name,
                  style: AdminTemplateTheme.menuLabel(selected: true).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.adminOpsSidebarSubtitle,
                  style: AdminTemplateTheme.menuSubtitle(selected: false),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tierLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    tierLabel!,
                    style: AdminTemplateTheme.menuSubtitle(selected: false)
                        .copyWith(fontSize: 9),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.item,
    required this.selected,
    required this.isEn,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final bool isEn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = item.urgent && item.badgeCount > 0
        ? AppTheme.error
        : AdminTemplateTheme.primaryColor;

    Widget leading = Icon(
      item.icon,
      size: 18,
      color: selected ? Colors.white : Colors.white54,
    );

    if (item.badgeCount > 0 &&
        (item.urgent || item.id == AdminNavId.viewingCalendar)) {
      leading = AdminAttentionIconBadge(
        count: item.badgeCount,
        child: SizedBox(width: 18, height: 18, child: leading),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected
            ? Colors.white.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (selected)
                Positioned(
                  left: 0,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(14, 10, 12, 10),
                child: Row(
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? item.labelEn : item.labelTh,
                            style: AdminTemplateTheme.menuLabel(
                              selected: selected,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isEn ? item.labelTh : item.labelEn,
                            style: AdminTemplateTheme.menuSubtitle(
                              selected: selected,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (item.badgeCount > 0 &&
                        !item.urgent &&
                        item.id != AdminNavId.viewingCalendar)
                      _CountBadge(count: item.badgeCount, urgent: item.urgent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.urgent});

  final int count;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final color =
        urgent ? AppTheme.error : AdminTemplateTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter({this.tierLabel, required this.s});

  final String? tierLabel;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final name = AuthService.instance.displayName;
    final role = tierLabel ?? s.adminOpsRoleFallback;
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'A';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: LivingBkkBrand.brandRed.withOpacity(0.85),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AdminTemplateTheme.menuLabel(selected: true)
                      .copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role,
                  style: AdminTemplateTheme.menuSubtitle(selected: false),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: Colors.white54),
      title: Text(
        label,
        style: AdminTemplateTheme.menuLabel(selected: false),
      ),
      onTap: onTap,
    );
  }
}
