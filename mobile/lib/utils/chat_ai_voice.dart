/// โทน AI แชท — แอดมิน/ทีมงาน (ค่ะ/คะ) · ห้าม ดิฉัน/ผม/ครับ
library;

const greetingKeys = ['สวัสดี', 'hello', 'hi', 'หวัดดี', 'hey'];

const greetingReplyText =
    'สวัสดีค่ะ แอดมิน RealXtate ยินดีให้บริการค่ะ สอบถามรายละเอียดทรัพย์หรือทำเลที่สนใจได้เลยนะคะ';

String get greetingReply => greetingReplyText;

bool isGreetingOnly(String text) {
  final raw = text.trim();
  if (raw.length > 40) return false;

  final q = raw.toLowerCase();
  if (!greetingKeys.any(q.contains)) return false;

  var rest = q.replaceAll(RegExp(r'[!?.,…]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  for (final strip in [
    'สวัสดี', 'hello', 'hi', 'หวัดดี', 'hey',
    'ค่ะ', 'คะ', 'ครับ', 'คับ', 'จ้า', 'น้า', 'นะ', 'ค้า',
  ]) {
    rest = rest.split(strip).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  return rest.isEmpty;
}

const appliancesFaqReply =
    'เบื้องต้นที่มีข้อมูล จะมีเครื่องใช้ไฟฟ้าพื้นฐานตามรูปในประกาศเลยค่ะ\n\n'
    'ถ้าอยากทราบว่ามีทีวีหรือไม่ กี่นิ้ว หรือยี่ห้ออะไร หรือหากมีคำถามอื่น ๆ เพิ่มเติม '
    'สามารถพิมพ์สอบถามได้เลยนะคะ แอดมินจะรวบรวมไปสอบถามเจ้าของให้ทีเดียวเลยค่ะ';

const coAgentReply =
    'RealXtate รองรับการทำงานร่วมกับ Co-Agent สำหรับทรัพย์ที่เจ้าของโพสต์เอง '
    'หรือเจ้าของ opt-in รับ co-agent แล้วค่ะ\n\n'
    'ถ้าสนใจร่วมงาน กรุณาส่งรหัสทรัพย์ (LB-…) หรือรายละเอียดทรัพย์ในแชทนี้ได้เลยค่ะ '
    'แอดมินจะตรวจสอบสิทธิ์และติดต่อกลับค่ะ';

String get coAgentFaqReply => coAgentReply;

const internetFaqBurst = [
  'ตามรายละเอียดค่าเช่าจะไม่ได้รวมอินเทอร์เน็ตค่ะ ทางเรามีบริการช่างอินเทอร์เน็ตให้นะคะ ทั้งสองค่าย',
  'ลูกค้าแค่ทำการเลือกแพ็กเกจ ไม่ต้องลำบากติดต่อพนักงานเองเลยค่ะ',
];

bool isInternetQuestion(String text) {
  final q = text.toLowerCase();
  const keys = ['อินเทอร์เน็ต', 'เน็ต', 'wifi', 'wi-fi', 'internet', 'ติดเน็ต', 'ติดตั้งเน็ต'];
  return keys.any(q.contains);
}

bool isAppliancesQuestion(String text) {
  final q = text.toLowerCase();
  const keys = [
    'ทีวี', 'tv', 'แอร์', 'ตู้เย็น', 'ไมโครเวฟ', 'เครื่องใช้ไฟฟ้า', 'appliance',
  ];
  return keys.any(q.contains);
}

const projectOtherUnitsSingleReply =
    'ในโครงการ The Address Asoke ตอนนี้เท่าที่เช็คในระบบมีห้องนี้ค่ะ:\n\n'
    '[PPTR-2026-000101 · 15,000 บาท/เดือน (Net)] ← ห้องที่ลูกค้าเปิดแชทอยู่\n\n'
    'ถ้าหากลูกค้าต้องการเฉพาะห้องที่โครงการนี้เท่านั้น '
    'สามารถกรอกฟอร์มช่วยหาทรัพย์ให้แอดมินช่วยประกาศหาได้ค่ะ '
    'หรือถ้าดูโครงการอื่นๆ ไว้ด้วย ลองบอกรายละเอียดเพิ่มเติมเกี่ยวกับห้องที่กำลังหา '
    'แอดมินจะดำเนินการส่งห้องในระบบที่ตรงตามเงื่อนไขมาให้ดูค่ะ';

String ensureFemaleAiTone(String text) {
  var s = text.trim();
  if (s.isEmpty) return s;

  if (s.contains('ยินดีที่สนใจห้องนี้นะคะ')) {
    s = greetingReplyText;
  }

  s = s
      .replaceAll('ไหมครับ', 'ไหมคะ')
      .replaceAll('นะครับ', 'นะคะ')
      .replaceAll('ครับผม', 'ค่ะ')
      .replaceAll('ผมผู้ช่วย', 'แอดมิน RealXtate')
      .replaceAll('ผมช่วย', 'แอดมินช่วย')
      .replaceAll('ผมจะ', 'แอดมินจะ')
      .replaceAll('ผมได้', 'แอดมินได้')
      .replaceAll('ผม', 'แอดมิน')
      .replaceAll('ดิฉันช่วย', 'แอดมินช่วย')
      .replaceAll('ดิฉันจะ', 'แอดมินจะ')
      .replaceAll('ดิฉันได้', 'แอดมินได้')
      .replaceAll('ดิฉัน', 'แอดมิน')
      .replaceAll('ครับ', 'ค่ะ');

  return s;
}
