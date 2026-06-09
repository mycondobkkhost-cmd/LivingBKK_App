import 'package:flutter/material.dart';

import '../services/in_app_notification_hub.dart';
import '../theme/app_palette.dart';

/// แบนเนอร์แจ้งเตือนด้านบนแอป
class InAppNotificationBanner extends StatelessWidget {
  const InAppNotificationBanner({
    super.key,
    required this.hub,
    this.onTap,
  });

  final InAppNotificationHub hub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: hub,
      builder: (context, _) {
        final msg = hub.bannerMessage;
        if (msg == null || msg.isEmpty) return const SizedBox.shrink();
        // ดันประกาศ / ทรัพย์ — ใช้ SnackBar ล่างจอ ไม่แสดงแบนเนอร์บน
        final isListingOps = msg.contains('ยืนยันว่าง') ||
            msg.contains('ดันประกาศ') ||
            msg.contains('Bump') ||
            msg.contains('มอบสิทธิ์') ||
            msg.contains('care access');
        if (isListingOps) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            hub.dismissBanner();
          });
          return const SizedBox.shrink();
        }
        final isChat = msg.contains('ข้อความจากทีม') ||
            msg.contains('Message from team') ||
            msg.contains('แชท');
        final p = context.palette;
        return Material(
          elevation: 6,
          color: p.primary,
          child: SafeArea(
            bottom: false,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isChat ? Icons.chat_bubble : Icons.notifications_active,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        msg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      onPressed: hub.dismissBanner,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
