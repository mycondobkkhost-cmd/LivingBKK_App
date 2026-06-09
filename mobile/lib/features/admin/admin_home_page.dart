import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../l10n/app_strings.dart';
import '../../models/admin_dashboard_overview.dart';
import '../../services/admin_repository.dart';
import '../../services/availability_alerts_repository.dart';
import '../../services/availability_follow_up_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/in_app_notification_hub.dart';
import '../../services/viewing_calendar_alert_service.dart';
import '../../services/viewing_final_confirm_reminder_service.dart';
import '../../services/appointment_repository.dart';
import '../../services/notification_service.dart';
import '../../services/realtime_service.dart';
import '../../services/supabase_service.dart';
import '../../state/admin_viewport_controller.dart';
import '../../state/session_gate.dart';
import '../../state/user_role_controller.dart';
import '../../services/demo_cast_bootstrap.dart';
import '../../services/demo_cast_session.dart';
import 'admin_demo_cast_switch_sheet.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/admin_listing_nav.dart';
import '../../widgets/admin_attention_badge.dart';
import '../../widgets/admin_mobile_layout.dart';
import 'admin_appointments_tab.dart';
import 'admin_viewing_calendar_tab.dart';
import 'admin_participant_page.dart';
import 'admin_chats_tab.dart';
import 'admin_create_demand_page.dart';
import 'admin_dashboard_tab.dart';
import 'admin_import_tab.dart';
import 'admin_inventory_tab.dart';
import 'admin_moderation_tab.dart';
import 'admin_nav_model.dart';
import 'admin_projects_tab.dart';
import 'admin_promos_tab.dart';
import 'admin_reports_tab.dart';
import '../../utils/admin_desktop.dart';
import '../../utils/admin_routing.dart';
import '../../utils/admin_sign_out.dart';
import 'admin_shell_scaffold.dart';
import 'admin_availability_alerts_tab.dart';
import 'admin_hidden_registry_tab.dart';
import 'admin_rental_management_tab.dart';
import 'admin_public_registry_tab.dart';
import 'admin_vault_tab.dart';
import 'admin_requirements_tab.dart';
import 'admin_vault_demo_tabs.dart';
import 'admin_watermark_tab.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key, this.initialNav, this.roleController});

  final AdminNavId? initialNav;
  final UserRoleController? roleController;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _admin = AdminRepository();
  bool _allowed = false;
  bool _loading = true;
  AdminNavId _selected = AdminNavId.dashboard;
  String _adminTier = 'admin';
  bool _viewingStaffOnly = false;
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
    _selected = widget.initialNav ?? AdminNavId.dashboard;
    _init();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
    final uid = SupabaseService.client?.auth.currentUser?.id ?? '';
    _realtime.subscribeToAdminChatOps(enabled: true, adminUserId: uid);
    _realtime.subscribeToAdminLeads(enabled: true);
    _notifSub = _realtime.messages.listen((msg) {
      _notifHub.show(msg, countAsUnread: false);
      ChatService.instance.refreshAdminInbox();
    });
    NotificationService.onForegroundMessage = (msg) {
      _notifHub.show(msg, countAsUnread: false);
    };
    NotificationService.onNotificationOpen = (type, _) {
      if (!mounted) return;
      if (type.startsWith('rental_payment_')) {
        setState(() => _selected = AdminNavId.rentalManagement);
        context.go('/admin?nav=rentalManagement');
      }
    };
  }

  @override
  void didUpdateWidget(AdminHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialNav ?? AdminNavId.dashboard;
    if (next != _selected) {
      setState(() => _selected = next);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notifSub?.cancel();
    _realtime.dispose();
    NotificationService.onForegroundMessage = null;
    NotificationService.onNotificationOpen = null;
    super.dispose();
  }

  Future<void> _reloadAfterCastSwitch() async {
    setState(() => _loading = true);
    await _init();
  }

  Future<void> _openCastSwitch() async {
    final rc = widget.roleController;
    if (rc == null || !DemoCastSession.hubEnabled) return;
    await showAdminDemoCastSwitchSheet(
      context,
      roleController: rc,
      onCastChanged: _reloadAfterCastSwitch,
    );
  }

  Future<void> _init() async {
    try {
      await DemoCastBootstrap.ensureReady(roleController: widget.roleController);
      ChatService.instance.reloadCastSimulation();
      final isAdmin = await _admin.isAdmin();
      final isStaff = await _admin.isViewingStaff();
      if (!isAdmin && !isStaff) {
        if (!mounted) return;
        setState(() {
          _allowed = false;
          _loading = false;
        });
        return;
      }
      if (isStaff && !isAdmin) {
        if (!mounted) return;
        setState(() {
          _allowed = true;
          _loading = false;
          _viewingStaffOnly = true;
          _adminTier = 'staff';
          if (widget.initialNav == null ||
              widget.initialNav == AdminNavId.dashboard) {
            _selected = AdminNavId.viewingCalendar;
          }
        });
        return;
      }
      if (DemoCastSession.hubEnabled &&
          DemoCastSession.instance.hasActiveCast &&
          !DemoCastSession.instance.isBackOfficeCast) {
        ChatService.instance.reloadCastSimulation();
        await _syncCalendarNavBadge();
        if (!mounted) return;
        setState(() {
          _allowed = true;
          _loading = false;
          _viewingStaffOnly = false;
          _adminTier = 'admin';
          _selected = AdminNavId.viewingCalendar;
        });
        return;
      }
      final tier = await _admin.fetchAdminTier();
      await _refresh();
      await _syncCalendarNavBadge();
      if (!mounted) return;
      setState(() {
        _allowed = true;
        _loading = false;
        _adminTier = tier;
        _viewingStaffOnly = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allowed = true;
        _loading = false;
      });
    }
  }

  Future<void> _syncCalendarNavBadge() async {
    if (_viewingStaffOnly) return;
    try {
      final appts = await AppointmentRepository().fetchUpcoming(limit: 200);
      final alerts = await ViewingCalendarAlertService.analyze(
        appts.where((a) => a.status != 'cancelled').toList(),
      );
      if (!mounted) return;
      setState(() {
        _overview = _overview.copyWith(
          viewingCalendarAttention: alerts.navBadgeCount,
        );
      });
    } catch (_) {}
  }

  Future<void> _refresh() async {
    try {
      if (mounted) {
        await ViewingFinalConfirmReminderService.checkDue(s: context.s);
      }
      await ChatService.instance.refreshAdminInbox();
      final offers = await _admin.allDemandOffers();
      final leads = await _admin.recentLeads();
      final stats = await _admin.leadStats();
      final overview = await _admin.fetchDashboardOverview();
      var dueCount = overview.availabilityAlertsDue;
      if (!DemoCastBootstrap.isolatedAdminTrial) {
        final alerts = await AvailabilityAlertsRepository.instance
            .fetchUpcoming(
              withinDays: AvailabilityAlertsRepository.notifyHorizonDays,
            );
        await AvailabilityFollowUpService.instance.ensureLoaded();
        dueCount = AvailabilityFollowUpService.instance.dueCount(
          alerts.map((e) => e.listingId),
        );
      }
      var calBadge = _overview.viewingCalendarAttention;
      if (!_viewingStaffOnly) {
        final appts = await AppointmentRepository().fetchUpcoming(limit: 200);
        final calAlerts = await ViewingCalendarAlertService.analyze(
          appts.where((a) => a.status != 'cancelled').toList(),
        );
        calBadge = calAlerts.navBadgeCount;
        if (!mounted) return;
        final s = context.s;
        await ViewingCalendarAlertService.publishOverviewBanner(
          summary: calAlerts,
          message: s.adminCalendarAlertOverview(
            unassigned: calAlerts.unassigned,
            awaitingConfirm: calAlerts.awaitingConfirm,
            newCases: calAlerts.newCases,
            postViewing: calAlerts.postViewing,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _leads = leads;
        _stats = stats;
        _overview = overview.copyWith(
          availabilityAlertsDue: dueCount,
          viewingCalendarAttention: calBadge,
        );
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

  bool _showNavBack(bool wide) => !wide && _selected != AdminNavId.dashboard;

  Widget? _appBarLeading(AppStrings s, bool compact, bool wide) {
    if (_showNavBack(wide)) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: s.back,
        onPressed: () => _selectNav(AdminNavId.dashboard),
      );
    }
    return AdminNavMenuButton(
      config: _navConfig,
      selected: _selected,
      onSelect: _selectNav,
      compact: compact,
    );
  }

  void _selectNav(AdminNavId id) {
    if (kIsWeb) {
      switch (id) {
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
    setState(() => _selected = id);
    if (kIsWeb) {
      context.go(
        id == AdminNavId.dashboard ? '/admin' : '/admin?nav=${id.name}',
      );
    }
  }

  Future<void> _signOut() => performAdminSignOut(context);

  Future<void> _openLead(String id) async {
    final changed = await context.push<bool>('/admin/lead/$id');
    if (changed == true) _refresh();
  }

  AdminNavConfig get _navConfig =>
      AdminNavConfig(tier: _adminTier, overview: _overview);

  List<Widget> _appBarActions(AppStrings s, bool compact) {
    final castBtn = DemoCastSession.hubEnabled && widget.roleController != null
        ? IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: s.t('สลับตัวละคร', 'Switch character'),
            onPressed: _openCastSwitch,
          )
        : null;

    if (compact) {
      return [
        if (_showNavBack(useAdminWideShell(context)))
          AdminNavMenuButton(
            config: _navConfig,
            selected: _selected,
            onSelect: _selectNav,
            compact: true,
          ),
        if (castBtn != null) castBtn,
        const AdminViewportToggleButton(),
        if (_selected != AdminNavId.viewingCalendar)
          AdminCalendarNavIconButton(
            unreadCount: _overview.viewingCalendarBadge,
            tooltip: s.adminNavViewingCalendar,
            onPressed: () => _selectNav(AdminNavId.viewingCalendar),
            compact: true,
          ),
        PopupMenuButton<String>(
          tooltip: s.adminMoreActions,
          onSelected: (value) {
            switch (value) {
              case 'calendar':
                _selectNav(AdminNavId.viewingCalendar);
              case 'consumer':
                goConsumerApp(context);
              case 'console':
                if (kIsWeb) context.go('/admin/console');
              case 'refresh':
                _refresh();
              case 'logout':
                _signOut();
            }
          },
          itemBuilder: (ctx) => [
            if (_selected != AdminNavId.viewingCalendar)
              PopupMenuItem(
                value: 'calendar',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.calendar_month_outlined, size: 20),
                  title: Text(s.adminNavViewingCalendar),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
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
      ];
    }
    return [
      if (_showNavBack(false))
        AdminNavMenuButton(
          config: _navConfig,
          selected: _selected,
          onSelect: _selectNav,
        ),
      if (castBtn != null) castBtn,
      const AdminViewportToggleButton(),
      if (_selected != AdminNavId.viewingCalendar)
        AdminCalendarNavIconButton(
          unreadCount: _overview.viewingCalendarBadge,
          tooltip: s.adminNavViewingCalendar,
          onPressed: () => _selectNav(AdminNavId.viewingCalendar),
        ),
      IconButton(
        icon: const Icon(Icons.storefront_outlined),
        tooltip: s.adminViewConsumerApp,
        onPressed: () => goConsumerApp(context),
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
    ];
  }

  Widget _buildBody(AppStrings s) {
    switch (_selected) {
      case AdminNavId.queue:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              color: AppTheme.error.withOpacity(0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.adminNavQueueTitle,
                    style: AdminTheme.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.error,
                    ),
                  ),
                  Text(s.adminNavQueueHint, style: AdminTheme.caption),
                ],
              ),
            ),
            const Expanded(child: AdminChatsTab(focusQueue: true)),
          ],
        );
      case AdminNavId.leads:
        return _leadsTab(s);
      case AdminNavId.inbox:
        return const AdminChatsTab();
      case AdminNavId.dashboard:
        return AdminDashboardTab(onOpenNav: _selectNav);
      case AdminNavId.assetRegistry:
        return const AdminPublicRegistryTab();
      case AdminNavId.availabilityAlerts:
        return AdminAvailabilityAlertsTab(adminTier: _adminTier);
      case AdminNavId.hiddenRegistry:
        return const AdminHiddenRegistryTab();
      case AdminNavId.rentalManagement:
        return const AdminRentalManagementTab();
      case AdminNavId.inventory:
        return const AdminInventoryTab();
      case AdminNavId.import:
        return const AdminImportTab();
      case AdminNavId.moderation:
        return const AdminModerationTab();
      case AdminNavId.projects:
        return AdminProjectsTab(isCeo: _navConfig.isCeo);
      case AdminNavId.participant360:
        return const AdminParticipantPage();
      case AdminNavId.viewingCalendar:
        return AdminViewingCalendarTab(
          viewingStaffOnly: _viewingStaffOnly,
          onAttentionCountChanged: (count) {
            if (!mounted) return;
            setState(() {
              _overview = _overview.copyWith(viewingCalendarAttention: count);
            });
          },
        );
      case AdminNavId.appointments:
        return const AdminAppointmentsTab();
      case AdminNavId.offers:
        return _offersTab(s);
      case AdminNavId.requirements:
        return AdminRequirementsTab(
          onOpenNav: _selectNav,
          onChanged: _refresh,
        );
      case AdminNavId.reports:
        return const AdminReportsTab();
      case AdminNavId.boardCreate:
        return AdminCreateDemandPage(onCreated: _refresh);
      case AdminNavId.promos:
        return const AdminPromosTab();
      case AdminNavId.watermark:
        return const AdminWatermarkTab();
      case AdminNavId.vault:
        return const AdminVaultTab();
      case AdminNavId.accessRequests:
        return const AdminAccessRequestsTab();
      case AdminNavId.org:
        return const AdminOrgTab();
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
        appBar: AdminMobileLayout.appBar(
          context: context,
          title: Text(s.adminTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(s.adminNeedRole, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final compact = AdminMobileLayout.isCompact(context);
    final shell = AdminTheme.shellTheme();
    final trialBanner = Env.trialMode
        ? Container(
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
          )
        : null;

    final isolatedBanner = DemoCastBootstrap.isolatedAdminTrial
        ? Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border(bottom: BorderSide(color: AdminTheme.border)),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 8 : 10,
            ),
            child: Text(
              s.adminUnifiedTrialBanner,
              style: AdminTheme.hint.copyWith(color: const Color(0xFF1D4ED8)),
            ),
          )
        : null;

    final castLabel = DemoCastSession.instance.displayLabel(s.isEnglish);
    final castBanner = DemoCastSession.hubEnabled && castLabel != null
        ? Material(
            color: LivingBkkBrand.purplePrimary.withOpacity(0.08),
            child: InkWell(
              onTap: widget.roleController != null ? _openCastSwitch : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: compact ? 8 : 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.t('กำลังเล่นเป็น: $castLabel', 'Playing as: $castLabel'),
                        style: AdminTheme.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      s.t('สลับ', 'Switch'),
                      style: TextStyle(
                        color: LivingBkkBrand.purplePrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : null;

    return PopScope(
      canPop: _selected == AdminNavId.dashboard,
      onPopInvoked: (didPop) {
        if (!didPop && _selected != AdminNavId.dashboard) {
          _selectNav(AdminNavId.dashboard);
        }
      },
      child: Theme(
      data: shell,
      child: AdminTheme.lightPaletteScope(
      child: ListenableBuilder(
        listenable: Listenable.merge([
          if (AdminViewportController.instance != null)
            AdminViewportController.instance!,
          DemoCastSession.instance,
        ]),
        builder: (context, _) {
          final wide = useAdminWideShell(context);
          final navConfig = _navConfig;
          final content = _buildBody(s);
          final main = wide
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminWideContentBar(
                      title: navConfig.labelForNav(_selected, s),
                      actions: _appBarActions(s, false),
                    ),
                    if (trialBanner != null) trialBanner,
                    if (isolatedBanner != null) isolatedBanner,
                    if (castBanner != null) castBanner,
                    Expanded(child: content),
                  ],
                )
              : content;

          return KeyedSubtree(
            key: ValueKey('admin-shell-${AdminViewportController.instance?.mode.name}'),
            child: AdminMobileLayout.scaffold(
              context: context,
              backgroundColor: AdminTheme.bg,
              appBar: wide
                  ? null
                  : AdminMobileLayout.appBar(
                      context: context,
                      leading: _appBarLeading(s, compact, wide),
                      title: Text(
                        s.adminLivingBkk,
                        style: AdminTheme.title.copyWith(fontSize: compact ? 16 : 17),
                      ),
                      actions: _appBarActions(s, compact),
                    ),
              body: AdminShellScaffold(
                config: navConfig,
                selected: _selected,
                onSelect: _selectNav,
                tierLabel: s.adminNavTierLabel(_adminTier),
                actions: _appBarActions(s, compact),
                header: wide
                    ? null
                    : (trialBanner != null ||
                            isolatedBanner != null ||
                            castBanner != null)
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (trialBanner != null) trialBanner,
                              if (isolatedBanner != null) isolatedBanner,
                              if (castBanner != null) castBanner,
                            ],
                          )
                        : null,
                body: main,
              ),
            ),
          );
        },
      ),
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
                          final res = await _admin.promoteDemandOffer(o['id'] as String);
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
          ..._leads.map((l) {
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
                      decoration: code != '—' ? TextDecoration.underline : null,
                      decorationColor: AppTheme.primary.withOpacity(0.5),
                    ),
                  ),
                ),
                subtitle: Text(
                  '${l['seeker_nickname']} · ${l['status']}${_viewingHint(l, s)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openLead(l['id'] as String),
              ),
            );
          }),
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
