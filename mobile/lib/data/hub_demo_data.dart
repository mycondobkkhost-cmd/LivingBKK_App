import '../models/profile_tag.dart';

/// ข้อมูลสมมุติ Hub + แท็ก + คำขอนัดดู (Phase 24 demo)
class HubDemoData {
  HubDemoData._();

  static const seekerUserId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  static const agentUserId = '33333333-3333-3333-3333-333333333333';
  static const ownerUserId = '11111111-1111-1111-1111-111111111111';
  static const seekerBeeId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  static const demoUserDirectory = <(String label, String userId, String? email)>[
    ('คุณมิ้นท์ (คนหาบ้าน)', seekerUserId, 'ทดลอง-คนหาบ้าน@livingbkk.local'),
    ('วิชัย โคเอ', agentUserId, 'ทดลอง-นายหน้า@livingbkk.local'),
    ('คุณสมชาย เจ้าของ', ownerUserId, 'demo-owner@livingbkk.local'),
    ('คุณบี (ลูกค้าโคเอ)', seekerBeeId, 'demo-seeker-bee@livingbkk.local'),
  ];

  static String? resolveUserId(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final row in demoUserDirectory) {
      if (row.$1.toLowerCase().contains(q) ||
          row.$2.toLowerCase() == q ||
          (row.$3?.toLowerCase().contains(q) ?? false)) {
        return row.$2;
      }
    }
    if (q.contains('มิ้นท์') || q.contains('seeker') || q.contains('คนหา')) {
      return seekerUserId;
    }
    if (q.contains('โคเอ') || q.contains('agent') || q.contains('วิชัย')) {
      return agentUserId;
    }
    if (q.contains('demo-user')) return seekerUserId;
    return q.length >= 8 ? q : seekerUserId;
  }

  static final DateTime _base = DateTime(2026, 6, 5, 10, 0);

  static List<ProfileTag> profileTags() {
    return [
      _tag(
        id: 'tag-sp-101',
        code: 'SP-2026-000101',
        role: ProfileTagRole.seekerSelf,
        version: 1,
        userId: seekerUserId,
        name: 'คุณมิ้นท์',
        at: _base.subtract(const Duration(days: 3)),
        snap: _seekerSnap('คุณมิ้นท์', '0812345678', '2', '18,000 – 22,000 บาท/เดือน'),
      ),
      _tag(
        id: 'tag-sp-102',
        code: 'SP-2026-000102',
        role: ProfileTagRole.seekerSelf,
        version: 2,
        userId: seekerUserId,
        name: 'คุณมิ้นท์',
        at: _base.subtract(const Duration(days: 1)),
        snap: _seekerSnap('คุณมิ้นท์', '0812345678', '2', '20,000 – 25,000 บาท/เดือน'),
      ),
      _tag(
        id: 'tag-sp-bee',
        code: 'SP-2026-000103',
        role: ProfileTagRole.seekerSelf,
        version: 1,
        userId: seekerBeeId,
        name: 'คุณบี',
        at: _base.subtract(const Duration(days: 2)),
        snap: _seekerSnap('คุณบี', '0898765432', '1', '12,000 – 16,000 บาท/เดือน'),
      ),
      _tag(
        id: 'tag-pr-201',
        code: 'PR-2026-000201',
        role: ProfileTagRole.coAgentPresenter,
        version: 1,
        userId: agentUserId,
        name: 'วิชัย นายหน้า',
        at: _base.subtract(const Duration(days: 10)),
        snap: {
          'displayName': 'Mint Patcha',
          'agencyName': 'RealXtate Co-Agent',
          'licenseNo': 'RE-2024-55821',
          'phone': '0654321098',
        },
      ),
      _tag(
        id: 'tag-cl-301',
        code: 'CL-2026-000301',
        role: ProfileTagRole.clientSubject,
        version: 1,
        userId: agentUserId,
        name: 'คุณบี',
        at: _base.subtract(const Duration(days: 4)),
        snap: _seekerSnap('คุณบี', '0891112233', '1', '15,000 – 18,000 บาท/เดือน'),
      ),
      _tag(
        id: 'tag-cl-302',
        code: 'CL-2026-000302',
        role: ProfileTagRole.clientSubject,
        version: 1,
        userId: agentUserId,
        name: 'คุณอาร์ม',
        at: _base.subtract(const Duration(days: 3)),
        snap: _seekerSnap('คุณอาร์ม', '0823344556', '2', '22,000 – 28,000 บาท/เดือน'),
      ),
      _tag(
        id: 'tag-cl-303',
        code: 'CL-2026-000303',
        role: ProfileTagRole.clientSubject,
        version: 1,
        userId: agentUserId,
        name: 'คุณเจน',
        at: _base.subtract(const Duration(days: 2)),
        snap: _seekerSnap('คุณเจน', '0867788990', '3', '35,000 – 45,000 บาท/เดือน'),
      ),
      _tag(
        id: 'tag-cl-304',
        code: 'CL-2026-000304',
        role: ProfileTagRole.clientSubject,
        version: 2,
        userId: agentUserId,
        name: 'คุณต้น',
        at: _base.subtract(const Duration(hours: 6)),
        snap: _seekerSnap('คุณต้น', '0998877665', '2', '18,000 – 22,000 บาท/เดือน'),
      ),
      _tag(
        id: 'tag-cl-305',
        code: 'CL-2026-000305',
        role: ProfileTagRole.clientSubject,
        version: 1,
        userId: agentUserId,
        name: 'คุณน้ำ',
        at: _base.subtract(const Duration(hours: 2)),
        snap: _seekerSnap('คุณน้ำ', '0912233445', '1', '10,000 – 14,000 บาท/เดือน'),
      ),
    ];
  }

  static Map<String, String> _seekerSnap(
    String nickname,
    String phone,
    String occupants,
    String budget,
  ) =>
      {
        'nickname': nickname,
        'phone': phone,
        'occupants': occupants,
        'occupation': 'พนักงานบริษัท',
        'contract': '12m',
        'budget': budget,
        'workplace': 'อโศก',
      };

  static ProfileTag _tag({
    required String id,
    required String code,
    required ProfileTagRole role,
    required int version,
    required String userId,
    required String name,
    required DateTime at,
    required Map<String, String> snap,
  }) {
    return ProfileTag(
      id: id,
      code: code,
      role: role,
      version: version,
      label: version > 1 ? '$code v$version' : code,
      snapshot: snap,
      ownerUserId: userId,
      createdAt: at,
      subjectDisplayName: name,
    );
  }

}
