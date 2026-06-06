import 'package:flutter/material.dart';

enum AppNotificationType {
  chatMessage,
  chatAdminReply,
  appointmentCreated,
  appointmentReminder,
  listingBumpDue,
  listingStaleWarning,
  listingDraftFix,
  listingPublished,
  savedSearchMatch,
  demandOffer,
  systemAnnouncement,
  leadNew,
}

enum AppNotificationFilter { all, chat, appointment, listing, system }

enum AppNotificationPriority { urgent, action, info }

extension AppNotificationTypeX on AppNotificationType {
  AppNotificationFilter get filter => switch (this) {
        AppNotificationType.chatMessage ||
        AppNotificationType.chatAdminReply ||
        AppNotificationType.leadNew =>
          AppNotificationFilter.chat,
        AppNotificationType.appointmentCreated ||
        AppNotificationType.appointmentReminder =>
          AppNotificationFilter.appointment,
        AppNotificationType.listingBumpDue ||
        AppNotificationType.listingStaleWarning ||
        AppNotificationType.listingDraftFix ||
        AppNotificationType.listingPublished =>
          AppNotificationFilter.listing,
        _ => AppNotificationFilter.system,
      };

  IconData get icon => switch (this) {
        AppNotificationType.chatMessage || AppNotificationType.chatAdminReply => Icons.chat_bubble_rounded,
        AppNotificationType.leadNew => Icons.inbox_rounded,
        AppNotificationType.appointmentCreated || AppNotificationType.appointmentReminder => Icons.event_rounded,
        AppNotificationType.listingBumpDue || AppNotificationType.listingStaleWarning => Icons.campaign_rounded,
        AppNotificationType.listingDraftFix => Icons.edit_note_rounded,
        AppNotificationType.listingPublished => Icons.check_circle_rounded,
        AppNotificationType.savedSearchMatch => Icons.notifications_active_rounded,
        AppNotificationType.demandOffer => Icons.forum_rounded,
        AppNotificationType.systemAnnouncement => Icons.info_outline_rounded,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.priority = AppNotificationPriority.info,
    this.route,
    this.ctaLabel,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final AppNotificationPriority priority;
  final String? route;
  final String? ctaLabel;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
        priority: priority,
        route: route,
        ctaLabel: ctaLabel,
      );
}
