enum ChatMessageRole { user, ai, system, adminNotice }

enum ChatMessageLinkKind { listing, projectUnits }

class ChatMessageLink {
  const ChatMessageLink({
    required this.label,
    required this.kind,
    required this.listingId,
    this.projectName,
  });

  factory ChatMessageLink.fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind']?.toString() ?? 'listing';
    return ChatMessageLink(
      label: json['label']?.toString() ?? '',
      kind: kindRaw == 'projectUnits'
          ? ChatMessageLinkKind.projectUnits
          : ChatMessageLinkKind.listing,
      listingId: json['listingId']?.toString() ?? json['listing_id']?.toString() ?? '',
      projectName: json['projectName']?.toString() ?? json['project_name']?.toString(),
    );
  }

  final String label;
  final ChatMessageLinkKind kind;
  final String listingId;
  final String? projectName;
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
