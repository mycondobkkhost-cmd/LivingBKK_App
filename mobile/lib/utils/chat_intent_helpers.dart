/// Mirrors supabase/functions/_shared/chat_logic.ts intent helpers (trial + tests).
library;

bool wantsOtherUnitsInProject(String text) {
  final q = text.toLowerCase();
  const keys = [
    'ห้องอื่น', 'ตัวอื่น', 'ในโครงการ', 'other unit', 'in project',
    'ห้องอื่นอีก', 'มีห้องอื่น',
  ];
  return keys.any((k) => q.contains(k));
}

bool isFindOtherRoomIntent(String text) {
  final q = text.toLowerCase();
  if (wantsOtherUnitsInProject(text)) return false;
  const keys = [
    'หาห้องให้', 'ช่วยหา', 'ฝากหา', 'หาห้อง', 'หาคอนโดให้', 'หาบ้านให้',
    'ช่วยสแกน', 'ช่วยคัด', 'find me a room', 'help me find', 'help find',
    'ไม่ตรงใจ', 'ไม่ชอบ', 'ไม่โดน', 'ไม่ถูกใจ', 'อยากได้อื่น', 'อยากได้ห้องอื่น',
    'หาที่พัก', 'หาที่อยู่', 'หาห้องอื่น', 'ขอห้องอื่น', 'รีบหาที่อยู่', 'ต้องการห้องด่วน',
  ];
  return keys.any((k) => q.contains(k));
}

bool isBroadDiscoveryIntent(String text) {
  final q = text.toLowerCase();
  const keys = [
    'หา', 'แนะนำ', 'ค้นห', 'อยาก', 'โครงการ', 'คอนโด', 'บ้าน',
    'bts', 'mrt', 'ใกล้', 'งบ', 'เช่า', 'ซื้อ', 'ห้องอื่น', 'ตัวอื่น',
    'find', 'search', 'recommend', 'condo', 'rent', 'buy', 'budget', 'near',
    'project', 'looking', 'other unit',
  ];
  if (keys.any((k) => q.contains(k))) return true;
  return RegExp(r'\d[\d,]*').hasMatch(q);
}

bool isDiscoveryIntentOnProperty(String text) {
  if (isFindOtherRoomIntent(text)) return false;
  if (wantsOtherUnitsInProject(text)) return true;
  if (!isBroadDiscoveryIntent(text)) return false;
  final q = text.toLowerCase();
  const zones = [
    'ทองหล่อ', 'เอกมัย', 'อโศก', 'สุขุมวิท', 'สาทร', 'สีลม', 'พระโขนง', 'อารีย์',
    'ลาดพร้าว', 'thong', 'ekkamai', 'asok', 'sukhumvit', 'sathorn', 'silom', 'bts', 'mrt',
  ];
  if (zones.any((z) => q.contains(z))) return true;
  if (RegExp(r'\d[\d,]*\s*(?:บาท|k)', caseSensitive: false).hasMatch(q)) {
    return true;
  }
  if (RegExp(r'\b(ideo|noble|rhythm|the\s|mobi|place)\b', caseSensitive: false)
      .hasMatch(q)) {
    return true;
  }
  return false;
}

bool shouldRejectProjectHint(String name) {
  const reject = [
    'ให้ได้ไหม', 'ได้ไหม', 'หน่อย', 'ช่วยหา', 'หาห้อง', 'หาคอนโด',
    'ไหมคะ', 'ไหมครับ', 'ค่ะ', 'ครับ',
  ];
  final lower = name.toLowerCase();
  return reject.any((r) => lower.contains(r));
}
