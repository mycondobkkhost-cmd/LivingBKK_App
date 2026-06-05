import '../config/legal_config.dart';

class LegalSection {
  const LegalSection({required this.titleTh, required this.titleEn, required this.bodyTh, required this.bodyEn});

  final String titleTh;
  final String titleEn;
  final String bodyTh;
  final String bodyEn;
}

class LegalDocuments {
  LegalDocuments._();

  static String header(LegalDocumentType type, bool isEnglish) {
    final en = isEnglish;
    if (type == LegalDocumentType.privacy) {
      return en
          ? 'Privacy Policy — ${LegalConfig.operatorName}\nEffective: ${LegalConfig.effectiveDateEn}\nVersion: ${LegalConfig.version}'
          : 'นโยบายความเป็นส่วนตัว — ${LegalConfig.operatorName}\nมีผล: ${LegalConfig.effectiveDate}\nเวอร์ชัน: ${LegalConfig.version}';
    }
    return en
        ? 'Terms of Service — ${LegalConfig.operatorName}\nEffective: ${LegalConfig.effectiveDateEn}\nVersion: ${LegalConfig.version}'
        : 'เงื่อนไขการใช้บริการ — ${LegalConfig.operatorName}\nมีผล: ${LegalConfig.effectiveDate}\nเวอร์ชัน: ${LegalConfig.version}';
  }

  static List<LegalSection> sections(LegalDocumentType type) {
    return type == LegalDocumentType.privacy ? _privacy : _terms;
  }

