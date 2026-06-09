/// กิจกรรมปฏิทินหลังบ้าน — AI draft + canonical + field locks
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.eventType,
    required this.status,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.version,
    this.description,
    this.colorHint,
    this.leadId,
    this.listingId,
    this.listingCode,
    this.appointmentId,
    this.threadId,
    this.seekerUserId,
    this.ownerUserId,
    this.assignedTo,
    this.createdBy,
    this.locationLabel,
    this.lat,
    this.lng,
    this.ownerNotes,
    this.seekerNotes,
    this.aiDraft = const {},
    this.fieldLocks = const {},
    this.aiLastRunAt,
    this.humanEditedAt,
    this.humanEditedBy,
    this.externalEventId,
    this.externalCalendarProvider,
    this.externalSyncedAt,
  });

  final String id;
  final String eventType;
  final String status;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final String? colorHint;
  final String? leadId;
  final String? listingId;
  final String? listingCode;
  final String? appointmentId;
  final String? threadId;
  final String? seekerUserId;
  final String? ownerUserId;
  final String? assignedTo;
  final String? createdBy;
  final String? locationLabel;
  final double? lat;
  final double? lng;
  final String? ownerNotes;
  final String? seekerNotes;
  final Map<String, dynamic> aiDraft;
  final Map<String, String> fieldLocks;
  final int version;
  final DateTime? aiLastRunAt;
  final DateTime? humanEditedAt;
  final String? humanEditedBy;
  final String? externalEventId;
  final String? externalCalendarProvider;
  final DateTime? externalSyncedAt;

  bool get isAiDraft => status == 'ai_draft';

  bool get isHumanLockedTitle => fieldLocks['title'] == 'human';
  bool get isHumanLockedDescription => fieldLocks['description'] == 'human';
  bool get isHumanLockedStart => fieldLocks['start_at'] == 'human';
  bool get isHumanLockedEnd => fieldLocks['end_at'] == 'human';

  String get timeSlotLabel {
    String two(int n) => n.toString().padLeft(2, '0');
    final s = '${two(startAt.hour)}:${two(startAt.minute)}';
    final e = '${two(endAt.hour)}:${two(endAt.minute)}';
    return '$s-$e';
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      eventType: json['event_type']?.toString() ?? 'viewing',
      status: json['status']?.toString() ?? 'ai_draft',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      startAt: DateTime.parse(json['start_at'] as String).toLocal(),
      endAt: DateTime.parse(json['end_at'] as String).toLocal(),
      colorHint: json['color_hint']?.toString(),
      leadId: json['lead_id']?.toString(),
      listingId: json['listing_id']?.toString(),
      listingCode: json['listing_code']?.toString(),
      appointmentId: json['appointment_id']?.toString(),
      threadId: json['thread_id']?.toString(),
      seekerUserId: json['seeker_user_id']?.toString(),
      ownerUserId: json['owner_user_id']?.toString(),
      assignedTo: json['assigned_to']?.toString(),
      createdBy: json['created_by']?.toString(),
      locationLabel: json['location_label']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      ownerNotes: json['owner_notes']?.toString(),
      seekerNotes: json['seeker_notes']?.toString(),
      aiDraft: json['ai_draft'] is Map
          ? Map<String, dynamic>.from(json['ai_draft'] as Map)
          : const {},
      fieldLocks: _parseLocks(json['field_locks']),
      version: (json['version'] as num?)?.toInt() ?? 1,
      aiLastRunAt: _parseTs(json['ai_last_run_at']),
      humanEditedAt: _parseTs(json['human_edited_at']),
      humanEditedBy: json['human_edited_by']?.toString(),
      externalEventId: json['external_event_id']?.toString(),
      externalCalendarProvider: json['external_calendar_provider']?.toString(),
      externalSyncedAt: _parseTs(json['external_synced_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_type': eventType,
        'status': status,
        'title': title,
        'description': description,
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': endAt.toUtc().toIso8601String(),
        'color_hint': colorHint,
        'lead_id': leadId,
        'listing_id': listingId,
        'listing_code': listingCode,
        'appointment_id': appointmentId,
        'thread_id': threadId,
        'seeker_user_id': seekerUserId,
        'owner_user_id': ownerUserId,
        'assigned_to': assignedTo,
        'created_by': createdBy,
        'location_label': locationLabel,
        'lat': lat,
        'lng': lng,
        'owner_notes': ownerNotes,
        'seeker_notes': seekerNotes,
        'ai_draft': aiDraft,
        'field_locks': fieldLocks,
        'version': version,
        'ai_last_run_at': aiLastRunAt?.toUtc().toIso8601String(),
        'human_edited_at': humanEditedAt?.toUtc().toIso8601String(),
        'human_edited_by': humanEditedBy,
        'external_event_id': externalEventId,
        'external_calendar_provider': externalCalendarProvider,
        'external_synced_at': externalSyncedAt?.toUtc().toIso8601String(),
      };

  CalendarEvent copyWith({
    String? eventType,
    String? status,
    String? title,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    String? colorHint,
    String? locationLabel,
    String? ownerNotes,
    String? seekerNotes,
    Map<String, String>? fieldLocks,
    int? version,
    DateTime? humanEditedAt,
    String? humanEditedBy,
    String? externalEventId,
    DateTime? externalSyncedAt,
    DateTime? aiLastRunAt,
  }) {
    return CalendarEvent(
      id: id,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      colorHint: colorHint ?? this.colorHint,
      leadId: leadId,
      listingId: listingId,
      listingCode: listingCode,
      appointmentId: appointmentId,
      threadId: threadId,
      seekerUserId: seekerUserId,
      ownerUserId: ownerUserId,
      assignedTo: assignedTo,
      createdBy: createdBy,
      locationLabel: locationLabel ?? this.locationLabel,
      lat: lat,
      lng: lng,
      ownerNotes: ownerNotes ?? this.ownerNotes,
      seekerNotes: seekerNotes ?? this.seekerNotes,
      aiDraft: aiDraft,
      fieldLocks: fieldLocks ?? this.fieldLocks,
      version: version ?? this.version,
      aiLastRunAt: aiLastRunAt ?? this.aiLastRunAt,
      humanEditedAt: humanEditedAt ?? this.humanEditedAt,
      humanEditedBy: humanEditedBy ?? this.humanEditedBy,
      externalEventId: externalEventId ?? this.externalEventId,
      externalCalendarProvider: externalCalendarProvider,
      externalSyncedAt: externalSyncedAt ?? this.externalSyncedAt,
    );
  }

  static Map<String, String> _parseLocks(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  static DateTime? _parseTs(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }
}
