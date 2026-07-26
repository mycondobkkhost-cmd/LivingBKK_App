import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/utils/chat_ai_voice.dart';

void main() {
  test('ensureFemaleAiTone converts masculine bot text', () {
    const raw = 'สวัสดีครับ ยินดีช่วยเหลือครับ ผมช่วยคัดให้';
    expect(
      ensureFemaleAiTone(raw),
      'สวัสดีค่ะ ยินดีช่วยเหลือค่ะ แอดมินช่วยคัดให้',
    );
  });

  test('isGreetingOnly matches สวัสดีค่ะ', () {
    expect(isGreetingOnly('สวัสดีค่ะ'), isTrue);
    expect(greetingReply, 'สวัสดีค่ะ แอดมิน RealXtate ยินดีให้บริการค่ะ สอบถามรายละเอียดทรัพย์หรือทำเลที่สนใจได้เลยนะคะ');
  });

  test('isGreetingOnly rejects greeting + question', () {
    expect(isGreetingOnly('สวัสดีค่ะ ราคาเท่าไร'), isFalse);
  });
}
