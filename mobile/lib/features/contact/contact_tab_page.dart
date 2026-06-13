import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_room_display.dart';
import '../../widgets/appointments_section.dart';
import 'property_chat_page.dart';
import '../../theme/li_layout.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

class ContactTabPage extends StatefulWidget {
  const ContactTabPage({
    super.key,
    this.isAgent = false,
    this.canManageLeads = false,
  });

  final bool isAgent;
  final bool canManageLeads;

  @override
  State<ContactTabPage> createState() => _ContactTabPageState();
}

class _ContactTabPageState extends State<ContactTabPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        ChatService.instance.ensureCustomerInboxRealtime();
        await ChatService.instance.ensureParticipantHub();
        if (mounted) _refresh();
      } catch (e) {
        _showChatError(e);
      }
    });
  }

  void _refresh() => setState(() {});

  void _showChatError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$error')),
    );
  }

  void _openRoom(ChatRoom room) {
    ChatService.instance.markThreadRead(room.id);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PropertyChatPage(room: room),
      ),
    ).then((_) {
      ChatService.instance.refreshMyThreads();
      _refresh();
    });
  }

  Future<void> _openAdminInquiry() async {
    try {
      final room = await ChatService.instance.openStaffSupportRoom();
      if (!mounted) return;
      _openRoom(room);
    } catch (e) {
      _showChatError(e);
    }
  }

  Future<void> _openDiscovery() async {
    try {
      final room = await ChatService.instance.openDiscoveryRoom();
      if (!mounted) return;
      _openRoom(room);
    } catch (e) {
      _showChatError(e);
    }
  }

  Future<void> _openHub() async {
    try {
      final room = await ChatService.instance.ensureParticipantHub();
      if (!mounted) return;
      _openRoom(room);
    } catch (e) {
      _showChatError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final chat = ChatService.instance;

    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        final rooms =
            chat.listMyRooms().where((r) => !r.isParticipantHub).toList();
        final totalUnread = chat.totalUnreadChats;

        return ConsumerPageShell(
          title: s.messagesTitle,
          safeBottomBody: false,
          actions: [
            if (totalUnread > 0)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      s.chatUnreadCount(totalUnread),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ConsumerHeaderIconButton(
              icon: Icons.refresh_rounded,
              onTap: () async {
                await chat.refreshMyThreads();
                _refresh();
              },
            ),
          ],
          body: ListView(
            padding: PageSafeInsets.padLTRB(
              context,
              left: LiLayout.pagePadding,
              top: 12,
              right: LiLayout.pagePadding,
              bottom: 16,
              addHomeIndicator: false,
            ),
            children: [
              Material(
                color: p.primaryLight,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openDiscovery,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: p.primary,
                          child: const Icon(Icons.travel_explore, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.chatDiscovery,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: p.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.chatDiscoveryEntryHint,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: p.primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: p.primaryLight,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openAdminInquiry,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: p.primary,
                          child: const Icon(Icons.support_agent, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.chatAdminInquiry,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: p.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.chatAdminInquiryHint,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: p.primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _HubEntryTile(onOpen: _openHub),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.history, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    s.chatHistory,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const Spacer(),
                  if (totalUnread > 0)
                    Text(
                      s.chatUnreadCount(totalUnread),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (rooms.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 44,
                        color: AppTheme.textSecondary.withOpacity(0.45),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.chatEmptyHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ...rooms.map((room) => _ChatHistoryTile(
                      room: room,
                      unread: chat.unreadForThread(room.id),
                      onTap: () => _openRoom(room),
                    )),
              const Divider(height: 28),
              AppointmentsSection(
                isAgent: widget.isAgent,
                canManageLeads: widget.canManageLeads,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HubEntryTile extends StatelessWidget {
  const _HubEntryTile({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: p.primary,
                child: const Icon(Icons.hub_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.hubSeekerTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: p.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.hubEntryHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHistoryTile extends StatelessWidget {
  const _ChatHistoryTile({
    required this.room,
    required this.unread,
    required this.onTap,
  });

  final ChatRoom room;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final time = DateFormat('d MMM HH:mm', 'th').format(room.updatedAt);
    final teamReply = room.lastTeamReply;
    final hasUnread = unread > 0;
    final preview = room.inboxPreviewText(s);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: hasUnread ? 2 : 0,
      color: hasUnread
          ? p.primaryLight
          : room.isSupportRoom
              ? p.surfaceVariant
              : p.surface,
      shape: hasUnread
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: p.primary.withOpacity(0.45), width: 1.5),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: hasUnread
                        ? p.primary
                        : room.isSupportRoom
                            ? p.surfaceVariant
                            : p.primaryLight,
                    child: Icon(
                      room.historyIcon,
                      color: hasUnread
                          ? Colors.white
                          : room.isSupportRoom
                              ? p.accent
                              : p.primary,
                      size: 20,
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: p.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.historyListTitle(s),
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 14,
                              color: hasUnread ? p.primary : p.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.transactionRefLabel}: ${room.effectiveTransactionRef}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary.withOpacity(0.85),
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (teamReply != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: hasUnread
                              ? p.surfaceElevated
                              : p.surfaceVariant.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasUnread
                                ? p.primary.withOpacity(0.35)
                                : p.border.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              room.hasTeamFormLink
                                  ? Icons.edit_note_outlined
                                  : Icons.support_agent,
                              size: 16,
                              color: AppTheme.accentMid,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasUnread
                                        ? s.chatTeamReplyWaiting
                                        : s.chatTeamLivingBkk,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.accentMid,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    preview.replaceFirst('${s.chatTeamLivingBkk}: ', ''),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          hasUnread ? FontWeight.w600 : FontWeight.w400,
                                      color: AppTheme.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    if (room.viewingSubmitted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          s.viewingSubmittedBadge,
                          style: TextStyle(fontSize: 10, color: AppTheme.accentDeep),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: hasUnread ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
