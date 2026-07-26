class AdminAiFeedItem {
  const AdminAiFeedItem({
    required this.id,
    required this.eventType,
    required this.priority,
    required this.status,
    required this.title,
    required this.summary,
    this.suggestedAction,
    this.deepLink,
    this.threadId,
    this.listingId,
    this.listingCode,
    this.ownerInquiryId,
    this.confidence,
    required this.createdAt,
  });

  factory AdminAiFeedItem.fromJson(Map<String, dynamic> json) {
    return AdminAiFeedItem(
      id: json['id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'normal',
      status: json['status']?.toString() ?? 'open',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      suggestedAction: json['suggested_action']?.toString(),
      deepLink: json['deep_link']?.toString(),
      threadId: json['thread_id']?.toString(),
      listingId: json['listing_id']?.toString(),
      listingCode: json['listing_code']?.toString(),
      ownerInquiryId: json['owner_inquiry_id']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String eventType;
  final String priority;
  final String status;
  final String title;
  final String summary;
  final String? suggestedAction;
  final String? deepLink;
  final String? threadId;
  final String? listingId;
  final String? listingCode;
  final String? ownerInquiryId;
  final double? confidence;
  final DateTime createdAt;

  bool get isUrgent => priority == 'urgent' || priority == 'high';
}

class AdminUnifiedSearchHit {
  const AdminUnifiedSearchHit({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.threadId,
    this.listingId,
    this.listingCode,
    this.deepLink,
  });

  factory AdminUnifiedSearchHit.fromJson(Map<String, dynamic> json) {
    return AdminUnifiedSearchHit(
      kind: json['kind']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      threadId: json['thread_id']?.toString(),
      listingId: json['listing_id']?.toString(),
      listingCode: json['listing_code']?.toString(),
      deepLink: json['deep_link']?.toString(),
    );
  }

  final String kind;
  final String title;
  final String subtitle;
  final String? threadId;
  final String? listingId;
  final String? listingCode;
  final String? deepLink;
}
