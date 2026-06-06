import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/appointment.dart';
import '../../services/admin_repository.dart';
import '../../services/appointment_repository.dart';
import '../../services/viewing_ops_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_listing_nav.dart';
import '../../widgets/appointments_map.dart';

class AdminAppointmentsTab extends StatefulWidget {
  const AdminAppointmentsTab({super.key});

  @override
  State<AdminAppointmentsTab> createState() => _AdminAppointmentsTabState();
}

class _AdminAppointmentsTabState extends State<AdminAppointmentsTab> {
  final _repo = AppointmentRepository();
  final _admin = AdminRepository();
  final _ops = ViewingOpsRepository();
  bool _loading = true;
  List<Appointment> _items = [];
  String? _selectedId;
  bool _showMap = true;
  Map<String, dynamic>? _leadDetail;
  bool _leadLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.fetchUpcoming();
    setState(() {
      _items = list;
      _loading = false;
    });
    if (_selectedId != null) {
      await _loadLeadFor(_selectedId!);
    }
  }

  Appointment? get _selected {
    if (_selectedId == null) return null;
    for (final a in _items) {
      if (a.id == _selectedId) return a;
    }
    return null;
  }

  Future<void> _select(Appointment a) async {
    setState(() => _selectedId = a.id);
    await _loadLeadFor(a.id);
  }

  Future<void> _loadLeadFor(String appointmentId) async {
    Appointment? appt;
    for (final x in _items) {
      if (x.id == appointmentId) {
        appt = x;
        break;
      }
    }
    final leadId = appt?.leadId;
    if (leadId == null || leadId.isEmpty) {
      setState(() => _leadDetail = null);
      return;
    }
    setState(() => _leadLoading = true);
    final lead = await _admin.fetchLead(leadId);
    if (!mounted) return;
    setState(() {
      _leadDetail = lead;
      _leadLoading = false;
    });
  }

  String _dateLabel(DateTime d, AppStrings s) =>
      '${d.day}/${d.month}/${d.year + (s.isEnglish ? 0 : 543)}';

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppTheme.primary;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  Future<void> _openCustomerChat(Appointment a) async {
    final s = context.s;
    final threadId = await _ops.resolveCustomerThreadId(a.leadId);
    if (!mounted) return;
    if (threadId == null || threadId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminInboxEmptyUnclaimed)),
      );
      return;
    }
    context.push('/admin/chat/$threadId');
  }

  Future<void> _requestSeniorCall(Appointment a) async {
    final s = context.s;
    final leadId = a.leadId;
    if (leadId == null || leadId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.notFoundLead)),
      );
      return;
    }
    final noteCtrl = TextEditingController(
      text: a.adminNotes ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ds = ctx.s;
        return AlertDialog(
          title: Text(ds.adminSeniorOwnerCallTitle),
          content: TextField(
            controller: noteCtrl,
            decoration: InputDecoration(
              labelText: ds.adminNotesLabel,
              hintText: ds.adminSeniorOwnerCallHint,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ds.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ds.adminSeniorOwnerCallSubmit),
            ),
          ],
        );
      },
    );
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (ok != true || !mounted) return;

    try {
      await _ops.requestSeniorOwnerCall(
        leadId: leadId,
        appointmentId: a.id,
        listingCode: a.listingCode,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminSeniorOwnerCallSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _sendProfileToOwner(Appointment a) async {
    final s = context.s;
    final lead = _leadDetail;
    if (lead == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.notFoundLead)),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.adminSendOwnerProfileTitle),
        content: Text(s.adminSendOwnerProfileBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.adminSendOwnerProfileConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      final point = await _admin.fetchListingMapPoint(
        a.listingId,
        listingCode: a.listingCode,
      );
      await _ops.sendCensoredProfileToOwner(
        lead: lead,
        listingCode: a.listingCode ?? lead['listing_code']?.toString() ?? '',
        listingId: a.listingId,
        listingTitle: point?['title']?.toString(),
        projectName: point?['project_name']?.toString(),
        appointmentDate: _dateLabel(a.scheduledDate, s),
        appointmentSlot: a.timeSlot,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminSendOwnerProfileDone)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('owner_not_found')
          ? s.adminOwnerNotFound
          : '$e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _actionBar(Appointment a, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _openCustomerChat(a),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: Text(s.adminOpenLinkedChat),
          ),
          if (a.listingCode != null && a.listingCode!.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => openAdminListing(
                context,
                listingId: a.listingId,
                listingCode: a.listingCode,
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(s.adminOpenListing),
            ),
          OutlinedButton.icon(
            onPressed: () => _requestSeniorCall(a),
            icon: const Icon(Icons.support_agent, size: 18),
            label: Text(s.adminSeniorOwnerCallBtn),
          ),
          FilledButton.icon(
            onPressed: _leadLoading ? null : () => _sendProfileToOwner(a),
            icon: const Icon(Icons.send_outlined, size: 18),
            label: Text(s.adminSendOwnerProfileBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final selected = _selected;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Text(
                s.adminManageAppointments,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                tooltip: _showMap ? s.adminHideMap : s.adminShowMap,
                onPressed: () => setState(() => _showMap = !_showMap),
                icon: Icon(_showMap ? Icons.map : Icons.map_outlined),
              ),
            ],
          ),
          if (_showMap) ...[
            AppointmentsMap(
              appointments: _items,
              selectedId: _selectedId,
              onAppointmentTap: (a) => _select(a),
              height: 240,
            ),
            const SizedBox(height: 12),
          ],
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.adminAppointmentsEmpty,
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._items.map((a) {
              final isSelected = a.id == _selectedId;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: isSelected
                        ? AppTheme.primaryLight.withOpacity(0.5)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: Icon(Icons.event, color: _statusColor(a.status)),
                          title: InkWell(
                            onTap: a.listingCode != null && a.listingCode!.isNotEmpty
                                ? () => openAdminListing(
                                      context,
                                      listingId: a.listingId,
                                      listingCode: a.listingCode,
                                    )
                                : null,
                            child: Text(
                              '${a.seekerNickname} · ${a.listingCode ?? ''}',
                              style: TextStyle(
                                color: a.listingCode != null &&
                                        a.listingCode!.isNotEmpty
                                    ? AppTheme.primary
                                    : null,
                                decoration: a.listingCode != null &&
                                        a.listingCode!.isNotEmpty
                                    ? TextDecoration.underline
                                    : null,
                                decorationColor: AppTheme.primary.withOpacity(0.4),
                              ),
                            ),
                          ),
                          subtitle: Text(
                            '${_dateLabel(a.scheduledDate, s)} · ${a.timeSlot}\n'
                            '${a.locationLabel ?? ''} · ${a.status}',
                          ),
                          isThreeLine: true,
                          onTap: () => _select(a),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              await _repo.updateStatus(a.id, v);
                              _load();
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'confirmed',
                                child: Text(s.adminConfirmAppointment),
                              ),
                              PopupMenuItem(
                                value: 'completed',
                                child: Text(s.adminCompleteAppointment),
                              ),
                              PopupMenuItem(
                                value: 'cancelled',
                                child: Text(s.cancel),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          if (_leadLoading)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          else
                            _actionBar(a, s),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }),
          if (selected != null && _selectedId != null && !_items.any((a) => a.id == _selectedId))
            _actionBar(selected, s),
        ],
      ),
    );
  }
}
