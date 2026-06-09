import '../data/demo_calendar_scenarios.dart';
import 'viewing_report.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.seekerNickname,
    required this.scheduledDate,
    required this.timeSlot,
    required this.status,
    this.leadId,
    this.listingId,
    this.listingCode,
    this.seekerPhone,
    this.locationLabel,
    this.lat,
    this.lng,
    this.adminNotes,
    this.assignedTo,
    this.transactionRef,
    this.viewingReport,
  });

  final String id;
  final String? leadId;
  final String? listingId;
  final String? listingCode;
  final String seekerNickname;
  final String? seekerPhone;
  final DateTime scheduledDate;
  final String timeSlot;
  final String status;
  final String? locationLabel;
  final double? lat;
  final double? lng;
  final String? adminNotes;
  final String? assignedTo;
  final String? transactionRef;
  final ViewingReport? viewingReport;

  static ViewingReport? _parseViewingReport(Map<String, dynamic> json) {
    final raw = json['follow_up'];
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final apptId = json['id']?.toString() ?? '';
    if (m['outcome'] != null && m['outcome'].toString().isNotEmpty) {
      return ViewingReport.fromJson({
        ...m,
        if (m['id'] == null) 'id': 'report-$apptId',
        'appointment_id': m['appointment_id'] ?? apptId,
      });
    }
    if (m['decision'] != null && m['decision'].toString().isNotEmpty) {
      return ViewingReport.fromLegacyFollowUp(
        m,
        appointmentId: apptId,
        leadId: json['lead_id'] as String?,
        listingCode: json['listing_code'] as String?,
        viewedDate: DateTime.tryParse(json['scheduled_date']?.toString() ?? ''),
        timeSlot: json['time_slot']?.toString(),
      );
    }
    return null;
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final dateStr = json['scheduled_date'] as String;
    return Appointment(
      id: json['id'] as String,
      leadId: json['lead_id'] as String?,
      listingId: json['listing_id'] as String?,
      listingCode: json['listing_code'] as String?,
      seekerNickname: json['seeker_nickname'] as String,
      seekerPhone: json['seeker_phone'] as String?,
      scheduledDate: DateTime.parse(dateStr),
      timeSlot: json['time_slot'] as String,
      status: json['status'] as String,
      locationLabel: json['location_label'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      adminNotes: json['admin_notes'] as String?,
      assignedTo: (json['guide_staff_id'] ?? json['assigned_to'])?.toString(),
      transactionRef: json['transaction_ref'] as String?,
      viewingReport: _parseViewingReport(json),
    );
  }

  static List<Appointment> demo() => DemoCalendarScenarios.buildAppointments();
}
