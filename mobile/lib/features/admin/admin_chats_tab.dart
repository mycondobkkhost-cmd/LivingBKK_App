import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_chat_ops.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';

/// กล่องแชทรอทีมงาน — รับงาน / งานของฉัน / ปิดแล้ว
class AdminChatsTab extends StatefulWidget {
  const AdminChatsTab({
    super.key,
    this.compact = false,
    this.embedded = false,
    this.selectedRoomId,
    this.onRoomSelected,
  });

  /// ซ่อน intro ยาว — ใช้ใน console บนคอม
  final bool compact;

  /// ไม่ push หน้าใหม่ — ใช้ callback เลือกห้อง
  final bool embedded;

  final String? selectedRoomId;
  final ValueChanged<String>? onRoomSelected;

  @override
  State<AdminChatsTab> createState() => _AdminChatsTabState();
}

class _AdminChatsTabState extends State<AdminChatsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _prevUnclaimed = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    ChatService.instance.addListener(_onInboxChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ChatService.instance.refreshAdminInbox();
      _onInboxChanged();
    });
  }

  void _onInboxChanged() {
    if (!mounted) return;
    final unclaimed =
        ChatService.instance.listAdminInbox(bucket: AdminInboxBucket.unclaimed);
    if (unclaimed.length > _prevUnclaimed && unclaimed.isNotEmpty) {
      _tabs.animateTo(0);
    }
    _prevUnclaimed = unclaimed.length;
  }

  @override
  void dispose() {
    ChatService.instance.removeListener(_onInboxChanged);
    _tabs.dispose();
    super.dispose();
  }

  String _inboxLabel(ChatRoom room, AppStrings s) {
    if (room.category == 'booking_interest') {
      return s.adminInboxBookingInterest;
    }
    if (room.category == 'viewing_request' || room.viewingSubmitted) {
      return s.adminInboxViewing;
    }
    if (room.category == 'discovery' || room.isDiscovery) {
      return s.adminInboxDiscovery;
    }
    if (room.category == 'staff_support' || room.isStaffSupport) {
      return s.adminStaffChatChip;
    }
    if (room.category == 'demand_offer') {
      return s.adminInboxDemandOffer;
    }
    if (room.category == 'customer_requirement' || room.isCustomerRequirement) {
      return s.adminInboxRequirement;
    }
    if (room.category == 'escalation' ||
        room.messages.any((m) => m.requiresAdmin)) {
      return s.adminInboxNeedsStaff;
    }
    return s.adminInboxPropertyChat;
  }

  Color _inboxColor(ChatRoom room) {
    if (room.category == 'booking_interest') return const Color(0xFFDC2626);
    if (room.isCustomerRequirement) return AppTheme.accentDeep;
    if (room.isDiscovery) return AppTheme.primary;
    if (room.isDemandOffer) return AppTheme.accentMid;
    if (room.viewingSubmitted) return AppTheme.accentDeep;
    if (room.isStaffSupport) return AppTheme.accentMid;
    return AppTheme.primary;
  }

  Future<void> _refresh() async {
    await ChatService.instance.refreshAdminInbox();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final chat = ChatService.instance;

    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        final unclaimed = chat.listAdminInbox(bucket: AdminInboxBucket.unclaimed);
        final mine = chat.listAdminInbox(bucket: AdminInboxBucket.mine);
        final resolved = chat.listAdminInbox(bucket: AdminInboxBucket.resolved);

        return Column(
          children: [
            if (!widget.compact)
              Card(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(s.adminInboxIntro, style: AdminTheme.hint),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (kIsWeb && !widget.embedded)
                            TextButton.icon(
                              onPressed: () => context.go('/admin/console'),
                              icon: const Icon(Icons.desktop_windows_outlined, size: 18),
                              label: Text(s.adminOpenConsole),
                            ),
                          TextButton.icon(
                            onPressed: () => context.push('/admin/faq'),
                            icon: const Icon(Icons.tune, size: 18),
                            label: Text(s.adminFaqSettings),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (unclaimed.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_outlined,
                          size: 18, color: AppTheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.adminInboxTabUnclaimed(unclaimed.length),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.adminConsoleInboxHint,
                        style: AdminTheme.caption,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, size: 20),
                      tooltip: s.adminFaqSettings,
                      onPressed: () => context.push('/admin/faq'),
                    ),
                  ],
                ),
              ),
            ],
            if (unclaimed.isEmpty && mine.isNotEmpty)
              Material(
                color: AppTheme.accentMidLight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.accentMid),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.adminInboxCheckMine(mine.length),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentMid,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _tabs.animateTo(1),
                        child: Text(s.adminInboxTabMine(mine.length)),
                      ),
                    ],
                  ),
                ),
              ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: [
                Tab(text: s.adminInboxTabUnclaimed(unclaimed.length)),
                Tab(text: s.adminInboxTabMine(mine.length)),
                Tab(text: s.adminInboxTabResolved(resolved.length)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(s.refresh),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _InboxList(
                    rooms: unclaimed,
                    emptyText: s.adminInboxEmptyUnclaimed,
                    labelFor: (r) => _inboxLabel(r, s),
                    accentFor: _inboxColor,
                    showClaimHint: true,
                    selectedRoomId: widget.selectedRoomId,
                    embedded: widget.embedded,
                    onRoomSelected: widget.onRoomSelected,
                  ),
                  _InboxList(
                    rooms: mine,
                    emptyText: s.adminInboxEmptyMine,
                    labelFor: (r) => _inboxLabel(r, s),
                    accentFor: _inboxColor,
                    showAssignee: true,
                    selectedRoomId: widget.selectedRoomId,
                    embedded: widget.embedded,
                    onRoomSelected: widget.onRoomSelected,
                  ),
                  _InboxList(
                    rooms: resolved,
                    emptyText: s.adminInboxEmptyResolved,
                    labelFor: (r) => _inboxLabel(r, s),
                    accentFor: (_) => AppTheme.textSecondary,
                    pending: false,
                    selectedRoomId: widget.selectedRoomId,
                    embedded: widget.embedded,
                    onRoomSelected: widget.onRoomSelected,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList({
    required this.rooms,
    required this.emptyText,
    required this.labelFor,
    required this.accentFor,
    this.pending = true,
    this.showClaimHint = false,
    this.showAssignee = false,
    this.selectedRoomId,
    this.embedded = false,
    this.onRoomSelected,
  });

  final List<ChatRoom> rooms;
  final String emptyText;
  final String Function(ChatRoom) labelFor;
  final Color Function(ChatRoom) accentFor;
  final bool pending;
  final bool showClaimHint;
  final bool showAssignee;
  final String? selectedRoomId;
  final bool embedded;
  final ValueChanged<String>? onRoomSelected;

  void _openRoom(BuildContext context, ChatRoom room) {
    if (embedded && onRoomSelected != null) {
      onRoomSelected!(room.id);
      return;
    }
    context.push('/admin/chat/${room.id}');
  }

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyText, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: rooms.length,
      itemBuilder: (context, i) {
        final room = rooms[i];
        return _InboxTile(
          room: room,
          label: labelFor(room),
          accent: accentFor(room),
          pending: pending,
          showClaimHint: showClaimHint,
          showAssignee: showAssignee,
          selected: selectedRoomId == room.id,
          onTap: () => _openRoom(context, room),
        );
      },
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.room,
    required this.label,
    required this.accent,
    required this.pending,
    required this.onTap,
    this.showClaimHint = false,
    this.showAssignee = false,
    this.selected = false,
  });

  final ChatRoom room;
  final String label;
  final Color accent;
  final bool pending;
  final VoidCallback onTap;
  final bool showClaimHint;
  final bool showAssignee;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final last = room.lastMessage;
    final locale = s.isEnglish ? 'en' : 'th';
    final time = DateFormat('d MMM HH:mm', locale).format(room.updatedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? AppTheme.primaryLight : null,
      shape: selected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.primary, width: 1.5),
            )
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent.withOpacity(0.15),
          child: Icon(
            room.viewingSubmitted
                ? Icons.event_available
                : room.isStaffSupport
                    ? Icons.support_agent
                    : Icons.chat_bubble_outline,
            color: accent,
            size: 20,
          ),
        ),
        title: Text(
          room.displayTitle,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              last?.text ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Chip(label: label, color: accent),
                if (room.priority == 'high')
                  _Chip(label: s.adminPriorityHigh, color: AppTheme.error),
                if (room.viewingSubmitted)
                  _Chip(
                    label: s.adminViewingFormSubmitted,
                    color: AppTheme.accentDeep,
                  ),
                if (pending)
                  _Chip(label: s.adminAwaitingReply, color: AppTheme.error),
                if (showClaimHint && room.isUnclaimed)
                  _Chip(label: s.adminNeedsClaim, color: AppTheme.accentMid),
                if (showAssignee &&
                    room.assignedAdminName != null &&
                    room.assignedAdminName!.isNotEmpty)
                  _Chip(
                    label: s.adminClaimedBy(room.assignedAdminName!),
                    color: AppTheme.primary,
                  ),
              ],
            ),
          ],
        ),
        trailing: Text(
          time,
          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
