import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/rental_lease.dart';
import '../../models/rental_payment_installment.dart';
import '../../models/rental_payment_policy.dart';
import '../../services/rental_lease_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../rental/rental_admin_confirm_payment.dart';

Future<void> showAdminRentalPaymentSheet({
  required BuildContext context,
  required RentalLease lease,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AdminRentalPaymentSheet(leaseId: lease.id),
  );
}

class _AdminRentalPaymentSheet extends StatefulWidget {
  const _AdminRentalPaymentSheet({required this.leaseId});

  final String leaseId;

  @override
  State<_AdminRentalPaymentSheet> createState() =>
      _AdminRentalPaymentSheetState();
}

class _AdminRentalPaymentSheetState extends State<_AdminRentalPaymentSheet> {
  final _service = RentalLeaseService.instance;
  late TextEditingController _remindDays;
  late TextEditingController _installments;
  late TextEditingController _grace;
  late TextEditingController _penalty;
  late TextEditingController _year;
  bool _saving = false;

  RentalLease? get _lease => _service.leaseById(widget.leaseId);

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    final p = _lease?.paymentPolicy ?? const RentalPaymentPolicy();
    _remindDays = TextEditingController(text: p.reminderDaysBefore.join(', '));
    _installments = TextEditingController(text: '${p.installmentsPerYear}');
    _grace = TextEditingController(text: '${p.graceDaysLate}');
    _penalty = TextEditingController(text: '${p.penaltyPerDayAfterGrace}');
    _year = TextEditingController(
      text: '${p.policyYear ?? DateTime.now().year}',
    );
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    _remindDays.dispose();
    _installments.dispose();
    _grace.dispose();
    _penalty.dispose();
    _year.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<int> _parseRemindDays(String raw) {
    return raw
        .split(RegExp(r'[,;\s]+'))
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((d) => d > 0)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  Future<void> _save({required bool regenerate}) async {
    final s = context.s;
    final days = _parseRemindDays(_remindDays.text);
    if (days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminRentalPaymentRemindInvalid)),
      );
      return;
    }
    setState(() => _saving = true);
    final policy = RentalPaymentPolicy(
      reminderDaysBefore: days,
      installmentsPerYear: int.tryParse(_installments.text.trim()) ?? 12,
      graceDaysLate: int.tryParse(_grace.text.trim()) ?? 3,
      penaltyPerDayAfterGrace: int.tryParse(_penalty.text.trim()) ?? 100,
      policyYear: int.tryParse(_year.text.trim()) ?? DateTime.now().year,
    );
    await _service.updatePaymentPolicy(
      leaseId: widget.leaseId,
      policy: policy,
      regenerateInstallments: regenerate,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminRentalPaymentSaved)),
    );
  }

  Future<void> _runReminders() async {
    await _service.runDueReminders(leaseId: widget.leaseId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminRentalPaymentRemindersRun)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lease = _lease;
    if (lease == null) return const SizedBox.shrink();
    final fmt = DateFormat(s.isEnglish ? 'd MMM yyyy' : 'd MMM yyyy');
    final maxH = MediaQuery.sizeOf(context).height * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.adminRentalPaymentSettings,
                      style: AdminTheme.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(s.adminRentalPaymentSettingsHint, style: AdminTheme.caption),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(s.adminRentalPaymentRemindSection, style: AdminTheme.section),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _remindDays,
                    decoration: InputDecoration(
                      labelText: s.adminRentalPaymentRemindDaysLabel,
                      hintText: '2, 1',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(s.adminRentalPaymentRemindHint, style: AdminTheme.caption),
                  const SizedBox(height: 16),
                  Text(s.adminRentalPaymentYearSection, style: AdminTheme.section),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _year,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: s.adminRentalPaymentYearLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _installments,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: s.adminRentalPaymentInstallmentsLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.rentalPaymentDay(lease.paymentDayOfMonth),
                    style: AdminTheme.caption,
                  ),
                  const SizedBox(height: 16),
                  Text(s.adminRentalPaymentLateSection, style: AdminTheme.section),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _grace,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: s.adminRentalPaymentGraceLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _penalty,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: s.adminRentalPaymentPenaltyLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : () => _save(regenerate: false),
                    icon: const Icon(Icons.save_outlined),
                    label: Text(s.adminRentalPaymentSavePolicy),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _save(regenerate: true),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(s.adminRentalPaymentRegenerate),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _runReminders,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(s.adminRentalPaymentRunReminders),
                  ),
                  const SizedBox(height: 20),
                  Text(s.adminRentalPaymentSchedulePreview, style: AdminTheme.section),
                  const SizedBox(height: 8),
                  ...lease.paymentInstallments.map(
                    (inst) => _ScheduleInstallmentRow(
                      leaseId: lease.id,
                      inst: inst,
                      dateFmt: fmt,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleInstallmentRow extends StatelessWidget {
  const _ScheduleInstallmentRow({
    required this.leaseId,
    required this.inst,
    required this.dateFmt,
  });

  final String leaseId;
  final RentalPaymentInstallment inst;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    late final String statusLabel;
    if (inst.isAdminConfirmed) {
      statusLabel = s.rentalPaymentAdminConfirmed;
    } else if (inst.hasSlip) {
      statusLabel = s.rentalPaymentSlipReceived;
    } else if (inst.remindersSentDaysBefore.isEmpty) {
      statusLabel = s.rentalPaymentPending;
    } else {
      statusLabel = s.rentalPaymentReminded(
        inst.remindersSentDaysBefore.join(', '),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  inst.isSettled ? Icons.check_circle_outline : Icons.schedule,
                  size: 20,
                  color: inst.isSettled ? Colors.green : AppTheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.rentalPaymentRound(inst.sequence)} — ${dateFmt.format(inst.dueDate)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(statusLabel, style: AdminTheme.caption),
                      if (inst.isAdminConfirmed) ...[
                        const SizedBox(height: 2),
                        Text(
                          s.rentalPaymentAdminConfirmedBy(
                            inst.adminConfirmedBy ?? '',
                            dateFmt.format(inst.adminConfirmedAt!),
                          ),
                          style: AdminTheme.caption,
                        ),
                        if (inst.adminConfirmNote != null &&
                            inst.adminConfirmNote!.isNotEmpty)
                          Text(inst.adminConfirmNote!, style: AdminTheme.caption),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (!inst.isSettled) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => showRentalAdminConfirmPaymentDialog(
                    context,
                    leaseId: leaseId,
                    installmentId: inst.id,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(s.rentalPaymentAdminConfirmBtn),
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
