import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/demo_appointments.dart';
import '../config/env.dart';
import '../l10n/app_strings.dart';
import '../services/co_agent_repository.dart';
import '../services/work_repository.dart';
import '../theme/app_theme.dart';

/// ส่วนนัดหมาย / Lead — ฝังในแท็บข้อความ
class AppointmentsSection extends StatefulWidget {
  const AppointmentsSection({
    super.key,
    required this.isAgent,
    required this.canManageLeads,
  });

  final bool isAgent;
  final bool canManageLeads;

  @override
  State<AppointmentsSection> createState() => _AppointmentsSectionState();
}

class _AppointmentsSectionState extends State<AppointmentsSection> {
  final _work = WorkRepository();
  final _coAgent = CoAgentRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _myLeads = [];
  List<Map<String, dynamic>> _inbox = [];
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _coAgentReqs = [];
  bool _usingDemo = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      var leads = await _work.mySubmittedLeads();
      var inbox =
          widget.canManageLeads ? await _work.inboxLeads() : <Map<String, dynamic>>[];
      var offers = await _work.myDemandOffers();
      var coReqs =
          widget.isAgent ? await _coAgent.myRequests() : <Map<String, dynamic>>[];

      var usingDemo = false;
      final allEmpty = leads.isEmpty &&
          offers.isEmpty &&
          inbox.isEmpty &&
          coReqs.isEmpty;
      if (allEmpty) {
        usingDemo = true;
        leads = DemoAppointments.myLeads;
        offers = DemoAppointments.offers;
        if (widget.canManageLeads) inbox = DemoAppointments.inbox;
        if (widget.isAgent) coReqs = DemoAppointments.coAgentReqs;
      }

      if (!mounted) return;
      setState(() {
        _myLeads = leads;
        _inbox = inbox;
        _offers = offers;
        _coAgentReqs = coReqs;
        _usingDemo = usingDemo;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLead(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final changed = await context.push<bool>('/work/lead/$id');
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(s.appointmentsTitle, s),
        if (_usingDemo)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '(${s.demoSampleLabel})',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (!Env.isConfigured)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(s.t('โหมด Demo', 'Demo mode')),
              subtitle: Text(
                s.t(
                  'สลับเป็นนายหน้า/เจ้าของเพื่อดูกล่อง Lead',
                  'Switch to agent/owner to see lead inbox',
                ),
              ),
            ),
          ),
        if (widget.canManageLeads) ...[
          _subHeader(s.t('กล่อง Lead ที่มอบหมาย', 'Assigned leads')),
          if (_inbox.isEmpty)
            _empty(s.t('ยังไม่มี Lead', 'No leads yet'))
          else
            ..._inbox.map(_inboxTile),
          const SizedBox(height: 12),
        ],
        _subHeader(s.myRequestsSection),
        if (_myLeads.isEmpty)
          _empty(s.t('ยังไม่มีนัดชมหรือคำขอ', 'No viewings or requests yet'))
        else
          ..._myLeads.map(_leadTile),
        if (widget.isAgent) ...[
          const SizedBox(height: 12),
          _subHeader(s.t('คำขอโคนายหน้า', 'Co-broker requests')),
          if (_coAgentReqs.isEmpty)
            _empty(s.t('ยังไม่มีคำขอ', 'No requests'))
          else
            ..._coAgentReqs.map(_coAgentTile),
        ],
        const SizedBox(height: 12),
        _subHeader(s.t('ข้อเสนอบอร์ดเสนอทรัพย์', 'Board offers submitted')),
        if (_offers.isEmpty)
          _empty(s.t('ยังไม่มีข้อเสนอ', 'No offers yet'))
        else
          ..._offers.map(_offerTile),
      ],
    );
  }

  Widget _header(String title, AppStrings s) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Row(
          children: [
            Icon(Icons.event, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _load,
              tooltip: s.reloadTooltip,
            ),
          ],
        ),
      );

  Widget _subHeader(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          t,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
      );

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(msg, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      );

  Widget _leadTile(Map<String, dynamic> row) {
    final s = context.s;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.mail_outline, color: AppTheme.primary),
        title: Text(row['listing_code']?.toString() ?? '—'),
        subtitle: Text(s.leadStatusLabel(row['status']?.toString() ?? '')),
      ),
    );
  }

  Widget _inboxTile(Map<String, dynamic> row) {
    final s = context.s;
    final qual = row['qualification_json'] as Map<String, dynamic>?;
    final viewing = qual?['viewing_schedule']?.toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.primaryLight.withOpacity(0.35),
      child: ListTile(
        leading: Icon(Icons.person_search, color: AppTheme.primary),
        title: Text(row['seeker_nickname']?.toString() ?? s.leadDefaultName),
        subtitle: Text(
          [
            row['transaction_ref'],
            row['listing_code'],
            row['seeker_phone_censored'] ?? s.phoneHidden,
            if (viewing != null) s.adminViewingPrefix(viewing),
          ].whereType<String>().where((e) => e.isNotEmpty).join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openLead(row),
      ),
    );
  }

  Widget _coAgentTile(Map<String, dynamic> row) {
    final s = context.s;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.handshake_outlined, color: AppTheme.primary),
        title: Text('Listing ${row['listing_id']?.toString().substring(0, 8) ?? ''}…'),
        subtitle: Text(s.leadStatusLabel(row['status']?.toString() ?? '')),
      ),
    );
  }

  Widget _offerTile(Map<String, dynamic> row) {
    final s = context.s;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.description_outlined, color: AppTheme.primary),
        title: Text('${row['offerer_capacity']}'),
        subtitle: Text(s.leadStatusLabel(row['status']?.toString() ?? '')),
      ),
    );
  }
}
