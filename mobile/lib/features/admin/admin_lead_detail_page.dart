import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../models/appointment.dart';
import '../../models/listing_public.dart';
import '../../data/demo_cast_simulation.dart';
import '../../services/admin_repository.dart';
import '../../services/appointment_repository.dart';
import '../../services/chat_service.dart';
import '../../services/viewing_calendar_alert_service.dart';
import '../../theme/app_theme.dart';
import 'admin_lead_viewing_access_panel.dart';
import 'admin_viewing_follow_up_actions.dart';
import 'admin_viewing_history_panel.dart';
import '../../utils/admin_listing_nav.dart';
import '../../utils/admin_reference_nav.dart';
import '../../utils/admin_routing.dart';
import 'admin_nav_model.dart';
import '../../widgets/admin_attention_badge.dart';
import '../../widgets/admin_mobile_layout.dart';
import '../../widgets/listings_map.dart';
import '../../widgets/reference_code_chip.dart';

class AdminLeadDetailPage extends StatefulWidget {
  const AdminLeadDetailPage({super.key, required this.leadId});

  final String leadId;

  @override
  State<AdminLeadDetailPage> createState() => _AdminLeadDetailPageState();
}

class _AdminLeadDetailPageState extends State<AdminLeadDetailPage> {
  final _admin = AdminRepository();
  final _appts = AppointmentRepository();
  final _viewingHistoryKey = GlobalKey<AdminViewingHistoryPanelState>();
  bool _loading = true;
  Map<String, dynamic>? _lead;
  Appointment? _appointment;
  Map<String, dynamic>? _listingPoint;
  ListingPublic? _listingForMap;
  String? _linkedThreadId;
  int _calendarUnread = 0;

  @override
  void initState() {
    super.initState();
    if (widget.leadId.startsWith('demo-lead')) {
      for (final l in DemoCastSimulation.leads()) {
        if (l['id'] == widget.leadId) {
          _lead = l;
          _linkedThreadId = l['thread_id']?.toString();
          _loading = false;
          break;
        }
      }
    }
    _load();
    _loadCalendarUnread();
  }

  Future<void> _loadCalendarUnread() async {
    try {
      final appts = await _appts.fetchUpcoming(limit: 200);
      final alerts = await ViewingCalendarAlertService.analyze(
        appts.where((a) => a.status != 'cancelled').toList(),
      );
      if (mounted) setState(() => _calendarUnread = alerts.navBadgeCount);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _loadInner();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadInner() async {
    var lead = await _admin.fetchLead(widget.leadId);
    if (lead == null && widget.leadId.startsWith('demo-lead')) {
      for (final l in DemoCastSimulation.leads()) {
        if (l['id'] == widget.leadId) {
          lead = l;
          break;
        }
      }
    }
    lead ??= _lead;
    final listingId = lead?['listing_id'] as String?;
    final listingCode = lead?['listing_code']?.toString();
    final point = await _admin.fetchListingMapPoint(
      listingId,
      listingCode: listingCode,
    );
    final threadId = lead == null
        ? null
        : (lead['thread_id']?.toString() ??
            await _admin.resolveLeadThreadId(lead));
    final appt = lead == null
        ? null
        : await _appts.fetchByLeadId(lead['id']?.toString() ?? '');
    ListingPublic? listing;
    if (point != null && point['lat'] != null && point['lng'] != null) {
      final fallbackTitle = mounted ? context.s.adminDefaultProperty : 'Property';
      listing = ListingPublic(
        id: listingId ?? listingCode ?? 'map',
        listingCode: point['listing_code'] as String? ?? listingCode ?? '',
        listingType: point['listing_type']?.toString() ?? 'rent',
        title: point['title'] as String? ?? fallbackTitle,
        priceNet: (point['price_net'] as num?)?.toDouble() ?? 0,
        district: point['district'] as String?,
        projectName: point['project_name'] as String?,
        lat: (point['lat'] as num).toDouble(),
        lng: (point['lng'] as num).toDouble(),
      );
    }
    setState(() {
      _lead = lead;
      _listingPoint = point;
      _listingForMap = listing;
      _linkedThreadId = threadId;
      _appointment = appt;
    });
  }

  Future<void> _openOwnerChat() async {
    final s = context.s;
    final lead = _lead;
    if (lead == null) return;

    final listingCode = lead['listing_code']?.toString();
    final listingId = lead['listing_id']?.toString();
    if (listingCode == null || listingCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminLeadViewingAccessNoListing)),
      );
      return;
    }

    ChatRoom? room = ChatService.instance.roomForListing(listingCode);
    if (room == null && listingId != null && listingId.isNotEmpty) {
      room = ChatService.instance.roomForListing(listingId);
    }

    if (room == null) {
      try {
        room = await ChatService.instance.openRoom(
          listingId: listingId ?? listingCode,
          listingCode: listingCode,
          listingTitle: _listingPoint?['title']?.toString() ?? listingCode,
          projectName: _listingPoint?['project_name']?.toString(),
        );
      } catch (_) {}
    }

