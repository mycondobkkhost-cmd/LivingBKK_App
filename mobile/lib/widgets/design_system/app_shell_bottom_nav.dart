import 'package:flutter/material.dart';

import '../../services/chat_service.dart';
import '../../services/in_app_notification_hub.dart';
import '../../services/property_care_notification_service.dart';
import '../../services/user_profile_service.dart';
import 'app_bottom_nav.dart';

/// แถบเมนูล่างมาตรฐาน — ใช้ร่วมกันระหว่าง MainShell และหน้านอก shell
class AppShellBottomNav extends StatelessWidget {
  const AppShellBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          InAppNotificationHub.instance,
          ChatService.instance,
          UserProfileService.instance,
          PropertyCareNotificationService.instance,
        ]),
        builder: (context, _) {
          final badge = ChatService.instance.totalUnreadChats > 0
              ? ChatService.instance.totalUnreadChats
              : InAppNotificationHub.instance.unreadChatCount;
          return AppBottomNav(
            index: index,
            onChanged: onChanged,
            contactBadgeCount: badge,
            myListingsBadgeCount:
                PropertyCareNotificationService.instance.actionRequiredCount,
            profileAvatarUrl: UserProfileService.instance.avatarUrl,
          );
        },
      ),
    );
  }
}
