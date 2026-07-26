import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';

/// จังหวะตอบแบบมนุษย์ — หน่วงคิด ~4 วินาที แล้วเปิดทีละฟอง (ไม่แตก/ไม่รวมข้อความ)
class ChatHumanPlaybackTiming {
  static const initialThinkDelay = Duration(seconds: 4);
  static const betweenMessages = Duration(milliseconds: 550);
  static const minTypingDelay = Duration(milliseconds: 900);
  static const maxTypingDelay = Duration(milliseconds: 2800);

  static Duration typingDelayFor(String text) {
    final ms = (900 + text.length * 38).clamp(900, 2800);
    return Duration(milliseconds: ms);
  }
}

class ChatHumanPlaybackController {
  final Set<String> _hiddenSourceIds = {};
  bool _isTyping = false;
  bool _isActive = false;

  bool get isActive => _isActive;
  bool get isTyping => _isTyping;

  bool shouldHideMessage(ChatMessage message) {
    return _hiddenSourceIds.contains(message.id);
  }

  void showWaitingForReply() {
    _isActive = true;
    _isTyping = true;
  }

  void reset() {
    _hiddenSourceIds.clear();
    _isTyping = false;
    _isActive = false;
  }

  void stashReplies(List<ChatMessage> replies) {
    _isActive = true;
    _isTyping = true;
    for (final message in replies) {
      if (message.role == ChatMessageRole.ai &&
          message.text.trim().isNotEmpty) {
        _hiddenSourceIds.add(message.id);
      }
    }
  }

  Future<void> playReplies(
    List<ChatMessage> replies, {
    required VoidCallback onTick,
    VoidCallback? onScroll,
    Duration elapsedBeforePlayback = Duration.zero,
  }) async {
    final aiReplies = replies
        .where((m) => m.role == ChatMessageRole.ai && m.text.trim().isNotEmpty)
        .toList();
    if (aiReplies.isEmpty) {
      reset();
      return;
    }

    stashReplies(aiReplies);
    onTick();
    onScroll?.call();

    final remainingThink = ChatHumanPlaybackTiming.initialThinkDelay -
        elapsedBeforePlayback;
    if (remainingThink > Duration.zero) {
      _isTyping = true;
      onTick();
      onScroll?.call();
      await Future<void>.delayed(remainingThink);
    }

    for (var i = 0; i < aiReplies.length; i++) {
      final message = aiReplies[i];

      _isTyping = true;
      onTick();
      onScroll?.call();
      await Future<void>.delayed(
        ChatHumanPlaybackTiming.typingDelayFor(message.text),
      );

      _isTyping = false;
      _hiddenSourceIds.remove(message.id);
      onTick();
      onScroll?.call();

      if (i < aiReplies.length - 1) {
        await Future<void>.delayed(ChatHumanPlaybackTiming.betweenMessages);
      }
    }

    _isTyping = false;
    _isActive = false;
    onTick();
    onScroll?.call();
  }
}
