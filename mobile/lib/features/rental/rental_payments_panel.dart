import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/rental_lease.dart';
import '../../models/rental_payment_installment.dart';
import '../../services/auth_service.dart';
import '../../services/rental_lease_service.dart';
import '../../services/rental_payment_logic.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_rental_payment_sheet.dart';
import 'rental_admin_confirm_payment.dart';

/// แท็บชำระค่าเช่า — รอบชำระ · สลิป · แจ้งเตือน
class RentalPaymentsPanel extends StatelessWidget {
  const RentalPaymentsPanel({
    super.key,
    required this.lease,
    this.isAdmin = false,
  });

  final RentalLease lease;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = DateFormat(s.isEnglish ? 'd MMM yyyy' : 'd MMM yyyy');
    final pending = RentalPaymentLogic.pendingReminders(lease: lease);
    final displayInst = RentalPaymentLogic.displayInstallment(lease: lease);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isAdmin)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => showAdminRentalPaymentSheet(
                context: context,
                lease: lease,
              ),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(s.adminRentalPaymentSettings),
            ),
          ),
        if (!isAdmin &&
            displayInst != null &&
            displayInst.isAdminConfirmed) ...[
          _TenantAdminConfirmedBanner(
            round: displayInst.sequence,
            dateFmt: fmt,
            confirmedAt: displayInst.adminConfirmedAt!,
            note: displayInst.adminConfirmNote,
          ),
          const SizedBox(height: 10),
        ],
        _PolicyCard(lease: lease),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ReminderBanner(
            count: pending.length,
            text: s.rentalPaymentRemindersDue(pending.length),
          ),
        ],
        const SizedBox(height: 12),
        Text(s.rentalPaymentInstallmentsTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (lease.paymentInstallments.isEmpty)
          Text(s.rentalPaymentNoInstallments, style: Theme.of(context).textTheme.bodySmall)
        else
          ...lease.paymentInstallments.map(
            (inst) => _InstallmentTile(
              lease: lease,
              inst: inst,
              dateFmt: fmt,
              isAdmin: isAdmin,
            ),
          ),
        const SizedBox(height: 16),
        Text(s.rentalPaymentSlipSection, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(s.rentalPaymentSlipHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        _SlipUploadSection(lease: lease, isAdmin: isAdmin),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.lease});

  final RentalLease lease;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = lease.paymentPolicy;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.policy_outlined, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(s.rentalPaymentPolicyTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(s.rentalPaymentRemindBefore(p.reminderDaysBefore.join(', '))),
            Text(s.rentalPaymentInstallmentsCount(p.installmentsPerYear)),
            Text(s.rentalPaymentGraceDays(p.graceDaysLate)),
            Text(s.rentalPaymentPenaltyPerDay(p.penaltyPerDayAfterGrace)),
            if (p.policyYear != null)
              Text(s.rentalPaymentPolicyYear(p.policyYear!)),
          ],
        ),
      ),
    );
  }
}

