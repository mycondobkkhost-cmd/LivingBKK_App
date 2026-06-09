import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../state/admin_viewport_controller.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../widgets/admin_attention_badge.dart';
import '../../services/chat_service.dart';
import '../../utils/admin_desktop.dart';
import '../../utils/admin_sign_out.dart';
import 'admin_nav_model.dart';
const double kAdminShellSidebarWidth = 220;

/// แถบหัวข้อเนื้อหาด้านขวา — โหมดคอม (ไม่มี AppBar คร่อม sidebar)
class AdminWideContentBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminWideContentBar({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminTheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AdminTheme.border)),
        ),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    title,
                    style: AdminTheme.title.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ...actions,
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

int _adminMenuBadgeCount(AdminNavConfig config, AppStrings s) =>
    config.menuBadgeCount(s);

/// ปุ่มเมนู — AppBar / sidebar (มือถือ + คอม)
class AdminNavMenuButton extends StatelessWidget {
  const AdminNavMenuButton({
    super.key,
    required this.config,
    required this.selected,
    required this.onSelect,
    this.showLabel = false,
    this.compact = false,
  });

  final AdminNavConfig config;
  final AdminNavId selected;
  final ValueChanged<AdminNavId> onSelect;
  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        final badge = _adminMenuBadgeCount(config, s);
        final icon = _menuIcon(badge);

        void open() => showAdminNavMenu(
              context: context,
              config: config,
              selected: selected,
              onSelect: onSelect,
            );

        if (showLabel) {
          return TextButton.icon(
            onPressed: open,
            icon: icon,
            label: Text(s.adminNavMenu),
            style: TextButton.styleFrom(
              foregroundColor: LivingBkkBrand.purplePrimary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          );
        }

        return IconButton(
          onPressed: open,
          tooltip: s.adminNavOpenMenu,
          icon: icon,
          visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        );
      },
    );
  }

  Widget _menuIcon(int badge) {
    final icon = Icon(
      showLabel ? Icons.menu_open : Icons.menu,
      size: showLabel ? 20 : (compact ? 22 : 24),
    );
    if (badge <= 0) return icon;
    return Badge(
      label: Text(badge > 99 ? '99+' : '$badge'),
      child: icon,
    );
  }
}

/// เปิดเมนูนำทาง — มือถือ: bottom sheet · คอม: แผง slide-in ซ้าย
void showAdminNavMenu({
  required BuildContext context,
  required AdminNavConfig config,
  required AdminNavId selected,
  required ValueChanged<AdminNavId> onSelect,
}) {
  final wide = useAdminWideShell(context);
  if (wide) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.s.adminNavMenu,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) => Align(
        alignment: Alignment.centerLeft,
        child: Material(
          elevation: 16,
          color: AdminTheme.surface,
          child: SizedBox(
            width: 340,
            height: MediaQuery.sizeOf(ctx).height,
            child: _AdminNavMenuPanel(
              config: config,
              selected: selected,
              onSelect: onSelect,
              onClose: () => Navigator.pop(ctx),
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, scroll) => _AdminNavMenuPanel(
        config: config,
        selected: selected,
        onSelect: onSelect,
        onClose: () => Navigator.pop(ctx),
        scrollController: scroll,
      ),
    ),
  );
}

class _AdminNavMenuPanel extends StatelessWidget {
  const _AdminNavMenuPanel({
    required this.config,
    required this.selected,
    required this.onSelect,
    required this.onClose,
    this.scrollController,
  });

  final AdminNavConfig config;
  final AdminNavId selected;
  final ValueChanged<AdminNavId> onSelect;
  final VoidCallback onClose;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.adminNavMenu,
                  style: AdminTheme.title.copyWith(fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListenableBuilder(
            listenable: ChatService.instance,
            builder: (context, _) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              children: _adminNavMenuChildren(
                context: context,
                config: config,
                selected: selected,
                onSelect: onSelect,
                onClose: onClose,
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        _AdminSignOutBar(onSignOut: () {
          onClose();
          performAdminSignOut(context);
        }),
        if (kIsWeb) _AdminViewportModeBar(onApplied: onClose),
      ],
    );
  }
}

