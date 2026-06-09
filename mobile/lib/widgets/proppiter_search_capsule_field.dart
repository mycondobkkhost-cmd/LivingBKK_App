import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'typewriter_hint_label.dart';

/// ช่องค้นหาแคปซูลขาวบนหัวม่วง — สไตล์เดียวกับหน้าแรก + hint พิมพ์ทีละตัว
class ProppiterSearchCapsuleField extends StatelessWidget {
  const ProppiterSearchCapsuleField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.typewriterHint,
    this.cacheKey = 'proppiter_search_capsule',
    this.onChanged,
    this.onSubmitted,
    this.height = 48,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String typewriterHint;
  final String cacheKey;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double height;

  static const double _leftPad = 14;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Material(
      color: p.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(height / 2),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: ListenableBuilder(
          listenable: Listenable.merge([controller, focusNode]),
          builder: (context, _) {
            final hasQuery = controller.text.trim().isNotEmpty;
            return wrapWithTypewriterHint(
              controller: controller,
              focusNode: focusNode,
              fullText: typewriterHint,
              cacheKey: cacheKey,
              leftPadding: 46,
              hintStyle: TextStyle(
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w400,
                color: p.textSecondary.withOpacity(0.85),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: ' ',
                  hintStyle: TextStyle(color: p.textSecondary.withOpacity(0.01)),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: p.primary,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 40,
                  ),
                  suffixIcon: hasQuery
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: p.textSecondary,
                          ),
                          onPressed: () {
                            controller.clear();
                            onChanged?.call('');
                          },
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
