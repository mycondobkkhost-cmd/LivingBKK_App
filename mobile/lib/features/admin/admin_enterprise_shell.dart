import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../services/chat_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/admin_desktop.dart';
import '../../utils/admin_routing.dart';
import '../../utils/admin_sign_out.dart';
import 'admin_command_palette.dart';
import 'admin_enterprise_zone.dart';
import 'admin_nav_model.dart';
import 'admin_phone_frame_host.dart';
import 'admin_shell_scaffold.dart';

const kAdminEnterpriseRailWidth = 64.0;
const kAdminEnterpriseSubnavWidth = 228.0;

/// Shell หลังบ้านองค์กร — rail โซน | เมนูย่อย | top bar | เนื้อหา
class AdminEnterpriseShell extends StatelessWidget {
  const AdminEnterpriseShell({
    super.key,
    required this.config,
    required this.selected,
    required this.onSelect,
    required this.body,
    required this.actions,
    this.banners = const [],
    this.tierLabel,
    this.pageTitle,
    this.hideSubnav = false,
    this.contentBackgroundColor = const Color(0xFFF1F5F9),
  });

  final AdminNavConfig config;
  final AdminNavId selected;
  final ValueChanged<AdminNavId> onSelect;
  final Widget body;
  final List<Widget> actions;
  final List<Widget> banners;
  final String? tierLabel;
  final String? pageTitle;
  final bool hideSubnav;
  final Color contentBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final zone = adminZoneForNav(selected);
    final showSubnav = useAdminSubnav(context) && !hideSubnav;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EnterpriseRail(
          config: config,
          activeZone: zone,
          selected: selected,
          onSelect: onSelect,
          tierLabel: tierLabel,
          showSubnav: showSubnav,
        ),
        if (showSubnav)
          _EnterpriseSubnav(
            config: config,
            zone: zone,
            selected: selected,
            onSelect: onSelect,
          ),
        Expanded(
          child: ColoredBox(
            color: contentBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EnterpriseTopBar(
                  config: config,
                  selected: selected,
                  pageTitle: pageTitle ?? config.labelForNav(selected, context.s),
                  actions: actions,
                ),
                ...banners,
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// เมนูโซน — เมื่อจอแคบ / จำลองมือถือ (ไม่มี subnav)
void showEnterpriseZoneSheet({
  required BuildContext context,
  required AdminEnterpriseZone zone,
  required AdminNavConfig config,
  required AdminNavId selected,
  required ValueChanged<AdminNavId> onSelect,
}) {
  final s = context.s;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              adminZoneLabel(zone, s),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              children: [
                for (final item in adminZoneNavItems(zone, config, s))
                  ..._subnavTiles(
                    item: item,
                    selected: selected,
                    isEn: s.isEnglish,
                    onSelect: (id) {
                      Navigator.pop(ctx);
                      onSelect(id);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EnterpriseRail extends StatelessWidget {
  const _EnterpriseRail({
    required this.config,
    required this.activeZone,
    required this.selected,
    required this.onSelect,
    required this.showSubnav,
    this.tierLabel,
  });

  final AdminNavConfig config;
  final AdminEnterpriseZone activeZone;
  final AdminNavId selected;
  final ValueChanged<AdminNavId> onSelect;
  final bool showSubnav;
  final String? tierLabel;

  void _openZone(BuildContext context, AdminEnterpriseZone zone) {
    if (zone == AdminEnterpriseZone.calendar) {
      onSelect(AdminNavId.viewingCalendar);
      return;
    }
    if (!showSubnav) {
      showEnterpriseZoneSheet(
        context: context,
        zone: zone,
        config: config,
        selected: selected,
        onSelect: onSelect,
      );
      return;
    }
    if (kIsWeb && zone == AdminEnterpriseZone.comms) {
      final queue = config.queueUnclaimedCount;
      context.go(
        queue > 0 ? '/admin/console?filter=unclaimed' : '/admin/console',
      );
      return;
    }
    final items = adminZoneNavItems(zone, config, context.s);
    if (items.isEmpty) return;
    onSelect(items.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final zones = adminVisibleZones(config);

    return Material(
      color: const Color(0xFF0F172A),
      child: SizedBox(
        width: kAdminEnterpriseRailWidth,
        child: ListenableBuilder(
          listenable: ChatService.instance,
          builder: (context, _) {
            return Column(
              children: [
                const SizedBox(height: 14),
                _BrandMark(tierLabel: tierLabel),
                const SizedBox(height: 18),
                ...zones.map(
                  (z) => _RailZoneBtn(
                    zone: z,
                    selected: activeZone == z,
                    badge: adminZoneBadgeCount(z, config),
                    urgent: adminZoneUrgent(z, config),
                    tooltip: adminZoneLabel(z, s),
                    onTap: () => _openZone(context, z),
                  ),
                ),
                const Spacer(),
                _RailIconBtn(
                  icon: Icons.storefront_outlined,
                  tooltip: s.adminViewConsumerApp,
                  onTap: () => goConsumerApp(context),
                ),
                if (!showSubnav)
                  _RailIconBtn(
                    icon: Icons.apps_outlined,
                    tooltip: s.adminNavMenu,
                    onTap: () => showEnterpriseZoneSheet(
                      context: context,
                      zone: activeZone,
                      config: config,
                      selected: selected,
                      onSelect: onSelect,
                    ),
                  ),
                _RailIconBtn(
                  icon: Icons.logout,
                  tooltip: s.signOut,
                  onTap: () => performAdminSignOut(context),
                ),
                const SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.tierLabel});

  final String? tierLabel;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tierLabel ?? 'RealXtate Ops',
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              LivingBkkBrand.purplePrimary,
              LivingBkkBrand.purplePrimary.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Text(
          'RX',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _RailZoneBtn extends StatelessWidget {
  const _RailZoneBtn({
    required this.zone,
    required this.selected,
    required this.badge,
    required this.urgent,
    required this.tooltip,
    required this.onTap,
  });

  final AdminEnterpriseZone zone;
  final bool selected;
  final int badge;
  final bool urgent;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : Colors.white.withOpacity(0.55);
    final bg = selected ? Colors.white.withOpacity(0.12) : Colors.transparent;

    Widget icon = Icon(adminZoneIcon(zone), size: 22, color: fg);
    if (badge > 0) {
      icon = Badge(
        backgroundColor: urgent ? AppTheme.error : LivingBkkBrand.purplePrimary,
        label: Text(
          badge > 9 ? '9+' : '$badge',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
        ),
        child: icon,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailIconBtn extends StatelessWidget {
  const _RailIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 48,
            height: 40,
            child: Icon(icon, size: 20, color: Colors.white.withOpacity(0.55)),
          ),
        ),
      ),
    );
  }
}

class _EnterpriseSubnav extends StatelessWidget {
  const _EnterpriseSubnav({
    required this.config,
    required this.zone,
    required this.selected,
    required this.onSelect,
  });

  final AdminNavConfig config;
  final AdminEnterpriseZone zone;
  final AdminNavId selected;
  final ValueChanged<AdminNavId> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final isEn = s.isEnglish;

    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: AdminTheme.border)),
        ),
        child: SizedBox(
          width: kAdminEnterpriseSubnavWidth,
          child: ListenableBuilder(
            listenable: ChatService.instance,
            builder: (context, _) {
              final items = adminZoneNavItems(zone, config, s);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminZoneLabel(zone, s),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AdminTheme.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.adminEnterpriseSubnavHint,
                          style: AdminTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      children: [
                        for (final item in items)
                          ..._subnavTiles(
                            item: item,
                            selected: selected,
                            isEn: isEn,
                            onSelect: onSelect,
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.adminEnterpriseOnline,
                          style: AdminTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

List<Widget> _subnavTiles({
  required AdminNavItem item,
  required AdminNavId selected,
  required bool isEn,
  required ValueChanged<AdminNavId> onSelect,
  int indent = 0,
}) {
  Widget tile(AdminNavItem nav, {int sub = 0}) {
    final active = selected == nav.id;
    final color = nav.urgent && nav.badgeCount > 0
        ? AppTheme.error
        : LivingBkkBrand.purplePrimary;

    return Padding(
      padding: EdgeInsets.only(left: sub * 12.0, bottom: 2),
      child: Material(
        color: active ? color.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onSelect(nav.id),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(
                  nav.icon,
                  size: 18,
                  color: active ? color : AdminTheme.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nav.label(isEn),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AdminTheme.text : AdminTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (nav.badgeCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (nav.urgent ? AppTheme.error : color)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      nav.badgeCount > 99 ? '99+' : '${nav.badgeCount}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: nav.urgent ? AppTheme.error : color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  return [
    tile(item, sub: indent),
    for (final child in item.children)
      ..._subnavTiles(
        item: child,
        selected: selected,
        isEn: isEn,
        onSelect: onSelect,
        indent: indent + 1,
      ),
  ];
}

class _EnterpriseTopBar extends StatelessWidget {
  const _EnterpriseTopBar({
    required this.config,
    required this.selected,
    required this.pageTitle,
    required this.actions,
  });

  final AdminNavConfig config;
  final AdminNavId selected;
  final String pageTitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        final kpis = adminEnterpriseKpis(config, s);
        return Material(
          color: Colors.white,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminTheme.border)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.adminEnterpriseOpsTitle,
                            style: AdminTheme.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            pageTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AdminTheme.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ...kpis.take(3).map(
                          (k) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _KpiChip(kpi: k),
                          ),
                        ),
                    const AdminPhoneFrameToggleButton(),
                    IconButton(
                      icon: const Icon(Icons.search, size: 20),
                      tooltip: s.adminCommandPaletteHint,
                      onPressed: () => showAdminCommandPalette(
                        context: context,
                        config: config,
                        current: selected,
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({required this.kpi});

  final AdminEnterpriseKpi kpi;

  @override
  Widget build(BuildContext context) {
    final color = kpi.alert ? AppTheme.error : AdminTheme.textFaint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kpi.alert
            ? AppTheme.error.withOpacity(0.08)
            : AdminTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: kpi.alert
              ? AppTheme.error.withOpacity(0.25)
              : AdminTheme.border,
        ),
      ),
      child: Text(
        '${kpi.label} ${kpi.value}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
