import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/listing/listing_stats_sheet.dart';
import '../l10n/app_strings.dart';
import '../models/listing_viewing_access.dart';
import '../services/listing_activity_service.dart';
import '../services/listing_availability_reminder_service.dart';
import '../services/listing_owner_repository.dart';
import '../theme/app_theme.dart';
import '../utils/app_notice.dart';
import '../utils/owner_listing_media.dart';

/// การ์ดประกาศเจ้าของ — สรุปกระชับ รายละเอียดเต็มแตะขยาย
class OwnerListingTile extends StatefulWidget {
  const OwnerListingTile({
    super.key,
    required this.row,
    required this.onBump,
    required this.onClose,
    required this.onSoftDelete,
    this.index,
    this.showOwnerDataChip = false,
    this.onCompleteData,
    this.onEdit,
    this.careAssignedLabel,
    this.daysUntilAvailable,
    this.onAvailabilityFollowUp,
  });

  final Map<String, dynamic> row;
  final int? index;
  final VoidCallback onBump;
  final VoidCallback onClose;
  final VoidCallback onSoftDelete;
  final bool showOwnerDataChip;
  final VoidCallback? onCompleteData;
  final VoidCallback? onEdit;
  final String? careAssignedLabel;
  final int? daysUntilAvailable;
  final VoidCallback? onAvailabilityFollowUp;

  @override
  State<OwnerListingTile> createState() => _OwnerListingTileState();
}

