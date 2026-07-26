import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/chat_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/admin_desktop.dart';
import '../../utils/admin_routing.dart';
import '../../utils/admin_sign_out.dart';
import 'admin_chat_panel.dart';
import 'admin_shell_scaffold.dart';
import 'admin_chats_tab.dart';
import 'admin_console_context_panel.dart';
import 'admin_nav_model.dart';

const kAdminOpsNavRailWidth = 56.0;
const kAdminOpsInboxWidth = 340.0;

/// เวิร์กสเปซหลังบ้านใหม่ — แถบบน + inbox | แชท | รายละเอียดเคส
class AdminOpsWorkspace extends StatelessWidget {
  const AdminOpsWorkspace({
    super.key,
    required this.navConfig,
    required this.selectedNav,
    required this.onSelectNav,
    required this.focusQueue,
    required this.selectedRoomId,
    required this.highlightMessageId,
    required this.onRoomSelected,
    required this.onSearchPick,
    required this.onClearRoom,
    required this.onHighlightConsumed,
    required this.onResolved,
    required this.onRefresh,
    required this.backTooltip,
    this.returnNav,
    this.showNavRail = true,
  });

  final AdminNavConfig navConfig;
  final AdminNavId selectedNav;
  final ValueChanged<AdminNavId> onSelectNav;
  final bool focusQueue;
  final String? selectedRoomId;
  final String? highlightMessageId;
  final ValueChanged<String> onRoomSelected;
  final void Function(String roomId, {String? messageId}) onSearchPick;
  final VoidCallback onClearRoom;
  final VoidCallback onHighlightConsumed;
  final Future<void> Function() onResolved;
  final Future<void> Function() onRefresh;
  final String? backTooltip;
  final AdminNavId? returnNav;
  final bool showNavRail;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final splitWide = useAdminSplitPane(context);
    final showContext = useAdminContextPane(context) && selectedRoomId != null;

