import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../config/env.dart';
import '../../services/co_agent_repository.dart';
import '../../services/work_repository.dart';
import '../../theme/app_theme.dart';

class WorkPage extends StatefulWidget {
  const WorkPage({
    super.key,
    this.isAgent = false,
    this.canManageLeads = false,
  });

  final bool isAgent;
  final bool canManageLeads;

  @override
  State<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage> {
  final _work = WorkRepository();
  final _coAgent = CoAgentRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _myLeads = [];
  List<Map<String, dynamic>> _inbox = [];
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _coAgentReqs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final leads = await _work.mySubmittedLeads();
      final inbox = widget.canManageLeads ? await _work.inboxLeads() : <Map<String, dynamic>>[];
      final offers = await _work.myDemandOffers();
      final coReqs = widget.isAgent ? await _coAgent.myRequests() : <Map<String, dynamic>>[];
      setState(() {
        _myLeads = leads;
        _inbox = inbox;
        _offers = offers;
        _coAgentReqs = coReqs;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
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
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.appointmentsTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!Env.isConfigured)
                    Card(
                      child: ListTile(
                        title: Text(s.workDemoMode),
                        subtitle: Text(s.workDemoHint),
                      ),
                    ),
                  if (widget.canManageLeads) ...[
                    _sectionTitle(s.workLeadInbox),
                    if (_inbox.isEmpty)
                      _empty(s.workNoLeadsInbox)
                    else
                      ..._inbox.map(_inboxTile),
                    const SizedBox(height: 16),
                  ],
                  _sectionTitle(s.myRequestsSection),
                  if (_myLeads.isEmpty)
                    _empty(s.workNoRequests)
                  else
                    ..._myLeads.map(_leadTile),
                  if (widget.isAgent) ...[
                    const SizedBox(height: 16),
                    _sectionTitle(s.workCoAgentRequests),
                    if (_coAgentReqs.isEmpty)
                      _empty(s.workNoCoAgentRequests)
                    else
                      ..._coAgentReqs.map(_coAgentTile),
                  ],
                  const SizedBox(height: 16),
                  _sectionTitle(s.workBoardOffers),
                  if (_offers.isEmpty)
                    _empty(s.workNoBoardOffers)
                  else
                    ..._offers.map(_offerTile),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(msg, style: TextStyle(color: AppTheme.textSecondary)),
      );

  Widget _leadTile(Map<String, dynamic> row) {
    final s = context.s;
    return Card(
      child: ListTile(
        leading: Icon(Icons.mail_outline, color: AppTheme.primary),
        title: Text(row['listing_code']?.toString() ?? '—'),
        subtitle: Text('${s.statusLabel}: ${s.leadStatusLabel(row['status']?.toString() ?? '')}'),
      ),
    );
  }

  Widget _inboxTile(Map<String, dynamic> row) {
    final s = context.s;
    final qual = row['qualification_json'] as Map<String, dynamic>?;
    final viewing = qual?['viewing_schedule']?.toString();
    return Card(
      color: AppTheme.primaryLight.withOpacity(0.35),
      child: ListTile(
        leading: Icon(Icons.person_search, color: AppTheme.primary),
        title: Text(row['seeker_nickname']?.toString() ?? s.leadDefaultName),
        subtitle: Text(
          [
            row['listing_code'],
            row['seeker_phone_censored'] ?? s.phoneHidden,
            if (viewing != null) s.adminViewingPrefix(viewing),
          ].whereType<String>().join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openLead(row),
      ),
    );
  }

  Widget _coAgentTile(Map<String, dynamic> row) {
    final s = context.s;
    return Card(
      child: ListTile(
        leading: Icon(Icons.handshake_outlined, color: AppTheme.primary),
        title: Text('Listing ${row['listing_id']?.toString().substring(0, 8) ?? ''}…'),
        subtitle: Text('${s.statusLabel}: ${s.leadStatusLabel(row['status']?.toString() ?? '')}'),
      ),
    );
  }

  Widget _offerTile(Map<String, dynamic> row) {
    final s = context.s;
    return Card(
      child: ListTile(
        leading: Icon(Icons.description_outlined, color: AppTheme.primary),
        title: Text(s.offererCapacityLabel(row['offerer_capacity']?.toString() ?? '')),
        subtitle: Text('${s.statusLabel}: ${s.leadStatusLabel(row['status']?.toString() ?? '')}'),
      ),
    );
  }
}
