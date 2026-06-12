import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_routing.dart';
import '../../utils/admin_sign_out.dart';
import '../../widgets/admin_attention_badge.dart';
import 'admin_enterprise_zone.dart';
import 'admin_nav_model.dart';
import 'admin_template_theme.dart';
import '../../services/chat_service.dart';

/// Sidebar มืดแบบ template — รวมทุกโซนเมนูหลังบ้าน
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
        listenable: ChatService.instance,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(tierLabel: tierLabel),
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
                        padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
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
              const SizedBox(height: 8),
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
  const _Header({this.tierLabel});

  final String? tierLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AdminTemplateTheme.primaryColor,
              borderRadius: BorderRadius.circular(10),
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
                  'RealXtate Ops',
                  style: AdminTemplateTheme.menuLabel(selected: true).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (tierLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    tierLabel!,
                    style: AdminTemplateTheme.menuLabel(selected: false)
                        .copyWith(fontSize: 11),
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
      color: selected ? accent : Colors.white54,
    );

    if (item.badgeCount > 0 &&
        (item.urgent || item.id == AdminNavId.viewingCalendar)) {
      leading = AdminAttentionIconBadge(
        count: item.badgeCount,
        child: SizedBox(width: 18, height: 18, child: leading),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: selected
            ? AdminTemplateTheme.secondaryColor
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label(isEn),
                    style: AdminTemplateTheme.menuLabel(selected: selected),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.badgeCount > 0 &&
                    !item.urgent &&
                    item.id != AdminNavId.viewingCalendar)
                  _CountBadge(count: item.badgeCount, urgent: item.urgent),
              ],
            ),
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
        color: color.withOpacity(0.2),
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
