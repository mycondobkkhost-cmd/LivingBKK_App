// ignore_for_file: avoid_print
/// Simulate property-chat bot routing (mirrors chat_router.ts).
/// Usage: dart run scripts/simulate_property_chat.dart "ข้อความลูกค้า" [unclear_streak]
import 'dart:convert';

import 'package:livingbkk/utils/chat_ai_voice.dart';
import 'package:livingbkk/utils/chat_map_link.dart' as map_link;
import 'package:livingbkk/utils/chat_intent_helpers.dart';
import 'package:livingbkk/utils/viewing_request_voice.dart';

void main(List<String> args) {
  final unclear = args.isNotEmpty && int.tryParse(args.last) != null
      ? int.parse(args.last)
      : 0;
  final message = args.isEmpty
      ? ''
      : (int.tryParse(args.last) != null && args.length > 1)
          ? args.sublist(0, args.length - 1).join(' ')
          : args.join(' ');

  if (message.trim().isEmpty) {
    print(_welcome);
    return;
  }

  final q = message.toLowerCase();

  if (_isExplicitStaff(message)) {
    _out('system', _escalate, admin: true, source: 'staff_request');
    return;
  }
  if (_hasPhone(message)) {
    _out('ai', _phoneAck, admin: true, source: 'phone_provided');
    return;
  }
  if (isFindOtherRoomIntent(message)) {
    _outBurst([
      'เข้าใจค่ะ ห้องนี้อาจยังไม่ตรงใจ — RealXtate ช่วยหาห้องที่ตรงบรีฟได้ค่ะ',
      'กรอกบรีฟในแชทแยก (ทีมคัดส่งให้) — แชทนี้ยังถามเรื่องทรัพย์นี้ต่อได้เลยค่ะ '
          'หลังส่งฟอร์มแล้ว ทีมจะแจ้งแอดมินเมื่อพร้อมคัดห้องให้จริงๆ ค่ะ',
    ], links: ['กรอกบรีฟฝากหาห้อง'], source: 'find_other_room');
    return;
  }
  if (isViewingRequestIntent(message)) {
    _outBurst(viewingRequestBurst(message), source: 'viewing_request');
    return;
  }
  if (q.contains('ต่อรอง') || q.contains('ลดราคา') || q.contains('ลดได้') || q.contains('ต่อราคา')) {
    _outBurst([
      'ในระบบข้อมูลที่ลงราคา 15,000 บาท/เดือน เป็นราคาสุทธิแล้วค่ะ',
      'แต่ถ้าหากลูกค้าดูแล้วพร้อมจอง ทางแอดมินจะช่วยคุยกับเจ้าของให้อย่างสุดความสามารถเลยค่ะ',
    ], source: 'price_negotiate_sales');
    return;
  }
  if (q.contains('สวัสดี') || q.contains('hello') || q.contains('หวัดดี')) {
    if (isGreetingOnly(message)) {
      _out('ai', greetingReply, source: 'greeting');
      return;
    }
  }
  if (wantsOtherUnitsInProject(message)) {
    _out(
      'ai',
      projectOtherUnitsSingleReply,
      source: 'project_other_sparse',
      links: [
        'PPTR-2026-000101 · 15,000 บาท/เดือน (Net)',
        'กรอกฟอร์มช่วยหาทรัพย์',
      ],
    );
    return;
  }
  if (isAppliancesQuestion(message)) {
    _out('ai', appliancesFaqReply, source: 'faq_appliances');
    return;
  }
  if (map_link.isLocationQuestion(message)) {
    _outBurst([
      'แอดมินส่งโลเคชั่นโครงการให้ทางนี้นะคะ ลูกค้าสามารถคลิกเพื่อตรวจสอบพิกัดได้เลยค่ะ',
    ], links: ['เปิด Google Maps · โครงการ'], source: 'location_map');
    return;
  }
  if (isInternetQuestion(message)) {
    _outBurst(internetFaqBurst, source: 'internet_concierge');
    return;
  }
  if (q.contains('ราคา') || q.contains('เท่าไร') || q.contains('เท่าไหร่') || q.contains('price')) {
    _out('ai', 'ราคา Net ของห้องนี้ (PPTR-2026-000101) อยู่ที่ 15,000 บาท/เดือนค่ะ '
        'ราคานี้รวมค่าบริการตัวกลางแล้วสำหรับผู้เช่าค่ะ', source: 'faq_property');
    return;
  }
  if (q.contains('สัตว') || q.contains('เลี้ยง') || q.contains('pet')) {
    _out('ai', 'เรื่องสัตว์เลี้ยงขึ้นกับเงื่อนไขของเจ้าของแต่ละรายค่ะ '
        'เจ้าหน้าที่จะยืนยันให้เมื่อติดต่อกลับ — หรือกรอกคำถามส่งเจ้าของในแชทนี้ได้ค่ะ', source: 'faq_property');
    return;
  }
  if (q.contains('เบอร์') || q.contains('line') || q.contains('ไลน์') || q.contains('โทร')) {
    _out('ai', 'ทางแพลตฟอร์มไม่เปิดเผยเบอร์/Line เจ้าของค่ะ (PDPA) '
        'รบกวนแจ้งเบอร์ของคุณ + คำถามในแชทนี้ เจ้าหน้าที่จะติดต่อกลับค่ะ', source: 'sensitive_contact');
    return;
  }
  if (isDiscoveryIntentOnProperty(message)) {
    _out('ai', 'พบทรัพย์ที่ใกล้เคียงบรีฟของคุณ:\nThe Address Asoke\n'
        'กดลิงก์ด้านล่างเพื่อดูประกาศ หรือห้องอื่นในโครงการ', links: [
      'PPTR-2026-000101 · 15,000 บาท/เดือน (Net)',
    ], source: 'discovery_db');
    return;
  }
  if (unclear < 2) {
    _out('ai', 'ยังไม่แน่ใจคำถามค่ะ ลองระบุทำเล · งบ · หรือรายละเอียดที่ต้องการเพิ่ม\n'
        'หากต้องการให้ช่วยหาห้องอื่น พิมพ์「ช่วยหาห้อง」\n'
        'หรือพิมพ์「ขอคุยกับเจ้าหน้าที่」เมื่อต้องการให้ทีมช่วยโดยตรงค่ะ', source: 'soft_clarify');
    return;
  }
  _out('system', _escalate, admin: true, source: 'fallback_admin');
}

