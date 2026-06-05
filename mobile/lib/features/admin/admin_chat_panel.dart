import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_chat_ops.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../services/chat_repository.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/reference_code_chip.dart';
import '../../utils/reference_codes.dart';

/// แผงตอบแชทแอดมิน — ใช้ได้ทั้งหน้าเต็มและฝังใน console บนคอม
class AdminChatPanel extends StatefulWidget {
  const AdminChatPanel({
    super.key,
    required this.roomId,
    this.embedded = false,
    this.onResolved,
    this.onBack,
  });

  final String roomId;
  final bool embedded;
  final VoidCallback? onResolved;
  final VoidCallback? onBack;

  @override
  State<AdminChatPanel> createState() => _AdminChatPanelState();
}

class _AdminChatPanelState extends State<AdminChatPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _chat = ChatService.instance;
  RealtimeChannel? _realtimeChannel;
  bool _loading = true;

  ChatRoom? get _room => _chat.roomById(widget.roomId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      _detachRealtime();
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    await _chat.loadThreadIfMissing(widget.roomId);
    final room = _room;
    if (room != null && room.isPersisted) {
      _realtimeChannel = _chat.subscribeToThread(room, () {
        if (mounted) setState(() {});
        _scrollToBottom();
      });
    }
    if (mounted) setState(() => _loading = false);
    _scrollToBottom();
  }

  void _detachRealtime() {
    if (_realtimeChannel != null) {
      ChatRepository().unsubscribe(_realtimeChannel);
      _realtimeChannel = null;
    }
  }

  @override
  void dispose() {
    _detachRealtime();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final room = _room;
    if (room == null) return;
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final s = context.s;
    if (!_chat.canReplyAsAdmin(room)) {
      if (room.isUnclaimed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.adminMustClaimFirst)),
        );
      } else if (_chat.isClaimedByOtherAdmin(room)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.adminClaimedByOther)),
        );
      }
      return;
    }
    _input.clear();
    try {
      await _chat.sendAdminReply(room, text);
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminClaimedByOther)),
      );
    }
  }

  Future<void> _claim() async {
    final room = _room;
    if (room == null || !room.isUnclaimed) return;
    await _chat.claimThread(room);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.adminClaimSuccess)),
    );
    setState(() {});
  }

  Future<void> _assign() async {
    final room = _room;
    if (room == null) return;
    final s = context.s;
    final peers = await _chat.fetchTeamAdmins();
    if (!mounted) return;
    if (peers.isEmpty) return;

    final picked = await showModalBottomSheet<AdminPeer>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  s.adminAssignTo,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
        );
      },
    );

    if (picked == null) return;
    await _chat.assignThread(room, picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminAssignSuccess)),
    );
    setState(() {});
  }

  void _useQuickReply(String text) {
    _input.text = text;
    setState(() {});
  }

  Future<void> _markResolved() async {
    final room = _room;
    if (room == null) return;
    await _chat.markAdminResolved(room);
    if (!mounted) return;
    final s = context.s;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminMarkedReplied)),
    );
    if (widget.embedded) {
      widget.onResolved?.call();
    } else {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final room = _room;
    if (room == null) {
      return Center(child: Text(s.notFoundChat));
    }

    return ListenableBuilder(
      listenable: _chat,
      builder: (context, _) {
        final live = _chat.roomById(widget.roomId)!;
        final pending = _chat.needsAdminReply(live);
        final canReply = _chat.canReplyAsAdmin(live);
        final claimedOther = _chat.isClaimedByOtherAdmin(live);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PanelHeader(
              room: live,
              embedded: widget.embedded,
              pending: pending,
              canReply: canReply,
              onBack: widget.onBack,
              onClaim: _claim,
              onAssign: _assign,
              onResolve: _markResolved,
            ),
            _MetaBar(room: live, pending: pending, canReply: canReply),
            if (live.isUnclaimed && pending) _ClaimBanner(onClaim: _claim),
            if (claimedOther && pending)
              _BlockedBanner(text: s.adminClaimedByOther),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: live.messages.length,
                itemBuilder: (context, i) => _AdminBubble(message: live.messages[i]),
              ),
            ),
            _QuickReplyRow(replies: s.adminQuickReplies, onPick: _useQuickReply),
            if (!canReply && pending)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  live.isUnclaimed ? s.adminMustClaimFirst : s.adminClaimedByOther,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: widget.embedded ? 6 : 4,
                        enabled: canReply || !pending,
                        decoration: InputDecoration(
                          hintText:
                              canReply ? s.adminReplyHint : s.adminMustClaimFirst,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: canReply ? (_) => _send() : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: canReply ? _send : null,
                      icon: const Icon(Icons.send),
                      tooltip: s.adminSendReply,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.room,
    required this.embedded,
    required this.pending,
    required this.canReply,
    this.onBack,
    required this.onClaim,
    required this.onAssign,
    required this.onResolve,
  });

  final ChatRoom room;
  final bool embedded;
  final bool pending;
  final bool canReply;
  final VoidCallback? onBack;
  final VoidCallback onClaim;
  final VoidCallback onAssign;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Material(
      elevation: embedded ? 0 : 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
        child: Row(
          children: [
            if (embedded && onBack != null)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                tooltip: s.back,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.adminReplyCustomer,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    room.displayTitle,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (room.isUnclaimed && pending)
              TextButton(onPressed: onClaim, child: Text(s.adminClaimWork)),
            if (pending) TextButton(onPressed: onAssign, child: Text(s.adminAssignWork)),
            if (pending && canReply)
              FilledButton(onPressed: onResolve, child: Text(s.adminCloseCase)),
          ],
        ),
      ),
    );
  }
}

