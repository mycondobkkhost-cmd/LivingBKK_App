import '../features/admin/admin_viewing_follow_up_actions.dart';
import '../models/appointment.dart';
import 'in_app_notification_hub.dart';
import 'local_prefs_service.dart';

/// สรุปงานปฏิทินนัดชมที่ต้องดูแล — แจ้งเตือนภาพรวมหลังบ้าน
class ViewingCalendarAlertSummary {
  const ViewingCalendarAlertSummary({
    this.unassigned = 0,
    this.awaitingConfirm = 0,
    this.newCases = 0,
    this.unreadReports = 0,
    this.postViewing = 0,
    this.pendingTotal = 0,
  });

  final int unassigned;
  final int awaitingConfirm;
  /// นัดที่ยังไม่เคยเปิดดูในปฏิทิน
  final int newCases;
  /// รายงานหลังพาชมที่ยังไม่เคยเปิดดู
  final int unreadReports;
  final int postViewing;
  final int pendingTotal;

  int get attentionTotal =>
      unassigned + awaitingConfirm + newCases + postViewing;

  bool get hasAny => attentionTotal > 0;

  /// badge บนไอคอนปฏิทิน — เฉพาะที่ยังไม่ได้เข้าไปดู
  int get navBadgeCount => newCases + unreadReports;
}

abstract final class ViewingCalendarAlertService {
  static const _seenApptIdsKey = 'viewing_calendar_seen_appt_ids_v1';
  static const _seenReportSigKey = 'viewing_calendar_seen_report_sigs_v1';
  static const _lastBannerTotalKey = 'viewing_calendar_last_banner_total_v1';

  static int lastUnreadNavBadge = 0;

  static Future<ViewingCalendarAlertSummary> analyze(
    List<Appointment> items,
  ) async {
    await LocalPrefsService.instance.init();
    final seenAppts =
        (await LocalPrefsService.instance.getStringList(_seenApptIdsKey))
            .toSet();
    final seenReports =
        (await LocalPrefsService.instance.getStringList(_seenReportSigKey))
            .toSet();

    var unassigned = 0;
    var awaitingConfirm = 0;
    var newCases = 0;
    var unreadReports = 0;
    var postViewing = 0;
    var pendingTotal = 0;

    for (final a in items) {
      if (a.status == 'cancelled') continue;

      final hasStaff =
          a.assignedTo != null && a.assignedTo!.trim().isNotEmpty;
      if (a.status == 'pending') {
        pendingTotal++;
        if (!hasStaff) {
          unassigned++;
        } else {
          awaitingConfirm++;
        }
      }

      if (!seenAppts.contains(a.id)) newCases++;

      if (appointmentEligibleForFollowUp(a)) {
        postViewing++;
        continue;
      }
      final report = a.viewingReport;
      if (report != null && !report.isEmpty) {
        final sig = '${a.id}:${report.outcome}:${report.recordedAt?.toIso8601String() ?? ''}';
        if (!seenReports.contains(sig)) {
          unreadReports++;
          postViewing++;
        }
      }
    }

    final summary = ViewingCalendarAlertSummary(
      unassigned: unassigned,
      awaitingConfirm: awaitingConfirm,
      newCases: newCases,
      unreadReports: unreadReports,
      postViewing: postViewing,
      pendingTotal: pendingTotal,
    );
    lastUnreadNavBadge = summary.navBadgeCount;
    return summary;
  }

  /// แบนเนอร์ภาพรวม — แสดงเมื่อจำนวนงานเปลี่ยนหรือ `force`
  static Future<void> publishOverviewBanner({
    required ViewingCalendarAlertSummary summary,
    required String message,
    bool force = false,
  }) async {
    if (!summary.hasAny) return;
    await LocalPrefsService.instance.init();
    final last =
        await LocalPrefsService.instance.getInt(_lastBannerTotalKey) ?? -1;
    if (!force && last == summary.attentionTotal) return;

    InAppNotificationHub.instance.show(message, countAsUnread: false);
    await LocalPrefsService.instance
        .setInt(_lastBannerTotalKey, summary.attentionTotal);
  }

  static Future<void> markSnapshot(List<Appointment> items) async {
    await LocalPrefsService.instance.init();
    final ids = items.map((a) => a.id).toList();
    final reportSigs = <String>[];
    for (final a in items) {
      final r = a.viewingReport;
      if (r == null || r.isEmpty) continue;
      reportSigs.add(
        '${a.id}:${r.outcome}:${r.recordedAt?.toIso8601String() ?? ''}',
      );
    }
    await LocalPrefsService.instance.setStringList(_seenApptIdsKey, ids);
    await LocalPrefsService.instance.setStringList(_seenReportSigKey, reportSigs);
  }
}
