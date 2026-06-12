import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../services/admin_repository.dart';
import '../../services/chat_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_listing_nav.dart';
import '../../utils/admin_reference_nav.dart';
import '../../widgets/reference_code_chip.dart';
import 'admin_chat_quick_actions.dart';
import 'admin_inbox_preview.dart';
import 'admin_inbox_sla.dart';

const kAdminContextPaneWidth = 300.0;

/// แผงขวาใน console — สรุปเคส + ทางลัด (Zaapi-style context)
class AdminConsoleContextPanel extends StatefulWidget {
  const AdminConsoleContextPanel({
    super.key,
    required this.roomId,
    this.onResolved,
  });

  final String roomId;
  final VoidCallback? onResolved;

  @override
  State<AdminConsoleContextPanel> createState() =>
      _AdminConsoleContextPanelState();
}

class _AdminConsoleContextPanelState extends State<AdminConsoleContextPanel> {
  final _admin = AdminRepository();
  Map<String, dynamic>? _lead;
  bool _loadingLead = false;

  @override
  void initState() {
    super.initState();
    _loadLead();
  }

  @override
  void didUpdateWidget(covariant AdminConsoleContextPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      _lead = null;
      _loadLead();
    }
  }

  Future<void> _loadLead() async {
    setState(() => _loadingLead = true);
    try {
      Map<String, dynamic>? lead;
      final roomId = widget.roomId;
      if (roomId.startsWith('demo-lead-chat-demo-lead-')) {
        final leadId = roomId.replaceFirst('demo-lead-chat-', '');
        lead = await _admin.fetchLead(leadId);
      } else {
        lead = await _admin.fetchLeadByThreadId(roomId);
      }
      if (mounted) setState(() => _lead = lead);
    } catch (_) {
      if (mounted) setState(() => _lead = null);
    } finally {
      if (mounted) setState(() => _loadingLead = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        final room = ChatService.instance.roomById(widget.roomId);
        if (room == null) {
          return ColoredBox(
            color: AdminTheme.surface,
            child: Center(
              child: Text(s.notFoundChat, style: AdminTheme.hint),
            ),
          );
        }

        final preview = AdminInboxPreview.fromRoom(room, s);
        final chat = ChatService.instance;
        final isOpen = !chat.isAdminResolved(room);
        final canReply = chat.canReplyAsAdmin(room);
        final needsAttention = chat.needsAdminReply(room);
        final sla = AdminInboxSla.forRoom(room, needsAttention: needsAttention);

        return Material(
          color: const Color(0xFFFAFBFC),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PanelTitle(text: s.adminContextPanelTitle),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  children: [
                    _Section(
                      title: s.adminContextStatusSection,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatusRow(
                            icon: isOpen
                                ? Icons.circle_outlined
                                : Icons.check_circle_outline,
                            label: isOpen
                                ? (needsAttention
                                    ? s.adminPendingMeta
                                    : s.adminActiveMeta)
                                : s.adminResolvedMeta,
                            color: isOpen
                                ? (needsAttention
                                    ? AppTheme.accentMid
                                    : AppTheme.primary)
                                : AppTheme.textSecondary,
                          ),
                          if (sla != null) ...[
                            const SizedBox(height: 8),
                            _SlaBanner(sla: sla),
                          ],
                          if (room.assignedAdminName != null &&
                              room.assignedAdminName!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _StatusRow(
                              icon: Icons.person_outline,
                              label: s.adminClaimedBy(room.assignedAdminName!),
                              color: AppTheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                    _Section(
                      title: s.adminContextActionsSection,
                      child: _ContextActions(
                        room: room,
                        isOpen: isOpen,
                        needsAttention: needsAttention,
                        canReply: canReply,
                        onResolved: widget.onResolved,
                      ),
                    ),
                    _Section(
                      title: s.adminContextCustomerSection,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preview.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _MiniChip(
                                label: preview.roleLabel,
                                color: AppTheme.primary,
                              ),
                              _MiniChip(
                                label: preview.intentLabel,
                                color: AppTheme.accentDeep,
                              ),
                              if (preview.isUrgent)
                                _MiniChip(
                                  label: s.adminPriorityHigh,
                                  color: AppTheme.error,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (room.isPropertyListing ||
                        room.listingCode.isNotEmpty &&
                            room.listingCode != 'DISCOVERY')
                      _Section(
                        title: s.adminContextPropertySection,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.listingTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            if (room.projectName != null &&
                                room.projectName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  room.projectName!,
                                  style: AdminTheme.caption,
                                ),
                              ),
                            if (room.listingCode.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                s.listingCodeShort(room.listingCode),
                                style: AdminTheme.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => openAdminListing(
                                context,
                                listingId: room.listingId.isNotEmpty
                                    ? room.listingId
                                    : null,
                                listingCode: room.listingCode,
                              ),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: Text(s.adminContextOpenListing),
                            ),
                          ],
                        ),
                      ),
                    _Section(
                      title: s.adminContextReferenceSection,
                      child: ReferenceCodeChip(
                        code: room.effectiveTransactionRef,
                        label: s.transactionRefLabel,
                        compact: false,
                        onNavigate: adminReferenceNavigateHandler(
                          context,
                          code: room.effectiveTransactionRef,
                          threadId: room.id,
                          listingId:
                              room.listingId.isNotEmpty ? room.listingId : null,
                          listingCode: room.listingCode,
                        ),
                      ),
                    ),
                    if (_loadingLead)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (_lead != null)
                      _Section(
                        title: s.adminContextLeadSection,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _KvRow(
                              label: s.leadDefaultName,
                              value: _lead!['seeker_nickname']?.toString() ??
                                  s.leadDefaultName,
                            ),
                            if ((_lead!['seeker_phone']?.toString() ?? '')
                                .isNotEmpty)
                              _KvRow(
                                label: s.adminContextPhoneLabel,
                                value: _lead!['seeker_phone']?.toString() ?? '',
                              ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                final id = _lead!['id']?.toString();
                                if (id != null && id.isNotEmpty) {
                                  context.push('/admin/lead/$id');
                                }
                              },
                              icon: const Icon(Icons.assignment_ind_outlined,
                                  size: 16),
                              label: Text(s.adminContextOpenLead),
                            ),
                          ],
                        ),
                      ),
                    _Section(
                      title: s.adminContextShortcutsSection,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (room.participantUserId != null &&
                              room.participantUserId!.isNotEmpty)
                            _ShortcutTile(
                              icon: Icons.hub_outlined,
                              label: s.adminContextParticipant360,
                              onTap: () => context.go(
                                '/admin?nav=participant360&user=${room.participantUserId}',
                              ),
                            ),
                          _ShortcutTile(
                            icon: Icons.calendar_month_outlined,
                            label: s.adminNavViewingCalendar,
                            onTap: () =>
                                context.go('/admin?nav=viewingCalendar'),
                          ),
                          _ShortcutTile(
                            icon: Icons.tune,
                            label: s.adminFaqSettings,
                            onTap: () => context.push('/admin/faq'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminTheme.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Text(
          text,
          style: AdminTheme.title.copyWith(fontSize: 14),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AdminTheme.caption.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SlaBanner extends StatelessWidget {
  const _SlaBanner({required this.sla});

  final AdminInboxSla sla;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: sla.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: sla.color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: sla.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sla.label(s),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sla.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: AdminTheme.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextActions extends StatelessWidget {
  const _ContextActions({
    required this.room,
    required this.isOpen,
    required this.needsAttention,
    required this.canReply,
    this.onResolved,
  });

  final ChatRoom room;
  final bool isOpen;
  final bool needsAttention;
  final bool canReply;
  final VoidCallback? onResolved;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (room.isUnclaimed && needsAttention)
          _ActionBtn(
            icon: Icons.back_hand_outlined,
            label: s.adminClaimWork,
            color: AppTheme.accentMid,
            onPressed: () => AdminChatQuickActions.claim(context, room),
          ),
        if (isOpen && needsAttention)
          _ActionBtn(
            icon: Icons.person_add_alt_1_outlined,
            label: s.adminAssignWork,
            onPressed: () => AdminChatQuickActions.assign(context, room),
          ),
        if (isOpen && canReply) ...[
          _ActionBtn(
            icon: Icons.check_circle_outline,
            label: s.adminCloseCase,
            color: const Color(0xFF059669),
            filled: true,
            onPressed: () => AdminChatQuickActions.resolve(
              context,
              room,
              onDone: onResolved,
            ),
          ),
          const SizedBox(height: 6),
          _ActionBtn(
            icon: Icons.event_note_outlined,
            label: s.adminSendViewingFormBtn,
            onPressed: () =>
                AdminChatQuickActions.sendViewingForm(context, room),
          ),
          _ActionBtn(
            icon: Icons.checklist_rtl_outlined,
            label: s.adminSendRequirementFormBtn,
            onPressed: () =>
                AdminChatQuickActions.sendRequirementForm(context, room),
          ),
          _ActionBtn(
            icon: Icons.home_work_outlined,
            label: s.adminSendListingCardsTitle,
            onPressed: () =>
                AdminChatQuickActions.sendListingCards(context, room),
          ),
        ],
        if (!isOpen)
          Text(
            s.adminResolvedMeta,
            style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    final child = Row(
      children: [
        Icon(icon, size: 16, color: filled ? Colors.white : c),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : c,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: c,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                alignment: Alignment.centerLeft,
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: c,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                alignment: Alignment.centerLeft,
              ),
              child: child,
            ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}
