import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../l10n/app_strings.dart';
import '../../models/admin_dashboard_overview.dart';
import '../../models/app_perspective.dart';
import '../../services/admin_repository.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/in_app_notification_hub.dart';
import '../../services/realtime_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/admin_listing_nav.dart';
import '../../state/session_gate.dart';
import '../../state/user_role_controller.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_dashboard_bar.dart';
import '../../widgets/admin_mobile_layout.dart';
import 'admin_appointments_tab.dart';
import 'admin_chats_tab.dart';
import 'admin_create_demand_page.dart';
import 'admin_dashboard_tab.dart';
import 'admin_import_tab.dart';
import 'admin_moderation_tab.dart';
import 'admin_inventory_tab.dart';
import 'admin_projects_tab.dart';
import 'admin_promos_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_watermark_tab.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  final _admin = AdminRepository();
  late final TabController _tabs;
  bool _allowed = false;
  bool _loading = true;
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _leads = [];
  Map<String, dynamic>? _stats;
  AdminDashboardOverview _overview = const AdminDashboardOverview();
  Timer? _refreshTimer;
  final _realtime = RealtimeService();
  final _notifHub = InAppNotificationHub.instance;
  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 13, vsync: this);
    _init();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
    final uid = SupabaseService.client?.auth.currentUser?.id ?? '';
    _realtime.subscribeToAdminChatOps(enabled: true, adminUserId: uid);
    _realtime.subscribeToAdminLeads(enabled: true);
    _notifSub = _realtime.messages.listen((msg) {
      _notifHub.show(msg, countAsUnread: false);
      ChatService.instance.refreshAdminInbox();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notifSub?.cancel();
    _realtime.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final ok = await _admin.isAdmin();
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _allowed = false;
          _loading = false;
        });
        return;
      }
      await _refresh();
      if (!mounted) return;
      setState(() {
        _allowed = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allowed = true;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      await ChatService.instance.refreshAdminInbox();
      final offers = await _admin.allDemandOffers();
      final leads = await _admin.recentLeads();
      final stats = await _admin.leadStats();
      final overview = await _admin.fetchDashboardOverview();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _leads = leads;
        _stats = stats;
        _overview = overview;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _offers = [];
        _leads = [];
        _stats = null;
      });
    }
  }

  void _jumpTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    _tabs.animateTo(index);
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    widget.roleController.setPerspective(AppPerspective.customer);
    widget.roleController.setPlatformAdmin(false);
    await SessionGate.instance?.resetToWelcome();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _openLead(String id) async {
    final changed = await context.push<bool>('/admin/lead/$id');
    if (changed == true) _refresh();
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
        appBar: AdminMobileLayout.appBar(
          context: context,
          title: Text(s.adminTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              s.adminNeedRole,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final compact = AdminMobileLayout.isCompact(context);
    final shell = AdminTheme.shellTheme(Theme.of(context));
    return Theme(
      data: shell,
      child: AdminMobileLayout.scaffold(
        context: context,
        backgroundColor: AdminTheme.bg,
        safeBottom: false,
        appBar: AdminMobileLayout.appBar(
          context: context,
          title: Text(
            s.adminLivingBkk,
            style: AdminTheme.title.copyWith(fontSize: compact ? 16 : 17),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(compact ? 42 : 48),
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: [
                  Tab(text: s.adminTabDashboard),
                  Tab(text: s.adminTabChat),
                  Tab(text: s.adminTabOffers),
                  Tab(text: s.adminTabLeads),
                  Tab(text: s.adminTabAppointments),
                  Tab(text: s.adminTabReports),
                  Tab(text: s.adminTabModeration),
                  Tab(text: s.adminTabInventory),
                  Tab(text: s.adminTabCreateBoard),
                  Tab(text: s.adminTabImport),
                  Tab(text: s.adminTabProjects),
                  Tab(text: s.adminTabPromos),
                  Tab(text: s.adminTabWatermark),
              ],
            ),
          ),
          actions: compact
              ? [
                    PopupMenuButton<String>(
                      tooltip: s.adminMoreActions,
                      onSelected: (value) {
                        switch (value) {
                          case 'consumer':
                            context.go('/?preview=1');
                          case 'console':
                            if (kIsWeb) context.go('/admin/console');
                          case 'refresh':
                            _refresh();
                          case 'logout':
                            _signOut();
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'consumer',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.storefront_outlined, size: 20),
                            title: Text(s.adminViewConsumerApp),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (kIsWeb)
                          PopupMenuItem(
                            value: 'console',
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.desktop_windows_outlined, size: 20),
                              title: Text(s.adminOpenConsole),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        PopupMenuItem(
                          value: 'refresh',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.refresh, size: 20),
                            title: Text(s.adminRefresh),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.logout, size: 20),
                            title: Text(s.signOut),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.storefront_outlined),
                      tooltip: s.adminViewConsumerApp,
                      onPressed: () => context.go('/?preview=1'),
                    ),
                    if (kIsWeb)
                      IconButton(
                        icon: const Icon(Icons.desktop_windows_outlined),
                        tooltip: s.adminOpenConsole,
                        onPressed: () => context.go('/admin/console'),
                      ),
                    IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: s.signOut,
                      onPressed: _signOut,
                    ),
                  ],
        ),
        body: Column(
            children: [
              if (Env.trialMode)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    border: Border(bottom: BorderSide(color: AdminTheme.border)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: compact ? 8 : 10,
                  ),
                  child: Text(
                    Env.isConfigured ? s.adminTrialBannerConfigured : s.demoData,
                    style: AdminTheme.hint.copyWith(color: const Color(0xFF9A3412)),
                  ),
                ),
              AdminDashboardBar(
                data: _overview,
                onJump: _jumpTab,
                compact: compact,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    AdminMobileLayout.tabBody(
                      context,
                      child: AdminDashboardTab(onOpenTab: _jumpTab),
                    ),
                    AdminMobileLayout.tabBody(
                      context,
                      child: const AdminChatsTab(),
                    ),
                    AdminMobileLayout.tabBody(context, child: _offersTab(s)),
                    AdminMobileLayout.tabBody(context, child: _leadsTab(s)),
                    AdminMobileLayout.tabBody(
                      context,
                      child: const AdminAppointmentsTab(),
                    ),
                    AdminMobileLayout.tabBody(
                      context,
                      child: const AdminReportsTab(),
                    ),
                    AdminMobileLayout.tabBody(
                      context,
                      child: const AdminModerationTab(),
                    ),
                    AdminMobileLayout.tabBody(
                      context,
                      child: const AdminInventoryTab(),
                    ),
                    AdminMobileLayout.tabBody(
                      context,
                      child: AdminCreateDemandPage(onCreated: _refresh),
                    ),
                    AdminMobileLayout.tabBody(
                      context,
                      child: const AdminImportTab(),
                    ),
                    AdminMobileLayout.tabBody(
                      context,
                      child: const AdminProjectsTab(),
                    ),
                    AdminMobileLayout.tabBody(
                      context,
                      child: const AdminPromosTab(),
                    ),
                    AdminMobileLayout.tabBody(
                      context,
                      child: const AdminWatermarkTab(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _offersTab(AppStrings s) {
    if (_offers.isEmpty) {
      return Center(child: Text(s.adminNoOffers));
    }
    return ListView.builder(
      padding: AdminMobileLayout.scrollPadding(context, top: 8, horizontal: 12, fabClearance: 16),
      itemCount: _offers.length,
      itemBuilder: (context, i) {
        final o = _offers[i];
        final post = o['demand_posts'] as Map<String, dynamic>?;
        return Card(
          child: ExpansionTile(
            title: Text(post?['title']?.toString() ?? s.adminDemandPostFallback),
            subtitle: Text(
              '${s.offererCapacityLabel(o['offerer_capacity']?.toString() ?? '')} · ${o['status']} · ${s.adminOfferVerifyLabel}: ${o['capacity_verified']}',
            ),
            children: [
              if (o['external_url'] != null)
                ListTile(
                  title: Text(s.adminLink),
                  subtitle: Text(o['external_url'].toString()),
                ),
              if (o['description'] != null)
                ListTile(
                  title: Text(s.adminDetails),
                  subtitle: Text(o['description'].toString()),
                ),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      await _admin.verifyOfferCapacity(o['id'] as String, approved: true);
                      _refresh();
                    },
                    child: Text(s.adminConfirmRole),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _admin.verifyOfferCapacity(o['id'] as String, approved: false);
                      _refresh();
                    },
                    child: Text(s.adminReject, style: TextStyle(color: AppTheme.error)),
                  ),
                  if (o['offer_type']?.toString() == 'in_app')
                    TextButton(
                      onPressed: () async {
                        try {
                          final res = await _admin.promoteDemandOffer(
                            o['id'] as String,
                          );
                          if (!mounted) return;
                          final code = res?['listing']?['listing_code'];
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                code != null
                                    ? '${s.adminPromoteOfferToListing}: $code'
                                    : s.adminPromoteOfferToListing,
                              ),
                            ),
                          );
                          _refresh();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      },
                      child: Text(s.adminPromoteOfferToListing),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _leadsTab(AppStrings s) {
    return ListView(
      padding: AdminMobileLayout.scrollPadding(context, top: 8, horizontal: 12, fabClearance: 16),
      children: [
        if (_stats != null)
          Card(
            child: ListTile(
              title: Text(s.adminStatsMakecom),
              subtitle: Text(
                s.adminLeadStatsLine(
                  (_stats!['lead_count'] as num?)?.toInt() ?? 0,
                  (_stats!['accepted_count'] as num?)?.toInt() ?? 0,
                ),
              ),
            ),
          ),
        if (_leads.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(s.adminNoLeads),
          )
        else
          ..._leads.map(
            (l) {
              final code = l['listing_code']?.toString() ?? '—';
              final listingId = l['listing_id']?.toString();
              return Card(
                child: ListTile(
                  leading: Icon(Icons.support_agent, color: AppTheme.primary),
                  title: InkWell(
                    onTap: code != '—'
                        ? () => openAdminListing(
                              context,
                              listingId: listingId,
                              listingCode: code,
                            )
                        : null,
                    child: Text(
                      code,
                      style: TextStyle(
                        color: code != '—' ? AppTheme.primary : null,
                        decoration:
                            code != '—' ? TextDecoration.underline : null,
                        decorationColor: AppTheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  subtitle: Text(
                    '${l['seeker_nickname']} · ${l['status']}'
                    '${_viewingHint(l, s)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openLead(l['id'] as String),
                ),
              );
            },
          ),
      ],
    );
  }

  String _viewingHint(Map<String, dynamic> l, AppStrings s) {
    final q = l['qualification_json'] as Map<String, dynamic>?;
    final v = q?['viewing_schedule'];
    if (v == null) return '';
    return '\n${s.adminViewingPrefix(v.toString())}';
  }
}
