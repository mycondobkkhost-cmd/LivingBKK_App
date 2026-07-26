import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../features/contact/chat_link_detail_sheets.dart';
import '../theme/app_theme.dart';
import '../utils/tag_mention_utils.dart';

/// ข้อความแชทที่ไฮไลต์ @แท็ก — กดเปิด detail sheet
class TagMentionText extends StatelessWidget {
  const TagMentionText({
    super.key,
    required this.text,
    required this.style,
    this.adminView = true,
  });

  final String text;
  final TextStyle style;
  final bool adminView;

  @override
  Widget build(BuildContext context) {
    final spans = TagMentionUtils.mentionSpans(text);
    if (spans.isEmpty) {
      return SelectableText(text, style: style);
    }

    final children = <InlineSpan>[];
    var cursor = 0;
    for (final span in spans) {
      if (span.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, span.start)));
      }
      final mention = text.substring(span.start, span.end);
      children.add(
        TextSpan(
          text: mention,
          style: style.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              showProfileTagDetailSheet(
                context,
                span.code,
                adminView: adminView,
              );
            },
        ),
      );
      cursor = span.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }

    return SelectableText.rich(
      TextSpan(style: style, children: children),
    );
  }
}