class _MetaBar extends StatelessWidget {
  const _MetaBar({
    required this.room,
    required this.pending,
    required this.canReply,
  });

  final ChatRoom room;
  final bool pending;
  final bool canReply;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      width: double.infinity,
      color: pending ? AppTheme.accentMidLight : AppTheme.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            pending
                ? (canReply ? Icons.mark_chat_unread : Icons.lock_outline)
                : Icons.check_circle_outline,
            size: 16,
            color: pending ? AppTheme.accentMid : AppTheme.primary,
          ),
          Text(
            pending
                ? (canReply ? s.adminPendingMeta : s.adminClaimedByOther)
                : s.adminResolvedMeta,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: pending ? AppTheme.accentMid : AppTheme.primary,
            ),
          ),
          if (room.assignedAdminName != null && room.assignedAdminName!.isNotEmpty)
            _MetaChip(
              label: s.adminClaimedBy(room.assignedAdminName!),
              color: AppTheme.primary,
            ),
          if (room.viewingSubmitted)
            _MetaChip(label: s.adminViewingFormChip, color: AppTheme.accentDeep),
          if (room.isStaffSupport)
            _MetaChip(label: s.adminStaffChatChip, color: AppTheme.accentMid),
          ReferenceCodeChip(
            code: room.effectiveTransactionRef,
            label: s.transactionRefLabel,
            compact: true,
          ),
          if (room.isPropertyListing &&
              !ReferenceCodes.isSpecialListingCode(room.listingCode))
            ReferenceCodeChip(
              code: room.listingCode,
              label: s.propertyCodeLabel,
              compact: true,
            ),
        ],
      ),
    );
  }
}

class _ClaimBanner extends StatelessWidget {
  const _ClaimBanner({required this.onClaim});

  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Material(
      color: AppTheme.accentDeepLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                s.adminMustClaimFirst,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(onPressed: onClaim, child: Text(s.adminClaimWork)),
          ],
        ),
      ),
    );
  }
}

class _BlockedBanner extends StatelessWidget {
  const _BlockedBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.accentMidLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: AppTheme.accentMid),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

class _QuickReplyRow extends StatelessWidget {
  const _QuickReplyRow({required this.replies, required this.onPick});

  final List<String> replies;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final text = replies[i];
          return ActionChip(
            label: Text(
              text.length > 28 ? '${text.substring(0, 28)}…' : text,
              style: TextStyle(fontSize: 11),
            ),
            onPressed: () => onPick(text),
          );
        },
      ),
    );
  }
}

class _AdminBubble extends StatelessWidget {
  const _AdminBubble({required this.message});

  final ChatMessage message;

  String _roleLabel(AppStrings s) {
    switch (message.role) {
      case ChatMessageRole.user:
        return s.chatRoleCustomer;
      case ChatMessageRole.ai:
        return 'AI';
      case ChatMessageRole.system:
        return s.chatRoleSystem;
      case ChatMessageRole.adminNotice:
        return s.chatRoleTeam;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final isUser = message.role == ChatMessageRole.user;
    final isStaff = message.role == ChatMessageRole.adminNotice;
    final isSystem = message.role == ChatMessageRole.system;
    final time = DateFormat('HH:mm').format(message.createdAt);
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.72;

    Color bg;
    Color fg;
    Alignment align;

    if (isUser) {
      bg = AppTheme.primary;
      fg = Colors.white;
      align = Alignment.centerRight;
    } else if (isStaff) {
      bg = AppTheme.accentMidLight;
      fg = AppTheme.textPrimary;
      align = Alignment.centerLeft;
    } else if (isSystem) {
      bg = AppTheme.accentDeepLight;
      fg = AppTheme.textPrimary;
      align = Alignment.center;
    } else {
      bg = AppTheme.accentMutedLight;
      fg = AppTheme.textPrimary;
      align = Alignment.centerLeft;
    }

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _roleLabel(s),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isStaff ? AppTheme.accentMid : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
                if (message.requiresAdmin) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.priority_high, size: 14, color: AppTheme.error),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border.withOpacity(0.45)),
              ),
              child: Text(message.text, style: TextStyle(color: fg, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}
