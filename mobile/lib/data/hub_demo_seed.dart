import '../data/demo_listings_factory.dart';
import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../models/viewing_request.dart';
import '../services/chat_service.dart';
import '../services/participant_moderation_service.dart';
import '../services/profile_tag_service.dart';
import '../services/viewing_request_service.dart';
import 'hub_demo_data.dart';

/// โหลดข้อมูลสมมุติ Hub / แท็ก / คำขอนัดดู
class HubDemoSeed {
  HubDemoSeed._();

  static bool _done = false;

  static void reset() => _done = false;

  static void ensure() {
    if (_done) return;
    _seedTags();
    _seedViewingRequests();
    _seedModeration();
    _seedHubChats();
    _seedReturningCustomerCase();
    _done = true;
  }

  static void _seedReturningCustomerCase() {
    final listings = DemoListingsFactory.cached;
    if (listings.length < 3) return;
    ChatService.instance.seedReturningCustomerDemo(
      participantUserId: HubDemoData.seekerUserId,
      activeListing: listings[0],
      newListing: listings[2],
      adminId: 'demo-admin-1',
      adminName: 'คุณแอน',
    );
  }

  static void _seedTags() {
    final svc = ProfileTagService.instance;
    if (svc.count > 0) return;
    for (final tag in HubDemoData.profileTags()) {
      svc.registerDemoTag(tag);
    }
  }

  static void _seedViewingRequests() {
    final svc = ViewingRequestService.instance;
    if (svc.count > 0) return;
    final listings = DemoListingsFactory.cached;
    final tags = {for (final t in HubDemoData.profileTags()) t.id: t};

    final specs = <_VRSpec>[
      _VRSpec(0, HubDemoData.seekerUserId, 'tag-sp-102', null, ViewingRequestSource.customer, ViewingRequestStatus.submitted, 2, 14),
      _VRSpec(1, HubDemoData.seekerUserId, 'tag-sp-102', null, ViewingRequestSource.customer, ViewingRequestStatus.sentToOwner, 3, 10),
      _VRSpec(2, HubDemoData.seekerUserId, 'tag-sp-101', null, ViewingRequestSource.customer, ViewingRequestStatus.ownerConfirmed, 1, 16),
      _VRSpec(3, HubDemoData.seekerUserId, 'tag-sp-102', null, ViewingRequestSource.customer, ViewingRequestStatus.ownerDeclined, 4, 11),
      _VRSpec(4, HubDemoData.seekerUserId, 'tag-sp-102', null, ViewingRequestSource.customer, ViewingRequestStatus.submitted, 2, 15),
      _VRSpec(5, HubDemoData.agentUserId, 'tag-cl-301', 'tag-pr-201', ViewingRequestSource.coAgent, ViewingRequestStatus.sentToOwner, 5, 13),
      _VRSpec(6, HubDemoData.agentUserId, 'tag-cl-302', 'tag-pr-201', ViewingRequestSource.coAgent, ViewingRequestStatus.ownerConfirmed, 1, 17),
      _VRSpec(7, HubDemoData.agentUserId, 'tag-cl-303', 'tag-pr-201', ViewingRequestSource.coAgent, ViewingRequestStatus.submitted, 3, 10),
      _VRSpec(8, HubDemoData.agentUserId, 'tag-cl-304', 'tag-pr-201', ViewingRequestSource.coAgent, ViewingRequestStatus.sentToOwner, 6, 9),
      _VRSpec(9, HubDemoData.agentUserId, 'tag-cl-301', 'tag-pr-201', ViewingRequestSource.coAgent, ViewingRequestStatus.ownerDeclined, 2, 11),
      _VRSpec(10, HubDemoData.agentUserId, 'tag-cl-305', 'tag-pr-201', ViewingRequestSource.coAgent, ViewingRequestStatus.submitted, 4, 14),
      _VRSpec(11, HubDemoData.agentUserId, 'tag-cl-302', 'tag-pr-201', ViewingRequestSource.adminPhone, ViewingRequestStatus.submitted, 7, 15),
      _VRSpec(12, HubDemoData.agentUserId, 'tag-cl-303', 'tag-pr-201', ViewingRequestSource.coAgent, ViewingRequestStatus.ownerConfirmed, 1, 10),
      _VRSpec(13, HubDemoData.seekerBeeId, 'tag-sp-bee', null, ViewingRequestSource.customer, ViewingRequestStatus.sentToOwner, 8, 16),
      _VRSpec(14, HubDemoData.agentUserId, 'tag-cl-304', 'tag-pr-201', ViewingRequestSource.coAgent, ViewingRequestStatus.submitted, 9, 11),
      _VRSpec(15, HubDemoData.agentUserId, 'tag-cl-305', 'tag-pr-201', ViewingRequestSource.adminPhone, ViewingRequestStatus.draft, 10, 13),
      _VRSpec(16, HubDemoData.seekerUserId, 'tag-sp-102', null, ViewingRequestSource.customer, ViewingRequestStatus.submitted, 11, 10),
      _VRSpec(17, HubDemoData.agentUserId, 'tag-cl-301', 'tag-pr-201', ViewingRequestSource.coAgent, ViewingRequestStatus.ownerConfirmed, 12, 14),
      _VRSpec(18, HubDemoData.agentUserId, 'tag-cl-302', 'tag-pr-201', ViewingRequestSource.coAgent, ViewingRequestStatus.submitted, 13, 16),
      _VRSpec(19, HubDemoData.seekerUserId, 'tag-sp-101', null, ViewingRequestSource.customer, ViewingRequestStatus.sentToOwner, 14, 11),
    ];

    var seq = 100;
    final base = DateTime(2026, 6, 5, 10, 0);
    for (final spec in specs) {
      if (spec.listingIndex >= listings.length) continue;
      final listing = listings[spec.listingIndex];
      final client = tags[spec.clientTagId]!;
      final presenter =
          spec.presenterTagId != null ? tags[spec.presenterTagId] : null;
      seq++;
      final scheduled = base.add(Duration(days: spec.dayOffset, hours: spec.hour));
      svc.registerDemoRequest(
        ViewingRequest(
          id: 'vr-demo-$seq',
          code: 'VR-2026-${seq.toString().padLeft(6, '0')}',
          listingId: listing.id,
          listingCode: listing.listingCode,
          listingTitle: listing.title,
          projectName: listing.projectName,
          scheduledAt: scheduled,
          clientTagId: client.id,
          clientTagCode: client.code,
          presenterTagId: presenter?.id,
          presenterTagCode: presenter?.code,
          source: spec.source,
          status: spec.status,
          createdAt: scheduled.subtract(const Duration(hours: 3)),
          createdByUserId: spec.userId,
          threadId: 'demo-thread-${listing.id}',
        ),
      );
    }
  }

