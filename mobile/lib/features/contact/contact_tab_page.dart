import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/appointments_section.dart';
import 'property_chat_page.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatService.instance.refreshMyThreads();
    });
  }

  void _refresh() => setState(() {});

  void _openRoom(ChatRoom room) {
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
    final room = await ChatService.instance.openStaffSupportRoom();
    if (!mounted) return;
    _openRoom(room);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        final rooms = ChatService.instance.listRooms();

        return Scaffold(
          backgroundColor: AppTheme.surfaceWarm,
          appBar: AppBar(
            title: Text(s.messagesTitle),
            backgroundColor: AppTheme.headerTint,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await ChatService.instance.refreshMyThreads();
                  _refresh();
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Material(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openAdminInquiry,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          child: Icon(Icons.support_agent, color: Colors.white),
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
                                  color: AppTheme.primary,
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
                        Icon(Icons.chevron_right, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.history, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    s.chatHistory,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
                ...rooms.map((room) {
                  final last = room.lastMessage;
                  final time = DateFormat('d MMM HH:mm', 'th').format(room.updatedAt);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: room.isSupportRoom
                        ? AppTheme.accentSoftLight
                        : AppTheme.cardTint,
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: room.isSupportRoom
                            ? AppTheme.accentMidLight
                            : AppTheme.primaryLight,
                        child: Icon(
                          room.adminEscalated ? Icons.support_agent : Icons.chat_bubble_outline,
                          color: room.isSupportRoom
                              ? AppTheme.accentMid
                              : AppTheme.primary,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        room.isStaffSupport ? s.chatAdminInquiry : room.displayTitle,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.transactionRefLabel}: ${room.effectiveTransactionRef}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            last?.text ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            time,
                            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                          if (room.viewingSubmitted)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                s.viewingSubmittedBadge,
                                style: TextStyle(fontSize: 10, color: AppTheme.accentDeep),
                              ),
                            ),
                        ],
                      ),
                      onTap: () => _openRoom(room),
                    ),
                  );
                }),
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
