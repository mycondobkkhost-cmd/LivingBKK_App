import 'package:flutter/material.dart';

import '../services/in_app_notification_hub.dart';
import '../services/property_care_notification_service.dart';
import '../theme/app_theme.dart';

/// Toast มุมบนขวา — มอบสิทธิ์ดูแลทรัพย์
class PropertyCareGrantToast extends StatelessWidget {
  const PropertyCareGrantToast({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PropertyCareNotificationService.instance,
      builder: (context, _) {
        final msg = PropertyCareNotificationService.instance.toastMessage;
        if (msg == null || msg.isEmpty) return const SizedBox.shrink();

        final top = MediaQuery.paddingOf(context).top + 8;
        return Positioned(
          top: top,
          right: 12,
          left: 72,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.primary,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                PropertyCareNotificationService.instance.dismissToast();
                InAppNotificationHub.instance.requestOpenMineTab();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        msg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      onPressed: PropertyCareNotificationService.instance.dismissToast,
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
