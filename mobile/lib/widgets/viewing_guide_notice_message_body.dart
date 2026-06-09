import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import 'chat_copyable_text.dart';

/// ข้อความยืนยันนัดลูกค้า — แท็ก/ลิงก์วางตามบรรทัดที่อ้างถึง
bool isViewingGuideNoticeDisplayText(String text) {
  final t = text.trim();
  return t.startsWith('✅ ยืนยันนัดชมทรัพย์') ||
      t.startsWith('✅ Your viewing is confirmed');
}

enum _GuideLinkSlot { map, footer }

_GuideLinkSlot? _slotForLine(String line) {
  final t = line.trim();
  if (t.startsWith('📍')) return _GuideLinkSlot.map;
  if (t.contains('กรุณากดยืนยันนัด') ||
      t.contains('Please confirm when notified')) {
    return _GuideLinkSlot.footer;
  }
  return null;
}

List<ChatMessageLink> _linksForSlot(
  List<ChatMessageLink> links,
  _GuideLinkSlot slot,
) {
  switch (slot) {
    case _GuideLinkSlot.map:
      return links
          .where((l) => l.kind == ChatMessageLinkKind.viewingLocation)
          .toList();
    case _GuideLinkSlot.footer:
      return links
          .where(
            (l) =>
                l.kind == ChatMessageLinkKind.viewingRequest ||
                l.kind == ChatMessageLinkKind.profileTag,
          )
          .toList();
  }
}

class ViewingGuideNoticeMessageBody extends StatelessWidget {
  const ViewingGuideNoticeMessageBody({
    super.key,
    required this.text,
    required this.links,
    required this.style,
    required this.linkBuilder,
    this.selectionColor,
    this.linkSpacing = 6,
    this.afterLinkSpacing = 8,
  });

  final String text;
  final List<ChatMessageLink> links;
  final TextStyle style;
  final Widget Function(ChatMessageLink link) linkBuilder;
  final Color? selectionColor;
  final double linkSpacing;
  final double afterLinkSpacing;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final children = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      children.add(
        ChatCopyableText(
          text: line,
          style: style,
          selectionColor: selectionColor,
        ),
      );

      final slot = _slotForLine(line);
      if (slot != null) {
        final slotLinks = _linksForSlot(links, slot);
        if (slotLinks.isNotEmpty) {
          children.add(SizedBox(height: linkSpacing));
          for (final link in slotLinks) {
            children.add(
              Padding(
                padding: EdgeInsets.only(bottom: linkSpacing),
                child: linkBuilder(link),
              ),
            );
          }
          children.add(SizedBox(height: afterLinkSpacing - linkSpacing));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