    if (!mounted) return;
    if (room != null) {
      if (kIsWeb) {
        context.go(
          '/admin/console?room=${room.id}&${kAdminReturnNavKey}=${AdminNavId.leads.name}',
        );
        return;
      }
      context.push(
        '/admin/chat/${room.id}?${kAdminReturnNavKey}=${AdminNavId.leads.name}',
      );
      return;
    }
    context.go('/admin/console');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminRegistryChatTagHint(listingCode))),
    );
  }

  Future<void> _openLinkedChat() async {
    var threadId = _linkedThreadId;
    final lead = _lead;
    if (threadId == null && lead != null) {
      threadId = await _admin.resolveLeadThreadId(lead);
      if (mounted) setState(() => _linkedThreadId = threadId);
    }
    if (!mounted) return;
    if (threadId == null || threadId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.adminInboxEmptyUnclaimed)),
      );
      return;
    }
    ChatService.instance.ensureViewingLeadChat(threadId);
    final fromQ = '${kAdminReturnNavKey}=${AdminNavId.leads.name}';
    if (kIsWeb) {
      context.go('/admin/console?room=$threadId&$fromQ');
      return;
    }
    context.push('/admin/chat/$threadId?$fromQ');
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
    final lead = _lead;
    if (lead == null) {
      return AdminMobileLayout.scaffold(
        context: context,
        body: Center(child: Text(s.notFoundLead)),
      );
    }

    final qual = lead['qualification_json'] as Map<String, dynamic>?;

    final listingCode = lead['listing_code']?.toString() ?? '—';
    final project = _listingPoint?['project_name']?.toString();
    final listingTitle = _listingPoint?['title']?.toString();

    return AdminMobileLayout.scaffold(
      context: context,
      appBar: AdminMobileLayout.appBar(
        context: context,
        title: Text(lead['transaction_ref']?.toString() ?? listingCode),
        actions: [
          AdminCalendarNavIconButton(
            unreadCount: _calendarUnread,
            tooltip: s.adminNavViewingCalendar,
            onPressed: () => context.push('/admin?nav=viewingCalendar'),
            iconSize: 22,
            compact: true,
          ),
        ],
      ),
      body: ListView(
        padding: AdminMobileLayout.scrollPadding(context, top: 20, horizontal: 20, fabClearance: 16),
        children: [
          if (lead['transaction_ref'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ReferenceCodeChip(
                code: lead['transaction_ref'].toString(),
                label: s.transactionRefLabel,
                onNavigate: adminReferenceNavigateHandler(
                  context,
                  code: lead['transaction_ref'].toString(),
                  leadId: widget.leadId,
                  listingId: lead['listing_id']?.toString(),
                  listingCode: listingCode != '—' ? listingCode : null,
                  threadId: _linkedThreadId,
                ),
              ),
            ),
          Card(
            color: AppTheme.primaryLight,
            child: InkWell(
              onTap: listingCode != '—'
                  ? () => openAdminListing(
                        context,
                        listingId: lead['listing_id']?.toString(),
                        listingCode: listingCode,
                      )
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.adminLeadPropertyCard,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        if (listingCode != '—')
                          Icon(Icons.open_in_new, size: 16, color: AppTheme.primary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project != null && project.isNotEmpty
                          ? '$project · $listingCode'
                          : listingCode,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  if (listingTitle != null && listingTitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      listingTitle,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                  if (_listingPoint?['price_net'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '฿${(_listingPoint!['price_net'] as num).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentDeep,
                      ),
                    ),
                  ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppTheme.accentMidLight,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: AppTheme.accentMid, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.adminConfirmViewingChatOnly,
                      style: TextStyle(fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _openLinkedChat,
                icon: const Icon(Icons.forum_outlined),
                label: Text(s.adminOpenLinkedChat),
              ),
              OutlinedButton.icon(
                onPressed: _openOwnerChat,
                icon: const Icon(Icons.real_estate_agent_outlined),
                label: Text(s.adminOpenOwnerChat),
              ),
            ],
          ),
          if (_appointment != null &&
              appointmentEligibleForFollowUp(_appointment!)) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => runAdminViewingFollowUp(
                context,
                appointment: _appointment!,
                listingTitle: listingTitle,
                seekerNickname: lead['seeker_nickname']?.toString(),
                seekerPhone: lead['seeker_phone']?.toString(),
                onRecorded: () async {
                  await _load();
                  await _viewingHistoryKey.currentState?.reload();
                },
              ),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(s.adminViewingFollowUpBtn),
            ),
          ],
          if (_appointment != null && appointmentHasViewingReport(_appointment!)) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => runAdminViewingFollowUp(
                context,
                appointment: _appointment!,
                seekerNickname: lead['seeker_nickname']?.toString(),
                seekerPhone: lead['seeker_phone']?.toString(),
              ),
              icon: const Icon(Icons.article_outlined),
              label: Text(s.adminViewingReportViewDetail),
            ),
          ],
          const SizedBox(height: 16),
          AdminViewingHistoryPanel(
            key: _viewingHistoryKey,
            leadId: widget.leadId,
            seekerPhone: lead['seeker_phone']?.toString(),
          ),
          const SizedBox(height: 16),
          AdminLeadViewingAccessPanel(
            leadId: widget.leadId,
            listingId: lead['listing_id']?.toString(),
            listingCode: listingCode != '—' ? listingCode : null,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead['seeker_nickname']?.toString() ?? s.leadDefaultName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    lead['seeker_phone']?.toString() ?? '—',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (qual?['viewing_schedule'] != null)
                    _line(s.adminViewingRequestField, qual!['viewing_schedule'].toString()),
                  _line(s.statusLabel, lead['status']?.toString()),
                  _line(s.occupationLabel, lead['occupation']?.toString()),
                  _line(s.movePlanLabel, lead['move_plan']?.toString()),
                  _line(s.contractFieldLabel, lead['contract_duration']?.toString()),
                  _line(s.budgetLabel, lead['budget']?.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.adminViewingMap, style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _listingForMap != null
                ? ListingsMap(listings: [_listingForMap!])
                : Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(s.adminNoCoords),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _line(String k, String? v) {
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$k: $v'),
    );
  }
}
