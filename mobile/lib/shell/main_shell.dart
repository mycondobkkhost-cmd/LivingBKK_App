import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/board/demand_board_page.dart';
import '../features/contact/contact_tab_page.dart';
import '../features/profile/profile_page.dart';
import '../features/search/map_home_page.dart';
import '../features/search/saved_listings_page.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';
import '../services/in_app_notification_hub.dart';
import '../services/realtime_service.dart';
import '../services/supabase_service.dart';
import '../config/env.dart';
import '../config/post_listing_menu_config.dart';
import '../l10n/app_strings.dart';
import '../state/locale_controller.dart';
import '../state/search_session_controller.dart';
import '../state/theme_controller.dart';
import '../state/user_role_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system/app_bottom_nav.dart';
import '../widgets/trial_mode_banner.dart';
import 'main_shell_scope.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.roleController,
    required this.searchSession,
    required this.localeController,
    required this.themeController,
  });

  final UserRoleController roleController;
  final SearchSessionController searchSession;
  final LocaleController localeController;
  final ThemeController themeController;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _realtime = RealtimeService();
  final _notifHub = InAppNotificationHub.instance;
  StreamSubscription<String>? _notifSub;

  static const _tabContact = 3;
  static const _tabProfile = 4;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    _setupPushNavigation();
    _syncRoleFromServer();
    widget.roleController.addListener(_syncAdminRealtime);
    _notifHub.addListener(_onNotifHubChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onNotifHubChanged());
  }

  void _onNotifHubChanged() {
    if (!mounted) return;
    if (_notifHub.openContactTabOnNextShell) {
      _notifHub.clearPendingNavigation();
      _selectTab(_tabContact);
    }
  }

  void _setupPushNavigation() {
    NotificationService.onNotificationOpen = (type, _) {
      if (!mounted) return;
      switch (type) {
        case 'chat_reply':
          _selectTab(_tabContact);
          break;
        case 'listing_bump':
        case 'listing_archived':
          context.push(PostListingMenuConfig.myListingsRoute);
          break;
      }
    };
  }

  Future<void> _syncRoleFromServer() async {
    final auth = AuthService.instance;
    if (Env.isConfigured &&
        SupabaseService.isReady &&
        auth.isRealSupabaseSession) {
      await NotificationService.instance.registerIfPossible();
    }
    final role = await auth.fetchProfileRole();
    if (!mounted) return;
    widget.roleController.setPlatformAdmin(role == 'admin');
    await _syncAdminRealtime();
  }

  Future<void> _syncAdminRealtime() async {
    if (!mounted) return;
    final uid = SupabaseService.client?.auth.currentUser?.id ?? '';
    await _realtime.subscribeToAdminChatOps(
      enabled: widget.roleController.isPlatformAdmin,
      adminUserId: uid,
    );
    await _realtime.subscribeToAdminLeads(
      enabled: widget.roleController.isPlatformAdmin,
    );
  }

  void _pushInAppNotification(String msg) {
    if (!mounted) return;
    var body = msg;
    String? threadId;
    if (msg.startsWith('chat:')) {
      final rest = msg.substring(5);
      final sep = rest.indexOf(':');
      if (sep > 0) {
        threadId = rest.substring(0, sep);
        body = rest.substring(sep + 1);
      }
    }
    final isChat = body.contains('ข้อความจากทีม') ||
        body.contains('Message from team') ||
        body.contains('แชท');
    if (isChat && threadId != null && threadId.isNotEmpty) {
      ChatService.instance.bumpUnread(threadId);
    }
    _notifHub.show(body, countAsUnread: isChat && threadId == null, threadId: threadId);
  }

  void _setupRealtime() {
    NotificationService.onForegroundMessage = _pushInAppNotification;
    _realtime.subscribeToMyLeads();
    ChatService.instance.ensureCustomerInboxRealtime();
    _notifSub = _realtime.messages.listen((msg) {
      if (!msg.startsWith('chat:')) {
        _pushInAppNotification(msg);
      }
    });
  }

  void _selectTab(int index) {
    if (index == _tabContact) {
      _notifHub.clearUnread();
      ChatService.instance.clearAllUnread();
    }
    setState(() => _index = index);
  }

  @override
  void dispose() {
    NotificationService.onForegroundMessage = null;
    NotificationService.onNotificationOpen = null;
    widget.roleController.removeListener(_syncAdminRealtime);
    _notifHub.removeListener(_onNotifHubChanged);
    _notifSub?.cancel();
    _realtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.roleController,
        widget.localeController,
        widget.themeController,
      ]),
      builder: (context, _) {
        final isAgent = widget.roleController.isAgent;
        final canManageLeads = widget.roleController.canManageLeads;

        final pages = [
          MapHomePage(
            roleController: widget.roleController,
            searchSession: widget.searchSession,
            localeController: widget.localeController,
            onOpenProfile: () => _selectTab(_tabProfile),
          ),
          const SavedListingsPage(),
          const DemandBoardPage(),
          ContactTabPage(isAgent: isAgent, canManageLeads: canManageLeads),
          ProfilePage(
            roleController: widget.roleController,
            localeController: widget.localeController,
            themeController: widget.themeController,
          ),
        ];

        final safeIndex = _index.clamp(0, pages.length - 1);

        final shellBg = context.palette.background;

        return MainShellScope(
          selectTab: _selectTab,
          child: Scaffold(
            backgroundColor: shellBg,
            body: Column(
              children: [
                if (widget.roleController.isPlatformAdmin &&
                    GoRouterState.of(context).uri.queryParameters['preview'] == '1')
                  Material(
                    color: AppTheme.primary,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings(widget.localeController.isEnglish).adminPreviewBanner,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/admin/console'),
                              style: TextButton.styleFrom(foregroundColor: Colors.white),
                              child: Text(
                                AppStrings(widget.localeController.isEnglish).adminBackToConsole,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (safeIndex > 0) const TrialModeBanner(),
                Expanded(
                  child: IndexedStack(index: safeIndex, children: pages),
                ),
              ],
            ),
            bottomNavigationBar: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  _notifHub,
                  ChatService.instance,
                  UserProfileService.instance,
                ]),
                builder: (context, _) {
                  final badge = ChatService.instance.totalUnreadChats > 0
                      ? ChatService.instance.totalUnreadChats
                      : _notifHub.unreadChatCount;
                  return AppBottomNav(
                    index: safeIndex,
                    onChanged: _selectTab,
                    contactBadgeCount: badge,
                    profileAvatarUrl: UserProfileService.instance.avatarUrl,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