  static const _privacy = <LegalSection>[
    LegalSection(
      titleTh: '1. ผู้ควบคุมข้อมูล',
      titleEn: '1. Data controller',
      bodyTh:
          'แอปและบริการ ${LegalConfig.operatorName} ดำเนินการโดยผู้ให้บริการแพลตฟอร์มอสังหาริมทรัพย์ '
          '(“เรา”) ติดต่อเรื่องความเป็นส่วนตัวได้ที่ ${LegalConfig.contactEmail}',
      bodyEn:
          '${LegalConfig.operatorName} is operated by the platform provider (“we”). '
          'Privacy inquiries: ${LegalConfig.contactEmail}',
    ),
    LegalSection(
      titleTh: '2. ข้อมูลที่เราเก็บ',
      titleEn: '2. Data we collect',
      bodyTh:
          '• บัญชี: อีเมล รหัสผ่าน (เข้ารหัสฝั่งผู้ให้บริการ) ชื่อที่แสดง รูปโปรไฟล์ บทบาท\n'
          '• ประกาศ: รายละเอียดทรัพย์ ราคา รูป/วิดีโอ ลิงก์แผนที่ แฮชแท็ก ภาษา\n'
          '• ติดต่อส่วนตัว (ไม่แสดงในประกาศสาธารณะ): เบอร์โทร ไอดีไลน์ — ใช้เพื่อให้ทีมงานติดต่อคุณเมื่อมีผู้สนใจ\n'
          '• การใช้งาน: การค้นหา รายการโปรด แชท นัดชม ลีด — เพื่อให้บริการและปรับปรุงระบบ\n'
          '• อุปกรณ์: โทเคนแจ้งเตือน (ถ้าเปิดใช้) ข้อมูลทางเทคนิคของอุปกรณ์',
      bodyEn:
          '• Account: email, password (handled by auth provider), display name, role\n'
          '• Listings: property details, price, media, map links, languages\n'
          '• Private contact (not shown on public listings): phone, Line ID — for our team to reach you when there is interest\n'
          '• Usage: search, saves, chat, viewings, leads\n'
          '• Device: push tokens (if enabled), technical device data',
    ),
    LegalSection(
      titleTh: '3. วัตถุประสงค์',
      titleEn: '3. Purposes',
      bodyTh:
          'ให้บริการโพสต์/ค้นหาทรัพย์ จับคู่ลูกค้า–ตัวแทน ตรวจสอบประกาศก่อนเผยแพร่ ป้องกันการฉ้อโกง '
          'ส่งการแจ้งเตือนที่เกี่ยวข้อง และปฏิบัติตามกฎหมายที่ใช้บังคับ',
      bodyEn:
          'To provide listing/search services, match customers and agents, moderate listings before publish, '
          'prevent fraud, send relevant notifications, and comply with applicable law.',
    ),
    LegalSection(
      titleTh: '4. การเปิดเผย',
      titleEn: '4. Sharing',
      bodyTh:
          'ประกาศสาธารณะแสดงเฉพาะเนื้อหาที่คุณเลือกเผยแพร่ — ไม่แสดงเบอร์/ไลน์ในหน้าประกาศสาธารณะ\n'
          'เราอาจใช้ผู้ให้บริการโฮสต์ฐานข้อมูล (เช่น Supabase) แผนที่ (Google) และแจ้งเตือน (Firebase) '
          'ภายใต้สัญญาความลับ เราไม่ขายข้อมูลส่วนบุคคลของคุณ',
      bodyEn:
          'Public listings show only what you publish — phone/Line are not shown on public listing pages.\n'
          'We use hosting (e.g. Supabase), maps (Google), and push (Firebase) under confidentiality. '
          'We do not sell your personal data.',
    ),
    LegalSection(
      titleTh: '5. ระยะเวลาเก็บรักษา',
      titleEn: '5. Retention',
      bodyTh:
          'เก็บข้อมูลตราบที่บัญชีหรือประกายังใช้งาน และตามที่กฎหมายกำหนด หลังปิดบัญชีเราจะลบหรือทำให้ไม่ระบุตัวตน '
          'ภายในระยะที่สมเหตุสมผล ยกเว้นข้อมูลที่ต้องเก็บเพื่อพิสูจน์การยอมรับเงื่อนไขหรือข้อพิพาท',
      bodyEn:
          'We retain data while your account or listings are active and as required by law. '
          'After account closure we delete or anonymize within a reasonable period, except records needed for consent or disputes.',
    ),
    LegalSection(
      titleTh: '6. สิทธิของคุณ',
      titleEn: '6. Your rights',
      bodyTh:
          'คุณสามารถขอเข้าถึง แก้ไข ลบบัญชี หรือคัดค้านการประมวลผลที่ไม่จำเป็น — ติดต่อ ${LegalConfig.contactEmail} '
          'เราจะตอบภายในระยะเวลาที่กฎหมายกำหนด',
      bodyEn:
          'You may request access, correction, account deletion, or object to non-essential processing — contact '
          '${LegalConfig.contactEmail}. We respond within applicable legal timeframes.',
    ),
    LegalSection(
      titleTh: '7. ความปลอดภัย',
      titleEn: '7. Security',
      bodyTh:
          'เราใช้มาตรการทางเทคนิคและองค์กรที่เหมาะสม อย่างไรก็ตามการส่งข้อมูลทางอินเทอร์เน็ตไม่ปลอดภัย 100%',
      bodyEn:
          'We apply appropriate technical and organizational measures. No internet transmission is 100% secure.',
    ),
    LegalSection(
      titleTh: '8. การเปลี่ยนแปลง',
      titleEn: '8. Changes',
      bodyTh:
          'เราอาจปรับนโยบายนี้ จะแจ้งในแอปหรือเว็บ และระบุเวอร์ชันใหม่ การใช้บริการต่อหลังมีผลถือว่ายอมรับ',
      bodyEn:
          'We may update this policy with in-app or web notice and a new version number. Continued use means acceptance.',
    ),
  ];

