import '../l10n/app_strings.dart';

enum ChatMessageRole { user, ai, system, adminNotice }

enum ChatMessageLinkKind {
  listing,
  projectUnits,
  requirementForm,
  viewingForm,
  profileTag,
  viewingRequest,
  viewingLocation,
  viewingAppointment,
}

class ChatMessageLink {
  const ChatMessageLink({
    required this.label,
    required this.kind,
    this.listingId = '',
    this.projectName,
    this.refCode = '',
  });

  factory ChatMessageLink.fromJson(Map<String, dynamic> json) {
    return ChatMessageLink(
      label: json['label']?.toString() ?? '',
      kind: _kindFromString(json['kind']?.toString() ?? 'listing'),
      listingId:
          json['listingId']?.toString() ?? json['listing_id']?.toString() ?? '',
      projectName:
          json['projectName']?.toString() ?? json['project_name']?.toString(),
      refCode: json['refCode']?.toString() ?? json['ref_code']?.toString() ?? '',
    );
  }

  factory ChatMessageLink.profileTag(String code, String label) {
    return ChatMessageLink(label: label, kind: ChatMessageLinkKind.profileTag, refCode: code);
  }

  factory ChatMessageLink.viewingRequest(String code, String label) {
    return ChatMessageLink(
      label: label,
      kind: ChatMessageLinkKind.viewingRequest,
      refCode: code,
    );
  }

  factory ChatMessageLink.requirementForm(AppStrings s) {
    return ChatMessageLink(
      label: s.chatLinkFillRequirement,
      kind: ChatMessageLinkKind.requirementForm,
    );
  }

  factory ChatMessageLink.viewingForm(AppStrings s) {
    return ChatMessageLink(
      label: s.chatLinkBookViewing,
      kind: ChatMessageLinkKind.viewingForm,
    );
  }

  factory ChatMessageLink.viewingLocation({
    required String label,
    required String mapsUrl,
  }) {
    return ChatMessageLink(
      label: label,
      kind: ChatMessageLinkKind.viewingLocation,
      refCode: mapsUrl,
    );
  }

  factory ChatMessageLink.viewingAppointment({
    required String label,
    required String appointmentId,
  }) {
    return ChatMessageLink(
      label: label,
      kind: ChatMessageLinkKind.viewingAppointment,
      refCode: appointmentId,
    );
  }

  final String label;
  final ChatMessageLinkKind kind;
  final String listingId;
  final String? projectName;
  final String refCode;

  bool get isFormAction =>
      kind == ChatMessageLinkKind.requirementForm ||
      kind == ChatMessageLinkKind.viewingForm;

  bool get isListingAction =>
      kind == ChatMessageLinkKind.listing ||
      kind == ChatMessageLinkKind.projectUnits;

  Map<String, dynamic> toJson() => {
        'label': label,
        'kind': _kindToString(kind),
        if (listingId.isNotEmpty) 'listingId': listingId,
        if (projectName != null) 'projectName': projectName,
        if (refCode.isNotEmpty) 'refCode': refCode,
      };

  static ChatMessageLinkKind _kindFromString(String raw) {
    switch (raw) {
      case 'projectUnits':
      case 'project_units':
        return ChatMessageLinkKind.projectUnits;
      case 'requirement_form':
        return ChatMessageLinkKind.requirementForm;
      case 'viewing_form':
        return ChatMessageLinkKind.viewingForm;
      case 'profile_tag':
        return ChatMessageLinkKind.profileTag;
      case 'viewing_request':
        return ChatMessageLinkKind.viewingRequest;
      case 'viewing_location':
        return ChatMessageLinkKind.viewingLocation;
      case 'viewing_appointment':
        return ChatMessageLinkKind.viewingAppointment;
      default:
        return ChatMessageLinkKind.listing;
    }
  }

  static String _kindToString(ChatMessageLinkKind kind) {
    switch (kind) {
      case ChatMessageLinkKind.projectUnits:
        return 'projectUnits';
      case ChatMessageLinkKind.requirementForm:
        return 'requirement_form';
      case ChatMessageLinkKind.viewingForm:
        return 'viewing_form';
      case ChatMessageLinkKind.profileTag:
        return 'profile_tag';
      case ChatMessageLinkKind.viewingRequest:
        return 'viewing_request';
      case ChatMessageLinkKind.viewingLocation:
        return 'viewing_location';
      case ChatMessageLinkKind.viewingAppointment:
        return 'viewing_appointment';
      case ChatMessageLinkKind.listing:
        return 'listing';
    }
  }
}

class ChatMessage {
  /// โน้ตภายในแอดมิน — ลูกค้าไม่เห็น (ใช้กับ role admin_notice)
  static const adminInternalPrefix = '🔒[โน้ตแอดมิน] ';

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    DateTime? createdAt,
    this.requiresAdmin = false,
    this.links = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  /// โน้ตบันทึกผลพาชม — แสดงเฉพาะแอดมิน
  bool get isAdminInternal =>
      role == ChatMessageRole.adminNotice &&
      text.startsWith(adminInternalPrefix);

  String get displayText =>
      isAdminInternal ? text.substring(adminInternalPrefix.length) : text;

  /// ข้อความระบบสรุปผลนัดดู — ลูกค้า+แอดมินเห็นและนับเป็น「ยังไม่อ่าน」
  static bool isViewingFollowUpSystemNotice(String text) {
    final t = text.trim();
    return t.startsWith('ผลการนัดดูวันนี้') ||
        t.startsWith('Post-viewing result today');
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final linksRaw = json['links'];
    final links = <ChatMessageLink>[];
    if (linksRaw is List) {
      for (final item in linksRaw) {
        if (item is Map<String, dynamic>) {
          links.add(ChatMessageLink.fromJson(item));
        } else if (item is Map) {
          links.add(ChatMessageLink.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      role: _roleFromString(json['role']?.toString() ?? 'user'),
      text: json['text']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      requiresAdmin: json['requires_admin'] == true,
      links: links,
    );
  }

  static ChatMessageRole _roleFromString(String raw) {
    switch (raw) {
      case 'ai':
        return ChatMessageRole.ai;
      case 'system':
        return ChatMessageRole.system;
      case 'admin_notice':
        return ChatMessageRole.adminNotice;
      default:
        return ChatMessageRole.user;
    }
  }

  final String id;
  final ChatMessageRole role;
  final String text;
  final DateTime createdAt;
  final bool requiresAdmin;
  final List<ChatMessageLink> links;
}
