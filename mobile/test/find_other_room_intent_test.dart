import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/utils/chat_intent_helpers.dart';

void main() {
  group('find-other-room intent', () {
    test('หาห้องให้ได้ไหมคะ', () {
      expect(isFindOtherRoomIntent('หาห้องให้ได้ไหมคะ'), isTrue);
    });

    test('ไม่ตรงใจ triggers find-other', () {
      expect(
        isFindOtherRoomIntent('ห้องนี้ไม่ตรงใจ ช่วยหาอื่นให้หน่อย'),
        isTrue,
      );
    });

    test('ห้องอื่นในโครงการ is not find-other fork', () {
      expect(
        isFindOtherRoomIntent('มีห้องอื่นในโครงการนี้ไหม'),
        isFalse,
      );
    });

    test('zone+budget on property is discovery not find-other', () {
      expect(isDiscoveryIntentOnProperty('หาคอนโดแถวอโศกงบหมื่นห้า'), isTrue);
      expect(isFindOtherRoomIntent('หาคอนโดแถวอโศกงบหมื่นห้า'), isFalse);
    });

    test('generic หา without zone on property is not discovery', () {
      expect(isDiscoveryIntentOnProperty('หาห้องให้ได้ไหมคะ'), isFalse);
    });
  });
}
