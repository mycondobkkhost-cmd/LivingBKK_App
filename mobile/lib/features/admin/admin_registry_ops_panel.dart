import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../models/vault_asset.dart';
import '../../services/chat_service.dart';
import '../../services/registry_asset_ops_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_listing_nav.dart';
import 'admin_listing_public_preview_sheet.dart';
import 'admin_registry_edit_sheet.dart';

/// แผงจัดการทรัพย์ — แก้ไข · แท็ก · ป้าย · ดันประกาศ · ลิงก์ภายใน
class AdminRegistryOpsPanel extends StatefulWidget {
  const AdminRegistryOpsPanel({
    super.key,
    required this.summary,
    required this.confidential,
    required this.parentContext,
    required this.adminTier,
    this.detail,
    this.isDemoPreview = false,
    this.onChanged,
  });

  final VaultAssetSummary summary;
  final VaultAssetDetail? detail;
  final bool confidential;
  final BuildContext parentContext;
  final String adminTier;
  final bool isDemoPreview;
  final VoidCallback? onChanged;

  @override
  State<AdminRegistryOpsPanel> createState() => _AdminRegistryOpsPanelState();
}

class _AdminRegistryOpsPanelState extends State<AdminRegistryOpsPanel> {
  final _ops = RegistryAssetOpsService.instance;
  late TextEditingController _noteCtrl;

