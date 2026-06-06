import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/l10n/app_strings.dart';
import 'package:livingbkk/models/chat_room.dart';
import 'package:livingbkk/utils/chat_room_display.dart';

void main() {
  test('requirement room is not staff support and uses need title', () {
    final s = AppStrings(false);
    final room = ChatRoom(
      id: 'thread-req-1',
      listingId: '',
      listingCode: 'REQ',
      listingTitle: 'หาคอนโด 2 ห้องนอน',
      roomKind: 'staff_support',
      category: 'customer_requirement',
    );

    expect(room.isCustomerRequirement, isTrue);
    expect(room.isStaffSupport, isFalse);
    expect(room.chatScreenTitle(s), s.chatRequirementRoomTitle);
    expect(room.historyListTitle(s), 'หาคอนโด 2 ห้องนอน');
  });

  test('discovery room uses discovery labels', () {
    final s = AppStrings(true);
    final room = ChatRoom(
      id: 'discovery-1',
      listingId: '',
      listingCode: 'DISCOVERY',
      listingTitle: 'PROPPITER — Property search',
      category: 'discovery',
    );

    expect(room.isDiscovery, isTrue);
    expect(room.chatScreenTitle(s), s.chatDiscoveryTitle);
    expect(room.historyListTitle(s), s.chatDiscoveryRoomTitle);
  });
}