class _AdminSignOutBar extends StatelessWidget {
  const _AdminSignOutBar({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListTile(
      dense: true,
      leading: Icon(Icons.logout_outlined, size: 20, color: AdminTheme.textMuted),
      title: Text(s.signOut, style: const TextStyle(fontSize: 14)),
      onTap: onSignOut,
    );
  }
}

/// ปุ่มสลับคอม/แอปบน AppBar — มองเห็นได้โดยไม่ต้องเปิดเมนู
class AdminViewportToggleButton extends StatelessWidget {
  const AdminViewportToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdminViewportController.instance;
    if (controller == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = context.s;
        final mode = controller.mode;
        final isDesktop = mode == AdminViewportMode.desktop;
        return IconButton(
          tooltip: isDesktop
              ? s.adminViewportToggleToMobile
              : s.adminViewportToggleToDesktop,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              adminViewportModeIcon(mode),
              key: ValueKey(mode),
            ),
          ),
          onPressed: () => controller.setMode(
            isDesktop ? AdminViewportMode.mobile : AdminViewportMode.desktop,
          ),
        );
      },
    );
  }
}

/// สลับมุมมองบนเว็บ — คอมเต็มจอ (sidebar) / แบบแอป (เมนู ☰)
class _AdminViewportModeBar extends StatelessWidget {
  const _AdminViewportModeBar({this.onApplied});

  final VoidCallback? onApplied;