  static const _terms = <LegalSection>[
    LegalSection(
      titleTh: '1. การยอมรับ',
      titleEn: '1. Acceptance',
      bodyTh:
          'การสมัคร ลงประกาศ หรือใช้ ${LegalConfig.operatorName} หมายความว่าคุณอ่านและยอมรับเงื่อนไขนี้ '
          'และนโยบายความเป็นส่วนตัว (เวอร์ชัน ${LegalConfig.version})',
      bodyEn:
          'By signing up, posting, or using ${LegalConfig.operatorName} you accept these Terms and the Privacy Policy '
          '(version ${LegalConfig.version}).',
    ),
    LegalSection(
      titleTh: '2. บริการ',
      titleEn: '2. Service',
      bodyTh:
          'แพลตฟอร์มเชื่อมต่อผู้ลงประกาศ ตัวแทน และผู้สนใจทรัพย์ เราไม่ใช่คู่สัญญาซื้อขาย/เช่าโดยตรง '
          'ไม่รับประกันผลการปิดดีล ราคา หรือความถูกต้องของข้อมูลที่ผู้ใช้ลง',
      bodyEn:
          'We connect posters, agents, and seekers. We are not a party to sale/lease contracts and do not guarantee '
          'deals, prices, or user-provided accuracy.',
    ),
    LegalSection(
      titleTh: '3. เนื้อหาผู้ใช้ (UGC)',
      titleEn: '3. User content',
      bodyTh:
          'คุณรับผิดชอบความถูกต้องของประกาศ รูป และวิดีโอ ห้ามลงข้อมูลเท็จ ทรัพย์ที่ไม่มีสิทธิ์ สแปม '
          'หรือข้อมูลติดต่อในส่วนที่ผู้ชมทั่วไปเห็น (เบอร์/ไลน์ต้องอยู่ในช่องส่วนตัวที่ทีมงานดูเท่านั้น)\n'
          'คุณให้สิทธิเราแสดง จัดเก็บ และเผยแพร่เนื้อหาที่ส่งเพื่อให้บริการ',
      bodyEn:
          'You are responsible for listing accuracy. No false listings, unauthorized properties, spam, or public contact '
          'in the viewer-facing content. You grant us rights to host and display content to operate the service.',
    ),
    LegalSection(
      titleTh: '4. การตรวจสอบก่อนเผยแพร่',
      titleEn: '4. Moderation',
      bodyTh:
          'ประกาศใหม่อยู่ในสถานะรอตรวจ (pending review) ทีมงานอาจอนุมัติ ปฏิเสธ หรือขอแก้ไข '
          'เราอาจลบประกาศที่ละเมิดกฎหมายหรือเงื่อนไขโดยไม่ต้องแจ้งล่วงหน้าในกรณีเร่งด่วน',
      bodyEn:
          'New listings are pending review. We may approve, reject, or request edits, and remove violations without '
          'prior notice when urgent.',
    ),
    LegalSection(
      titleTh: '5. ค่าคอมมิชชันและราคา',
      titleEn: '5. Commission and pricing',
      bodyTh:
          'ตัวเลือกค่าคอมมิชชันในแอปเป็นแนวทางตามที่คุณระบุ ไม่ใช่สัญญาผูกพันกับบุคคลที่สาม '
          'การเจรจาจริงอยู่ระหว่างคู่ค้า',
      bodyEn:
          'In-app commission options reflect your stated intent, not binding third-party contracts. '
          'Final terms are between the parties.',
    ),
    LegalSection(
      titleTh: '6. บัญชีและความปลอดภัย',
      titleEn: '6. Accounts',
      bodyTh:
          'รักษาความลับรหัสผ่าน แจ้งเราหากมีการใช้บัญชีโดยไม่ได้รับอนุญาต เราอาจระงับบัญชีที่ละเมิดหรือเสี่ยงต่อผู้อื่น',
      bodyEn:
          'Keep credentials secure and report unauthorized use. We may suspend accounts that violate these Terms or harm others.',
    ),
    LegalSection(
      titleTh: '7. ข้อจำกัดความรับผิด',
      titleEn: '7. Liability',
      bodyTh:
          'บริการให้ “ตามสภาพ” เราไม่รับผิดต่อความเสียหายทางอ้อมจากการใช้แพลตฟอร์ม '
          'ภายในขอบเขตที่กฎหมายไม่อนุญาตให้จำกัด',
      bodyEn:
          'The service is provided “as is”. We are not liable for indirect damages from platform use, '
          'to the extent permitted by law.',
    ),
    LegalSection(
      titleTh: '8. กฎหมายที่ใช้บังคับ',
      titleEn: '8. Governing law',
      bodyTh:
          'เงื่อนไขนี้อยู่ภายใต้กฎหมายไทย ข้อพิพาทให้พยายามเจรจาเป็นอันดับแรก ติดต่อ ${LegalConfig.contactEmail}',
      bodyEn:
          'These Terms are governed by Thai law. Disputes should first be resolved amicably — contact ${LegalConfig.contactEmail}',
    ),
  ];
}
