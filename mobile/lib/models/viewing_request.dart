enum ViewingRequestSource { customer, coAgent, adminPhone }

enum ViewingRequestStatus {
  draft,
  submitted,
  sentToOwner,
  ownerConfirmed,
  ownerDeclined,
  cancelled,
}

class ViewingRequest {
  const ViewingRequest({
    required this.id,
    required this.code,
    required this.listingId,
    required this.listingCode,
    required this.listingTitle,
    required this.scheduledAt,
    required this.clientTagId,
    required this.clientTagCode,
    required this.source,
    required this.status,
    required this.createdAt,
    required this.createdByUserId,
    this.presenterTagId,
    this.presenterTagCode,
    this.threadId,
    this.projectName,
    this.appointmentId,
  });

  final String id;
  final String code;
  final String listingId;
  final String listingCode;
  final String listingTitle;
  final String? projectName;
  final DateTime scheduledAt;
  final String clientTagId;
  final String clientTagCode;
  final String? presenterTagId;
  final String? presenterTagCode;
  final ViewingRequestSource source;
  final ViewingRequestStatus status;
  final DateTime createdAt;
  final String createdByUserId;
  final String? threadId;
  final String? appointmentId;

  ViewingRequest copyWith({
    ViewingRequestStatus? status,
    String? appointmentId,
    DateTime? scheduledAt,
  }) {
    return ViewingRequest(
      id: id,
      code: code,
      listingId: listingId,
      listingCode: listingCode,
      listingTitle: listingTitle,
      projectName: projectName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      clientTagId: clientTagId,
      clientTagCode: clientTagCode,
      presenterTagId: presenterTagId,
      presenterTagCode: presenterTagCode,
      source: source,
      status: status ?? this.status,
      createdAt: createdAt,
      createdByUserId: createdByUserId,
      threadId: threadId,
      appointmentId: appointmentId ?? this.appointmentId,
    );
  }
}
