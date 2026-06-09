import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'typewriter_hint_controller.dart';

/// ข้อความ hint แบบพิมพ์ทีละตัวอักษร
class TypewriterHintLabel extends StatefulWidget {
  const TypewriterHintLabel({
    super.key,
    required this.fullText,
    this.cacheKey,
    this.style,
    this.duration = const Duration(seconds: 5),
    this.enabled = true,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String fullText;
  /// คง animation ต่อเนื่องเมื่อ parent rebuild (เช่น sticky header scroll)
  final String? cacheKey;
  final TextStyle? style;
  final Duration duration;
  final bool enabled;
  final int maxLines;
  final TextOverflow overflow;

  @override
  State<TypewriterHintLabel> createState() => _TypewriterHintLabelState();
}

class _TypewriterHintLabelState extends State<TypewriterHintLabel> {
  late final TypewriterHintController _controller = TypewriterHintController(
    cacheKey: widget.cacheKey,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(TypewriterHintLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fullText != widget.fullText ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.duration != widget.duration) {
      _sync();
    }
  }

  void _sync() {
    _controller.duration = widget.duration;
    if (!widget.enabled) {
      _controller.stop();
      if (mounted) setState(() {});
      return;
    }
    if (widget.fullText.isEmpty) {
      _controller.stop();
      if (mounted) setState(() {});
      return;
    }
    _controller.start(widget.fullText, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled && _controller.visible.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      widget.enabled ? _controller.visible : '',
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

/// hint สำหรับ TextField — ว่างเมื่อแสดง typewriter
String typewriterFieldHintText(
  AppStrings s,
  TextEditingController controller,
  FocusNode focusNode,
) {
  if (controller.text.isNotEmpty || focusNode.hasFocus) {
    return s.searchDiscoveryHint;
  }
  return ' ';
}

/// ซ้อน typewriter บน TextField เมื่อว่างและไม่โฟกัส
Widget wrapWithTypewriterHint({
  required Widget child,
  required TextEditingController controller,
  required FocusNode focusNode,
  required TextStyle hintStyle,
  String? fullText,
  String? cacheKey,
  double leftPadding = 44,
  double rightPadding = 12,
}) {
  return Stack(
    alignment: Alignment.centerLeft,
    children: [
      child,
      ListenableBuilder(
        listenable: Listenable.merge([controller, focusNode]),
        builder: (context, _) {
          final show = controller.text.isEmpty && !focusNode.hasFocus;
          if (!show) return const SizedBox.shrink();
          final text = fullText ?? AppStrings.of(context).searchDiscoveryTypewriterHint;
          return IgnorePointer(
            child: Padding(
              padding: EdgeInsets.fromLTRB(leftPadding, 0, rightPadding, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TypewriterHintLabel(
                  fullText: text,
                  cacheKey: cacheKey ?? 'search_field_typewriter',
                  style: hintStyle,
                  enabled: show,
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}