class _OwnerListingTileState extends State<OwnerListingTile> {
  bool _expanded = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _armCooldownTimer();
  }

  @override
  void didUpdateWidget(OwnerListingTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row['last_bump_at'] != widget.row['last_bump_at']) {
      _armCooldownTimer();
    }
  }

  void _armCooldownTimer() {
    _cooldownTimer?.cancel();
    final left = ListingOwnerRepository.bumpCooldownRemaining(widget.row);
    if (left == null) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {});
      if (ListingOwnerRepository.bumpCooldownRemaining(widget.row) == null) {
        _cooldownTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _openPreview(BuildContext context) {
    final s = AppStrings.of(context);
    final row = widget.row;
    if (!OwnerListingMedia.canPreviewOnline(row)) {
      AppNotice.snack(context, s.listingPreviewNotOnline);
      return;
    }
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return;
    context.push('/listing/$id');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final row = widget.row;
    final status = row['status']?.toString() ?? '';
    final published = status == 'published';
    final archived = status == 'archived';
    final pending = status == 'pending_review';
    final needsOwnerData =
        widget.showOwnerDataChip && widget.onCompleteData != null;
    final canBump =
        published && !needsOwnerData && ListingOwnerRepository.canBumpNow(row);
    final cooldown = needsOwnerData
        ? null
        : ListingOwnerRepository.bumpCooldownRemaining(row);
    final daysLeft = published ? ListingOwnerRepository.daysUntilAutoArchive(row) : 0;
    final statsLine = _statsLine(s, row['id']?.toString() ?? '');
    final canPreview = OwnerListingMedia.canPreviewOnline(row);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.18)),
      ),
      color: pending ? AppTheme.accentAmberLight.withOpacity(0.25) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.index != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, right: 4),
                        child: Text(
                          '${widget.index}.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                    _CoverThumb(
                      row: row,
                      canPreview: canPreview,
                      onTap: () => _openPreview(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['title']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.25,
                            ),
                          ),
                          if (canPreview) ...[
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => _openPreview(context),
                              child: Text(
                                s.listingPreviewOnline,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                          if (widget.careAssignedLabel != null ||
                              widget.showOwnerDataChip) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (widget.careAssignedLabel != null)
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    label: Text(
                                      widget.careAssignedLabel!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: AppTheme.primaryLight,
                                    side: BorderSide(
                                      color: AppTheme.primary.withOpacity(0.25),
                                    ),
                                  ),
                                if (widget.showOwnerDataChip)
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    label: Text(
                                      s.careOwnerDataPending,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor:
                                        AppTheme.accentAmberLight.withOpacity(0.65),
                                    side: BorderSide(
                                      color: AppTheme.accentDeep.withOpacity(0.35),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          if (published) ...[
                            const SizedBox(height: 4),
                            Text(
                              statsLine,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.textSecondary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            if (published) ...[
              const SizedBox(height: 6),
              if (needsOwnerData) ...[
                Text(
                  s.careOwnerDataRequiredHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.accentDeep,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: widget.onCompleteData,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_note_outlined, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          s.careOwnerDataRequiredBeforeBump,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  s.listingExpiresBumpHint(daysLeft),
                  style: TextStyle(
                    fontSize: 12,
                    color: ListingOwnerRepository.needsBumpReminder(row)
                        ? AppTheme.accentDeep
                        : AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: canBump ? widget.onBump : null,
                  child: Text(s.confirmAvailableBump),
                ),
                if (cooldown != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.listingBumpCooldownHint(
                      cooldown.inHours,
                      cooldown.inMinutes.remainder(60),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _actionChip(
                    icon: Icons.bar_chart_outlined,
                    label: s.listingViewStats,
                    onTap: () => showListingStatsSheet(context, row: row),
                  ),
                  const SizedBox(width: 6),
                  _actionChip(
                    icon: Icons.edit_outlined,
                    label: s.listingEditAction,
                    onTap: widget.onEdit ??
                        () => AppNotice.snack(context, s.listingEditComingSoon),
                  ),
                  const SizedBox(width: 6),
                  _actionChip(
                    icon: Icons.block_outlined,
                    label: s.listingCloseShort,
                    onTap: widget.onClose,
                  ),
                ],
              ),
              Text(
                s.listingClosePickReason,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
            if (pending)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  s.listingPendingReviewHint,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            if (archived && widget.daysUntilAvailable != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmberLight.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.listingArchivedAvailableLine(
                    ListingAvailabilityReminderService.formatAvailableDate(row),
                    widget.daysUntilAvailable!,
                  ),
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
              if (widget.onAvailabilityFollowUp != null) ...[
                const SizedBox(height: 6),
                FilledButton.tonal(
                  onPressed: widget.onAvailabilityFollowUp,
                  child: Text(s.listingAvailabilityManageAction),
                ),
              ],
            ],
            if (archived)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: widget.onSoftDelete,
                  child: Text(
                    s.hideListingFromMine,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: AppTheme.textSecondary.withOpacity(0.15)),
              const SizedBox(height: 8),
              _detailLine(
                '${row['listing_code']} · '
                '${s.listingTransactionLabel(row['listing_type']?.toString())} · '
                '${_statusLabel(s, row)} · ฿${row['price_net']}',
              ),
              if (_viewingAccessLine(s, row) != null) ...[
                const SizedBox(height: 4),
                _detailLine(_viewingAccessLine(s, row)!, accent: true),
              ],
              if (needsOwnerData) ...[
                const SizedBox(height: 8),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(s.careOwnerDataPending, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppTheme.accentAmberLight,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _statsLine(AppStrings s, String listingId) {
    final activity = ListingActivityService.instance;
    final views = activity.viewCount(listingId);
    final shares = activity.shareCount(listingId);
    final chats = activity.chatCount(listingId);
    if (views == 0 && shares == 0 && chats == 0) {
      return s.listingInsightsEmpty;
    }
    return s.listingStatsOneLiner(views, shares, chats);
  }

  Widget _detailLine(String text, {bool accent = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: accent ? AppTheme.primary : AppTheme.textSecondary,
        height: 1.35,
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  String _statusLabel(AppStrings s, Map<String, dynamic> row) {
    final status = row['status']?.toString() ?? '';
    switch (status) {
      case 'published':
        return s.listingStatusPublished;
      case 'archived':
        return s.listingStatusArchived;
      case 'hidden':
        return s.listingStatusHidden;
      case 'draft':
        return s.listingStatusDraft;
      case 'pending_review':
        return s.listingStatusPendingReview;
      default:
        return status;
    }
  }

  String? _viewingAccessLine(AppStrings s, Map<String, dynamic> row) {
    final raw = row['viewing_access'];
    if (raw is! Map) return null;
    final access = ListingViewingAccess.fromJson(Map<String, dynamic>.from(raw));
    if (access.isEmpty) return null;
    return access.summary(s);
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({
    required this.row,
    required this.canPreview,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final bool canPreview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = OwnerListingMedia.coverUrl(row);
    return Semantics(
      button: true,
      label: AppStrings.of(context).listingCoverPreviewHint,
      child: Material(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url != null)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                else
                  _placeholder(),
                if (canPreview)
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.visibility_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.apartment_outlined,
        size: 22,
        color: AppTheme.primary.withOpacity(0.7),
      ),
    );
  }
}