  VaultAssetSummary get sum => widget.summary;
  String get entityType => sum.entityType;
  String get entityId => sum.entityId;
  String? get listingId => sum.listingId ?? (entityType == 'listing' ? entityId : null);

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(
      text: _ops.opsFor(entityType: entityType, entityId: entityId).adminNote,
    );
    _ops.addListener(_onOps);
  }

  @override
  void dispose() {
    _ops.removeListener(_onOps);
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onOps() {
    if (mounted) setState(() {});
  }

  RegistryAssetOps get ops => _ops.opsFor(entityType: entityType, entityId: entityId);

  String? get _publicDescription {
    final p = widget.detail?.payload;
    if (p == null) return null;
    return p['description_public_stripped']?.toString() ??
        p['description_public']?.toString();
  }

  String get _displayTitle =>
      _ops.titleFor(entityType: entityType, entityId: entityId) ??
      sum.titlePreview ??
      '';

  Future<void> _bump() async {
    final s = context.s;
    final ok = await _ops.manualBump(listingId: listingId);
    if (ok) {
      _ops.recordManualBump(entityType: entityType, entityId: entityId);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? s.adminRegistryBumpDone
              : (listingId == null ? s.adminRegistryBumpNeedListing : s.adminRegistryBumpFailed),
        ),
      ),
    );
  }

  Future<void> _previewPublic() async {
    final id = listingId;
    if (id == null) return;
    await showAdminListingPublicPreview(
      context: context,
      listingId: id,
      titleOverride: _displayTitle,
      descriptionOverride:
          _ops.descriptionFor(entityType: entityType, entityId: entityId) ??
              _publicDescription,
    );
  }

  Future<void> _edit() async {
    final changed = await showRegistryEditSheet(
      context: context,
      summary: sum,
      initialTitle: _displayTitle,
      initialDescription:
          _ops.descriptionFor(entityType: entityType, entityId: entityId) ??
              _publicDescription ??
              '',
    );
    if (changed == true) {
      widget.onChanged?.call();
      if (mounted) setState(() {});
    }
  }

  bool get _canChatOwner => _ops.hasChatAccess(
        entityType: entityType,
        entityId: entityId,
        adminTier: widget.adminTier,
      );

  String get _chatTag => sum.listingCode ?? sum.displayCode;

  Future<void> _chatOwner() async {
    final s = context.s;
    if (!_canChatOwner) {
      await _requestChatAccess();
      return;
    }
    await _openOwnerChat(s);
  }

  Future<void> _requestChatAccess() async {
    final s = context.s;
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.adminRegistryChatRequestTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.adminRegistryChatRequestHint, style: AdminTheme.caption),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: s.adminRegistryChatRequestReason,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.adminRegistryChatRequestSubmit),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminRegistryChatRequestNeedReason)),
      );
      return;
    }
    _ops.requestChatAccess(
      entityType: entityType,
      entityId: entityId,
      actor: 'แอดมิน',
      reason: reason,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminRegistryChatRequestSent)),
    );
  }

  Future<void> _openOwnerChat(AppStrings s) async {
    final tag = _chatTag;
    ChatRoom? room = ChatService.instance.roomForListing(tag);
    if (room == null && sum.listingId != null) {
      room = ChatService.instance.roomForListing(sum.listingId!);
    }
    if (room == null && widget.isDemoPreview) {
      try {
        room = await ChatService.instance.openRoom(
          listingId: sum.listingId ?? entityId,
          listingCode: tag,
          listingTitle: _displayTitle,
        );
      } catch (_) {}
    }
    await _openAfterClose((host) async {
      if (room != null) {
        host.go('/admin/console?room=${room.id}');
        return;
      }
      host.go('/admin/console');
      ScaffoldMessenger.of(host).showSnackBar(
        SnackBar(content: Text(s.adminRegistryChatTagHint(tag))),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bumpFmt = DateFormat('d MMM HH:mm');
    final pendingChat = _ops.hasPendingChatRequest(
      entityType: entityType,
      entityId: entityId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(s.adminRegistryOpsTitle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(s.adminRegistryEdit),
            ),
            OutlinedButton.icon(
              onPressed: listingId == null ? null : _previewPublic,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(s.adminListingPreview),
            ),
            OutlinedButton.icon(
              onPressed: pendingChat ? null : _chatOwner,
              icon: Icon(
                _canChatOwner ? Icons.chat_outlined : Icons.lock_outline,
                size: 18,
              ),
              label: Text(
                _canChatOwner
                    ? s.adminRegistryChatOwner
                    : (pendingChat
                        ? s.adminRegistryChatRequestPending
                        : s.adminRegistryChatOwnerRequest),
              ),
            ),
            if (listingId != null)
              OutlinedButton.icon(
                onPressed: _bump,
                icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                label: Text(s.adminRegistryBumpNow),
              ),
            if (sum.listingCode != null || listingId != null)
              OutlinedButton.icon(
                onPressed: () => openAdminListing(
                  context,
                  listingId: listingId,
                  listingCode: sum.listingCode,
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(s.adminOpenListing),
              ),
          ],
        ),
        if (!_canChatOwner && !pendingChat) ...[
          const SizedBox(height: 6),
          Text(s.adminRegistryChatOwnerGate, style: AdminTheme.caption),
        ],
        if (ops.lastManualBumpAt != null) ...[
          const SizedBox(height: 6),
          Text(
            s.adminRegistryLastBump(bumpFmt.format(ops.lastManualBumpAt!)),
            style: AdminTheme.caption,
          ),
        ],
        const SizedBox(height: 16),
        _sectionTitle(s.adminRegistryTagsTitle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RegistryAdminTag.values
              .where((tag) => tag != RegistryAdminTag.ownerUnreachable)
              .map((tag) {
            final selected = ops.tags.contains(tag);
            return FilterChip(
              label: Text(_tagLabel(s, tag)),
              selected: selected,
              avatar: Icon(_tagIcon(tag), size: 16),
              onSelected: (_) {
                _ops.toggleTag(entityType: entityType, entityId: entityId, tag: tag);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _sectionTitle(s.adminRegistryOverlayTitle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(s.adminRegistryOverlayNormal),
              selected: ops.overlay == RegistryDisplayOverlay.none,
              onSelected: (_) => _ops.setOverlay(
                entityType: entityType,
                entityId: entityId,
                overlay: RegistryDisplayOverlay.none,
              ),
            ),
            ChoiceChip(
              label: Text(s.adminRegistryOverlaySold),
              selected: ops.overlay == RegistryDisplayOverlay.sold,
              labelStyle: TextStyle(
                color: ops.overlay == RegistryDisplayOverlay.sold ? Colors.white : AppTheme.error,
                fontWeight: FontWeight.w800,
              ),
              selectedColor: AppTheme.error,
              onSelected: (_) => _ops.setOverlay(
                entityType: entityType,
                entityId: entityId,
                overlay: RegistryDisplayOverlay.sold,
              ),
            ),
            ChoiceChip(
              label: Text(s.adminRegistryOverlayNotAvailable),
              selected: ops.overlay == RegistryDisplayOverlay.notAvailable,
              onSelected: (_) => _ops.setOverlay(
                entityType: entityType,
                entityId: entityId,
                overlay: RegistryDisplayOverlay.notAvailable,
              ),
            ),
          ],
        ),
        if (ops.overlay != RegistryDisplayOverlay.none) ...[
          const SizedBox(height: 8),
          _previewOverlay(ops.overlay, s),
        ],
        const SizedBox(height: 16),
        _sectionTitle(s.adminRegistryAutoBumpTitle),
        const SizedBox(height: 4),
        Text(s.adminRegistryAutoBumpHint, style: AdminTheme.caption),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.adminRegistryAutoBumpEnable),
          subtitle: listingId == null ? Text(s.adminRegistryBumpNeedListing, style: AdminTheme.caption) : null,
          value: ops.autoBumpEnabled && listingId != null,
          onChanged: listingId == null
              ? null
              : (v) => _ops.setAutoBump(
                    entityType: entityType,
                    entityId: entityId,
                    enabled: v,
                    hours: ops.autoBumpHours > 0
                        ? ops.autoBumpHours
                        : _ops.defaultAutoBumpHours(),
                  ),
        ),
        if (ops.autoBumpEnabled && listingId != null) ...[
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: ops.autoBumpHours.clamp(1, 72).toDouble(),
                  min: 1,
                  max: 72,
                  divisions: 71,
                  label: '${ops.autoBumpHours}h',
                  onChanged: (v) => _ops.setAutoBump(
                    entityType: entityType,
                    entityId: entityId,
                    enabled: true,
                    hours: v.round(),
                  ),
                ),
              ),
              Text(s.adminRegistryAutoBumpEvery(ops.autoBumpHours), style: AdminTheme.caption),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _sectionTitle(s.adminRegistryInternalLinks),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (listingId != null || sum.listingCode != null)
              _linkBtn(Icons.home_work_outlined, s.adminOpenListing, () {
                openAdminListing(context, listingId: listingId, listingCode: sum.listingCode);
              }),
            _linkBtn(Icons.shield_outlined, s.adminTabModeration, () => context.go('/admin')),
            _linkBtn(Icons.chat_bubble_outline, s.adminTabChat, () {
              if (context.mounted) context.go('/admin/console');
            }),
            _linkBtn(Icons.event_outlined, s.adminTabAppointments, () => context.go('/admin')),
            _linkBtn(Icons.support_agent_outlined, s.adminTabLeads, () => context.go('/admin')),
            if (widget.confidential)
              _linkBtn(Icons.lock_outline, s.adminNavVault, () => context.go('/admin')),
            if (sum.profileId != null)
              _linkBtn(Icons.person_outline, s.adminVaultFilterProfile, () {}),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle(s.adminRegistryAdminNote),
        const SizedBox(height: 8),
        TextField(
          controller: _noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: s.adminRegistryAdminNoteHint,
            filled: true,
            fillColor: AdminTheme.surfaceMuted,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (v) => _ops.setNote(
            entityType: entityType,
            entityId: entityId,
            note: v,
          ),
        ),
      ],
    );
  }

  Future<void> _openAfterClose(Future<void> Function(BuildContext host) action) async {
    final host = widget.parentContext;
    Navigator.of(context).pop();
    await Future<void>.delayed(Duration.zero);
    if (!host.mounted) return;
    await action(host);
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AdminTheme.body.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
    );
  }

  Widget _linkBtn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget _previewOverlay(RegistryDisplayOverlay overlay, AppStrings s) {
    final (text, color) = switch (overlay) {
      RegistryDisplayOverlay.sold => (s.adminRegistryOverlaySold, AppTheme.error),
      RegistryDisplayOverlay.notAvailable => (
          s.adminRegistryOverlayNotAvailable,
          const Color(0xFF6B7280),
        ),
      RegistryDisplayOverlay.none => ('', Colors.transparent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.layers_outlined, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.adminRegistryOverlayPreview(text),
              style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _tagLabel(AppStrings s, RegistryAdminTag tag) => switch (tag) {
        RegistryAdminTag.hot => s.adminRegistryTagHot,
        RegistryAdminTag.exclusive => s.adminRegistryTagExclusive,
        RegistryAdminTag.featured => s.adminRegistryTagFeatured,
        RegistryAdminTag.verified => s.adminRegistryTagVerified,
        RegistryAdminTag.urgent => s.adminRegistryTagUrgent,
        RegistryAdminTag.ownerUnreachable => s.adminRegistryTagOwnerUnreachable,
      };

  IconData _tagIcon(RegistryAdminTag tag) => switch (tag) {
        RegistryAdminTag.hot => Icons.local_fire_department_outlined,
        RegistryAdminTag.exclusive => Icons.verified_outlined,
        RegistryAdminTag.featured => Icons.star_outline,
        RegistryAdminTag.verified => Icons.check_circle_outline,
        RegistryAdminTag.urgent => Icons.priority_high,
        RegistryAdminTag.ownerUnreachable => Icons.phone_disabled_outlined,
      };
}
