import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../theme/app_palette.dart';

/// ฟองแชทสไตล์ Messenger — ใช้ร่วม seeker / admin
class ChatMessengerBubble extends StatelessWidget {
  const ChatMessengerBubble({
    super.key,
    required this.text,
    required this.isOutgoing,
    required this.createdAt,
    this.isImportant = false,
    this.isSystem = false,
    this.headerLabel,
    this.child,
  });

  final String text;
  final bool isOutgoing;
  final DateTime createdAt;
  final bool isImportant;
  final bool isSystem;
  final String? headerLabel;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final time = DateFormat('HH:mm').format(createdAt);

    Color bg;
    Alignment align;
    BorderRadius radius;
    if (isSystem) {
      bg = p.primaryLight;
      align = Alignment.center;
      radius = BorderRadius.circular(12);
    } else if (isOutgoing) {
      bg = p.primary;
      align = Alignment.centerRight;
      radius = const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(4),
      );
    } else {
      bg = isImportant ? const Color(0xFFE8F5E9) : p.surfaceElevated;
      align = Alignment.centerLeft;
      radius = const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(18),
      );
    }

    final textColor = isOutgoing ? Colors.white : p.textPrimary;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: isSystem ? null : Border.all(color: p.border.withOpacity(0.35)),
          boxShadow: isImportant
              ? [
                  BoxShadow(
                    color: p.primary.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headerLabel != null && headerLabel!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  headerLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isOutgoing ? Colors.white70 : p.accent,
                  ),
                ),
              ),
            if (child != null)
              child!
            else
              Text(
                text,
                style: TextStyle(color: textColor, height: 1.35),
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isOutgoing
                      ? Colors.white70
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
