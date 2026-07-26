import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_strings.dart';
import '../../models/admin_chat_ops.dart';
import '../../models/chat_room.dart';
import '../../services/admin_chat_label_service.dart';
import '../../services/chat_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import 'admin_chat_rename_sheet.dart';
import 'admin_inbox_preview.dart';
import 'admin_inbox_search.dart';
import 'admin_inbox_sla.dart';

/// กล่องแชทรอทีมงาน — รับงาน / งานของฉัน / ปิดแล้ว
class AdminChatsTab extends StatefulWidget {
  const AdminChatsTab({
    super.key,
    this.compact = false,
    this.embedded = false,
    this.selectedRoomId,
    this.onRoomSelected,
    this.onSearchPick,
    this.focusQueue = false,
    this.opsLayout = false,
  });

  /// ซ่อน intro ยาว — ใช้ใน console บนคอม
  final bool compact;

  /// UI หลังบ้านใหม่ — segment + รายการกระชับ
  final bool opsLayout;

  /// ไม่ push หน้าใหม่ — ใช้ callback เลือกห้อง
  final bool embedded;

  final String? selectedRoomId;
  final ValueChanged<String>? onRoomSelected;

  /// หลังค้นหาข้อความ — เปิดห้อง + เลื่อนไปข้อความ
  final void Function(String roomId, {String? messageId})? onSearchPick;

  /// เปิดที่แท็บ「รอรับงาน」— ใช้จากเมนูเร่งด่วน
  final bool focusQueue;

  @override
  State<AdminChatsTab> createState() => _AdminChatsTabState();
}

