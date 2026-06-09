import '../config/env.dart';
import '../data/demo_cast_catalog.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/demo_cast_persona.dart';
import '../services/viewing_request_service.dart';
import '../utils/reference_codes.dart';
import 'demo_calendar_scenarios.dart';
import 'demo_cast_listing_pins.dart';
import 'demo_viewing_record_seed.dart';

/// จำลองแชท/เคส — ทุกตัวละครมีบทบาทกำลังทำงาน
abstract final class DemoCastSimulation {
  static bool get enabled => Env.adminDemoCases;

  static List<Map<String, dynamic>> leads() {
    final seekers = DemoCastCatalog.byKind(DemoCastKind.seeker);
    final now = DateTime.now();
    return List.generate(DemoCalendarScenarios.all.length, (i) {
      final scenario = DemoCalendarScenarios.byLeadNum(i + 1);
      final leadId = scenario.leadId;
      final s = seekers[i % seekers.length];
      final listingCode = scenario.listingCode;
      return {
        'id': leadId,
        'listing_code': listingCode,
        'listing_id': DemoCastListingPins.idForCode(listingCode),
        'transaction_ref': 'LEAD-2026-${(11 + i).toString().padLeft(6, '0')}',
        'status': scenario.adminClaimed ? 'routed' : 'new',
        'seeker_nickname': scenario.seekerNickname,
        'seeker_phone': scenario.seekerPhone,
        'seeker_cast_id': s.castId,
        'thread_id': scenario.threadId,
        'qualification_json': {
          'viewing_schedule':
              '${scenario.dayOffset >= 0 ? '+' : ''}${scenario.dayOffset} วัน · ${scenario.timeSlot}',
          if (scenario.isCoAgent) 'co_agent': true,
        },
        'created_at': now.subtract(Duration(hours: i + 1)).toIso8601String(),
      };
    });
  }

  static Map<String, dynamic> leadStats() {
    final scenarios = DemoCalendarScenarios.all;
    final claimed = scenarios.where((s) => s.adminClaimed).length;
    return {
      'lead_count': scenarios.length,
      'accepted_count': claimed,
      'new_count': scenarios.length - claimed,
    };
  }

  /// แชทรอรับงาน — ใช้ KPI โหมดทดลองแยก (ไม่นับจาก Supabase)
  static int inboxWaitingCount() => chatSeeds()
      .where((s) => s.status == 'waiting_admin' && s.adminClaimed == null)
      .length;

  /// แชทนัดดู — ห้อง id ตรงกับ `demo-lead-chat-{leadId}` ที่ผูกกับเคสในปฏิทิน
  static List<_ChatSeed> viewingLeadChatSeeds() {
    final seekers = DemoCastCatalog.byKind(DemoCastKind.seeker);
    const titles = {
      'LB-2026-000102': 'The Esse Asoke · 1BR',
      'RENT-CD-2026-000015': 'Rhythm Sukhumvit 36',
      'SALE-HS-2026-000003': 'บ้านเดี่ยว รามอินทรา',
      'RENT-CD-2026-000021': 'Ideo Q Sukhumvit 36',
      'SALE-CD-2026-000012': 'บ้านอ่อนนุชคอนโดมิเนียม',
      'RENT-CD-2026-000033': 'Life Asoke Hype',
      'RENT-CD-2026-000044': 'เดอะ ไลน์ ราชเทรี',
      'RENT-CD-2026-000055': 'ดี คอนโด เอกมัย',
      'SALE-HS-2026-000008': 'บ้านเดี่ยว พัฒนาการ',
      'RENT-CD-2026-000066': 'ศุภาลัย ปาร์ค บางนา',
      'RENT-CD-2026-000077': 'The Line จตุจักร',
      'SALE-CD-2026-000099': 'คอนโด สุขุมวิท',
    };
    final admins = DemoCastCatalog.byKind(DemoCastKind.admin);
    final brokers = DemoCastCatalog.byKind(DemoCastKind.broker);
    return DemoCalendarScenarios.all.map((scenario) {
      final code = scenario.listingCode;
      final nick = scenario.seekerNickname;
      final castId = leads()
          .firstWhere((l) => l['id'] == scenario.leadId)['seeker_cast_id']
          ?.toString();
      final seekerPersona = scenario.isCoAgent && brokers.isNotEmpty
          ? brokers[(scenario.leadNum - 1) % brokers.length]
          : DemoCastCatalog.find(castId ?? '') ??
              seekers.firstWhere(
                (p) => p.displayNameTh == nick,
                orElse: () => seekers[0],
              );
      final claimed = scenario.adminClaimed && admins.isNotEmpty
          ? admins[(scenario.leadNum - 1) % admins.length]
          : null;
      final userText = scenario.isCoAgent
          ? 'ขอนัดดู ${scenario.projectName} ให้ลูกค้า $nick ($code)'
          : 'ขอนัดดู ${scenario.projectName} · $code ($nick)';
      return _ChatSeed(
        roomId: scenario.threadId,
        listingCode: code,
        listingTitle: titles[code] ?? scenario.projectName,
        seeker: seekerPersona,
        customerLabel: nick,
        status: claimed != null ? 'active' : 'waiting_admin',
        category: 'viewing_request',
        viewingSubmitted: true,
        userText: userText,
        adminClaimed: claimed,
      );
    }).toList();
  }

