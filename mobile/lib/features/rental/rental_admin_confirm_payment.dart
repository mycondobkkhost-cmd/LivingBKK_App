import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/rental_lease_service.dart';

/// แอดมินยืนยันรับเงินแล้ว (ไม่มีสลิปจากผู้เช่า) — ใช้ร่วมกันในแท็บชำระและ sheet ตั้งค่า
Future<void> showRentalAdminConfirmPaymentDialog(
  BuildContext context, {
  required String leaseId,
  required String installmentId,
}) async {
  final s = context.s;
  final noteCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.rentalPaymentAdminConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.rentalPaymentAdminConfirmHint, style: Theme.of(ctx).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: s.rentalPaymentAdminConfirmNote,
              hintText: s.rentalPaymentAdminConfirmNoteHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(s.rentalPaymentAdminConfirmSave),
        ),
      ],
    ),
  );
  if (ok != true) {
    noteCtrl.dispose();
    return;
  }
  final note = noteCtrl.text.trim();
  noteCtrl.dispose();
  final actor = AuthService.instance.displayEmail ?? 'แอดมิน';
  await RentalLeaseService.instance.adminConfirmPayment(
    leaseId: leaseId,
    installmentId: installmentId,
    confirmedBy: actor,
    note: note.isEmpty ? null : note,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(s.rentalPaymentAdminConfirmDone)),
  );
}
