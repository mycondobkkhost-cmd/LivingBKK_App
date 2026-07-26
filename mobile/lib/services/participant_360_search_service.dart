import '../data/hub_demo_data.dart';
import '../data/hub_demo_seed.dart';
import '../models/profile_tag.dart';
import '../models/viewing_request.dart';
import 'chat_service.dart';
import 'profile_tag_repository.dart';
import 'viewing_request_repository.dart';

enum Participant360HitKind {
  user,
  profileTag,
  viewingRequest,
  chatMessage,
  listing,
}

class Participant360Hit {
  const Participant360Hit({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.userId,
    this.refCode,
    this.threadId,
    this.agent = false,
  });

  final Participant360HitKind kind;
  final String title;
  final String subtitle;
  final String? userId;
  final String? refCode;
  final String? threadId;
  final bool agent;
}

/// ค้นหา 360° — user · แท็ก · VR · ข้อความแชท · รหัสทรัพย์
class Participant360SearchService {
  Participant360SearchService._();
  static final instance = Participant360SearchService._();

  static final _tagCodeRe = RegExp(
    r'^(SP|CL|PR)-2026-\d{6}$',
    caseSensitive: false,
  );
  static final _vrCodeRe = RegExp(r'^VR-2026-\d{6}$', caseSensitive: false);
  static final _rxtCodeRe = RegExp(
    r'^RXT-\d{4}-\d+$',
    caseSensitive: false,
  );
  static final _listingRe = RegExp(
    r'^(RENT|SALE|RENT-AND-SALE)-[A-Z0-9-]+$',
    caseSensitive: false,
  );

  Future<List<Participant360Hit>> search(String query) async {
    HubDemoSeed.ensure();
    await ProfileTagRepository.instance.ensureLoaded();
    await ViewingRequestRepository.instance.fetchAllForAdmin();

    final q = query.trim();
    if (q.isEmpty) return [];

    final hits = <Participant360Hit>[];
    final seen = <String>{};

    void add(Participant360Hit hit) {
      final key = '${hit.kind.name}:${hit.refCode ?? hit.userId ?? hit.title}';
      if (seen.add(key)) hits.add(hit);
    }

    final upper = q.toUpperCase();

    if (_vrCodeRe.hasMatch(upper)) {
      final req = ViewingRequestRepository.instance.byCode(upper) ??
          await ViewingRequestRepository.instance.fetchByCode(upper);
      if (req != null) {
        add(
          Participant360Hit(
            kind: Participant360HitKind.viewingRequest,
            title: req.code,
            subtitle: '${req.listingCode} · ${_statusLabel(req.status)}',
            userId: req.createdByUserId,
            refCode: req.code,
            threadId: req.threadId,
          ),
        );
      }
    }

    if (_tagCodeRe.hasMatch(upper) || q.startsWith('@')) {
      final code = upper.replaceFirst('@', '');
      final tag = ProfileTagRepository.instance.tagByCode(code) ??
          await ProfileTagRepository.instance.fetchTagByCode(code);
      if (tag != null) {
        add(_hitFromTag(tag));
      }
    }

    if (_rxtCodeRe.hasMatch(upper) || _listingRe.hasMatch(upper)) {
      add(
        Participant360Hit(
          kind: Participant360HitKind.listing,
          title: upper,
          subtitle: 'Listing 360°',
          refCode: upper,
        ),
      );
    }

    for (final row in HubDemoData.demoUserDirectory) {
      if (row.$1.toLowerCase().contains(q.toLowerCase()) ||
          row.$2.toLowerCase().contains(q.toLowerCase()) ||
          (row.$3?.toLowerCase().contains(q.toLowerCase()) ?? false)) {
        add(
          Participant360Hit(
            kind: Participant360HitKind.user,
            title: row.$1,
            subtitle: row.$3 ?? row.$2,
            userId: row.$2,
            agent: row.$2 == HubDemoData.agentUserId,
          ),
        );
      }
    }

    final uid = HubDemoData.resolveUserId(q);
    if (uid != null) {
      for (final row in HubDemoData.demoUserDirectory) {
        if (row.$2 == uid) {
          add(
            Participant360Hit(
              kind: Participant360HitKind.user,
              title: row.$1,
              subtitle: row.$3 ?? row.$2,
              userId: row.$2,
              agent: row.$2 == HubDemoData.agentUserId,
            ),
          );
        }
      }
    }

    for (final tag in ProfileTagRepository.instance.searchGlobal(q)) {
      add(_hitFromTag(tag));
    }

    for (final req in ViewingRequestRepository.instance.all()) {
      if (req.code.toUpperCase().contains(upper) ||
          req.listingCode.toUpperCase().contains(upper) ||
          req.clientTagCode.toUpperCase().contains(upper) ||
          req.listingTitle.toLowerCase().contains(q.toLowerCase())) {
        add(
          Participant360Hit(
            kind: Participant360HitKind.viewingRequest,
            title: req.code,
            subtitle: '${req.listingCode} · ${req.clientTagCode}',
            userId: req.createdByUserId,
            refCode: req.code,
            threadId: req.threadId,
          ),
        );
      }
    }

    _searchMessages(q, add);
    return hits.take(40).toList();
  }

  Participant360Hit _hitFromTag(ProfileTag tag) {
    return Participant360Hit(
      kind: Participant360HitKind.profileTag,
      title: tag.code,
      subtitle: tag.subjectDisplayName ?? tag.role.name,
      userId: tag.ownerUserId,
      refCode: tag.code,
      agent: tag.role == ProfileTagRole.coAgentPresenter,
    );
  }

  void _searchMessages(String q, void Function(Participant360Hit) add) {
    final lower = q.toLowerCase();
    if (lower.length < 2) return;

    for (final room in ChatService.instance.allRoomsForSearch()) {
      for (final msg in room.messages) {
        if (!msg.text.toLowerCase().contains(lower)) continue;
        final preview = msg.text.length > 80
            ? '${msg.text.substring(0, 80)}…'
            : msg.text;
        add(
          Participant360Hit(
            kind: Participant360HitKind.chatMessage,
            title: room.listingCode,
            subtitle: preview,
            userId: room.participantUserId,
            threadId: room.id,
          ),
        );
        break;
      }
    }
  }

  String _statusLabel(ViewingRequestStatus s) => switch (s) {
        ViewingRequestStatus.draft => 'ร่าง',
        ViewingRequestStatus.submitted => 'ส่งแล้ว',
        ViewingRequestStatus.sentToOwner => 'ส่งเจ้าของ',
        ViewingRequestStatus.ownerConfirmed => 'ยืนยัน',
        ViewingRequestStatus.ownerDeclined => 'ปฏิเสธ',
        ViewingRequestStatus.cancelled => 'ยกเลิก',
      };
}
