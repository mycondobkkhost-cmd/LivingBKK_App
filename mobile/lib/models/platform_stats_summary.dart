/// สรุปตัวเลขจาก `platform_stats_daily` สำหรับหน้ารายงาน
class PlatformStatsSummary {
  const PlatformStatsSummary({
    this.totalLeads = 0,
    this.totalAccepted = 0,
    this.totalNewLeads = 0,
    this.totalAppointments = 0,
    this.totalConfirmed = 0,
    this.totalCompleted = 0,
    this.dayCount = 0,
  });

  final int totalLeads;
  final int totalAccepted;
  final int totalNewLeads;
  final int totalAppointments;
  final int totalConfirmed;
  final int totalCompleted;
  final int dayCount;

  double get leadAcceptRate =>
      totalLeads == 0 ? 0 : totalAccepted / totalLeads;

  double get apptConfirmRate =>
      totalAppointments == 0 ? 0 : totalConfirmed / totalAppointments;

  double get apptCompleteRate =>
      totalAppointments == 0 ? 0 : totalCompleted / totalAppointments;

  static PlatformStatsSummary fromRows(List<Map<String, dynamic>> rows) {
    var leads = 0;
    var accepted = 0;
    var newLeads = 0;
    var appts = 0;
    var confirmed = 0;
    var completed = 0;

    for (final row in rows) {
      leads += (row['lead_count'] as num?)?.toInt() ?? 0;
      accepted += (row['accepted_count'] as num?)?.toInt() ?? 0;
      newLeads += (row['new_count'] as num?)?.toInt() ?? 0;
      appts += (row['appointment_count'] as num?)?.toInt() ?? 0;
      confirmed += (row['appointment_confirmed_count'] as num?)?.toInt() ?? 0;
      completed += (row['appointment_completed_count'] as num?)?.toInt() ?? 0;
    }

    return PlatformStatsSummary(
      totalLeads: leads,
      totalAccepted: accepted,
      totalNewLeads: newLeads,
      totalAppointments: appts,
      totalConfirmed: confirmed,
      totalCompleted: completed,
      dayCount: rows.length,
    );
  }
}