  @override
  Widget build(BuildContext context) {
    final controller = AdminViewportController.instance;
    if (controller == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = context.s;
        final current = controller.mode;

        Widget chip({
          required AdminViewportMode mode,
          required IconData icon,
          required String label,
        }) {
          final selected = current == mode;
          return Expanded(
            child: Material(
              color: selected
                  ? LivingBkkBrand.purplePrimary.withOpacity(0.14)
                  : AdminTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () async {
                  await controller.setMode(mode);
                  onApplied?.call();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: selected
                            ? LivingBkkBrand.purplePrimary
                            : AdminTheme.textMuted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? LivingBkkBrand.purplePrimary
                              : AdminTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final modeHint = current == AdminViewportMode.desktop
            ? s.adminViewportDesktopHint
            : s.adminViewportMobileHint;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.adminViewportSetting,
                style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                s.adminViewportWebOnlyNote,
                style: AdminTheme.caption.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  chip(
                    mode: AdminViewportMode.desktop,
                    icon: Icons.desktop_windows_outlined,
                    label: s.adminViewportDesktop,
                  ),
                  const SizedBox(width: 6),
                  chip(
                    mode: AdminViewportMode.mobile,
                    icon: Icons.smartphone_outlined,
                    label: s.adminViewportMobile,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                modeHint,
                style: AdminTheme.caption.copyWith(
                  fontSize: 10,
                  color: LivingBkkBrand.purplePrimary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

List<Widget> _navTilesForItem(
  BuildContext context,
  AdminNavItem item, {
  required AdminNavId selected,
  required bool isEn,
  required ValueChanged<AdminNavId> onSelect,
  double basePadding = 8,
}) {
  Widget tile(AdminNavItem nav) {
    return Padding(
      padding: EdgeInsets.only(left: basePadding + (nav.subIndent * 16)),
      child: _NavTile(
        item: nav,
        selected: selected == nav.id,
        isEn: isEn,
        dense: true,
        onTap: () => _handleNavTap(context, nav.id, onSelect),
      ),
    );
  }

  return [
    tile(item),
    for (final child in item.children) tile(child),
  ];
}

List<Widget> _adminNavMenuChildren({
  required BuildContext context,
  required AdminNavConfig config,
  required AdminNavId selected,
  required ValueChanged<AdminNavId> onSelect,
  required VoidCallback onClose,
}) {
  final s = context.s;
  return [
    ...config.pinnedItems(s).map(
          (item) => _NavTile(
            item: item,
            selected: selected == item.id,
            isEn: s.isEnglish,
            onTap: () {
              onClose();
              _handleNavTap(context, item.id, onSelect);
            },
          ),
        ),
    const Divider(),
    ...config.visibleGroups.expand((group) {
      final items = config.groupItems(group, s);
      if (items.isEmpty) return <Widget>[];
      final badge = config.badgeForGroup(group);
      return [
        ListTile(
          leading: Icon(config.groupIcon(group)),
          title: Text(
            config.groupLabel(group, s),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          trailing: badge > 0 ? _Badge(count: badge, urgent: false) : null,
        ),
        ...items.expand(
          (item) => _navTilesForItem(
            context,
            item,
            selected: selected,
            isEn: s.isEnglish,
            onSelect: (id) {
              onClose();
              onSelect(id);
            },
            basePadding: 12,
          ),
        ),
        const SizedBox(height: 4),
      ];
    }),
  ];
}

/// เลย์เอาต์หลังบ้านใหม่ — ปักหมุดเร่งด่วน + กลุ่มดรอปดาวน์พร้อม badge
class AdminShellScaffold extends StatelessWidget {
  const AdminShellScaffold({
    super.key,
    required this.config,
    required this.selected,
    required this.onSelect,
    required this.body,
    required this.actions,
    this.header,
    this.tierLabel,
  });

  final AdminNavConfig config;
  final AdminNavId selected;
  final ValueChanged<AdminNavId> onSelect;
  final Widget body;
  final List<Widget> actions;
  final Widget? header;
  final String? tierLabel;

  @override
  Widget build(BuildContext context) {
    final viewport = AdminViewportController.instance;
    return ListenableBuilder(
      listenable: viewport ?? Listenable.merge(const []),
      builder: (context, _) {
        if (useAdminWideShell(context)) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Sidebar(
                config: config,
                selected: selected,
                onSelect: onSelect,
                tierLabel: tierLabel,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (header != null) header!,
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) header!,
            Expanded(child: body),
          ],
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.config,
    required this.selected,
    required this.onSelect,
    this.tierLabel,
  });

  final AdminNavConfig config;
  final AdminNavId selected;
  final ValueChanged<AdminNavId> onSelect;
  final String? tierLabel;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final isEn = s.isEnglish;

    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        return Material(
          color: AdminTheme.surface,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: AdminTheme.border),
              ),
            ),
            child: SizedBox(
            width: kAdminShellSidebarWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RealXtate Ops',
                        style: AdminTheme.section.copyWith(
                          color: LivingBkkBrand.purplePrimary,
                          fontSize: 14,
                        ),
                      ),
                      if (tierLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(tierLabel!, style: AdminTheme.caption),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
                        child: Text(
                          s.adminNavPinned,
                          style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      ...config.pinnedItems(s).map(
                            (item) => _NavTile(
                              item: item,
                              selected: selected == item.id,
                              isEn: isEn,
                              onTap: () => _handleNavTap(context, item.id, onSelect),
                            ),
                          ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, indent: 12, endIndent: 12),
                      const SizedBox(height: 4),
                      ...config.visibleGroups.map(
                        (group) => _GroupSection(
                          config: config,
                          group: group,
                          selected: selected,
                          isEn: isEn,
                          onSelect: onSelect,
                          alwaysExpanded: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _AdminSignOutBar(
                  onSignOut: () => performAdminSignOut(context),
                ),
                if (kIsWeb) const _AdminViewportModeBar(),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}

void _handleNavTap(
  BuildContext context,
  AdminNavId id,
  ValueChanged<AdminNavId> onSelect,
) {
  if (kIsWeb) {
    switch (id) {
      case AdminNavId.dashboard:
        context.go('/admin');
        return;
      case AdminNavId.inbox:
        context.go('/admin/console');
        return;
      case AdminNavId.queue:
        context.go('/admin/console?filter=unclaimed');
        return;
      default:
        break;
    }
  }
  onSelect(id);
}

class _GroupSection extends StatefulWidget {
  const _GroupSection({
    required this.config,
    required this.group,
    required this.selected,
    required this.isEn,
    required this.onSelect,
    this.alwaysExpanded = false,
  });

  final AdminNavConfig config;
  final AdminNavGroup group;
  final AdminNavId selected;
  final bool isEn;
  final ValueChanged<AdminNavId> onSelect;
  final bool alwaysExpanded;

  @override
  State<_GroupSection> createState() => _GroupSectionState();
}

class _GroupSectionState extends State<_GroupSection> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.alwaysExpanded ||
        _groupContainsSelection() ||
        (widget.group == AdminNavGroup.vault && widget.config.canSeeVault);
  }

  @override
  void didUpdateWidget(covariant _GroupSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alwaysExpanded) {
      _expanded = true;
    } else if (widget.selected != oldWidget.selected && _groupContainsSelection()) {
      _expanded = true;
    }
  }

  bool _groupContainsSelection() {
    return widget.config
        .navIdsInGroup(widget.group)
        .contains(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final badge = widget.config.badgeForGroup(widget.group);
    final items = widget.config.groupItems(widget.group, s);
    if (items.isEmpty) return const SizedBox.shrink();

    final expanded = widget.alwaysExpanded || _expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.alwaysExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(
              children: [
                Icon(widget.config.groupIcon(widget.group), size: 16, color: AdminTheme.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.config.groupLabel(widget.group, s),
                    style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (badge > 0) _Badge(count: badge, urgent: false),
              ],
            ),
          )
        else
          ListTile(
            dense: true,
            leading: Icon(widget.config.groupIcon(widget.group), size: 20),
            title: Text(
              widget.config.groupLabel(widget.group, s),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badge > 0) _Badge(count: badge, urgent: false),
                Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 20),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        if (expanded)
          ...items.expand(
            (item) => _navTilesForItem(
              context,
              item,
              selected: widget.selected,
              isEn: widget.isEn,
              onSelect: widget.onSelect,
            ),
          ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.isEn,
    required this.onTap,
    this.dense = false,
  });

  final AdminNavItem item;
  final bool selected;
  final bool isEn;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = item.urgent && item.badgeCount > 0
        ? AppTheme.error
        : LivingBkkBrand.purplePrimary;

    final iconSize = dense ? 18.0 : 20.0;
    final leadingIcon = Icon(
      item.icon,
      size: iconSize,
      color: selected ? color : AdminTheme.textMuted,
    );

    return ListTile(
      dense: dense,
      selected: selected,
      selectedTileColor: LivingBkkBrand.purplePrimary.withOpacity(0.08),
      leading: item.badgeCount > 0 &&
              (item.urgent || item.id == AdminNavId.viewingCalendar)
          ? Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: AdminAttentionIconBadge(
                count: item.badgeCount,
                child: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: leadingIcon,
                ),
              ),
            )
          : leadingIcon,
      title: Text(
        item.label(isEn),
        style: TextStyle(
          fontSize: dense ? 12 : 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: item.urgent && item.badgeCount > 0 ? AppTheme.error : null,
        ),
      ),
      trailing: item.badgeCount > 0 &&
              !item.urgent &&
              item.id != AdminNavId.viewingCalendar
          ? _Badge(count: item.badgeCount, urgent: item.urgent)
          : null,
      onTap: onTap,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.urgent});

  final int count;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final display = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (urgent ? AppTheme.error : LivingBkkBrand.purplePrimary)
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        display,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: urgent ? AppTheme.error : LivingBkkBrand.purplePrimary,
        ),
      ),
    );
  }
}

/// Placeholder สำหรับแท็บ Vault / Org ที่ยังไม่ implement
class AdminVaultPlaceholder extends StatelessWidget {
  const AdminVaultPlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: LivingBkkBrand.purplePrimary),
            const SizedBox(height: 16),
            Text(title, style: AdminTheme.title.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: AdminTheme.hint),
          ],
        ),
      ),
    );
  }
}
