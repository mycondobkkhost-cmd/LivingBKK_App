import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/rental_lease.dart';
import '../../models/rental_maintenance_ticket.dart';
import '../../services/rental_lease_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/rental_pii_guard.dart';

/// แจ้งซ่อมในกลุ่มเช่า — Phase 27d
class RentalMaintenancePanel extends StatefulWidget {
  const RentalMaintenancePanel({
    super.key,
    required this.lease,
    this.isAdmin = false,
  });

  final RentalLease lease;
  final bool isAdmin;

  @override
  State<RentalMaintenancePanel> createState() => _RentalMaintenancePanelState();
}

class _RentalMaintenancePanelState extends State<RentalMaintenancePanel> {
  final _service = RentalLeaseService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);
  }

  @override
  void dispose() {
    _service.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _openTicket() async {
    final s = context.s;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.rentalMaintenanceOpenTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: s.rentalMaintenanceTitleLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: s.rentalMaintenanceDescLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.rentalMaintenanceSubmit),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true) return;
    final title = titleCtrl.text.trim();
    final desc = descCtrl.text.trim();
    titleCtrl.dispose();
    descCtrl.dispose();
    if (title.isEmpty || desc.isEmpty) return;

    final combined = '$title\n$desc';
    final piiOk = await RentalPiiGuard.checkAndAudit(
      leaseId: widget.lease.id,
      channel: 'maintenance',
      text: combined,
    );
    if (!piiOk) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.rentalGroupPiiBlocked)),
      );
      return;
    }

    await _service.openMaintenanceTicket(
      leaseId: widget.lease.id,
      title: title,
      description: desc,
      openedBy: widget.isAdmin ? 'แอดมิน' : s.rentalMaintenanceTenantLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final tickets = _service.maintenanceTicketsFor(widget.lease.id);
    final fmt = DateFormat(s.isEnglish ? 'd MMM yyyy' : 'd MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.rentalMaintenanceSection(tickets.length),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton.icon(
                onPressed: _openTicket,
                icon: const Icon(Icons.build_outlined, size: 18),
                label: Text(s.rentalMaintenanceNewBtn),
              ),
            ],
          ),
        ),
        Expanded(
          child: tickets.isEmpty
              ? Center(
                  child: Text(
                    s.rentalMaintenanceEmpty,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = tickets[i];
                    return Card(
                      child: ListTile(
                        title: Text(t.title),
                        subtitle: Text(
                          '${fmt.format(t.openedAt)} · ${_statusLabel(t.status, s)}'
                          '${widget.isAdmin && t.isSlaBreached(slaHours: RentalLeaseService.maintenanceSlaHours) ? ' · ${s.rentalMaintenanceSlaOverdue}' : ''}\n'
                          '${t.description}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: widget.isAdmin && t.isOpen
                            ? PopupMenuButton<RentalMaintenanceStatus>(
                                onSelected: (st) {
                                  _service.updateMaintenanceStatus(
                                    leaseId: widget.lease.id,
                                    ticketId: t.id,
                                    status: st,
                                  );
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: RentalMaintenanceStatus.inProgress,
                                    child: Text(s.rentalMaintenanceInProgress),
                                  ),
                                  PopupMenuItem(
                                    value: RentalMaintenanceStatus.resolved,
                                    child: Text(s.rentalMaintenanceResolved),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _statusLabel(RentalMaintenanceStatus st, AppStrings s) =>
      switch (st) {
        RentalMaintenanceStatus.open => s.rentalMaintenanceStatusOpen,
        RentalMaintenanceStatus.inProgress => s.rentalMaintenanceInProgress,
        RentalMaintenanceStatus.resolved => s.rentalMaintenanceResolved,
        RentalMaintenanceStatus.cancelled => s.rentalMaintenanceCancelled,
      };
}
