import '../utils/reference_codes.dart';

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
      assignedTo: json['assigned_to'] as String?,
      transactionRef: json['transaction_ref'] as String?,
    );
  }

  static List<Appointment> demo() => [
        Appointment(
          id: 'demo-appt-1',
          leadId: 'demo-lead-1',
          listingCode: 'RENT-CD-2026-000001',
          transactionRef: ReferenceCodes.demoApptRef('demo-appt-1'),
          seekerNickname: 'น้องบี',
          seekerPhone: '0812345678',
          scheduledDate: DateTime.now().add(const Duration(days: 2)),
          timeSlot: '15:00 – 18:00 น.',
          status: 'pending',
          locationLabel: 'โซน BTS ทองหล่อ (โดยประมาณ)',
          lat: 13.7234,
          lng: 100.5794,
        ),
      ];
}
