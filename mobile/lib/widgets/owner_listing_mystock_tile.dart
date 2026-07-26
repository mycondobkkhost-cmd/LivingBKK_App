import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../features/listing/listing_stats_sheet.dart';
import '../l10n/app_strings.dart';
import '../services/listing_activity_service.dart';
import '../services/listing_availability_reminder_service.dart';
import '../services/listing_owner_repository.dart';
import '../theme/app_theme.dart';
import '../theme/living_bkk_brand.dart';
import '../utils/app_notice.dart';
import '../utils/owner_listing_media.dart';

/// การ์ดประกาศเจ้าของแบบ MyStock — กะทัดรัด (~20% ต่ำกว่าเลย์เอาต์เต็ม) · ธีม RealXtate
class OwnerListingMystockTile extends StatefulWidget {
  const OwnerListingMystockTile({
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
    this.compact = false,
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
  /// รอตรวจ / แบบร่าง — ไม่มี hero รูปใหญ่
  final bool compact;

  @override
  State<OwnerListingMystockTile> createState() => _OwnerListingMystockTileState();
}

class _OwnerListingMystockTileState extends State<OwnerListingMystockTile> {
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _armCooldownTimer();
  }

  @override
  void didUpdateWidget(OwnerListingMystockTile oldWidget) {
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
    final id = widget.row['id']?.toString();
    if (id == null || id.isEmpty) return;
    if (!OwnerListingMedia.canPreviewOnline(widget.row)) {
      AppNotice.snack(context, s.listingPreviewNotOnline);
      return;
    }
    context.push('/listing/$id');
  }

  void _openManageSheet(BuildContext context) {
    final s = AppStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text(s.listingPreviewOnline),
              onTap: () {
                Navigator.pop(ctx);
                _openPreview(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: Text(s.listingViewStats),
              onTap: () {
                Navigator.pop(ctx);
                showListingStatsSheet(context, row: widget.row);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(s.listingEditAction),
              onTap: () {
                Navigator.pop(ctx);
                if (widget.onEdit != null) {
                  widget.onEdit!();
                } else {
                  AppNotice.snack(context, s.listingEditComingSoon);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.block_outlined, color: AppTheme.textSecondary),
              title: Text(s.listingCloseShort),
              onTap: () {
                Navigator.pop(ctx);
                widget.onClose();
              },
            ),
          ],
        ),
      ),
    );
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
    final canPreview = OwnerListingMedia.canPreviewOnline(row);
    final currency = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    final price = row['price_net'];
    final priceText = price is num ? currency.format(price) : '—';
    final listingType = row['listing_type']?.toString() ?? 'rent';
    final perMonth = listingType == 'rent' || listingType == 'rent_and_sale';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.14)),
      ),
      color: pending ? AppTheme.accentAmberLight.withOpacity(0.2) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (published && !widget.compact) _HeroCover(row: row, onTap: () => _openPreview(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.compact || !published) ...[
                      _MiniCover(
                        row: row,
                        canPreview: canPreview,
                        onTap: () => _openPreview(context),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _TypeBadge(
                                label: _propertyTypeLabel(s, row['property_type']?.toString()),
                                filled: true,
                              ),
                              const SizedBox(width: 4),
                              _TypeBadge(
                                label: s.listingTransactionLabel(listingType),
                                filled: false,
                              ),
                              const Spacer(),
                              _StatIcons(listingId: row['id']?.toString() ?? ''),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            row['title']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.25,
                            ),
                          ),
                          if (row['project_name'] != null &&
                              row['project_name'].toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: LivingBkkBrand.propPurple.withOpacity(0.75),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    row['project_name'].toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (published || pending) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$priceText${perMonth ? s.perMonth : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              _specsLine(s, row),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                          if (widget.careAssignedLabel != null ||
                              widget.showOwnerDataChip) ...[
                            const SizedBox(height: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (widget.careAssignedLabel != null)
                                  _StatusChip(
                                    widget.careAssignedLabel!,
                                    color: AppTheme.primaryLight,
                                    fullWidth: true,
                                  ),
                                if (widget.showOwnerDataChip) ...[
                                  if (widget.careAssignedLabel != null)
                                    const SizedBox(height: 4),
                                  _StatusChip(
                                    s.careOwnerDataPending,
                                    color: AppTheme.accentAmberLight,
                                    fullWidth: true,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (published) ...[
                  const SizedBox(height: 6),
                  if (needsOwnerData)
                    SizedBox(
                      height: 42,
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: LivingBkkBrand.accentYellow,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: widget.onCompleteData,
                        child: Text(
                          s.careOwnerDataRequiredBeforeBump,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: LivingBkkBrand.accentYellow,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  else
                    _ActionRow(
                      manageLabel: s.myListingsManageAction,
                      bumpLabel: s.myListingsBumpFreeAction,
                      onManage: () => _openManageSheet(context),
                      onBump: canBump ? widget.onBump : null,
                    ),
                ],
                if (pending)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s.listingPendingReviewHint,
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ),
                if (archived && widget.daysUntilAvailable != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    s.listingArchivedAvailableLine(
                      ListingAvailabilityReminderService.formatAvailableDate(row),
                      widget.daysUntilAvailable!,
                    ),
                    style: const TextStyle(fontSize: 11, height: 1.3),
                  ),
                  if (widget.onAvailabilityFollowUp != null) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 34,
                      child: FilledButton.tonal(
                        onPressed: widget.onAvailabilityFollowUp,
                        child: Text(
                          s.listingAvailabilityManageAction,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ],
                if (archived)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: widget.onSoftDelete,
                      child: Text(
                        s.hideListingFromMine,
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _propertyTypeLabel(AppStrings s, String? type) {
    if (type == 'townhome') return s.propertyTypeChip('townhouse');
    return s.propertyTypeChip(type ?? '');
  }

  String _specsLine(AppStrings s, Map<String, dynamic> row) {
    final parts = <String>[];
    final area = row['area_sqm'];
    if (area is num && area > 0) {
      parts.add('${area.toInt()} ${s.isEnglish ? 'sqm' : 'ตร.ม.'}');
    }
    final beds = row['bedrooms'];
    if (beds is num) {
      parts.add(beds == 0
          ? s.filterStudio
          : '${beds.toInt()} ${s.isEnglish ? 'bed' : 'นอน'}');
    }
    final baths = row['bathrooms'];
    if (baths is num && baths > 0) {
      parts.add('${baths.toInt()} ${s.isEnglish ? 'bath' : 'น้ำ'}');
    }
    if (parts.isEmpty) return row['listing_code']?.toString() ?? '';
    return parts.join(' · ');
  }
}

class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.row, required this.onTap});

  final Map<String, dynamic> row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final url = OwnerListingMedia.coverUrl(row);
    final daysLeft = ListingOwnerRepository.daysUntilAutoArchive(row);
    final expiresRaw = row['expires_at']?.toString();
    final expires = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

    return AspectRatio(
      aspectRatio: 2.35,
      child: Material(
        color: AppTheme.primaryLight,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url != null)
                Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
              else
                _ph(),
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.62),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    expires != null
                        ? s.myListingsExpiresBadge(daysLeft, _fmtDate(expires, s.isEnglish))
                        : s.listingDaysUntilArchive(daysLeft),
                    style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.2),
                  ),
                ),
              ),
              if (ListingOwnerRepository.needsBumpReminder(row))
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: LivingBkkBrand.piterOrange.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.rocket_launch_outlined, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          s.myListingsBumpSoonHint,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ph() => Center(
        child: Icon(Icons.apartment_outlined, size: 28, color: AppTheme.primary.withOpacity(0.5)),
      );

  String _fmtDate(DateTime dt, bool en) {
    final local = dt.toLocal();
    if (en) return DateFormat('d MMM yyyy').format(local);
    return '${local.day} ${_thMonth(local.month)} ${local.year + 543}';
  }

  String _thMonth(int m) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    return months[m - 1];
  }
}

class _MiniCover extends StatelessWidget {
  const _MiniCover({
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
    return Material(
      color: AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: url != null
              ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
              : _ph(),
        ),
      ),
    );
  }

  Widget _ph() => Icon(Icons.apartment_outlined, size: 20, color: AppTheme.primary.withOpacity(0.6));
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? AppTheme.primary : AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : AppTheme.primary,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(
    this.label, {
    required this.color,
    this.fullWidth = false,
  });

  final String label;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: fullWidth ? 10 : 6,
        vertical: fullWidth ? 6 : 2,
      ),
      alignment: fullWidth ? Alignment.center : null,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(fullWidth ? 6 : 4),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Text(
        label,
        textAlign: fullWidth ? TextAlign.center : null,
        style: TextStyle(
          fontSize: fullWidth ? 11 : 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatIcons extends StatelessWidget {
  const _StatIcons({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final activity = ListingActivityService.instance;
    final views = activity.viewCount(listingId);
    final chats = activity.chatCount(listingId);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconStat(Icons.visibility_outlined, views),
        const SizedBox(width: 6),
        _iconStat(Icons.auto_awesome_outlined, chats),
      ],
    );
  }

  Widget _iconStat(IconData icon, int n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 2),
        Text(
          '$n',
          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.manageLabel,
    required this.bumpLabel,
    required this.onManage,
    required this.onBump,
  });

  final String manageLabel;
  final String bumpLabel;
  final VoidCallback onManage;
  final VoidCallback? onBump;

  static const _btnHeight = 42.0;

  @override
  Widget build(BuildContext context) {
    final orange = LivingBkkBrand.piterOrange;
    return Row(
      children: [
        Expanded(
          child: _OutlineBtn(
            label: manageLabel,
            icon: Icons.settings_outlined,
            onTap: onManage,
            color: orange,
            height: _btnHeight,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, _btnHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onBump,
            child: Text(
              bumpLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.label,
    required this.onTap,
    required this.color,
    this.icon,
    this.height = 42,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.55)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size(0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onTap,
      child: icon != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}
