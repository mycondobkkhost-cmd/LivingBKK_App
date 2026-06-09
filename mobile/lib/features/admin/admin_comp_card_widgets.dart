import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_comp_card.dart';
import '../../models/appointment.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../models/profile_tag.dart';
import '../../services/admin_comp_card_service.dart';
import '../../services/chat_service.dart';
import '../../services/profile_tag_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../contact/chat_link_detail_sheets.dart';

/// แชทลูกค้าที่ผูกกับลีดนัดชม
ChatRoom? chatRoomForAppointmentLead(String? leadId) {
  if (leadId == null || leadId.isEmpty) return null;
  final roomId = leadId.startsWith('demo-lead')
      ? 'demo-lead-chat-$leadId'
      : null;
  if (roomId == null) return null;
  return ChatService.instance.roomById(roomId);
}

class AdminChatAdminInfo {
  const AdminChatAdminInfo({
    this.adminId,
    this.adminName,
    this.compCard,
    this.room,
  });

  final String? adminId;
  final String? adminName;
  final AdminCompCard? compCard;
  final ChatRoom? room;

  bool get hasAdmin =>
      adminName != null && adminName!.trim().isNotEmpty;

  static AdminChatAdminInfo resolve(Appointment appointment) {
    final room = chatRoomForAppointmentLead(appointment.leadId);
    final adminId = room?.assignedAdminId?.trim();
    final adminName = room?.assignedAdminName?.trim();
    AdminCompCard? card;
    if (adminId != null && adminId.isNotEmpty) {
      card = AdminCompCardService.instance.byProfileId(adminId);
    }
    if (card == null && adminName != null && adminName.isNotEmpty) {
      for (final c in AdminCompCardService.instance.all) {
        if (c.displayNameTh == adminName || c.displayNameEn == adminName) {
          card = c;
          break;
        }
      }
    }
    if (card == null &&
        appointment.assignedTo != null &&
        appointment.assignedTo!.trim().isNotEmpty) {
      card = AdminCompCardService.instance.byProfileId(appointment.assignedTo);
    }
    return AdminChatAdminInfo(
      adminId: adminId,
      adminName: adminName,
      compCard: card,
      room: room,
    );
  }
}

/// แท็ก PR / คอมพ์การ์ด — กดดูรายละเอียด
class AdminCompTagChip extends StatelessWidget {
  const AdminCompTagChip({
    super.key,
    required this.tagCode,
    this.compact = false,
  });

  final String tagCode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      padding: compact ? const EdgeInsets.symmetric(horizontal: 4) : null,
      label: Text(
        tagCode,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
          color: LivingBkkBrand.purplePrimary,
        ),
      ),
      avatar: Icon(
        Icons.sell_outlined,
        size: compact ? 14 : 16,
        color: LivingBkkBrand.purplePrimary,
      ),
      onPressed: () => showProfileTagDetailSheet(context, tagCode, adminView: true),
    );
  }
}

/// แถวแอดมินที่คุย + แท็ก — ใช้ในรายละเอียดนัดชม
class AdminAppointmentChatAdminRow extends StatelessWidget {
  const AdminAppointmentChatAdminRow({
    super.key,
    required this.appointment,
    this.onSendTag,
    this.compact = false,
  });

  final Appointment appointment;
  final Future<void> Function(AdminCompCard card, ChatRoom room)? onSendTag;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final info = AdminChatAdminInfo.resolve(appointment);
    final card = info.compCard;
    final tagCode = card?.tagCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.headset_mic_outlined,
              size: compact ? 15 : 16,
              color: AdminTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                info.hasAdmin
                    ? s.adminCalendarChatAdminLine(info.adminName!)
                    : s.adminCalendarChatAdminUnset,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: info.hasAdmin ? AdminTheme.text : AdminTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
        if (tagCode != null) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminCompTagChip(tagCode: tagCode, compact: compact),
              if (card != null && info.room != null && onSendTag != null)
                TextButton.icon(
                  onPressed: () => onSendTag!(card, info.room!),
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: Text(
                    s.adminCompCardSendTag,
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// ตัวอย่างคอมพ์การ์ดในรายการตั้งค่า
class AdminCompCardPreviewTile extends StatelessWidget {
  const AdminCompCardPreviewTile({
    super.key,
    required this.card,
    required this.onEdit,
  });

  final AdminCompCard card;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final isEn = s.isEnglish;
    final tag = ProfileTagService.instance.tagByCode(card.tagCode);

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: LivingBkkBrand.purplePrimary.withOpacity(0.12),
                child: Text(
                  card.displayName(isEn).isNotEmpty
                      ? card.displayName(isEn)[0]
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: LivingBkkBrand.purplePrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.displayName(isEn),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${card.roleLabel(isEn)} · ${card.castId}',
                      style: AdminTheme.caption,
                    ),
                    const SizedBox(height: 6),
                    AdminCompTagChip(tagCode: card.tagCode, compact: true),
                    if (tag != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        tag.publicSnapshot.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AdminTheme.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AdminTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> sendCompCardTagToRoom(
  BuildContext context, {
  required AdminCompCard card,
  required ChatRoom room,
}) async {
  final s = context.s;
  final tag = ProfileTagService.instance.tagByCode(card.tagCode);
  if (tag == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.chatLinkTagNotFound(card.tagCode))),
    );
    return;
  }
  await ChatService.instance.sendAdminReply(
    room,
    s.adminCompCardSendTagMessage(card.displayName(s.isEnglish)),
    links: [
      ChatMessageLink.profileTag(tag.code, tag.displayLabel),
    ],
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(s.adminCompCardSendTagDone)),
  );
}
