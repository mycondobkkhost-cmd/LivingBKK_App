import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/chat_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import 'admin_command_palette.dart';
import 'admin_enterprise_zone.dart';
import 'admin_nav_model.dart';
import 'admin_phone_frame_host.dart';
import 'admin_template_responsive.dart';
import 'admin_template_side_menu.dart';
import 'admin_template_theme.dart';

/// Shell หลังบ้านแบบ Responsive Admin Panel — sidebar มืด + drawer มือถือ
class AdminTemplateShell extends StatefulWidget {
  const AdminTemplateShell({
    super.key,
    required this.config,
    required this.selected,
    required this.onSelect,
    required this.body,
    required this.actions,
    this.banners = const [],
    this.tierLabel,
    this.pageTitle,
    this.contentBackgroundColor = AdminTemplateTheme.contentBg,
  });

  final AdminNavConfig config;
  final AdminNavId selected;
  final ValueChanged<AdminNavId> onSelect;
  final Widget body;
  final List<Widget> actions;
  final List<Widget> banners;
  final String? tierLabel;
  final String? pageTitle;
  final Color contentBackgroundColor;

  @override
  State<AdminTemplateShell> createState() => _AdminTemplateShellState();
}

class _AdminTemplateShellState extends State<AdminTemplateShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _closeDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminTemplateResponsive.isDesktop(context);
    final s = context.s;
    final title =
        widget.pageTitle ?? widget.config.labelForNav(widget.selected, s);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminTemplateTheme.sidebarBg,
      drawer: isDesktop
          ? null
          : Drawer(
              width: AdminTemplateTheme.sidebarWidth,
              backgroundColor: AdminTemplateTheme.sidebarBg,
              child: AdminTemplateSideMenu(
                config: widget.config,
                selected: widget.selected,
                onSelect: widget.onSelect,
                tierLabel: widget.tierLabel,
                onItemTap: _closeDrawer,
              ),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              SizedBox(
                width: AdminTemplateTheme.sidebarWidth,
                child: AdminTemplateSideMenu(
                  config: widget.config,
                  selected: widget.selected,
                  onSelect: widget.onSelect,
                  tierLabel: widget.tierLabel,
                ),
              ),
            Expanded(
              child: ColoredBox(
                color: widget.contentBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TemplateHeader(
                      config: widget.config,
                      selected: widget.selected,
                      pageTitle: title,
                      actions: widget.actions,
                      showMenuButton: !isDesktop,
                      onMenu: _openDrawer,
                    ),
                    ...widget.banners,
                    Expanded(child: widget.body),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateHeader extends StatelessWidget {
  const _TemplateHeader({
    required this.config,
    required this.selected,
    required this.pageTitle,
    required this.actions,
    required this.showMenuButton,
    required this.onMenu,
  });

  final AdminNavConfig config;
  final AdminNavId selected;
  final String pageTitle;
  final List<Widget> actions;
  final bool showMenuButton;
  final VoidCallback onMenu;

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
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AdminTemplateTheme.defaultPadding,
                vertical: 10,
              ),
              child: Row(
                children: [
                  if (showMenuButton) ...[
                    IconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: s.adminNavMenu,
                      onPressed: onMenu,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.adminEnterpriseOpsTitle,
                          style: AdminTemplateTheme.pageSubtitle(),
                        ),
                        Text(
                          pageTitle,
                          style: AdminTemplateTheme.pageTitle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!AdminTemplateResponsive.isMobile(context))
                    ...kpis.take(3).map(
                          (k) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _KpiChip(kpi: k),
                          ),
                        ),
                  const AdminPhoneFrameToggleButton(),
                  IconButton(
                    icon: const Icon(Icons.search, size: 22),
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
    final color = kpi.alert ? AppTheme.error : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kpi.alert
            ? AppTheme.error.withOpacity(0.08)
            : AdminTemplateTheme.secondaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: kpi.alert
              ? AppTheme.error.withOpacity(0.25)
              : AdminTheme.border,
        ),
      ),
      child: Text(
        '${kpi.label} ${kpi.value}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
