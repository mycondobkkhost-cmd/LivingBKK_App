/// บัญชีทดลอง — กดเลือกบทบาทได้โดยไม่ต้องมีรหัสผ่าน (ช่วง TRIAL_MODE)
class TrialPersona {
  const TrialPersona({
    required this.role,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.labelTh,
  });

  final String role;
  final String userId;
  final String email;
  final String displayName;
  final String labelTh;

  static const personas = [
    TrialPersona(
      role: 'seeker',
      userId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      email: 'ทดลอง-คนหาบ้าน@livingbkk.local',
      displayName: 'คนหาบ้าน (ทดลอง)',
      labelTh: 'คนหาบ้าน',
    ),
    TrialPersona(
      role: 'owner',
      userId: '11111111-1111-1111-1111-111111111111',
      email: 'demo-owner@livingbkk.local',
      displayName: 'เจ้าของทรัพย์ (ทดลอง)',
      labelTh: 'เจ้าของทรัพย์',
    ),
    TrialPersona(
      role: 'agent',
      userId: '33333333-3333-3333-3333-333333333333',
      email: 'ทดลอง-นายหน้า@livingbkk.local',
      displayName: 'นายหน้า (ทดลอง)',
      labelTh: 'นายหน้า',
    ),
    TrialPersona(
      role: 'admin',
      userId: '22222222-2222-2222-2222-222222222222',
      email: 'demo-admin@livingbkk.local',
      displayName: 'ผู้ดูแลระบบ (ทดลอง)',
      labelTh: 'แอดมิน',
    ),
  ];

  static TrialPersona? byRole(String role) {
    for (final p in personas) {
      if (p.role == role) return p;
    }
    return null;
  }
}
