class OwnerInquiryRow {
  const OwnerInquiryRow({
    required this.id,
    required this.code,
    required this.threadId,
    required this.listingCode,
    required this.inquiryType,
    required this.seekerQuestion,
    required this.status,
    this.listingId,
    this.ownerId,
    this.seekerContext = const {},
    this.ownerReplyRaw,
    this.ownerReplyRelay,
    this.createdAt,
  });

  factory OwnerInquiryRow.fromJson(Map<String, dynamic> json) {
    final ctx = json['seeker_context'];
    return OwnerInquiryRow(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      threadId: json['thread_id'] as String? ?? '',
      listingId: json['listing_id'] as String?,
      listingCode: json['listing_code'] as String? ?? '',
      inquiryType: json['inquiry_type'] as String? ?? 'general',
      seekerQuestion: json['seeker_question'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_owner',
      ownerId: json['owner_id'] as String?,
      seekerContext: ctx is Map
          ? Map<String, dynamic>.from(ctx)
          : const {},
      ownerReplyRaw: json['owner_reply_raw'] as String?,
      ownerReplyRelay: json['owner_reply_relay'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  final String id;
  final String code;
  final String threadId;
  final String? listingId;
  final String listingCode;
  final String inquiryType;
  final String seekerQuestion;
  final String status;
  final String? ownerId;
  final Map<String, dynamic> seekerContext;
  final String? ownerReplyRaw;
  final String? ownerReplyRelay;
  final DateTime? createdAt;

  bool get isPending => status == 'pending_owner';
}
