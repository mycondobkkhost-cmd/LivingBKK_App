import '../models/demo_cast_persona.dart';

/// รายชื่อตัวละครจำลองทั้งหมด — สร้างอัตโนมัติตามจำนวนที่กำหนด
abstract final class DemoCastCatalog {
  static const sharedEntryEmail = 'demo-admin@livingbkk.local';
  static const sharedEntryPassword = 'demo12345';

  static const _thaiNames = [
    'สมชาย', 'สมหญิง', 'วิชัย', 'นภา', 'ก้อง', 'มิ้นท์', 'พลอย', 'ต้น', 'แนน', 'บี',
    'เจ', 'แป้ง', 'ก้าว', 'หนึ่ง', 'สอง', 'สาม', 'โฟร์', 'ไฟว์', 'อาร์ต', 'บูม',
    'เจน', 'โอ๊ต', 'แอน', 'บอส', 'โจ', 'เคน', 'มาย', 'ฟ้า', 'ดาว', 'ฝน',
    'ปาล์ม', 'มะปราง', 'น้ำผึ้ง', 'ชิน', 'เต้ย', 'ปอนด์', 'มิว', 'เบล', 'เจมส์', 'ลูค',
    'เอม', 'เบิร์ด', 'ต้นโอ', 'ปิง', 'แพร', 'มิน', 'เติ้ล', 'ปุย', 'แม็ก', 'เจม',
    'โน้ต', 'พิม', 'แบงค์', 'ต้น', 'ปลา', 'หมู', 'ไก่', 'วัว', 'แมว', 'หมา',
    'นก', 'ปู', 'กุ้ง', 'ปลาดุก', 'ทูน่า', 'แซลมอน', 'เต่า', 'จระเข้', 'งู', 'กบ',
    'ผึ้ง', 'มด', 'แมลง', 'ใบ', 'ดอก', 'ผล', 'ราก', 'ลำ', 'กิ่ง', 'เมล็ด',
  ];

  static final all = <DemoCastPersona>[
    ..._buildKind(DemoCastKind.ceo, 1, 'ceo'),
    ..._buildKind(DemoCastKind.sup, 2, 'sup'),
    ..._buildKind(DemoCastKind.lead, 5, 'lead'),
    ..._buildKind(DemoCastKind.admin, 10, 'admin'),
    ..._buildGuides(10),
    ..._buildKind(DemoCastKind.seeker, 20, 'seeker'),
    ..._buildKind(DemoCastKind.broker, 10, 'broker'),
    ..._buildKind(DemoCastKind.owner, 20, 'owner'),
  ];

  static List<DemoCastPersona> byKind(DemoCastKind kind) =>
      all.where((p) => p.kind == kind).toList();

  static DemoCastPersona? find(String castId) {
    final id = castId.trim().toLowerCase();
    for (final p in all) {
      if (p.castId == id) return p;
    }
    return null;
  }

  static DemoCastPersona? authenticate({
    required String castId,
    required String password,
  }) {
    final hit = find(castId);
    if (hit == null) return null;
    if (hit.password != password.trim()) return null;
    return hit;
  }

  static List<DemoCastPersona> get guides => byKind(DemoCastKind.guide);

  static DemoCastPersona? guideByProfileId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final g in guides) {
      if (g.profileId == id || g.staffSlug == id) return g;
    }
    return null;
  }

  static List<DemoCastPersona> _buildKind(
    DemoCastKind kind,
    int count,
    String prefix,
  ) {
    return List.generate(count, (i) {
      final n = i + 1;
      final id = '$prefix-${n.toString().padLeft(2, '0')}';
      final name = _thaiNames[(i + kind.index * 3) % _thaiNames.length];
      return DemoCastPersona(
        castId: id,
        password: id,
        kind: kind,
        displayNameTh: _displayTh(kind, name, n),
        displayNameEn: _displayEn(kind, n),
        profileId: 'cast-$id',
        phone: '08${(10000000 + n + kind.index * 100).toString().substring(0, 8)}',
      );
    });
  }

  static List<DemoCastPersona> _buildGuides(int count) {
    return List.generate(count, (i) {
      final n = i + 1;
      final id = 'guide-${n.toString().padLeft(2, '0')}';
      final slug = 'guide-${n.toString().padLeft(2, '0')}';
      final uuid =
          '33333333-3333-3333-3333-33333333${n.toString().padLeft(4, '0')}';
      return DemoCastPersona(
        castId: id,
        password: id,
        kind: DemoCastKind.guide,
        displayNameTh: 'เอเจ้นพานัด ${n.toString().padLeft(2, '0')}',
        displayNameEn: 'Guide ${n.toString().padLeft(2, '0')}',
        profileId: uuid,
        staffSlug: slug,
        phone: '081-234-56${n.toString().padLeft(2, '0')}',
      );
    });
  }

  static String _displayTh(DemoCastKind kind, String name, int n) =>
      switch (kind) {
        DemoCastKind.ceo => 'CEO $name',
        DemoCastKind.sup => 'SUP $name',
        DemoCastKind.lead => 'Lead $name',
        DemoCastKind.admin => 'แอดมิน $name',
        DemoCastKind.seeker => 'ลูกค้า $name',
        DemoCastKind.broker => 'โคนายหน้า $name',
        DemoCastKind.owner => 'เจ้าของ $name',
        DemoCastKind.guide => 'เอเจ้นพานัด $n',
      };

  static String _displayEn(DemoCastKind kind, int n) => switch (kind) {
        DemoCastKind.ceo => 'CEO $n',
        DemoCastKind.sup => 'SUP $n',
        DemoCastKind.lead => 'Lead $n',
        DemoCastKind.admin => 'Admin $n',
        DemoCastKind.seeker => 'Customer $n',
        DemoCastKind.broker => 'Broker $n',
        DemoCastKind.owner => 'Owner $n',
        DemoCastKind.guide => 'Guide $n',
      };
}