class _AdminChatsTabState extends State<AdminChatsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _prevUnclaimed = 0;
  AdminInboxSort _inboxSort = AdminInboxSort.recentFirst;
  AdminInboxFilterTag _inboxFilter = AdminInboxFilterTag.all;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: widget.focusQueue ? 0 : 0);
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

  Future<void> _openSearch() async {
    final result = await showAdminInboxSearchSheet(
      context,
      rooms: adminInboxSearchScope(),
    );
    if (result == null || !mounted) return;
    if (widget.embedded && widget.onRoomSelected != null) {
      widget.onRoomSelected!(result.room.id);
      widget.onSearchPick?.call(
        result.room.id,
        messageId: result.message.id,
      );
      return;
    }
    if (kIsWeb) {
      context.go(
        '/admin/console?room=${result.room.id}&message=${result.message.id}',
      );
      return;
    }
    context.push('/admin/chat/${result.room.id}');
  }

  Future<void> _renameRoom(ChatRoom room) async {
    final s = context.s;
    final suggested = AdminInboxPreview.fromRoom(room, s).displayName;
    await showAdminChatRenameSheet(
      context,
      room: room,
      suggestedName: suggested,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final chat = ChatService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([chat, AdminChatLabelService.instance]),
      builder: (context, _) {
        final unclaimed = chat.listAdminInbox(bucket: AdminInboxBucket.unclaimed);
        final mine = chat.listAdminInbox(bucket: AdminInboxBucket.mine);
        final resolved = chat.listAdminInbox(bucket: AdminInboxBucket.resolved);

        if (widget.opsLayout) {
          return _OpsInboxBody(
            tabs: _tabs,
            unclaimed: unclaimed,
            mine: mine,
            resolved: resolved,
            sort: _inboxSort,
            filter: _inboxFilter,
            onSortChanged: (v) => setState(() => _inboxSort = v),
            onFilterChanged: (f) => setState(() => _inboxFilter = f),
            onRefresh: _refresh,
            onSearch: _openSearch,
            selectedRoomId: widget.selectedRoomId,
            embedded: widget.embedded,
            onRoomSelected: widget.onRoomSelected,
            onRename: _renameRoom,
            accentFor: _inboxColor,
          );
        }

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
            _InboxSortBar(
              sort: _inboxSort,
              onSortChanged: (v) => setState(() => _inboxSort = v),
              onRefresh: _refresh,
              onSearch: _openSearch,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InboxFilterBar(
                        filter: _inboxFilter,
                        onFilterChanged: (f) =>
                            setState(() => _inboxFilter = f),
                      ),
                      Expanded(
                        child: _InboxList(
                          rooms: unclaimed,
                          sort: _inboxSort,
                          filter: _inboxFilter,
                          emptyText: s.adminInboxEmptyUnclaimed,
                          accentFor: _inboxColor,
                          showClaimHint: true,
                          selectedRoomId: widget.selectedRoomId,
                          embedded: widget.embedded,
                          onRoomSelected: widget.onRoomSelected,
                          onRename: _renameRoom,
                        ),
                      ),
                    ],
                  ),
                  _InboxList(
                    rooms: mine,
                    sort: _inboxSort,
                    emptyText: s.adminInboxEmptyMine,
                    accentFor: _inboxColor,
                    showAssignee: true,
                    selectedRoomId: widget.selectedRoomId,
                    embedded: widget.embedded,
                    onRoomSelected: widget.onRoomSelected,
                    onRename: _renameRoom,
                  ),
                  _InboxList(
                    rooms: resolved,
                    sort: _inboxSort,
                    emptyText: s.adminInboxEmptyResolved,
                    accentFor: (_) => AppTheme.textSecondary,
                    pending: false,
                    selectedRoomId: widget.selectedRoomId,
                    embedded: widget.embedded,
                    onRoomSelected: widget.onRoomSelected,
                    onRename: _renameRoom,
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

/// Inbox โหมด Ops — segment ชัด + รายการอ่านง่าย
class _OpsInboxBody extends StatelessWidget {
  const _OpsInboxBody({
    required this.tabs,
    required this.unclaimed,
    required this.mine,
    required this.resolved,
    required this.sort,
    required this.filter,
    required this.onSortChanged,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onSearch,
    this.selectedRoomId,
    this.embedded = false,
    this.onRoomSelected,
    this.onRename,
    required this.accentFor,
  });

  final TabController tabs;
  final List<ChatRoom> unclaimed;
  final List<ChatRoom> mine;
  final List<ChatRoom> resolved;
  final AdminInboxSort sort;
  final AdminInboxFilterTag filter;
  final ValueChanged<AdminInboxSort> onSortChanged;
  final ValueChanged<AdminInboxFilterTag> onFilterChanged;
  final VoidCallback onRefresh;
  final VoidCallback onSearch;
  final String? selectedRoomId;
  final bool embedded;
  final ValueChanged<String>? onRoomSelected;
  final Future<void> Function(ChatRoom room)? onRename;
  final Color Function(ChatRoom) accentFor;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.adminOpsInboxTitle,
                  style: AdminTheme.title.copyWith(fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, size: 20),
                tooltip: s.adminChatSearchTitle,
                onPressed: onSearch,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: s.refresh,
                onPressed: onRefresh,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: _OpsSegmentBar(controller: tabs, s: s),
        ),
        if (tabs.index == 0)
          _InboxFilterBar(
            filter: filter,
            onFilterChanged: onFilterChanged,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          child: _InboxSortBar(
            sort: sort,
            onSortChanged: onSortChanged,
            onRefresh: onRefresh,
            onSearch: onSearch,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              _OpsInboxList(
                rooms: unclaimed,
                sort: sort,
                filter: filter,
                emptyText: s.adminInboxEmptyUnclaimed,
                accentFor: accentFor,
                showClaimHint: true,
                selectedRoomId: selectedRoomId,
                embedded: embedded,
                onRoomSelected: onRoomSelected,
                onRename: onRename,
              ),
              _OpsInboxList(
                rooms: mine,
                sort: sort,
                emptyText: s.adminInboxEmptyMine,
                accentFor: accentFor,
                showAssignee: true,
                selectedRoomId: selectedRoomId,
                embedded: embedded,
                onRoomSelected: onRoomSelected,
                onRename: onRename,
              ),
              _OpsInboxList(
                rooms: resolved,
                sort: sort,
                emptyText: s.adminInboxEmptyResolved,
                accentFor: (_) => AppTheme.textSecondary,
                pending: false,
                selectedRoomId: selectedRoomId,
                embedded: embedded,
                onRoomSelected: onRoomSelected,
                onRename: onRename,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpsSegmentBar extends StatelessWidget {
  const _OpsSegmentBar({required this.controller, required this.s});

  final TabController controller;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final chat = ChatService.instance;
        final unclaimed =
            chat.listAdminInbox(bucket: AdminInboxBucket.unclaimed).length;
        final mine = chat.listAdminInbox(bucket: AdminInboxBucket.mine).length;
        final resolved =
            chat.listAdminInbox(bucket: AdminInboxBucket.resolved).length;
        final labels = [
          s.adminInboxTabUnclaimed(unclaimed),
          s.adminInboxTabMine(mine),
          s.adminInboxTabResolved(resolved),
        ];
        return Container(
          decoration: BoxDecoration(
            color: AdminTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: List.generate(3, (i) {
              final selected = controller.index == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.animateTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AdminTheme.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: selected
                          ? const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected
                            ? LivingBkkBrand.purplePrimary
                            : AdminTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _OpsInboxList extends StatelessWidget {
  const _OpsInboxList({
    required this.rooms,
    required this.sort,
    required this.emptyText,
    required this.accentFor,
    this.filter = AdminInboxFilterTag.all,
    this.pending = true,
    this.showClaimHint = false,
    this.showAssignee = false,
    this.selectedRoomId,
    this.embedded = false,
    this.onRoomSelected,
    this.onRename,
  });

  final List<ChatRoom> rooms;
  final AdminInboxSort sort;
  final AdminInboxFilterTag filter;
  final String emptyText;
  final Color Function(ChatRoom) accentFor;
  final bool pending;
  final bool showClaimHint;
  final bool showAssignee;
  final String? selectedRoomId;
  final bool embedded;
  final ValueChanged<String>? onRoomSelected;
  final Future<void> Function(ChatRoom room)? onRename;

  void _openRoom(BuildContext context, ChatRoom room) {
    ChatService.instance.markAdminThreadRead(room.id);
    if (embedded && onRoomSelected != null) {
      onRoomSelected!(room.id);
      return;
    }
    context.push('/admin/chat/${room.id}');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyText, textAlign: TextAlign.center, style: AdminTheme.hint),
        ),
      );
    }
    final filtered = AdminInboxPreview.filterRooms(rooms, filter, s);
    if (filtered.isEmpty) {
      return Center(
        child: Text(s.adminInboxEmptyFiltered(rooms.length), style: AdminTheme.hint),
      );
    }
    final sorted = AdminInboxPreview.sortRooms(filtered, sort);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final room = sorted[i];
        final preview = AdminInboxPreview.fromRoom(room, s);
        return _OpsInboxTile(
          room: room,
          preview: preview,
          accent: accentFor(room),
          pending: pending,
          selected: selectedRoomId == room.id,
          showSla: pending,
          onTap: () => _openRoom(context, room),
          onRename: onRename == null ? null : () => onRename!(room),
        );
      },
    );
  }
}

class _OpsInboxTile extends StatelessWidget {
  const _OpsInboxTile({
    required this.room,
    required this.preview,
    required this.accent,
    required this.pending,
    required this.onTap,
    this.selected = false,
    this.showSla = true,
    this.onRename,
  });

  final ChatRoom room;
  final AdminInboxPreview preview;
  final Color accent;
  final bool pending;
  final VoidCallback onTap;
  final bool selected;
  final bool showSla;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final chat = ChatService.instance;
    final isUnread = chat.isAdminThreadUnread(room);
    final needsAttention = chat.needsAdminReply(room);
    final sla = showSla && pending
        ? AdminInboxSla.forRoom(room, needsAttention: needsAttention)
        : null;
    final sentAt =
        AdminInboxPreview.formatMessageSentAt(preview.previewMessageAt, s);

    return Material(
      color: selected
          ? LivingBkkBrand.purplePrimary.withOpacity(0.07)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onRename,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected
                    ? LivingBkkBrand.purplePrimary
                    : (sla?.color ?? accent).withOpacity(
                        selected ? 1 : 0.35,
                      ),
                width: selected ? 3 : 2,
              ),
              bottom: BorderSide(color: AdminTheme.border.withOpacity(0.7)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview.titleLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 14,
                              color: AdminTheme.text,
                            ),
                          ),
                        ),
                        Text(
                          sentAt,
                          style: AdminTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isUnread
                                ? LivingBkkBrand.purplePrimary
                                : AdminTheme.textFaint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preview.intentLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.previewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: isUnread
                            ? AdminTheme.textMuted
                            : AdminTheme.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              if (sla != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: sla.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${sla.waitMinutes}m',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: sla.color,
                    ),
                  ),
                ),
              ] else if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: LivingBkkBrand.purplePrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxFilterBar extends StatelessWidget {
  const _InboxFilterBar({
    required this.filter,
    required this.onFilterChanged,
  });

  final AdminInboxFilterTag filter;
  final ValueChanged<AdminInboxFilterTag> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final options = adminInboxFilterOptions(s);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Text(
            s.adminInboxFilterHint,
            style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final opt = options[i];
              final selected = filter == opt.tag;
              return FilterChip(
                label: Text(opt.label, style: const TextStyle(fontSize: 11)),
                selected: selected,
                onSelected: (_) => onFilterChanged(opt.tag),
                visualDensity: VisualDensity.compact,
                showCheckmark: false,
                selectedColor: LivingBkkBrand.purplePrimary.withOpacity(0.14),
                labelStyle: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? LivingBkkBrand.purplePrimary
                      : AdminTheme.textMuted,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InboxSortBar extends StatelessWidget {
  const _InboxSortBar({
    required this.sort,
    required this.onSortChanged,
    required this.onRefresh,
    required this.onSearch,
  });

  final AdminInboxSort sort;
  final ValueChanged<AdminInboxSort> onSortChanged;
  final VoidCallback onRefresh;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: ToggleButtons(
              isSelected: [
                sort == AdminInboxSort.recentFirst,
                sort == AdminInboxSort.oldestWaitingFirst,
              ],
              onPressed: (i) => onSortChanged(
                i == 0
                    ? AdminInboxSort.recentFirst
                    : AdminInboxSort.oldestWaitingFirst,
              ),
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minHeight: 32, minWidth: 0),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    s.adminInboxSortRecentFirst,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    s.adminInboxSortOldestWaiting,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            tooltip: s.adminChatSearchTitle,
            onPressed: onSearch,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: s.refresh,
            onPressed: onRefresh,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList({
    required this.rooms,
    required this.sort,
    required this.emptyText,
    required this.accentFor,
    this.filter = AdminInboxFilterTag.all,
    this.pending = true,
    this.showClaimHint = false,
    this.showAssignee = false,
    this.selectedRoomId,
    this.embedded = false,
    this.onRoomSelected,
    this.onRename,
  });

  final List<ChatRoom> rooms;
  final AdminInboxSort sort;
  final AdminInboxFilterTag filter;
  final String emptyText;
  final Color Function(ChatRoom) accentFor;
  final bool pending;
  final bool showClaimHint;
  final bool showAssignee;
  final String? selectedRoomId;
  final bool embedded;
  final ValueChanged<String>? onRoomSelected;
  final Future<void> Function(ChatRoom room)? onRename;

  void _openRoom(BuildContext context, ChatRoom room) {
    ChatService.instance.markAdminThreadRead(room.id);
    if (embedded && onRoomSelected != null) {
      onRoomSelected!(room.id);
      return;
    }
    context.push('/admin/chat/${room.id}');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyText, textAlign: TextAlign.center),
        ),
      );
    }

    final filtered = AdminInboxPreview.filterRooms(rooms, filter, s);
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            s.adminInboxEmptyFiltered(rooms.length),
            textAlign: TextAlign.center,
            style: AdminTheme.hint,
          ),
        ),
      );
    }

    final sorted = AdminInboxPreview.sortRooms(filtered, sort);

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AdminTheme.border.withOpacity(0.6),
      ),
      itemBuilder: (context, i) {
        final room = sorted[i];
        final continuity = room.isUnclaimed
            ? ChatService.instance.continuityHintForRoom(room)
            : null;
        return _InboxTile(
          room: room,
          preview: AdminInboxPreview.fromRoom(room, context.s),
          accent: accentFor(room),
          pending: pending,
          showClaimHint: showClaimHint,
          queueOrder: showClaimHint ? i + 1 : null,
          showAssignee: showAssignee,
          continuityHint: continuity,
          selected: selectedRoomId == room.id,
          onTap: () => _openRoom(context, room),
          onRename: onRename == null ? null : () => onRename!(room),
        );
      },
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.room,
    required this.preview,
    required this.accent,
    required this.pending,
    required this.onTap,
    this.showClaimHint = false,
    this.queueOrder,
    this.showAssignee = false,
    this.continuityHint,
    this.selected = false,
    this.onRename,
  });

  final ChatRoom room;
  final AdminInboxPreview preview;
  final Color accent;
  final bool pending;
  final VoidCallback onTap;
  final bool showClaimHint;
  /// ลำดับในแท็บรอรับงาน (1 = รายการแรกตามการเรียงปัจจุบัน)
  final int? queueOrder;
  final bool showAssignee;
  final CustomerAdminContinuityHint? continuityHint;
  final bool selected;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final chat = ChatService.instance;
    final isUnread = chat.isAdminThreadUnread(room);
    final needsAttention = chat.needsAdminReply(room);
    final sla = AdminInboxSla.forRoom(room, needsAttention: needsAttention);
    final sentAt =
        AdminInboxPreview.formatMessageSentAt(preview.previewMessageAt, s);
    final initials = AdminInboxPreview.initials(preview.titleLine);
    final previewColor = isUnread ? AdminTheme.text : AdminTheme.textFaint;
    final timeColor = isUnread ? AdminTheme.textMuted : AdminTheme.textFaint;

    return Material(
      color: selected
          ? LivingBkkBrand.purplePrimary.withOpacity(0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onRename,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (queueOrder != null) ...[
                SizedBox(
                  width: 30,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722).withOpacity(0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF5722).withOpacity(0.55),
                          ),
                        ),
                        child: Text(
                          '$queueOrder',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF5722),
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withOpacity(0.14),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.titleLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 15,
                        color: isUnread ? AdminTheme.text : AdminTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (preview.isCoAgencyCustomer)
                          AdminInboxPreview.coAgencyCustomerChip(context),
                        _Chip(label: preview.intentLabel, color: accent),
                        if (preview.isUrgent)
                          _Chip(label: s.adminPriorityHigh, color: AppTheme.error),
                        if (pending && room.isUnclaimed)
                          _Chip(label: s.adminAwaitingReply, color: AppTheme.error),
                        if (sla != null)
                          _Chip(label: sla.label(s), color: sla.color),
                        if (showClaimHint && room.isUnclaimed)
                          _Chip(label: s.adminNeedsClaim, color: AppTheme.accentMid),
                        if (continuityHint != null)
                          _Chip(
                            label: s.adminReturningCustomerChip(
                              continuityHint!.adminName,
                            ),
                            color: const Color(0xFFB45309),
                          ),
                        if (showAssignee &&
                            room.assignedAdminName != null &&
                            room.assignedAdminName!.isNotEmpty)
                          _Chip(
                            label: s.adminClaimedBy(room.assignedAdminName!),
                            color: AppTheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: previewColor,
                          fontWeight:
                              isUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                        children: [
                          TextSpan(
                            text: '$sentAt · ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: timeColor,
                            ),
                          ),
                          TextSpan(text: preview.previewText),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
