import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_dashboard_overview.dart';
import '../../services/admin_repository.dart';
import '../../services/chat_service.dart';
import '../../services/demo_cast_bootstrap.dart';
import '../../services/in_app_notification_hub.dart';
import '../../services/realtime_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/admin_theme.dart';
import '../../utils/admin_desktop.dart';
import '../../utils/admin_routing.dart';
import '../../widgets/admin_mobile_layout.dart';
import 'admin_nav_model.dart';
import 'admin_ops_workspace.dart';
import 'admin_phone_frame_host.dart';
import 'admin_shell_scaffold.dart';

/// โหมดแอดมินบนคอม — inbox + แชทในจอเดียว (Web)
class AdminConsolePage extends StatefulWidget {
  const AdminConsolePage({
    super.key,
    this.initialRoomId,
    this.initialMessageId,
    this.focusQueue = false,
    this.initialReturnNav,
  });

  final String? initialRoomId;
  final String? initialMessageId;
  final bool focusQueue;
  final AdminNavId? initialReturnNav;

  @override
  State<AdminConsolePage> createState() => _AdminConsolePageState();
}

class _AdminConsolePageState extends State<AdminConsolePage> {
  final _admin = AdminRepository();
  bool _allowed = false;
  bool _loading = true;
  String _adminTier = 'admin';
  String? _selectedRoomId;
  String? _highlightMessageId;
  AdminNavId? _returnNav;
  Timer? _refreshTimer;
  AdminDashboardOverview _overview = const AdminDashboardOverview();
  final _notifHub = InAppNotificationHub.instance;
  final _realtime = RealtimeService();
  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.initialRoomId;
    _highlightMessageId = widget.initialMessageId;
    _returnNav = widget.initialReturnNav;
    if (widget.initialRoomId != null) {
      final roomId = widget.initialRoomId!;
      ChatService.instance.markAdminThreadRead(roomId);
      if (roomId.startsWith('demo-lead-chat-')) {
        ChatService.instance.ensureViewingLeadChat(roomId);
      }
    }
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

  AdminNavConfig get _navConfig =>
      AdminNavConfig(tier: _adminTier, overview: _overview);

  void _selectNav(AdminNavId id) {
    switch (id) {
      case AdminNavId.dashboard:
        context.go('/admin');
        return;
      case AdminNavId.inbox:
        _clearRoom();
        context.go('/admin/console');
        return;
      case AdminNavId.queue:
        _clearRoom();
        context.go('/admin/console?filter=unclaimed');
        return;
      default:
        context.go('/admin?nav=${id.name}');
    }
  }

  @override
  void didUpdateWidget(covariant AdminConsolePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRoomId != widget.initialRoomId ||
        oldWidget.initialMessageId != widget.initialMessageId ||
        oldWidget.initialReturnNav != widget.initialReturnNav) {
      setState(() {
        _selectedRoomId = widget.initialRoomId;
        _highlightMessageId = widget.initialMessageId;
        _returnNav = widget.initialReturnNav;
      });
      final roomId = widget.initialRoomId;
      if (roomId != null) {
        ChatService.instance.markAdminThreadRead(roomId);
        if (roomId.startsWith('demo-lead-chat-')) {
          ChatService.instance.ensureViewingLeadChat(roomId);
        }
      }
    }
  }

  Future<void> _init() async {
    try {
      await DemoCastBootstrap.ensureReady();
      final ok = await _admin.isAdmin();
      final tier = await _admin.fetchAdminTier();
      if (!mounted) return;
      setState(() {
        _allowed = ok;
        _loading = false;
        _adminTier = tier;
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

  void _selectRoom(String roomId, {String? messageId}) {
    ChatService.instance.markAdminThreadRead(roomId);
    setState(() {
      _selectedRoomId = roomId;
      _highlightMessageId = messageId;
    });
    if (kIsWeb) {
      context.go(
        adminConsoleChatPath(
          roomId: roomId,
          messageId: messageId,
          returnNav: _returnNav,
        ),
      );
    }
  }

  void _exitChatView() {
    final returnNav = _returnNav;
    if (returnNav != null &&
        returnNav != AdminNavId.inbox &&
        returnNav != AdminNavId.queue) {
      if (context.canPop()) {
        context.pop();
        return;
      }
      context.go(adminReturnPath(returnNav));
      return;
    }
    context.go(
      widget.focusQueue ? '/admin/console?filter=unclaimed' : '/admin/console',
    );
  }

  void _clearRoom() {
    setState(() {
      _selectedRoomId = null;
      _highlightMessageId = null;
    });
    if (kIsWeb) {
      _exitChatView();
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

    final consoleActions = [
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: s.refresh,
        onPressed: () async => _refreshInbox(),
      ),
    ];

    final navSelected =
        widget.focusQueue ? AdminNavId.queue : AdminNavId.inbox;

    return AdminPhoneFrameHost(
      child: PopScope(
      canPop: _selectedRoomId == null,
      onPopInvoked: (didPop) {
        if (!didPop && _selectedRoomId != null) _clearRoom();
      },
      child: Theme(
      data: AdminTheme.shellTheme(),
      child: AdminTheme.lightPaletteScope(
      child: Builder(
        builder: (context) {
          final navConfig = _navConfig;

          final opsWorkspace = AdminOpsWorkspace(
            navConfig: navConfig,
            selectedNav: navSelected,
            onSelectNav: _selectNav,
            focusQueue: widget.focusQueue,
            showNavRail: false,
            selectedRoomId: _selectedRoomId,
            highlightMessageId: _highlightMessageId,
            onRoomSelected: (id) => _selectRoom(id),
            onSearchPick: (id, {messageId}) =>
                _selectRoom(id, messageId: messageId),
            onClearRoom: _clearRoom,
            onHighlightConsumed: () {
              if (mounted) setState(() => _highlightMessageId = null);
            },
            onResolved: () async {
              await _refreshInbox();
            },
            onRefresh: _refreshInbox,
            backTooltip: adminChatBackTooltip(_returnNav, s),
            returnNav: _returnNav,
          );

          final isolatedBanner = DemoCastBootstrap.isolatedAdminTrial
              ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    border: Border(bottom: BorderSide(color: AdminTheme.border)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    s.adminUnifiedTrialBanner,
                    style: AdminTheme.hint.copyWith(color: const Color(0xFF1D4ED8)),
                  ),
                )
              : null;

          final shellBody = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isolatedBanner != null) isolatedBanner,
              Expanded(child: opsWorkspace),
            ],
          );

          return AdminMobileLayout.scaffold(
            context: context,
            body: AdminShellScaffold(
              config: navConfig,
              selected: navSelected,
              onSelect: _selectNav,
              tierLabel: s.adminNavTierLabel(_adminTier),
              pageTitle: s.adminOpsWorkspaceTitle,
              actions: consoleActions,
              hideSubnav: true,
              contentBackgroundColor: const Color(0xFFF8FAFC),
              body: shellBody,
            ),
          );
        },
      ),
    ),
    ),
    ),
    );
  }
}


