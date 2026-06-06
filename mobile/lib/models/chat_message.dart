import '../l10n/app_strings.dart';

enum ChatMessageRole { user, ai, system, adminNotice }

enum ChatMessageLinkKind {
  listing,
  projectUnits,
  requirementForm,
  viewingForm,
}

class ChatMessageLink {
  const ChatMessageLink({
    required this.label,
    required this.kind,
    this.listingId = '',
    this.projectName,
  });

  factory ChatMessageLink.fromJson(Map<String, dynamic> json) {
    return ChatMessageLink(
      label: json['label']?.toString() ?? '',
      kind: _kindFromString(json['kind']?.toString() ?? 'listing'),
      listingId:
          json['listingId']?.toString() ?? json['listing_id']?.toString() ?? '',
      projectName:
          json['projectName']?.toString() ?? json['project_name']?.toString(),
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

  final String label;
  final ChatMessageLinkKind kind;
  final String listingId;
  final String? projectName;

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
      case ChatMessageLinkKind.listing:
        return 'listing';
    }
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    DateTime? createdAt,
    this.requiresAdmin = false,
    this.links = const [],
  }) : createdAt = createdAt ?? DateTime.now();

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
