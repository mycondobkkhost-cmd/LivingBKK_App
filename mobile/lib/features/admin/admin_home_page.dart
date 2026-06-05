import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../l10n/app_strings.dart';
import '../../models/admin_dashboard_overview.dart';
import '../../services/admin_repository.dart';
import '../../services/auth_service.dart';
import '../../state/session_gate.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../widgets/admin_dashboard_bar.dart';
import 'admin_appointments_tab.dart';
import 'admin_chats_tab.dart';
import 'admin_create_demand_page.dart';
import 'admin_dashboard_tab.dart';
import 'admin_import_tab.dart';
import 'admin_moderation_tab.dart';
import 'admin_inventory_tab.dart';
import 'admin_projects_tab.dart';
import 'admin_reports_tab.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with SingleTickerProviderStateMixin {
  final _admin = AdminRepository();
  late final TabController _tabs;
  bool _allowed = false;
  bool _loading = true;
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _leads = [];
  Map<String, dynamic>? _stats;
  AdminDashboardOverview _overview = const AdminDashboardOverview();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 11, vsync: this);
    _init();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_allowed) {
      return Scaffold(
        appBar: AppBar(title: Text(s.adminTitle)),
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

    return Scaffold(
      backgroundColor: LivingBkkBrand.adminBg,
      appBar: AppBar(
        title: Text(s.adminLivingBkk),
        bottom: TabBar(
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
          ],
        ),
        actions: [
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
              color: AppTheme.accentMidLight,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                Env.isConfigured ? s.adminTrialBannerConfigured : s.demoData,
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
          AdminDashboardBar(data: _overview, onJump: _jumpTab),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                AdminDashboardTab(onOpenTab: _jumpTab),
                const AdminChatsTab(),
                _offersTab(s),
                _leadsTab(s),
                const AdminAppointmentsTab(),
                const AdminReportsTab(),
                const AdminModerationTab(),
                const AdminInventoryTab(),
                AdminCreateDemandPage(onCreated: _refresh),
                const AdminImportTab(),
                const AdminProjectsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _offersTab(AppStrings s) {
    if (_offers.isEmpty) {
      return Center(child: Text(s.adminNoOffers));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _offers.length,
      itemBuilder: (context, i) {
        final o = _offers[i];
        final post = o['demand_posts'] as Map<String, dynamic>?;
        return Card(
          child: ExpansionTile(
            title: Text(post?['title']?.toString() ?? 'Demand'),
            subtitle: Text(
              '${s.offererCapacityLabel(o['offerer_capacity']?.toString() ?? '')} · ${o['status']} · verify: ${o['capacity_verified']}',
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
      padding: const EdgeInsets.all(12),
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
            (l) => Card(
              child: ListTile(
                leading: Icon(Icons.support_agent, color: AppTheme.primary),
                title: Text(l['listing_code']?.toString() ?? '—'),
                subtitle: Text(
                  '${l['seeker_nickname']} · ${l['status']}'
                  '${_viewingHint(l, s)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openLead(l['id'] as String),
              ),
            ),
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
