/// บันทึกผลหลังพาชม — โน้ตแอดมิน (เชื่อม lead · นัด · ทรัพย์)
class ViewingReport {
  const ViewingReport({
    required this.id,
    required this.appointmentId,
    this.leadId,
    this.listingId,
    this.listingCode,
    this.locationLabel,
    required this.viewedDate,
    required this.timeSlot,
    this.guideStaffId,
    required this.outcome,
    required this.customerFeedback,
    required this.customerWants,
    this.teamNotes,
    required this.decision,
    this.intent,
    this.seekerNickname,
    this.seekerPhone,
    this.recordedAt,
  });

  final String id;
  final String appointmentId;
  final String? leadId;
  final String? listingId;
  final String? listingCode;
  final String? locationLabel;
  final DateTime viewedDate;
  final String timeSlot;
  final String? guideStaffId;
  /// ผลการพาชมโดยรวม
  final String outcome;
  final String customerFeedback;
  final String customerWants;
  final String? teamNotes;
  /// `continue` | `closed`
  final String decision;
  final String? intent;
  final String? seekerNickname;
  final String? seekerPhone;
  final DateTime? recordedAt;

  bool get isContinue => decision == 'continue';
  bool get isClosed => decision == 'closed';
  bool get isEmpty => outcome.isEmpty;

  /// ลูกค้าไม่มาตามนัด — แสดงในปฏิทินแยกจากเคสอื่น
  bool get isNoShow {
    final o = outcome.toLowerCase();
    return outcome.contains('ลูกค้าไม่มา') ||
        o.contains('no-show') ||
        o.contains('no show') ||
        o.contains('customer no-show');
  }

  factory ViewingReport.fromJson(Map<String, dynamic> json) {
    final dateStr = json['viewed_date'] as String? ?? json['scheduled_date'] as String?;
    return ViewingReport(
      id: json['id']?.toString() ?? '',
      appointmentId: json['appointment_id']?.toString() ?? '',
      leadId: json['lead_id'] as String?,
      listingId: json['listing_id'] as String?,
      listingCode: json['listing_code'] as String?,
      locationLabel: json['location_label'] as String?,
      viewedDate: dateStr != null
          ? DateTime.parse(dateStr)
          : DateTime.now(),
      timeSlot: json['time_slot']?.toString() ?? '',
      guideStaffId: json['guide_staff_id'] as String?,
      outcome: json['outcome']?.toString() ?? '',
      customerFeedback: json['customer_feedback']?.toString() ?? '',
      customerWants: json['customer_wants']?.toString() ?? '',
      teamNotes: json['team_notes'] as String?,
      decision: json['decision']?.toString() ?? '',
      intent: json['intent'] as String?,
      seekerNickname: json['seeker_nickname'] as String?,
      seekerPhone: json['seeker_phone'] as String?,
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'appointment_id': appointmentId,
        if (leadId != null) 'lead_id': leadId,
        if (listingId != null) 'listing_id': listingId,
        if (listingCode != null) 'listing_code': listingCode,
        if (locationLabel != null) 'location_label': locationLabel,
        'viewed_date': viewedDate.toIso8601String().split('T').first,
        'time_slot': timeSlot,
        if (guideStaffId != null) 'guide_staff_id': guideStaffId,
        'outcome': outcome,
        'customer_feedback': customerFeedback,
        'customer_wants': customerWants,
        if (teamNotes != null && teamNotes!.trim().isNotEmpty)
          'team_notes': teamNotes!.trim(),
        'decision': decision,
        if (intent != null) 'intent': intent,
        if (seekerNickname != null) 'seeker_nickname': seekerNickname,
        if (seekerPhone != null) 'seeker_phone': seekerPhone,
        if (recordedAt != null) 'recorded_at': recordedAt!.toUtc().toIso8601String(),
      };

  /// แปลงจาก follow_up เก่า (backward compat)
  factory ViewingReport.fromLegacyFollowUp(
    Map<String, dynamic> json, {
    required String appointmentId,
    String? leadId,
    String? listingCode,
    DateTime? viewedDate,
    String? timeSlot,
  }) {
    return ViewingReport(
      id: 'legacy-$appointmentId',
      appointmentId: appointmentId,
      leadId: leadId,
      listingCode: listingCode,
      viewedDate: viewedDate ?? DateTime.now(),
      timeSlot: timeSlot ?? '',
      outcome: json['reason']?.toString() ?? '',
      customerFeedback: '',
      customerWants: '',
      decision: json['decision']?.toString() ?? '',
      intent: json['intent'] as String?,
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'].toString())
          : null,
    );
  }
}

enum ViewingFollowUpDecision { continueFollow, closeCase }

enum ViewingFollowUpIntent { consider, findMore, both }

class ViewingReportSheetResult {
  const ViewingReportSheetResult({
    required this.decision,
    this.intent,
    required this.outcome,
    required this.customerFeedback,
    required this.customerWants,
    this.teamNotes,
  });

  final ViewingFollowUpDecision decision;
  final ViewingFollowUpIntent? intent;
  final String outcome;
  final String customerFeedback;
  final String customerWants;
  final String? teamNotes;
}
