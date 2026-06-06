import 'package:flutter/material.dart';

import '../services/in_app_notification_hub.dart';
import '../services/notification_center_repository.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// ปุ่มกระดิ่ง — badge รวมจากศูนย์แจ้งเตือน
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    required this.onPressed,
    this.compact = false,
    this.onPurple = false,
  });

  final VoidCallback onPressed;
  final bool compact;
  final bool onPurple;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListenableBuilder(
      listenable: Listenable.merge([
        InAppNotificationHub.instance,
        NotificationCenterRepository.instance,
      ]),
      builder: (context, _) {
        final hub = InAppNotificationHub.instance.unreadChatCount;
        final center = NotificationCenterRepository.instance.unreadCount;
        final n = hub > center ? hub : center;
        final size = compact ? 20.0 : 22.0;
        final min = compact ? 36.0 : 40.0;
        return Material(
          color: onPurple ? Colors.white.withOpacity(0.18) : p.surface,
          shape: const CircleBorder(),
          elevation: onPurple || compact ? 0 : 2,
          shadowColor: p.cardShadow,
          child: Badge(
            isLabelVisible: n > 0,
            label: Text(
              n > 9 ? '9+' : '$n',
              style: const TextStyle(fontSize: 9),
            ),
            backgroundColor: AppTheme.error,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.all(compact ? 6 : 8),
              constraints: BoxConstraints(minWidth: min, minHeight: min),
              icon: Icon(
                Icons.notifications_outlined,
                color: onPurple ? Colors.white : p.primary,
                size: size,
              ),
              onPressed: onPressed,
            ),
          ),
        );
      },
    );
  }
}
