import '../utils/reference_codes.dart';
import 'chat_message.dart';

class ChatRoom {
  ChatRoom({
    required this.id,
    required this.listingId,
    required this.listingCode,
    required this.listingTitle,
    this.projectName,
    this.roomKind,
    this.transactionRef,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
    this.adminEscalated = false,
    this.viewingSubmitted = false,
    this.allowViewingRequest = false,
    this.adminReplyDone = false,
    this.unclearStreak = 0,
    this.category,
    this.status,
    this.priority,
    this.assignedAdminId,
    this.assignedAdminName,
    this.assignedAt,
  })  : messages = messages ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String listingId;
  final String listingCode;
  /// CHAT-2026-000001 — อ้างอิงย้อนกลับเมื่อคุยกับเจ้าหน้าที่
  final String? transactionRef;
  final String listingTitle;
  final String? projectName;
  /// property | staff_support | discovery (property thread, no listing)
  final String? roomKind;
  String? category;
  String? status;
  String? priority;
  final List<ChatMessage> messages;
  DateTime updatedAt;
  bool adminEscalated;
  bool viewingSubmitted;
  bool allowViewingRequest;
  bool adminReplyDone;
  int unclearStreak;
  String? assignedAdminId;
  String? assignedAdminName;
  DateTime? assignedAt;

  bool get isResolved =>
      status == 'resolved' || (adminReplyDone && status != 'waiting_admin');

  bool isClaimedBy(String? adminId) =>
      adminId != null && assignedAdminId == adminId;

  bool get isUnclaimed =>
      assignedAdminId == null || assignedAdminId!.isEmpty;

  bool get isDiscovery =>
      category == 'discovery' ||
      listingCode == 'DISCOVERY' ||
      id == ChatServiceIds.discovery;

  /// @deprecated use [isDiscovery]
  bool get isAiSupport => isDiscovery;

  bool get isStaffSupport =>
      roomKind == 'staff_support' || id == ChatServiceIds.staffSupport;

  bool get isDemandOffer => category == 'demand_offer';

  bool get isCustomerRequirement => category == 'customer_requirement';

  bool get isSupportRoom =>
      isDiscovery || isStaffSupport || isDemandOffer || isCustomerRequirement;
  bool get isPropertyListing =>
      !isStaffSupport && !isDiscovery && listingCode != 'DISCOVERY';
  bool get isPersisted => !id.startsWith('__') && !id.startsWith('demo-');

  String get effectiveTransactionRef =>
      (transactionRef != null && transactionRef!.isNotEmpty)
          ? transactionRef!
          : ReferenceCodes.demoChatRef(id);

  String get displayTitle =>
      projectName != null && projectName!.isNotEmpty
          ? '$projectName · $listingCode'
          : listingTitle;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  factory ChatRoom.fromThreadJson(
    Map<String, dynamic> thread,
    List<ChatMessage> messages,
  ) {
    final roomKind = thread['room_kind']?.toString();
    final rawListingId = thread['listing_id'];
    final listingId = rawListingId != null ? rawListingId.toString() : '';
    return ChatRoom(
      id: thread['id']?.toString() ?? listingId,
      listingId: listingId,
      listingCode: thread['listing_code']?.toString() ?? '',
      transactionRef: thread['transaction_ref']?.toString(),
      listingTitle: thread['listing_title']?.toString() ?? '',
      projectName: thread['project_name']?.toString(),
      roomKind: roomKind,
      category: thread['category']?.toString(),
      status: thread['status']?.toString(),
      priority: thread['priority']?.toString(),
      messages: messages,
      updatedAt: thread['last_message_at'] != null
          ? DateTime.tryParse(thread['last_message_at'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      adminEscalated: thread['admin_escalated'] == true,
      viewingSubmitted: thread['viewing_submitted'] == true,
      allowViewingRequest: thread['allow_viewing_request'] == true,
      adminReplyDone: thread['admin_reply_done'] == true,
      unclearStreak: (thread['unclear_streak'] as num?)?.toInt() ?? 0,
      assignedAdminId: thread['assigned_admin_id']?.toString(),
      assignedAdminName: thread['assigned_admin_name']?.toString(),
      assignedAt: thread['assigned_at'] != null
          ? DateTime.tryParse(thread['assigned_at'].toString())
          : null,
    );
  }
}

/// Legacy in-memory ids for demo/trial mode.
abstract final class ChatServiceIds {
  static const discovery = '__discovery__';
  /// @deprecated
  static const aiSupport = discovery;
  static const staffSupport = '__support_staff__';
  static const demandOffer = '__demand_offer__';
  static String customerRequirement(String reqId) => '__req__$reqId';
}
