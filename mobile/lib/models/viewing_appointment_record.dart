/// แท็กบันทึกการนัดชม — snapshot ครบทุกรายละเอียด (immutable ต่อเวอร์ชัน)
class ViewingAppointmentRecord {
  const ViewingAppointmentRecord({
    required this.appointmentId,
    required this.seekerNickname,
    required this.scheduledDate,
    required this.timeSlot,
    required this.status,
    required this.updatedAt,
    this.transactionRef,
    this.viewingRequestCode,
    this.clientTagCode,
    this.presenterTagCode,
    this.leadId,
    this.threadId,
    this.listingId,
    this.listingCode,
    this.listingTitle,
    this.locationLabel,
    this.seekerPhone,
    this.guideStaffId,
    this.guideName,
    this.guidePhone,
    this.lat,
    this.lng,
    this.clientSnapshot = const {},
  });

  final String appointmentId;
  final String? transactionRef;
  final String? viewingRequestCode;
  final String? clientTagCode;
  final String? presenterTagCode;
  final String? leadId;
  final String? threadId;
  final String? listingId;
  final String? listingCode;
  final String? listingTitle;
  final String seekerNickname;
  final String? seekerPhone;
  final DateTime scheduledDate;
  final String timeSlot;
  final String status;
  final String? locationLabel;
  final double? lat;
  final double? lng;
  final String? guideStaffId;
  final String? guideName;
  final String? guidePhone;
  final Map<String, String> clientSnapshot;
  final DateTime updatedAt;

  ViewingAppointmentRecord copyWith({
    String? transactionRef,
    String? viewingRequestCode,
    String? clientTagCode,
    String? presenterTagCode,
    String? leadId,
    String? threadId,
    String? listingId,
    String? listingCode,
    String? listingTitle,
    String? seekerNickname,
    String? seekerPhone,
    DateTime? scheduledDate,
    String? timeSlot,
    String? status,
    String? locationLabel,
    double? lat,
    double? lng,
    String? guideStaffId,
    String? guideName,
    String? guidePhone,
    Map<String, String>? clientSnapshot,
    DateTime? updatedAt,
  }) {
    return ViewingAppointmentRecord(
      appointmentId: appointmentId,
      transactionRef: transactionRef ?? this.transactionRef,
      viewingRequestCode: viewingRequestCode ?? this.viewingRequestCode,
      clientTagCode: clientTagCode ?? this.clientTagCode,
      presenterTagCode: presenterTagCode ?? this.presenterTagCode,
      leadId: leadId ?? this.leadId,
      threadId: threadId ?? this.threadId,
      listingId: listingId ?? this.listingId,
      listingCode: listingCode ?? this.listingCode,
      listingTitle: listingTitle ?? this.listingTitle,
      seekerNickname: seekerNickname ?? this.seekerNickname,
      seekerPhone: seekerPhone ?? this.seekerPhone,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      locationLabel: locationLabel ?? this.locationLabel,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      guideStaffId: guideStaffId ?? this.guideStaffId,
      guideName: guideName ?? this.guideName,
      guidePhone: guidePhone ?? this.guidePhone,
      clientSnapshot: clientSnapshot ?? this.clientSnapshot,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'appointment_id': appointmentId,
        if (transactionRef != null) 'transaction_ref': transactionRef,
        if (viewingRequestCode != null) 'viewing_request_code': viewingRequestCode,
        if (clientTagCode != null) 'client_tag_code': clientTagCode,
        if (presenterTagCode != null) 'presenter_tag_code': presenterTagCode,
        if (leadId != null) 'lead_id': leadId,
        if (threadId != null) 'thread_id': threadId,
        if (listingId != null) 'listing_id': listingId,
        if (listingCode != null) 'listing_code': listingCode,
        if (listingTitle != null) 'listing_title': listingTitle,
        'seeker_nickname': seekerNickname,
        if (seekerPhone != null) 'seeker_phone': seekerPhone,
        'scheduled_date': scheduledDate.toIso8601String(),
        'time_slot': timeSlot,
        'status': status,
        if (locationLabel != null) 'location_label': locationLabel,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (guideStaffId != null) 'guide_staff_id': guideStaffId,
        if (guideName != null) 'guide_name': guideName,
        if (guidePhone != null) 'guide_phone': guidePhone,
        if (clientSnapshot.isNotEmpty) 'client_snapshot': clientSnapshot,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ViewingAppointmentRecord.fromJson(Map<String, dynamic> json) {
    return ViewingAppointmentRecord(
      appointmentId: json['appointment_id']?.toString() ?? '',
      transactionRef: json['transaction_ref']?.toString(),
      viewingRequestCode: json['viewing_request_code']?.toString(),
      clientTagCode: json['client_tag_code']?.toString(),
      presenterTagCode: json['presenter_tag_code']?.toString(),
      leadId: json['lead_id']?.toString(),
      threadId: json['thread_id']?.toString(),
      listingId: json['listing_id']?.toString(),
      listingCode: json['listing_code']?.toString(),
      listingTitle: json['listing_title']?.toString(),
      seekerNickname: json['seeker_nickname']?.toString() ?? '—',
      seekerPhone: json['seeker_phone']?.toString(),
      scheduledDate: DateTime.tryParse(json['scheduled_date']?.toString() ?? '') ??
          DateTime.now(),
      timeSlot: json['time_slot']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      locationLabel: json['location_label']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      guideStaffId: json['guide_staff_id']?.toString(),
      guideName: json['guide_name']?.toString(),
      guidePhone: json['guide_phone']?.toString(),
      clientSnapshot: _parseSnapshot(json['client_snapshot']),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, String> _parseSnapshot(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}