  static void _seedModeration() {
    ParticipantModerationService.instance.setFlagged(
      HubDemoData.seekerBeeId,
      true,
    );
    ParticipantModerationService.instance.setMuted(
      HubDemoData.ownerUserId,
      true,
    );
  }

  static void _seedHubChats() {
    final chat = ChatService.instance;
    final copy = AppStrings(false);
    final allReqs = ViewingRequestService.instance.all();

    void seedHub(String userId, bool agent) {
      final hub = chat.ensureHubForUser(userId, agent: agent);
      if (hub.messages.isNotEmpty) return;

      chat.appendHubSystemMessage(
        userId: userId,
        agent: agent,
        message: ChatMessage(
          id: 'hub-welcome-$userId',
          role: ChatMessageRole.system,
          text: agent
              ? 'แชทกลางงานโคเอ — สรุปคำขอนัดดูและแท็กลูกค้า'
              : 'แชทกลางของคุณ — สรุปคำขอนัดดูและแท็กโปรไฟล์',
          createdAt: DateTime(2026, 6, 4, 9, 0),
        ),
      );

      final reqs = allReqs.where((r) => r.createdByUserId == userId).toList();
      for (final req in reqs.take(10)) {
        final links = <ChatMessageLink>[
          ChatMessageLink.profileTag(req.clientTagCode, req.clientTagCode),
          ChatMessageLink.viewingRequest(req.code, req.code),
        ];
        if (req.presenterTagCode != null) {
          links.insert(
            0,
            ChatMessageLink.profileTag(req.presenterTagCode!, req.presenterTagCode!),
          );
        }
        chat.appendHubSystemMessage(
          userId: userId,
          agent: agent,
          message: ChatMessage(
            id: 'hub-vr-${req.id}',
            role: ChatMessageRole.system,
            text: 'คำขอ ${req.code}\n'
                '${req.listingCode} · ${req.listingTitle}\n'
                'นัด: ${req.scheduledAt.day}/${req.scheduledAt.month}/${req.scheduledAt.year + 543} '
                '${req.scheduledAt.hour.toString().padLeft(2, '0')}:'
                '${req.scheduledAt.minute.toString().padLeft(2, '0')}\n'
                'สถานะ: ${_statusLabel(req.status)}',
            createdAt: req.createdAt,
            links: links,
          ),
        );
      }

      chat.appendHubSystemMessage(
        userId: userId,
        agent: agent,
        message: ChatMessage(
          id: 'hub-user-q-$userId',
          role: ChatMessageRole.user,
          text: agent
              ? 'ขอสรุปสถานะคำขอ CL-2026-000301 กับเจ้าของหน่อยครับ'
              : 'อยากทราบว่าคำขอ VR-2026-000103 เจ้าของตอบรับหรือยังคะ',
          createdAt: DateTime(2026, 6, 5, 11, 15),
        ),
      );

      chat.appendHubSystemMessage(
        userId: userId,
        agent: agent,
        message: ChatMessage(
          id: 'hub-admin-$userId',
          role: ChatMessageRole.adminNotice,
          text: 'ทีมงาน: รับคำขอแล้ว — จะติดต่อเจ้าของทรัพย์และแจ้งกลับในแชทนี้',
          createdAt: DateTime(2026, 6, 5, 14, 30),
        ),
      );

      chat.appendHubSystemMessage(
        userId: userId,
        agent: agent,
        message: ChatMessage(
          id: 'hub-admin-reply-$userId',
          role: ChatMessageRole.adminNotice,
          text: agent
              ? 'เจ้าของยืนยันนัด CL-2026-000302 แล้ว — ดูรายละเอียดใน thread ทรัพย์'
              : 'VR-2026-000103 เจ้าของยืนยันแล้วค่ะ นัดวันที่ 6/6 เวลา 16:00',
          createdAt: DateTime(2026, 6, 5, 15, 0),
        ),
      );
    }

    seedHub(HubDemoData.seekerUserId, false);
    seedHub(HubDemoData.agentUserId, true);
    seedHub(HubDemoData.seekerBeeId, false);

    for (final req in allReqs
        .where((r) => r.createdByUserId == HubDemoData.seekerUserId)
        .take(6)) {
      chat.seedPropertyViewingRecap(
        req: req,
        recapText: copy.viewingTagRecap(
          schedule:
              '${req.scheduledAt.day}/${req.scheduledAt.month} ${req.scheduledAt.hour}:${req.scheduledAt.minute.toString().padLeft(2, '0')}',
          clientCode: req.clientTagCode,
          viewingCode: req.code,
        ),
      );
    }

    for (final req in allReqs
        .where((r) => r.createdByUserId == HubDemoData.seekerBeeId)
        .take(2)) {
      chat.seedPropertyViewingRecap(
        req: req,
        recapText: copy.viewingTagRecap(
          schedule:
              '${req.scheduledAt.day}/${req.scheduledAt.month} ${req.scheduledAt.hour}:${req.scheduledAt.minute.toString().padLeft(2, '0')}',
          clientCode: req.clientTagCode,
          viewingCode: req.code,
        ),
      );
    }

    for (final req in allReqs
        .where((r) => r.createdByUserId == HubDemoData.agentUserId)
        .take(4)) {
      chat.seedPropertyViewingRecap(
        req: req,
        recapText: copy.viewingTagRecap(
          schedule:
              '${req.scheduledAt.day}/${req.scheduledAt.month} ${req.scheduledAt.hour}:${req.scheduledAt.minute.toString().padLeft(2, '0')}',
          clientCode: req.clientTagCode,
          viewingCode: req.code,
          presenterCode: req.presenterTagCode,
        ),
      );
    }
  }

  static String _statusLabel(ViewingRequestStatus s) => switch (s) {
        ViewingRequestStatus.draft => 'ร่าง',
        ViewingRequestStatus.submitted => 'ส่งแล้ว',
        ViewingRequestStatus.sentToOwner => 'ส่งเจ้าของแล้ว',
        ViewingRequestStatus.ownerConfirmed => 'เจ้าของยืนยัน',
        ViewingRequestStatus.ownerDeclined => 'เจ้าของปฏิเสธ',
        ViewingRequestStatus.cancelled => 'ยกเลิก',
      };
}

class _VRSpec {
  const _VRSpec(
    this.listingIndex,
    this.userId,
    this.clientTagId,
    this.presenterTagId,
    this.source,
    this.status,
    this.dayOffset,
    this.hour,
  );

  final int listingIndex;
  final String userId;
  final String clientTagId;
  final String? presenterTagId;
  final ViewingRequestSource source;
  final ViewingRequestStatus status;
  final int dayOffset;
  final int hour;
}
