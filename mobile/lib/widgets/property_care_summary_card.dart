import 'package:flutter/material.dart';

import '../config/code_glossary.dart';
import '../features/listing/close_listing_sheet.dart';
import '../features/listing/property_care_owner_data_sheet.dart';
import '../l10n/app_strings.dart';
import '../models/property_care_summary.dart';
import '../services/listing_owner_repository.dart';
import '../services/property_care_repository.dart';
import '../theme/app_theme.dart';
import '../theme/living_bkk_brand.dart';
import '../utils/app_notice.dart';
import 'owner_listing_tile.dart';

class PropertyCareSummaryCard extends StatefulWidget {
  const PropertyCareSummaryCard({
    super.key,
    required this.item,
    required this.onAccept,
    required this.onComplete,
    required this.onRefresh,
  });

  final PropertyCareSummary item;
  final VoidCallback onAccept;
  final VoidCallback onComplete;
  final Future<void> Function() onRefresh;

  @override
  State<PropertyCareSummaryCard> createState() => _PropertyCareSummaryCardState();
}

class _PropertyCareSummaryCardState extends State<PropertyCareSummaryCard> {
  final _ownerRepo = ListingOwnerRepository();
  final _careRepo = PropertyCareRepository.instance;
  List<Map<String, dynamic>> _listings = [];
  bool _loadingListings = false;

  @override
  void initState() {
    super.initState();
    if (!widget.item.needsClaim) _loadListings();
  }

  @override
  void didUpdateWidget(PropertyCareSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.needsClaim && !widget.item.needsClaim) {
      _loadListings();
    } else if (!widget.item.needsClaim &&
        (oldWidget.item.right.status != widget.item.right.status ||
            oldWidget.item.pendingDataCount != widget.item.pendingDataCount)) {
      _loadListings();
    }
  }

  Future<void> _loadListings() async {
    setState(() => _loadingListings = true);
    final rows = await _careRepo.listingsForSummary(widget.item);
    if (!mounted) return;
    setState(() {
      _listings = rows;
      _loadingListings = false;
    });
  }

  Future<void> _bump(Map<String, dynamic> row) async {
    final s = AppStrings.of(context);
    if (!ListingOwnerRepository.canBumpNow(row)) {
      final left = ListingOwnerRepository.bumpCooldownRemaining(row)!;
      AppNotice.error(
        context,
        s.listingBumpCooldownHint(left.inHours, left.inMinutes.remainder(60)),
      );
      return;
    }
    final ok = await _ownerRepo.bumpListing(
      row['id'] as String,
      listingCode: row['listing_code']?.toString(),
    );
    if (!mounted) return;
    if (!ok) {
      AppNotice.error(context, s.listingBumpFailed);
      return;
    }
    AppNotice.snack(context, s.confirmedAvailableBump);
    await _loadListings();
    await widget.onRefresh();
  }

  Future<void> _close(Map<String, dynamic> row) async {
    final s = AppStrings.of(context);
    final type = row['listing_type']?.toString() ?? 'sale';
    final id = row['id'] as String;

    if (type == 'rent') {
      final result = await showCloseListingRentSheet(context);
      if (result == null || !mounted) return;
      await _ownerRepo.closeRent(
        listingId: id,
        permanent: result.permanent,
        availableAgain: result.availableAgain,
        permanentReason: result.permanentReason,
      );
    } else {
      final ok = await confirmCloseListingSale(context);
      if (ok != true || !mounted) return;
      await _ownerRepo.closeSale(listingId: id);
    }

    if (!mounted) return;
    AppNotice.show(context, s.listingClosedArchived);
    await _loadListings();
    await widget.onRefresh();
  }

  Future<void> _softDelete(String id) async {
    final s = AppStrings.of(context);
    final ok = await confirmSoftDeleteListing(context);
    if (!ok || !mounted) return;
    await _ownerRepo.softDelete(listingId: id);
    if (!mounted) return;
    AppNotice.show(context, s.listingDeletedFromView);
    await _loadListings();
    await widget.onRefresh();
  }

  Future<void> _completeListingData(
    Map<String, dynamic> row, {
    bool isEdit = false,
  }) async {
    final invId = widget.item.right.inventoryId;
    if (invId == null) return;
    final result = await showPropertyCareOwnerDataSheet(
      context,
      row: row,
      inventoryId: invId,
      inventoryCode: widget.item.inventoryCode,
      isEdit: isEdit,
    );
    if (result?.saved != true || !mounted) return;
    await _loadListings();
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final item = widget.item;
    final code = item.inventoryCode ?? 'RXT';
    final role = CodeGlossary.careRoleLabel(item.right.careRole, isEn: s.isEnglish);
    final status = CodeGlossary.careStatusLabel(item.right.status, isEn: s.isEnglish);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              CodeGlossary.captionFor(code, isEn: s.isEnglish),
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            if (item.canonicalTitle != null && item.canonicalTitle!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.canonicalTitle!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (item.district != null) ...[
              const SizedBox(height: 4),
              Text(
                item.district!,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip(role),
                _chip(status),
                if (item.needsOwnerData)
                  _chip(s.careOwnerDataPending, color: LivingBkkBrand.peach),
              ],
            ),
            const SizedBox(height: 12),
            if (item.needsClaim)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onAccept,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(s.careAcceptButton),
                ),
              )
            else if (!item.needsClaim) ...[
              if (item.needsOwnerData) ...[
                const SizedBox(height: 8),
                Text(
                  s.careMineDataHint(item.pendingDataCount),
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
              const SizedBox(height: 10),
                if (_loadingListings)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (_listings.isEmpty)
                  Text(
                    s.careManageListingsEmpty,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  )
                else
                  for (final row in _listings)
                    OwnerListingTile(
                      key: ValueKey(
                        '${row['id']}-${row['last_bump_at']}-${row['owner_data_pending']}',
                      ),
                      row: row,
                      showOwnerDataChip: row['owner_data_pending'] == true,
                      onBump: () => _bump(row),
                      onClose: () => _close(row),
                      onSoftDelete: () => _softDelete(row['id'] as String),
                      onCompleteData: row['owner_data_pending'] == true
                          ? () => _completeListingData(row)
                          : null,
                      onEdit: () => _completeListingData(
                            row,
                            isEdit: row['owner_data_pending'] != true,
                          ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryLight).withOpacity(0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