  static List<_ChatSeed> chatSeeds() {
    return [
      ...viewingLeadChatSeeds(),
      ..._inboxVarietySeeds(),
    ];
  }

  static List<_ChatSeed> _inboxVarietySeeds() {
    final seekers = DemoCastCatalog.byKind(DemoCastKind.seeker);
    final brokers = DemoCastCatalog.byKind(DemoCastKind.broker);
    final admins = DemoCastCatalog.byKind(DemoCastKind.admin);
    final leads = DemoCastCatalog.byKind(DemoCastKind.lead);

    final seeds = <_ChatSeed>[
      _ChatSeed(
        roomId: 'cast-chat-queue-1',
        listingCode: 'RENT-CD-2026-000042',
        listingTitle: 'The Line Sukhumvit 101 · 2BR',
        seeker: seekers[0],
        status: 'waiting_admin',
        category: 'viewing_request',
        viewingSubmitted: true,
        userText: 'ขอนัดดูห้องวันเสาร์ 14:00 ค่ะ',
        adminClaimed: null,
      ),
      _ChatSeed(
        roomId: 'cast-chat-queue-2',
        listingCode: 'LB-2026-000102',
        listingTitle: 'The Esse Asoke · 1BR',
        seeker: seekers[1],
        status: 'waiting_admin',
        category: 'viewing_request',
        viewingSubmitted: true,
        userText: 'สนใจเช่าระยะยาว มีสัตว์เลี้ยง',
        adminClaimed: null,
      ),
      _ChatSeed(
        roomId: 'cast-chat-mine-1',
        listingCode: 'RENT-CD-2026-000015',
        listingTitle: 'Rhythm Sukhumvit 36',
        seeker: seekers[2],
        status: 'active',
        category: 'viewing_request',
        viewingSubmitted: true,
        userText: 'ยืนยันนัดวันนี้ 10:30 ครับ',
        adminClaimed: admins[0],
      ),
      _ChatSeed(
        roomId: 'cast-chat-mine-2',
        listingCode: 'SALE-CD-2026-000012',
        listingTitle: 'บ้านอ่อนนุชคอนโดมิเนียม',
        seeker: seekers[3],
        status: 'active',
        category: 'escalation',
        userText: 'อยากต่อรองราคาขาย ช่วยประสานเจ้าของ',
        adminClaimed: leads[0],
      ),
      _ChatSeed(
        roomId: 'cast-chat-broker-1',
        listingCode: 'RENT-CD-2026-000021',
        listingTitle: 'Ideo Q Sukhumvit 36',
        seeker: brokers[0],
        status: 'waiting_admin',
        category: 'staff_support',
        userText: 'ลูกค้าผมต้องการสตูดิโอ อารีย์ งบ 18k',
        adminClaimed: admins[1],
      ),
      _ChatSeed(
        roomId: 'cast-chat-offer-1',
        listingCode: 'BD-2026-000042',
        listingTitle: 'บอร์ดความต้องการ · ทองหล่อ',
        seeker: seekers[4],
        status: 'waiting_admin',
        category: 'demand_offer',
        userText: 'ส่งข้อเสนอทรัพย์จากเจ้าของตรงแล้วครับ',
        adminClaimed: null,
      ),
      _ChatSeed(
        roomId: 'cast-chat-req-1',
        listingCode: 'REQ-2026-000011',
        listingTitle: 'คำขอหาทรัพย์ · อโศก',
        seeker: seekers[5],
        status: 'active',
        category: 'customer_requirement',
        userText: 'อัปเดตงบเป็น 7 ล้านแล้วค่ะ',
        adminClaimed: admins[2],
      ),
      _ChatSeed(
        roomId: 'cast-chat-resolved-1',
        listingCode: 'RENT-CD-2026-000033',
        listingTitle: 'Life Asoke Hype',
        seeker: seekers[6],
        status: 'resolved',
        category: 'viewing_request',
        viewingSubmitted: true,
        userText: 'ขอบคุณค่ะ นัดชมเรียบร้อยแล้ว',
        adminClaimed: admins[3],
        resolved: true,
      ),
    ];

    for (var i = 7; i < 15 && i < seekers.length; i++) {
      seeds.add(
        _ChatSeed(
          roomId: 'cast-chat-extra-$i',
          listingCode: 'RENT-CD-2026-${(100 + i).toString().padLeft(6, '0')}',
          listingTitle: 'ทรัพย์ตัวอย่าง #${i + 1}',
          seeker: seekers[i],
          status: i.isEven ? 'waiting_admin' : 'active',
          category: i.isEven ? 'discovery' : 'booking_interest',
          userText: 'สอบถามทรัพย์ ${seekers[i].displayNameTh}',
          adminClaimed: i.isOdd ? admins[i % admins.length] : null,
        ),
      );
    }
    return seeds;
  }