const _welcome = '''
🤖 RealXtate AI (จำลองแชททรัพย์)
─────────────────────────────
ทรัพย์: PPTR-2026-000101 · The Address Asoke
เช่า Net 15,000 บาท/เดือน · วัฒนา

สวัสดีค่ะ แอดมิน RealXtate ดูแลห้องนี้ให้นะคะ
ถามรายละเอียดได้เลยค่ะ — หากไม่ตรงใจ พิมพ์「ช่วยหาห้อง」ได้ค่ะ
''';

const _escalate =
    'คำถามนี้ต้องให้เจ้าหน้าที่ตอบโดยตรงค่ะ — ดิฉันแจ้งทีมแล้ว และจะติดต่อกลับในแชทนี้โดยเร็วที่สุดค่ะ';

const _phoneAck =
    'ขอบคุณมากค่ะ ทางเราได้รับเบอร์ติดต่อและข้อมูลของท่านเรียบร้อยแล้ว '
    'ทีมงานจะรีบนำข้อมูลไปตรวจสอบและติดต่อกลับเพื่อให้บริการโดยเร็วที่สุดค่ะ';

bool _isExplicitStaff(String t) {
  const k = ['ขอคุยกับแอดมิน', 'ขอคุยกับเจ้าหน้าที่', 'คุยกับเจ้าหน้าที่', 'ขอเจ้าหน้าที่'];
  final q = t.toLowerCase();
  return k.any(q.contains);
}

bool _hasPhone(String t) {
  final c = t.replaceAll(RegExp(r'[\s\-().]'), '');
  return RegExp(r'(?:^|[^\d])(0[689]\d{8}|0[2-9]\d{7,8})(?:[^\d]|$)').hasMatch(c);
}

void _out(String role, String text, {bool admin = false, String? source, List<String>? links}) {
  print(jsonEncode({
    'role': role,
    'text': text,
    'admin': admin,
    'source': source,
    'links': links ?? [],
  }));
}

void _outBurst(List<String> texts, {List<String>? links, String? source}) {
  print(jsonEncode({
    'role': 'ai',
    'burst': texts,
    'admin': false,
    'source': source,
    'links': links ?? [],
  }));
}
