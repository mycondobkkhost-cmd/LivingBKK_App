import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/appointment.dart';
import '../../models/viewing_report.dart';
import '../../services/appointment_repository.dart';
import '../../services/viewing_ops_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/appointment_staff_labels.dart';
import 'admin_viewing_follow_up_sheet.dart';

Future<void> showAdminViewingReportDetail(
  BuildContext context, {
  required ViewingReport report,
  required AppStrings s,
}) {
  final guide = AppointmentStaffLabels.label(report.guideStaffId, isEn: s.isEnglish);
  final d = report.viewedDate;
  final y = s.isEnglish ? d.year : d.year + 543;
  final dateLabel = '${d.day}/${d.month}/$y';

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) {
      final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${report.listingCode ?? '—'} · $dateLabel · ${report.timeSlot}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              if (report.locationLabel != null && report.locationLabel!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(report.locationLabel!, style: AdminTheme.caption),
              ],
              const SizedBox(height: 8),
              Text(
                s.adminViewingHistoryGuideLine(guide),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              _reportDetailBlock(s.adminViewingReportOutcomeShort, report.outcome),
              _reportDetailBlock(s.adminViewingReportFeedbackShort, report.customerFeedback),
              _reportDetailBlock(s.adminViewingReportWantsShort, report.customerWants),
              if (report.teamNotes != null && report.teamNotes!.isNotEmpty)
                _reportDetailBlock(s.adminViewingReportNotesShort, report.teamNotes!),
              const SizedBox(height: 8),
              if (report.isNoShow)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    s.adminCalendarNoShowBadge,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              Text(
                s.adminViewingFollowUpBadge(report.decision),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: report.isContinue ? AppTheme.primary : AdminTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _reportDetailBlock(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, height: 1.45)),
      ],
    ),
  );
}

Future<ViewingReport?> _resolveExistingReport(Appointment appointment) async {
  if (appointment.viewingReport != null && !appointment.viewingReport!.isEmpty) {
    return appointment.viewingReport;
  }
  final fresh = await AppointmentRepository().fetchById(appointment.id);
  final report = fresh?.viewingReport;
  if (report != null && !report.isEmpty) return report;
  return null;
}

Future<void> runAdminViewingFollowUp(
  BuildContext context, {
  required Appointment appointment,
  String? listingTitle,
  String? seekerNickname,
  String? seekerPhone,
  VoidCallback? onRecorded,
  bool popParentSheetOnDone = false,
}) async {
  final s = context.s;
  final existing = await _resolveExistingReport(appointment);
  if (existing != null) {
    if (!context.mounted) return;
    await showAdminViewingReportDetail(context, report: existing, s: s);
    return;
  }

  final result = await showAdminViewingFollowUpSheet(
    context,
    listingCode: appointment.listingCode,
    timeSlot: appointment.timeSlot,
    viewedDateLabel:
        '${appointment.scheduledDate.day}/${appointment.scheduledDate.month}/${appointment.scheduledDate.year + (s.isEnglish ? 0 : 543)}',
  );
  if (result == null || !context.mounted) return;

  try {
    final ops = ViewingOpsRepository();
    final roomId = await ops.recordViewingReport(
      appointment: appointment,
      input: result,
      s: s,
      listingTitle: listingTitle,
      seekerNickname: seekerNickname,
      seekerPhone: seekerPhone,
    );
    if (!context.mounted) return;
    onRecorded?.call();
    if (popParentSheetOnDone && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (result.decision == ViewingFollowUpDecision.continueFollow) {
      if (roomId != null && roomId.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.adminViewingReportSavedContinue)),
        );
        context.push('/admin/chat/$roomId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.adminViewingReportSavedChatPending)),
        );
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminViewingReportSavedClose)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }
}

bool appointmentEligibleForFollowUp(Appointment a) {
  if (a.status == 'cancelled') return false;
  if (a.viewingReport != null && !a.viewingReport!.isEmpty) return false;
  final today = DateTime.now();
  final day = DateTime(a.scheduledDate.year, a.scheduledDate.month, a.scheduledDate.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  return !day.isAfter(todayDay);
}

bool appointmentHasViewingReport(Appointment a) =>
    a.viewingReport != null && !a.viewingReport!.isEmpty;

bool appointmentIsNoShow(Appointment a) =>
    a.viewingReport != null && a.viewingReport!.isNoShow;
