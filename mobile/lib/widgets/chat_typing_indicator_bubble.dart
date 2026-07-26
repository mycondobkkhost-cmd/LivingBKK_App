import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// ฟองข้อความ「กำลังพิมพ์…」แบบ Messenger
class ChatTypingIndicatorBubble extends StatefulWidget {
  const ChatTypingIndicatorBubble({super.key});

  @override
  State<ChatTypingIndicatorBubble> createState() =>
      _ChatTypingIndicatorBubbleState();
}

class _ChatTypingIndicatorBubbleState extends State<ChatTypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final phase = (_controller.value + index * 0.2) % 1.0;
                final scale = 0.65 + (phase < 0.5 ? phase : 1 - phase) * 0.7;
                return Container(
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 5),
                  width: 7 * scale,
                  height: 7 * scale,
                  decoration: BoxDecoration(
                    color: p.textSecondary.withOpacity(0.45 + scale * 0.35),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
