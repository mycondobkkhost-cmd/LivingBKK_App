import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../services/chat_service.dart';
import '../../theme/admin_theme.dart';
import 'admin_command_palette.dart';
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

  String _dateLabel(AppStrings s) {
    final now = DateTime.now();
    final locale = s.isEnglish ? 'en_US' : 'th_TH';
    return DateFormat.yMMMMEEEEd(locale).format(now);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final isMobile = AdminTemplateResponsive.isMobile(context);
    final subtitle = selected == AdminNavId.dashboard
        ? s.adminDashPageSubtitle
        : s.adminEnterpriseOpsTitle;

    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        return Material(
          color: Colors.white,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminTheme.border)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AdminTemplateTheme.defaultPadding,
                vertical: 12,
              ),
              child: Row(
                children: [
                  if (showMenuButton) ...[
                    IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      tooltip: s.adminNavMenu,
                      onPressed: onMenu,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    flex: isMobile ? 2 : 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pageTitle,
                          style: AdminTemplateTheme.pageTitle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AdminTemplateTheme.pageSubtitle(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    Expanded(
                      flex: 2,
                      child: _HeaderSearchField(
                        hint: s.adminCommandPaletteHint,
                        onTap: () => showAdminCommandPalette(
                          context: context,
                          config: config,
                          current: selected,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _DateChip(label: _dateLabel(s)),
                    const SizedBox(width: 8),
                  ] else
                    IconButton(
                      icon: const Icon(Icons.search_rounded, size: 22),
                      tooltip: s.adminCommandPaletteHint,
                      onPressed: () => showAdminCommandPalette(
                        context: context,
                        config: config,
                        current: selected,
                      ),
                    ),
                  const AdminPhoneFrameToggleButton(),
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

class _HeaderSearchField extends StatelessWidget {
  const _HeaderSearchField({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminTemplateTheme.contentBg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: AdminTheme.textFaint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: AdminTheme.textFaint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AdminTemplateTheme.contentBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 14, color: AdminTemplateTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AdminTemplateTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
