import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../data/admin_demo_data.dart';
import '../../l10n/app_strings.dart';
import '../../features/notifications/notification_center_sheet.dart';
import '../../models/property_care_summary.dart';
import '../../navigation/post_listing_navigation.dart';
import '../../services/auth_service.dart';
import '../../services/property_care_notification_service.dart';
import '../../services/property_care_repository.dart';
import '../../state/locale_controller.dart';
import '../../state/session_gate.dart';
import '../../state/user_role_controller.dart';
import '../../services/listing_activity_service.dart';
import '../../services/listing_availability_reminder_service.dart';
import '../../services/listing_owner_repository.dart';
import '../../services/notification_center_repository.dart';
import 'listing_availability_follow_up_sheet.dart';
import 'property_care_owner_data_sheet.dart';
import '../../utils/app_notice.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../widgets/listing_insights_strip.dart';
import 'close_listing_sheet.dart';
import '../../theme/li_layout.dart';
import '../../utils/page_safe_insets.dart';
import '../../shell/main_shell_scope.dart';
import '../../widgets/consumer/consumer_page_shell.dart';
import '../../widgets/notification_bell_button.dart';
import '../../widgets/owner_listing_tile.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({
    super.key,
    this.isShellTab = false,
    this.roleController,
    this.localeController,
  });

  final bool isShellTab;
  final UserRoleController? roleController;
  final LocaleController? localeController;

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final _repo = ListingOwnerRepository();
  final _careRepo = PropertyCareRepository.instance;
  List<Map<String, dynamic>> _rows = [];
  List<PropertyCareSummary> _carePending = [];
  List<PropertyCareSummary> _careActive = [];
  List<Map<String, dynamic>> _carePublished = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ListingActivityService.instance.load();
    AuthService.instance.addListener(_onAuthChanged);
    _careRepo.addListener(_onAuthChanged);
    _load();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    _careRepo.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => _load();

  Future<void> _enterOwnerTrial() async {
    final s = AppStrings.of(context);
    if (!Env.allowPasswordlessLogin) {
      context.push('/login');
      return;
    }
    try {
      await AuthService.instance.signInAsTrial(role: 'owner');
      widget.roleController?.setRole('owner');
      await PropertyCareRepository.ensureDemoForTrialOwner();
      await PropertyCareNotificationService.instance.init();
      await SessionGate.instance?.markAuthenticated();
      if (!mounted) return;
      AppNotice.snack(context, s.trialEntered);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppNotice.error(context, AuthService.friendlyMessage(e));
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _repo.myListings();
    final carePending = <PropertyCareSummary>[];
    final careActive = <PropertyCareSummary>[];
    final carePublished = <Map<String, dynamic>>[];

    if (AuthService.instance.isSignedIn) {
      await PropertyCareRepository.ensureDemoForTrialOwner();
      final summaries = await _careRepo.summariesForCurrentUser();
      carePending.addAll(summaries.where((s) => s.needsClaim));
      for (final item in summaries.where((s) => !s.needsClaim)) {
        careActive.add(item);
        final listingRows = await _careRepo.listingsForSummary(item);
        for (final r in listingRows) {
          carePublished.add({
            ...r,
            '_care': true,
            '_care_inventory_code': item.inventoryCode,
            '_care_inv_id': item.right.inventoryId,
          });
        }
      }
    }

    if (!mounted) return;
    await ListingAvailabilityReminderService.instance.scanOwnerListings(rows);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _carePending = carePending;
      _careActive = careActive;
      _carePublished = carePublished;
      _loading = false;
    });
    if (mounted && AuthService.instance.isSignedIn) {
      final isEnglish = AppStrings.of(context).isEnglish;
      await PropertyCareNotificationService.instance.sync(isEnglish: isEnglish);
    }
  }

  Future<void> _acceptCare(PropertyCareSummary item) async {
    try {
      await _careRepo.acceptClaim(item.right.id);
      if (!mounted) return;
      AppNotice.snack(context, context.s.careAcceptDone);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppNotice.error(context, '$e');
    }
  }

  Future<void> _refreshOwnerNotifications() async {
    if (widget.roleController == null || widget.localeController == null) return;
    await NotificationCenterRepository.instance.refresh(
      role: widget.roleController!,
      isEnglish: widget.localeController!.isEnglish,
    );
    await PropertyCareNotificationService.instance.sync(
      isEnglish: widget.localeController!.isEnglish,
    );
  }

  String? _careInventoryId(Map<String, dynamic> row) {
    final direct = row['_care_inv_id']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    return AdminDemoData.inventoryIdForCode(
      row['_care_inventory_code']?.toString(),
    );
  }

  Future<void> _completeCareData(Map<String, dynamic> row) async {
    final s = AppStrings.of(context);
    final invId = _careInventoryId(row);
    if (invId == null) {
      AppNotice.error(context, s.careOwnerDataInventoryMissing);
      return;
    }
    final code = row['listing_code']?.toString() ?? '';
    final result = await showPropertyCareOwnerDataSheet(
      context,
      row: row,
      inventoryId: invId,
      inventoryCode: row['_care_inventory_code']?.toString(),
      isEdit: !_rowNeedsOwnerData(row),
    );
    if (result?.saved != true || !mounted) return;
    AppNotice.snack(
      context,
      result!.titleSentForReview
          ? s.careOwnerDataTitleReviewSaved
          : s.careCompleteListingDone(code),
    );
    await _refreshOwnerNotifications();
    await _load();
  }

  Future<void> _bump(Map<String, dynamic> row) async {
    final s = AppStrings.of(context);
    if (_rowNeedsOwnerData(row)) {
      await _completeCareData(_rowWithCareContext(row));
      return;
    }
    if (!ListingOwnerRepository.canBumpNow(row)) {
      final left = ListingOwnerRepository.bumpCooldownRemaining(row)!;
      AppNotice.error(
        context,
        s.listingBumpCooldownHint(left.inHours, left.inMinutes.remainder(60)),
      );
      return;
    }
    final ok = await _repo.bumpListing(
      row['id'] as String,
      listingCode: row['listing_code']?.toString(),
    );
    if (!mounted) return;
    if (!ok) {
      AppNotice.error(context, s.listingBumpFailed);
      return;
    }
    AppNotice.snack(context, s.confirmedAvailableBump);
    await _refreshOwnerNotifications();
    await _load();
  }

  Future<void> _closeListing(Map<String, dynamic> row) async {
    final s = AppStrings.of(context);
    final type = row['listing_type']?.toString() ?? 'sale';
    final id = row['id'] as String;

    if (type == 'rent') {
      final result = await showCloseListingRentSheet(context);
      if (result == null || !mounted) return;
      await _repo.closeRent(
        listingId: id,
        permanent: result.permanent,
        availableAgain: result.availableAgain,
        permanentReason: result.permanentReason,
      );
    } else {
      final result =
          await showCloseListingRentSheet(context, listingType: 'sale');
      if (result == null || !mounted) return;
      await _repo.closeSale(
        listingId: id,
        permanentReason: result.permanentReason,
      );
    }

    if (!mounted) return;
    AppNotice.snack(context, s.listingClosedArchived);
    _load();
  }

  Future<void> _availabilityFollowUp(Map<String, dynamic> row) async {
    final s = AppStrings.of(context);
    final days = ListingAvailabilityReminderService.instance.daysUntilAvailable(row);
    final raw = row['available_again']?.toString();
    final again = raw == null ? null : DateTime.tryParse(raw);
    if (days == null || again == null) return;

    final result = await showListingAvailabilityFollowUpSheet(
      context,
      listingTitle: row['title']?.toString() ?? row['listing_code']?.toString() ?? '',
      availableAgain: again,
      daysUntil: days,
    );
    if (result == null || !mounted) return;

    final id = row['id'] as String;
    switch (result.action) {
      case ListingAvailabilityFollowUpAction.republishEarly:
        final ok = await _repo.republishRentEarly(listingId: id);
        if (!mounted) return;
        if (!ok) {
          AppNotice.error(context, s.listingBumpFailed);
          return;
        }
        AppNotice.snack(context, s.listingRepublishedEarly);
      case ListingAvailabilityFollowUpAction.remindLater:
        await ListingAvailabilityReminderService.instance.snoozeTo15Days(id);
        if (!mounted) return;
        AppNotice.snack(context, s.listingAvailabilityRemindScheduled);
      case ListingAvailabilityFollowUpAction.updateDate:
        if (result.newDate == null) return;
        await _repo.updateAvailableAgain(listingId: id, date: result.newDate!);
        if (!mounted) return;
        AppNotice.snack(context, s.listingAvailabilityDateUpdated);
      case ListingAvailabilityFollowUpAction.permanentClose:
        final pr = result.permanentResult;
        if (pr == null || !pr.permanent) return;
        await _repo.closeRent(
          listingId: id,
          permanent: true,
          permanentReason: pr.permanentReason,
        );
        if (!mounted) return;
        AppNotice.snack(context, s.listingClosedArchived);
    }
    await _load();
  }

  Future<void> _softDelete(String id) async {
    final s = AppStrings.of(context);
    final ok = await confirmSoftDeleteListing(context);
    if (!ok || !mounted) return;
    await _repo.softDelete(listingId: id);
    if (!mounted) return;
    AppNotice.snack(context, s.listingDeletedFromView);
    _load();
  }

  List<Map<String, dynamic>> _mergedPublished() {
    final careCodes = _carePublished
        .map((r) => r['listing_code']?.toString())
        .whereType<String>()
        .toSet();
    final pendingClaimCodes = _carePending
        .map((s) => s.primaryListingCode)
        .whereType<String>()
        .toSet();
    final owned = _rows
        .where(
          (r) {
            final code = r['listing_code']?.toString();
            return r['status']?.toString() == 'published' &&
                code != null &&
                !careCodes.contains(code) &&
                !pendingClaimCodes.contains(code);
          },
        )
        .toList();
    return [..._carePublished, ...owned];
  }

  bool _rowNeedsOwnerData(Map<String, dynamic> r) {
    if (r['owner_data_status']?.toString() == 'complete') return false;
    if (r['owner_data_complete'] == true) return false;
    if (r['owner_data_pending'] == true) return true;
    final code = r['listing_code']?.toString();
    if (code == null || code.isEmpty) return false;
    for (final item in _careActive) {
      if (item.pendingDataCount <= 0) continue;
      if (item.primaryListingCode == code) return true;
    }
    return false;
  }

  Map<String, dynamic> _rowWithCareContext(Map<String, dynamic> r) {
    if (r['_care_inv_id'] != null) return r;
    final code = r['listing_code']?.toString();
    if (code == null) return r;
    for (final item in _careActive) {
      if (item.pendingDataCount <= 0) continue;
      if (item.primaryListingCode != code) continue;
      return {
        ...r,
        '_care': true,
        '_care_inv_id': item.right.inventoryId,
        '_care_inventory_code': item.inventoryCode,
        'owner_data_pending': true,
      };
    }
    return r;
  }

  bool get _hasAnyContent =>
      _rows.isNotEmpty || _carePending.isNotEmpty || _carePublished.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final pending =
        _rows.where((r) => r['status']?.toString() == 'pending_review').toList();
    final published = _mergedPublished();
    final archived = _rows.where((r) => r['status'] == 'archived').toList();
    final other = _rows
        .where((r) {
          final st = r['status']?.toString() ?? '';
          return st != 'published' &&
              st != 'archived' &&
              st != 'pending_review';
        })
        .toList();

    final isTab = widget.isShellTab;
    final allListingIds = [
      ...published.map((r) => r['id']?.toString()).whereType<String>(),
      ...pending.map((r) => r['id']?.toString()).whereType<String>(),
    ];

    return ConsumerPageShell(
      title: isTab ? s.homeQuickManageTitle : s.myListingsTitle,
      onBack: isTab
          ? () => MainShellScope.maybeOf(context)?.selectTab(0)
          : () => context.pop(),
      safeBottomBody: !isTab,
      actions: [
        if (isTab &&
            widget.roleController != null &&
            widget.localeController != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: NotificationBellButton(
              compact: true,
              onPurple: true,
              onPressed: () => NotificationCenterSheet.show(
                context,
                roleController: widget.roleController!,
                localeController: widget.localeController!,
              ),
            ),
          ),
        ConsumerHeaderIconButton(
          icon: Icons.refresh_rounded,
          onTap: _load,
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: PageSafeInsets.padLTRB(
                context,
                left: LiLayout.pagePadding,
                top: LiLayout.pagePadding,
                right: LiLayout.pagePadding,
                bottom: 16,
                addHomeIndicator: false,
              ),
              children: [
                if (isTab) ...[
                  if (!AuthService.instance.isSignedIn)
                    _MineTabSignInCard(
                      onOwnerTrial: _enterOwnerTrial,
                      onLogin: () => context.push('/login'),
                    ),
                  const SizedBox(height: 12),
                  _CreateFreeListingHero(
                    title: s.createListingFree,
                    subtitle: s.homeQuickOwnerBody,
                    onTap: () =>
                        PostListingNavigation.openCreateWithAuthGate(context),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!_hasAnyContent && AuthService.instance.isSignedIn)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        isTab ? s.myListingsHubEmpty : s.noListingsYet,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else if (_hasAnyContent) ...[
                  if (published.isNotEmpty)
                    ListingPortfolioSummary(
                      listingIds: allListingIds,
                      publishedCount: published.length,
                    ),
                  if (published.isNotEmpty) const SizedBox(height: 12),
                  if (published.isNotEmpty || _carePending.isNotEmpty) ...[
                    _sectionTitle(s.listingSectionActive),
                    ..._indexedActiveTiles(s, published),
                  ],
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _sectionTitle(s.listingSectionPendingReview),
                    ...pending.asMap().entries.map(
                          (e) => _tile(s, e.value, index: e.key + 1),
                        ),
                  ],
                  if (archived.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _sectionTitle(s.listingSectionArchived),
                    ...archived.asMap().entries.map(
                          (e) => _tile(s, e.value, archived: true, index: e.key + 1),
                        ),
                  ],
                  if (other.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _sectionTitle(s.listingSectionOther),
                    ...other.asMap().entries.map(
                          (e) => _tile(s, e.value, index: e.key + 1),
                        ),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      s.listingLifecyclePolicy,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ],
            ),
      floatingActionButton: isTab
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  PostListingNavigation.openCreateWithAuthGate(context),
              icon: const Icon(Icons.add),
              label: Text(s.postListing),
            ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      );

  List<Widget> _indexedActiveTiles(
    AppStrings s,
    List<Map<String, dynamic>> published,
  ) {
    final tiles = <Widget>[];
    var index = 0;
    for (final item in _carePending) {
      index++;
      tiles.add(
        _CareClaimTile(
          index: index,
          item: item,
          onAccept: () => _acceptCare(item),
        ),
      );
    }
    for (final r in published) {
      index++;
      tiles.add(_tile(s, r, index: index));
    }
    return tiles;
  }

  Widget _tile(
    AppStrings s,
    Map<String, dynamic> r, {
    bool archived = false,
    int? index,
  }) {
    final enriched = _rowWithCareContext(r);
    final isCare = enriched['_care'] == true;
    final needsOwnerData = _rowNeedsOwnerData(enriched);
    final daysUntil =
        archived ? ListingAvailabilityReminderService.instance.daysUntilAvailable(r) : null;
    final hasAvailDate = daysUntil != null && daysUntil > 0;
    return OwnerListingTile(
      key: ValueKey(
        '${enriched['id']}-${enriched['last_bump_at']}-${enriched['owner_data_pending']}-$needsOwnerData',
      ),
      row: enriched,
      index: index,
      careAssignedLabel: isCare ? s.careAssignedListingTag : null,
      showOwnerDataChip: needsOwnerData,
      onCompleteData: needsOwnerData
          ? () => _completeCareData(enriched)
          : null,
      onEdit: isCare ? () => _completeCareData(enriched) : null,
      daysUntilAvailable: hasAvailDate ? daysUntil : null,
      onAvailabilityFollowUp:
          hasAvailDate ? () => _availabilityFollowUp(r) : null,
      onBump: () => _bump(r),
      onClose: () => _closeListing(r),
      onSoftDelete: () => _softDelete(r['id'] as String),
    );
  }
}

/// รอรับสิทธิ์ — อยู่ในรายการประกาศปกติ ไม่มีหมวดแยก
class _CareClaimTile extends StatelessWidget {
  const _CareClaimTile({
    required this.index,
    required this.item,
    required this.onAccept,
  });

  final int index;
  final PropertyCareSummary item;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final code = item.inventoryCode ?? 'RXT';
    final coverSeed = Uri.encodeComponent(code);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, right: 4),
                  child: Text(
                    '$index.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://picsum.photos/seed/$coverSeed/240/180',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: AppTheme.primaryLight,
                      child: Icon(Icons.apartment_outlined, color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.canonicalTitle ?? code,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                s.careAssignedListingTag,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.primaryLight,
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(s.careAcceptButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _MineTabSignInCard extends StatelessWidget {
  const _MineTabSignInCard({
    required this.onOwnerTrial,
    required this.onLogin,
  });

  final VoidCallback onOwnerTrial;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Card(
      elevation: 0,
      color: AppTheme.primaryLight.withOpacity(0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.home_work_outlined, color: AppTheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.mineTabSignInTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.mineTabSignInBody,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onOwnerTrial,
              style: FilledButton.styleFrom(
                backgroundColor: LivingBkkBrand.piterOrange,
              ),
              child: Text(s.mineTabOwnerTrialButton),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onLogin,
              child: Text(s.mineTabGoLoginButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateFreeListingHero extends StatelessWidget {
  const _CreateFreeListingHero({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LivingBkkBrand.ctaGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: LivingBkkBrand.piterOrange.withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_home_work_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
