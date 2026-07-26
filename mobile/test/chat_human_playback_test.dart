import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/chat_message.dart';
import 'package:livingbkk/utils/chat_human_playback.dart';

void main() {
  test('playReplies reveals one message bubble at a time', () async {
    final controller = ChatHumanPlaybackController();
    final replies = [
      ChatMessage(id: 'a', role: ChatMessageRole.ai, text: 'ข้อความแรกค่ะ'),
      ChatMessage(id: 'b', role: ChatMessageRole.ai, text: 'ข้อความสองค่ะ'),
    ];

    var ticks = 0;
    final play = controller.playReplies(
      replies,
      elapsedBeforePlayback: const Duration(seconds: 4),
      onTick: () => ticks++,
    );

    expect(controller.shouldHideMessage(replies[0]), isTrue);
    expect(controller.shouldHideMessage(replies[1]), isTrue);

    await play;
    expect(controller.shouldHideMessage(replies[0]), isFalse);
    expect(controller.shouldHideMessage(replies[1]), isFalse);
    expect(controller.isActive, isFalse);
    expect(ticks, greaterThan(0));
  });
}