  static ChatRoom toRoom(_ChatSeed seed) {
    DemoViewingRecordSeed.ensure();
    final nick = seed.customerLabel ?? seed.seeker.displayNameTh;
    final now = DateTime.now();
    final messages = <ChatMessage>[
      ChatMessage(
        id: 'ai-${seed.roomId}',
        role: ChatMessageRole.ai,
        text: 'สวัสดีค่ะ ยินดีช่วยเรื่อง ${seed.listingTitle}',
      ),
      ChatMessage(
        id: 'user-${seed.roomId}',
        role: ChatMessageRole.user,
        text: seed.userText,
        createdAt: now.subtract(Duration(hours: seed.roomId.hashCode % 12 + 1)),
      ),
    ];
    if (seed.viewingSubmitted) {
      final vr = ViewingRequestService.instance.byThreadId(seed.roomId);
      if (vr != null) {
        final links = <ChatMessageLink>[
          ChatMessageLink.profileTag(vr.clientTagCode, vr.clientTagCode),
          ChatMessageLink.viewingRequest(vr.code, vr.code),
        ];
        if (vr.presenterTagCode != null) {
          links.add(
            ChatMessageLink.profileTag(
              vr.presenterTagCode!,
              vr.presenterTagCode!,
            ),
          );
        }
        messages.add(
          ChatMessage(
            id: 'sys-vr-${seed.roomId}',
            role: ChatMessageRole.system,
            text:
                'รับคำขอนัดดูแล้ว · ${vr.listingCode}\nโปรไฟล์: ${vr.clientTagCode}\nคำขอ: ${vr.code}',
            links: links,
            createdAt: now.subtract(const Duration(minutes: 40)),
          ),
        );
      } else {
        messages.add(
          ChatMessage(
            id: 'sys-${seed.roomId}',
            role: ChatMessageRole.system,
            text: 'สรุปโปรไฟล์ลูกค้า\n• ชื่อ: $nick\n• ทรัพย์: ${seed.listingCode}',
            createdAt: now.subtract(const Duration(minutes: 40)),
          ),
        );
      }
    }

    final room = ChatRoom(
      id: seed.roomId,
      listingId: seed.roomId,
      listingCode: seed.listingCode,
      listingTitle: seed.listingTitle,
      transactionRef: ReferenceCodes.demoChatRef(seed.roomId),
      roomKind: 'property',
      category: seed.category,
      allowViewingRequest: true,
      participantUserId: seed.seeker.profileId,
      adminDisplayName: nick,
      viewingSubmitted: seed.viewingSubmitted,
      adminEscalated: !seed.resolved,
      adminReplyDone: seed.resolved,
      status: seed.status,
      priority: seed.viewingSubmitted ? 'high' : 'normal',
      messages: messages,
      updatedAt: now.subtract(Duration(minutes: seed.roomId.length * 3)),
    );

    if (seed.adminClaimed != null) {
      room.assignedAdminId = seed.adminClaimed!.profileId;
      room.assignedAdminName = seed.adminClaimed!.displayNameTh;
    }
    return room;
  }
}

class _ChatSeed {
  const _ChatSeed({
    required this.roomId,
    required this.listingCode,
    required this.listingTitle,
    required this.seeker,
    required this.status,
    required this.category,
    required this.userText,
    this.adminClaimed,
    this.viewingSubmitted = false,
    this.resolved = false,
    this.customerLabel,
  });

  final String roomId;
  final String listingCode;
  final String listingTitle;
  final DemoCastPersona seeker;
  final String status;
  final String category;
  final String userText;
  final DemoCastPersona? adminClaimed;
  final bool viewingSubmitted;
  final bool resolved;
  final String? customerLabel;
}
