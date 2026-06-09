import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/viewing_report.dart';
import '../../services/viewing_report_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/appointment_staff_labels.dart';
import 'admin_viewing_follow_up_actions.dart';

/// ประวัติพาชมทรัพย์ — เชื่อม lead · เบอร์ลูกค้า · รายงานทุกครั้ง
class AdminViewingHistoryPanel extends StatefulWidget {
  const AdminViewingHistoryPanel({
    super.key,
    required this.leadId,
    this.seekerPhone,
    this.onOpenReport,
  });

  final String leadId;
  final String? seekerPhone;
  final void Function(ViewingReport report)? onOpenReport;

  @override
  State<AdminViewingHistoryPanel> createState() => AdminViewingHistoryPanelState();
}

class AdminViewingHistoryPanelState extends State<AdminViewingHistoryPanel> {
  /// โหลดใหม่หลังบันทึกผลพาชม
  Future<void> reload() => _load();
  final _repo = ViewingReportRepository();
  bool _loading = true;
  List<ViewingReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final byLead = await _repo.forLead(widget.leadId);
    final byPhone = await _repo.forSeekerPhone(widget.seekerPhone);
    final merged = <String, ViewingReport>{};
    for (final r in [...byLead, ...byPhone]) {
      merged[r.id] = r;
    }
    final list = merged.values.toList()
      ..sort((a, b) {
        final ad = a.recordedAt ?? a.viewedDate;
        final bd = b.recordedAt ?? b.viewedDate;
        return bd.compareTo(ad);
      });
    if (!mounted) return;
    setState(() {
      _reports = list;
      _loading = false;
    });
  }

  String _dateLabel(ViewingReport r, AppStrings s) {
    final d = r.viewedDate;
    final y = s.isEnglish ? d.year : d.year + 543;
    return '${d.day}/${d.month}/$y';
  }

  void _openDetail(ViewingReport r) {
    showAdminViewingReportDetail(context, report: r, s: context.s);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.adminViewingHistoryTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
                if (!_loading)
                  Text(
                    s.adminViewingHistoryCount(_reports.length),
                    style: AdminTheme.caption,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(s.adminViewingHistorySubtitle, style: AdminTheme.caption),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_reports.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  s.adminViewingHistoryEmpty,
                  style: AdminTheme.caption,
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._reports.map((r) => _ReportTile(
                    report: r,
                    s: s,
                    dateLabel: _dateLabel(r, s),
                    onTap: () {
                      if (widget.onOpenReport != null) {
                        widget.onOpenReport!(r);
                      } else {
                        _openDetail(r);
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.report,
    required this.s,
    required this.dateLabel,
    this.onTap,
  });

  final ViewingReport report;
  final AppStrings s;
  final String dateLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final guide = AppointmentStaffLabels.label(r.guideStaffId, isEn: s.isEnglish);
    final badge = s.adminViewingFollowUpBadge(r.decision);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AdminTheme.surfaceMuted.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r.listingCode ?? '—'} · $dateLabel · ${r.timeSlot}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: r.isContinue
                            ? AppTheme.primary.withOpacity(0.12)
                            : AdminTheme.textMuted.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                if (r.locationLabel != null && r.locationLabel!.isNotEmpty)
                  Text(r.locationLabel!, style: AdminTheme.caption),
                const SizedBox(height: 6),
                Text(
                  s.adminViewingHistoryGuideLine(guide),
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 6),
                _line(s.adminViewingReportOutcomeShort, r.outcome),
                _line(s.adminViewingReportFeedbackShort, r.customerFeedback),
                _line(s.adminViewingReportWantsShort, r.customerWants),
                if (r.teamNotes != null && r.teamNotes!.isNotEmpty)
                  _line(s.adminViewingReportNotesShort, r.teamNotes!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, height: 1.35),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
