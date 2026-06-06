import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_dashboard_overview.dart';
import '../../services/admin_repository.dart';
import '../../services/chat_service.dart';
import '../../services/in_app_notification_hub.dart';
import '../../services/realtime_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_desktop.dart';
import '../../widgets/admin_dashboard_bar.dart';
import '../../widgets/admin_mobile_layout.dart';
import '../../widgets/admin_recent_leads_strip.dart';
import 'admin_chat_panel.dart';
import 'admin_chats_tab.dart';

/// โหมดแอดมินบนคอม — inbox + แชทในจอเดียว (Web)
class AdminConsolePage extends StatefulWidget {
  const AdminConsolePage({super.key, this.initialRoomId});

  final String? initialRoomId;

  @override
  State<AdminConsolePage> createState() => _AdminConsolePageState();
}

class _AdminConsolePageState extends State<AdminConsolePage> {
  final _admin = AdminRepository();
  bool _allowed = false;
  bool _loading = true;
  String? _selectedRoomId;
  Timer? _refreshTimer;
  AdminDashboardOverview _overview = const AdminDashboardOverview();
  final _notifHub = InAppNotificationHub.instance;
  final _realtime = RealtimeService();
  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.initialRoomId;
    _init();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshInbox());
    final uid = SupabaseService.client?.auth.currentUser?.id ?? '';
    _realtime.subscribeToAdminChatOps(enabled: true, adminUserId: uid);
    _notifSub = _realtime.messages.listen((msg) {
      _notifHub.show(msg, countAsUnread: false);
      _refreshInbox();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notifSub?.cancel();
    _realtime.dispose();
    super.dispose();
  }

  Future<void> _refreshInbox() async {
    await ChatService.instance.refreshAdminInbox();
    try {
      final overview = await _admin.fetchDashboardOverview();
      if (mounted) {
        setState(() => _overview = overview);
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  void _jumpFromKpi(int tabIndex) {
    if (tabIndex == 1) {
      _clearRoom();
      return;
    }
    context.go('/admin');
  }

  @override
  void didUpdateWidget(covariant AdminConsolePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRoomId != widget.initialRoomId) {
      setState(() => _selectedRoomId = widget.initialRoomId);
    }
  }

  Future<void> _init() async {
    try {
      final ok = await _admin.isAdmin();
      if (!mounted) return;
      setState(() {
        _allowed = ok;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allowed = true;
        _loading = false;
      });
    }
    await _refreshInbox();
  }

  void _selectRoom(String roomId) {
    setState(() => _selectedRoomId = roomId);
    if (kIsWeb) {
      context.go('/admin/console?room=$roomId');
    }
  }

  void _clearRoom() {
    setState(() => _selectedRoomId = null);
    if (kIsWeb) {
      context.go('/admin/console');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (_loading) {
      return AdminMobileLayout.scaffold(
        context: context,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_allowed) {
      return AdminMobileLayout.scaffold(
        context: context,
        appBar: AppBar(title: Text(s.adminConsoleTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(s.adminNeedRole, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Theme(
      data: AdminTheme.shellTheme(Theme.of(context)),
      child: AdminMobileLayout.scaffold(
      context: context,
      safeBottom: false,
      appBar: AdminMobileLayout.appBar(
        context: context,
        title: Text(s.adminConsoleTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: s.adminViewConsumerApp,
            onPressed: () => context.go('/?preview=1'),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: s.adminImportTitle,
            onPressed: () => context.push('/admin/import'),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: s.adminFaqSettings,
            onPressed: () => context.push('/admin/faq'),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: s.adminTitle,
            onPressed: () => context.go('/admin'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: s.refresh,
            onPressed: () async {
              await _refreshInbox();
            },
          ),
        ],
      ),
      body: AdminMobileLayout.tabBody(
        context,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminDashboardBar(
            data: _overview,
            compact: true,
            onJump: _jumpFromKpi,
          ),
          AdminRecentLeadsStrip(onChanged: _refreshInbox),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= kAdminDesktopMinWidth;
                final selected = _selectedRoomId;

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: kAdminInboxPaneWidth,
                        child: AdminChatsTab(
                          compact: true,
                          embedded: true,
                          selectedRoomId: selected,
                          onRoomSelected: _selectRoom,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: selected == null
                            ? _EmptyChatPane(text: s.adminConsolePickChat)
                            : AdminChatPanel(
                                key: ValueKey(selected),
                                roomId: selected,
                                embedded: true,
                                onResolved: () async {
                                  await _refreshInbox();
                                },
                              ),
                      ),
                    ],
                  );
                }

                if (selected != null) {
                  return AdminChatPanel(
                    key: ValueKey(selected),
                    roomId: selected,
                    embedded: true,
                    onBack: _clearRoom,
                    onResolved: () async {
                      await _refreshInbox();
                      if (mounted) _clearRoom();
                    },
                  );
                }

                return AdminChatsTab(
                  compact: true,
                  embedded: true,
                  onRoomSelected: _selectRoom,
                );
              },
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}

class _EmptyChatPane extends StatelessWidget {
  const _EmptyChatPane({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AdminTheme.surfaceMuted,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 56, color: AppTheme.primary.withOpacity(0.45)),
              const SizedBox(height: 16),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: AdminTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