class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.count, required this.text});

  final int count;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.accentMid.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: AppTheme.accentMid, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _TenantAdminConfirmedBanner extends StatelessWidget {
  const _TenantAdminConfirmedBanner({
    required this.round,
    required this.dateFmt,
    required this.confirmedAt,
    this.note,
  });

  final int round;
  final DateFormat dateFmt;
  final DateTime confirmedAt;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, color: Colors.green.shade800, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.rentalPaymentHomeAdminConfirmed(round),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.rentalPaymentAdminConfirmedTenantBanner,
                  style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                ),
                const SizedBox(height: 2),
                Text(
                  s.rentalPaymentAdminConfirmedOn(dateFmt.format(confirmedAt)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(note!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({
    required this.lease,
    required this.inst,
    required this.dateFmt,
    required this.isAdmin,
  });

  final RentalLease lease;
  final RentalPaymentInstallment inst;
  final DateFormat dateFmt;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final penalty = RentalPaymentLogic.latePenaltyBaht(
      inst: inst,
      policy: lease.paymentPolicy,
    );
    final late = inst.daysLate(DateTime.now());

    late final Color statusColor;
    late final String statusLabel;
    switch (inst.status) {
      case RentalInstallmentStatus.slipSubmitted:
        statusColor = Colors.green.shade700;
        statusLabel = s.rentalPaymentSlipReceived;
      case RentalInstallmentStatus.confirmed:
        statusColor = Colors.green.shade800;
        statusLabel = inst.isAdminConfirmed
            ? s.rentalPaymentAdminConfirmed
            : s.rentalPaymentConfirmed;
      case RentalInstallmentStatus.pending:
        statusColor = inst.remindersPaused ? Colors.grey.shade700 : AppTheme.accentMid;
        statusLabel = inst.remindersPaused
            ? s.rentalPaymentRemindersPaused
            : s.rentalPaymentPending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.rentalPaymentRound(inst.sequence),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(s.rentalNextPayment(dateFmt.format(inst.dueDate))),
            if (inst.remindersSentDaysBefore.isNotEmpty)
              Text(
                s.rentalPaymentReminded(inst.remindersSentDaysBefore.join(', ')),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (late > 0 && !inst.isSettled) ...[
              Text(
                s.rentalPaymentLateDays(late),
                style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
              ),
              if (penalty > 0)
                Text(
                  s.rentalPaymentPenaltyAmount(penalty),
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                ),
            ],
            if (inst.slip != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      inst.slip!.fileName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            if (inst.isAdminConfirmed) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_outlined, size: 16, color: Colors.green.shade800),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [
                        if (isAdmin)
                          s.rentalPaymentAdminConfirmedBy(
                            inst.adminConfirmedBy ?? '',
                            dateFmt.format(inst.adminConfirmedAt!),
                          )
                        else
                          s.rentalPaymentAdminConfirmedOn(
                            dateFmt.format(inst.adminConfirmedAt!),
                          ),
                        if (inst.adminConfirmNote != null &&
                            inst.adminConfirmNote!.isNotEmpty)
                          inst.adminConfirmNote!,
                      ].join('\n'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            if (isAdmin && !inst.isSettled) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => showRentalAdminConfirmPaymentDialog(
                  context,
                  leaseId: lease.id,
                  installmentId: inst.id,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(s.rentalPaymentAdminConfirmBtn),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: lease.paymentPolicy.reminderDaysBefore
                    .where((d) => !inst.remindersSentDaysBefore.contains(d))
                    .map(
                      (d) => OutlinedButton(
                        onPressed: () async {
                          await RentalLeaseService.instance.sendPaymentReminder(
                            leaseId: lease.id,
                            installmentId: inst.id,
                            daysBefore: d,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.rentalPaymentReminderSent(d))),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(s.rentalPaymentSendRemind(d)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlipUploadSection extends StatefulWidget {
  const _SlipUploadSection({required this.lease, required this.isAdmin});

  final RentalLease lease;
  final bool isAdmin;

  @override
  State<_SlipUploadSection> createState() => _SlipUploadSectionState();
}

class _SlipUploadSectionState extends State<_SlipUploadSection> {
  final _service = RentalLeaseService.instance;
  String? _selectedInstallmentId;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    _pickDefaultInstallment();
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _pickDefaultInstallment() {
    final lease = _service.leaseById(widget.lease.id) ?? widget.lease;
    final open = lease.paymentInstallments.where((i) => !i.isSettled).toList();
    if (open.isNotEmpty) _selectedInstallmentId = open.first.id;
  }

  Future<void> _submitSlip() async {
    final s = context.s;
    final lease = _service.leaseById(widget.lease.id) ?? widget.lease;
    final instId = _selectedInstallmentId;
    if (instId == null) return;

    final nameCtrl = TextEditingController(text: 'slip-${DateFormat('yyyyMMdd').format(DateTime.now())}.jpg');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.rentalPaymentUploadSlip),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: s.adminRentalAttachFileName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.rentalPaymentSubmitSlip)),
        ],
      ),
    );
    if (ok != true) {
      nameCtrl.dispose();
      return;
    }
    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (name.isEmpty) return;

    final actor = widget.isAdmin
        ? (AuthService.instance.displayEmail ?? 'แอดมิน')
        : 'ผู้เช่า';
    await _service.submitPaymentSlip(
      leaseId: lease.id,
      installmentId: instId,
      fileName: name,
      uploadedBy: actor,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.rentalPaymentSlipSubmitted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lease = _service.leaseById(widget.lease.id) ?? widget.lease;
    final open = lease.paymentInstallments.where((i) => !i.isSettled).toList();

    if (open.isEmpty) {
      return Text(s.rentalPaymentAllSlipsReceived, style: Theme.of(context).textTheme.bodySmall);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedInstallmentId ?? open.first.id,
          decoration: InputDecoration(
            labelText: s.rentalPaymentSelectRound,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: open
              .map(
                (i) => DropdownMenuItem(
                  value: i.id,
                  child: Text('${s.rentalPaymentRound(i.sequence)} — ${DateFormat('d MMM yyyy').format(i.dueDate)}'),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedInstallmentId = v),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _submitSlip,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(s.rentalPaymentUploadSlip),
        ),
        if (!widget.isAdmin)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              s.rentalPaymentSlipStopsReminders,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
