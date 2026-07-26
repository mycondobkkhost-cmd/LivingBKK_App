import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/utils/chat_text_fuzzy.dart';
import 'package:livingbkk/utils/viewing_request_voice.dart';

void main() {
  group('viewing request intent', () {
    test('สนใจนัดดู', () {
      expect(isViewingRequestIntent('สนใจนัดดู'), isTrue);
      expect(viewingRequestBurst('สนใจนัดดู'), [
        'ได้เลยค่ะ สะดวกเป็นช่วงวันไหนดีคะ',
        'แอดมินจะรีบเช็กคิวและประสานงานให้ค่ะ',
      ]);
    });

    test('อยากนัดดูวันนี้ — ถามเวลา', () {
      expect(isViewingRequestIntent('ถ้าอยากนัดดูวันนี้ได้ไหมครับ'), isTrue);
      expect(viewingRequestBurst('อยากนัดดูวันนี้'), [
        'ได้เลยค่ะ วันนี้ลูกค้าสะดวกประมาณกี่โมงคะ',
        'แอดมินจะสอบถามเจ้าของให้โดยประมาณนะคะ',
      ]);
    });

    test('typo นัดดุวันนี้', () {
      expect(isViewingRequestIntent('นัดดุวันนี้'), isTrue);
      expect(normalizeChatText('นัดดุ'), contains('นัดดู'));
    });
  });
}
