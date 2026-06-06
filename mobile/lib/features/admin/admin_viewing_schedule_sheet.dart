import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

class AdminViewingScheduleResult {
  const AdminViewingScheduleResult({
    required this.date,
    required this.timeSlot,
    this.adminNotes,
  });

  final DateTime date;
  final String timeSlot;
  final String? adminNotes;
}

/// ฟอร์มยืนยันนัดดู — ใช้ในแชทแอดมินหลังรับงานและคุยกับลูกค้าแล้ว
Future<AdminViewingScheduleResult?> showAdminViewingScheduleSheet(
  BuildContext context, {
  String? preferredSlot,
}) async {
  final s = context.s;
  final timeSlots = s.adminTimeSlots;

  var slot = preferredSlot;
  if (slot != null && slot.contains('·')) {
    slot = slot.split('·').last.trim();
  }
  if (slot == null || !timeSlots.contains(slot)) {
    slot = timeSlots.length > 2 ? timeSlots[2] : timeSlots.first;
  }

  DateTime? date = DateTime.now().add(const Duration(days: 1));
  final notesCtrl = TextEditingController();

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModal) {
          final sheetS = context.s;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  sheetS.adminConfirmViewingTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setModal(() => date = picked);
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    date == null
                        ? sheetS.selectDate
                        : '${date!.day}/${date!.month}/${date!.year + (sheetS.isEnglish ? 0 : 543)}',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: slot,
                  decoration: InputDecoration(
                    labelText: sheetS.adminTimeSlotLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: timeSlots
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModal(() => slot = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: sheetS.adminNotesLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: date != null && slot != null
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  child: Text(sheetS.adminSaveViewing),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  final notes = notesCtrl.text.trim();
  notesCtrl.dispose();
  if (ok != true || date == null || slot == null) return null;

  return AdminViewingScheduleResult(
    date: date!,
    timeSlot: slot!,
    adminNotes: notes.isEmpty ? null : notes,
  );
}
