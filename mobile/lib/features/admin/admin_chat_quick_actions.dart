import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_chat_ops.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import 'admin_listing_link_picker.dart';

/// การกระทำด่วนจากแผง context / หลังบ้าน — ใช้ร่วมกับแชท
class AdminChatQuickActions {
  AdminChatQuickActions._();

  static final _chat = ChatService.instance;

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static Future<void> claim(BuildContext context, ChatRoom room) async {
    final s = context.s;
    if (!room.isUnclaimed) {
      if (_chat.isClaimedByOtherAdmin(room)) {
        _snack(context, s.adminClaimedByOther);
      }
      return;
    }
    try {
      await _chat.claimThread(room);
      if (context.mounted) _snack(context, s.adminClaimSuccess);
    } catch (e) {
      if (context.mounted) {
        _snack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  static Future<void> assign(BuildContext context, ChatRoom room) async {
    final s = context.s;
    final peers = await _chat.fetchTeamAdmins();
    if (!context.mounted || peers.isEmpty) return;

    final picked = await showModalBottomSheet<AdminPeer>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                s.adminAssignTo,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            ...peers.map(
              (p) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(p.displayName),
                onTap: () => Navigator.pop(ctx, p),
              ),
            ),
          ],
        ),
      ),
    );

    if (picked == null || !context.mounted) return;
    await _chat.assignThread(room, picked);
    if (context.mounted) _snack(context, s.adminAssignSuccess);
  }

  static Future<void> resolve(
    BuildContext context,
    ChatRoom room, {
    VoidCallback? onDone,
  }) async {
    final s = context.s;
    if (!_chat.canReplyAsAdmin(room)) {
      _snack(context, s.adminMustClaimFirst);
      return;
    }
    await _chat.markAdminResolved(room);
    if (!context.mounted) return;
    _snack(context, s.adminMarkedReplied);
    onDone?.call();
  }

  static Future<void> sendFormLink(
    BuildContext context,
    ChatRoom room,
    ChatMessageLink link,
    String defaultMessage,
  ) async {
    final s = context.s;
    if (!_chat.canReplyAsAdmin(room)) {
      _snack(context, s.adminMustClaimFirst);
      return;
    }
    try {
      await _chat.sendAdminReply(room, defaultMessage, links: [link]);
    } catch (_) {
      if (context.mounted) _snack(context, s.adminClaimedByOther);
    }
  }

  static Future<void> sendRequirementForm(BuildContext context, ChatRoom room) {
    final s = context.s;
    return sendFormLink(
      context,
      room,
      ChatMessageLink.requirementForm(s),
      s.adminSendRequirementFormMessage,
    );
  }

  static Future<void> sendViewingForm(BuildContext context, ChatRoom room) {
    final s = context.s;
    return sendFormLink(
      context,
      room,
      ChatMessageLink.viewingForm(s),
      s.adminSendViewingFormMessage,
    );
  }

  static Future<void> sendListingCards(BuildContext context, ChatRoom room) async {
    final s = context.s;
    if (!_chat.canReplyAsAdmin(room)) {
      _snack(context, s.adminMustClaimFirst);
      return;
    }
    final links = await AdminListingLinkPicker.show(context);
    if (links == null || links.isEmpty || !context.mounted) return;
    try {
      await _chat.sendAdminReply(
        room,
        s.t('ชุดทรัพย์ที่แนะนำ', 'Recommended listings'),
        links: links,
      );
    } catch (_) {
      if (context.mounted) _snack(context, s.adminClaimedByOther);
    }
  }
}
