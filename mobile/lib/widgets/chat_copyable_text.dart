import 'package:flutter/material.dart';

/// ข้อความในแชท — ลากคลุมเลือกได้ (เว็บ/คอม) · มือถือกดค้างเลือกแล้วคัดลอก
class ChatCopyableText extends StatelessWidget {
  const ChatCopyableText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.selectionColor,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final fg = style.color ?? Theme.of(context).textTheme.bodyMedium?.color;
    final sel = selectionColor ??
        (fg != null ? fg.withOpacity(0.28) : null);

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: sel,
          cursorColor: fg,
          selectionHandleColor: fg,
        ),
      ),
      child: SelectableText(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        showCursor: false,
      ),
    );
  }
}
