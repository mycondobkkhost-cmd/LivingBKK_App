import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';

extension ChatRoomDisplay on ChatRoom {
  String chatScreenTitle(AppStrings s) {
    if (isCustomerRequirement) return s.chatRequirementRoomTitle;
    if (isDiscovery) return s.chatDiscoveryTitle;
    if (isDemandOffer) return s.chatDemandOfferRoomTitle;
    if (isStaffSupport) return s.chatAdminInquiry;
    if (isParticipantHub) return s.hubSeekerTitle;
    return s.chatPropertyTitle;
  }

  String historyListTitle(AppStrings s) {
    if (isCustomerRequirement) {
      return listingTitle.isNotEmpty ? listingTitle : s.chatRequirementRoomTitle;
    }
    if (isDiscovery) return s.chatDiscoveryRoomTitle;
    if (isDemandOffer) {
      return listingTitle.isNotEmpty ? listingTitle : s.chatDemandOfferRoomTitle;
    }
    if (isStaffSupport) return s.chatAdminInquiry;
    if (isParticipantHub) return listingTitle;
    return displayTitle;
  }

  IconData get historyIcon {
    if (isCustomerRequirement) return Icons.assignment_outlined;
    if (isDiscovery) return Icons.travel_explore_outlined;
    if (isDemandOffer) return Icons.local_offer_outlined;
    if (isStaffSupport) return Icons.support_agent_outlined;
    if (isParticipantHub) return Icons.hub_outlined;
    return Icons.home_outlined;
  }

  ChatMessage? get lastTeamReply {
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m.role != ChatMessageRole.adminNotice) continue;
      if (m.text.startsWith('รับข้อความแล้ว') ||
          m.text.startsWith('Message received') ||
          m.text.startsWith('⚠️') ||
          m.text.startsWith('รายละเอียดนัดดู') ||
          m.text.startsWith('Viewing details')) {
        continue;
      }
      return m;
    }
    return null;
  }

  String inboxPreviewText(AppStrings s) {
    final team = lastTeamReply;
    if (team != null) {
      final text = team.text.trim();
      if (team.links.isNotEmpty) {
        return '${s.chatTeamLivingBkk}: ${team.links.first.label}';
      }
      return '${s.chatTeamLivingBkk}: $text';
    }
    final last = lastMessage;
    if (last == null) return s.chatEmptyHint;
    if (last.role == ChatMessageRole.system) {
      return last.text;
    }
    return last.text;
  }

  bool get hasTeamFormLink =>
      lastTeamReply?.links.any((l) => l.isFormAction) == true;
}