    if (!splitWide) {
      return _MobileOpsBody(
        focusQueue: focusQueue,
        selectedRoomId: selectedRoomId,
        highlightMessageId: highlightMessageId,
        onRoomSelected: onRoomSelected,
        onSearchPick: onSearchPick,
        onClearRoom: onClearRoom,
        onHighlightConsumed: onHighlightConsumed,
        onResolved: onResolved,
        backTooltip: backTooltip,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showNavRail)
          AdminOpsNavRail(
            config: navConfig,
            selected: selectedNav,
            onSelect: onSelectNav,
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminOpsTopBar(
                config: navConfig,
                focusQueue: focusQueue,
                onRefresh: onRefresh,
                onOpenSearch: () => _openInboxSearch(context),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: kAdminOpsInboxWidth,
                      child: AdminChatsTab(
                        compact: true,
                        opsLayout: true,
                        embedded: true,
                        focusQueue: focusQueue,
                        selectedRoomId: selectedRoomId,
                        onRoomSelected: onRoomSelected,
                        onSearchPick: onSearchPick,
                      ),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      child: selectedRoomId == null
                          ? _OpsEmptyChat(text: s.adminConsolePickChat)
                          : AdminChatPanel(
                              key: ValueKey(
                                '$selectedRoomId-${highlightMessageId ?? ''}',
                              ),
                              roomId: selectedRoomId!,
                              embedded: true,
                              opsLayout: true,
                              highlightMessageId: highlightMessageId,
                              onBack: showContext ? null : onClearRoom,
                              backTooltip: backTooltip,
                              onHighlightConsumed: onHighlightConsumed,
                              onResolved: onResolved,
                            ),
                    ),
                    if (showContext) ...[
                      const VerticalDivider(width: 1, thickness: 1),
                      SizedBox(
                        width: kAdminContextPaneWidth,
                        child: AdminConsoleContextPanel(
                          key: ValueKey('ctx-$selectedRoomId'),
                          roomId: selectedRoomId!,
                          onResolved: () => onResolved(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openInboxSearch(BuildContext context) async {
    // ค้นหาเปิดจาก inbox panel โดยตรง — top bar ใช้ปุ่ม refresh เป็นหลัก
  }
}

class _MobileOpsBody extends StatelessWidget {
  const _MobileOpsBody({
    required this.focusQueue,
    required this.selectedRoomId,
    required this.highlightMessageId,
    required this.onRoomSelected,
    required this.onSearchPick,
    required this.onClearRoom,
    required this.onHighlightConsumed,
    required this.onResolved,
    required this.backTooltip,
  });

  final bool focusQueue;
  final String? selectedRoomId;
  final String? highlightMessageId;
  final ValueChanged<String> onRoomSelected;
  final void Function(String roomId, {String? messageId}) onSearchPick;
  final VoidCallback onClearRoom;
  final VoidCallback onHighlightConsumed;
  final Future<void> Function() onResolved;
  final String? backTooltip;

  @override
  Widget build(BuildContext context) {
    if (selectedRoomId != null) {
      return AdminChatPanel(
        key: ValueKey('$selectedRoomId-${highlightMessageId ?? ''}'),
        roomId: selectedRoomId!,
        embedded: true,
        opsLayout: true,
        highlightMessageId: highlightMessageId,
        onBack: onClearRoom,
        backTooltip: backTooltip,
        onHighlightConsumed: onHighlightConsumed,
        onResolved: onResolved,
      );
    }
    return AdminChatsTab(
      compact: true,
      opsLayout: true,
      embedded: true,
      focusQueue: focusQueue,
      onRoomSelected: onRoomSelected,
      onSearchPick: onSearchPick,
    );
  }
}

/// แถบนำทางแคบซ้าย — เข้าหน้าหลักได้เร็ว
class AdminOpsNavRail extends StatelessWidget {
  const AdminOpsNavRail({
    super.key,
    required this.config,
    required this.selected,
    required this.onSelect,
  });

  final AdminNavConfig config;
  final AdminNavId selected;
  final ValueChanged<AdminNavId> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        final queue = config.queueUnclaimedCount;
        final mine = config.inboxMineCount;
        return Material(
          color: const Color(0xFF1E1B4B),
          child: SizedBox(
            width: kAdminOpsNavRailWidth,
            child: Column(
              children: [
                const SizedBox(height: 12),
                _RailLogo(),
                const SizedBox(height: 16),
                _RailBtn(
                  icon: Icons.inbox_outlined,
                  selected: selected == AdminNavId.inbox,
                  badge: mine,
                  tooltip: s.adminTabChat,
                  onTap: () => onSelect(AdminNavId.inbox),
                ),
                _RailBtn(
                  icon: Icons.notification_important_outlined,
                  selected: selected == AdminNavId.queue,
                  badge: queue,
                  urgent: queue > 0,
                  tooltip: s.adminNavQueueTitle,
                  onTap: () => onSelect(AdminNavId.queue),
                ),
                _RailBtn(
                  icon: Icons.dashboard_outlined,
                  selected: selected == AdminNavId.dashboard,
                  tooltip: s.adminTabDashboard,
                  onTap: () => onSelect(AdminNavId.dashboard),
                ),
                _RailBtn(
                  icon: Icons.calendar_month_outlined,
                  selected: selected == AdminNavId.viewingCalendar,
                  tooltip: s.adminNavViewingCalendar,
                  onTap: () => onSelect(AdminNavId.viewingCalendar),
                ),
                const Spacer(),
                _RailBtn(
                  icon: Icons.menu,
                  tooltip: s.adminNavMenu,
                  onTap: () => showAdminNavMenu(
                    context: context,
                    config: config,
                    selected: selected,
                    onSelect: onSelect,
                  ),
                ),
                _RailBtn(
                  icon: Icons.storefront_outlined,
                  tooltip: s.adminViewConsumerApp,
                  onTap: () => goConsumerApp(context),
                ),
                _RailBtn(
                  icon: Icons.logout,
                  tooltip: s.signOut,
                  onTap: () => performAdminSignOut(context),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RailLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LivingBkkBrand.purplePrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'RX',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _RailBtn extends StatelessWidget {
  const _RailBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
    this.badge = 0,
    this.urgent = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool selected;
  final int badge;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Colors.white.withOpacity(0.14)
        : Colors.transparent;
    final fg = selected ? Colors.white : Colors.white.withOpacity(0.72);

    Widget iconWidget = Icon(icon, size: 22, color: fg);

    if (badge > 0) {
      iconWidget = Badge(
        backgroundColor: urgent ? AppTheme.error : LivingBkkBrand.purplePrimary,
        label: Text(
          badge > 9 ? '9+' : '$badge',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
        ),
        child: iconWidget,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(child: iconWidget),
            ),
          ),
        ),
      ),
    );
  }
}

/// แถบบน — สรุปคิว + เครื่องมือ
class AdminOpsTopBar extends StatelessWidget {
  const AdminOpsTopBar({
    super.key,
    required this.config,
    required this.focusQueue,
    required this.onRefresh,
    this.onOpenSearch,
  });

  final AdminNavConfig config;
  final bool focusQueue;
  final Future<void> Function() onRefresh;
  final VoidCallback? onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        final queue = config.queueUnclaimedCount;
        final mine = config.inboxMineCount;
        return Material(
          color: AdminTheme.surface,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminTheme.border)),
            ),
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      s.adminOpsWorkspaceTitle,
                      style: AdminTheme.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(width: 16),
                    _KpiPill(
                      label: s.adminInboxTabUnclaimed(queue),
                      color: queue > 0
                          ? AppTheme.error
                          : AdminTheme.textFaint,
                      filled: focusQueue,
                    ),
                    const SizedBox(width: 8),
                    _KpiPill(
                      label: s.adminInboxTabMine(mine),
                      color: AppTheme.primary,
                      filled: !focusQueue && mine > 0,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: s.refresh,
                      onPressed: () => onRefresh(),
                    ),
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

class _KpiPill extends StatelessWidget {
  const _KpiPill({
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.12) : AdminTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled ? color.withOpacity(0.4) : AdminTheme.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? color : AdminTheme.textMuted,
        ),
      ),
    );
  }
}

class _OpsEmptyChat extends StatelessWidget {
  const _OpsEmptyChat({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: LivingBkkBrand.purplePrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 36,
                color: LivingBkkBrand.purplePrimary.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AdminTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
