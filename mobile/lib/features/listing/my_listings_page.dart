import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../navigation/post_listing_navigation.dart';
import '../../models/listing_viewing_access.dart';
import '../../services/listing_owner_repository.dart';
import '../../theme/app_theme.dart';
import 'close_listing_sheet.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final _repo = ListingOwnerRepository();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _repo.myListings();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _bump(String id) async {
    final s = AppStrings.of(context);
    await _repo.bumpListing(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.confirmedAvailableBump)),
    );
    _load();
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
        availableAgain: result.availableAgain,
      );
    } else {
      final ok = await confirmCloseListingSale(context);
      if (ok != true || !mounted) return;
      await _repo.closeSale(listingId: id);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.listingClosedArchived)),
    );
    _load();
  }

  Future<void> _softDelete(String id) async {
    final s = AppStrings.of(context);
    final ok = await confirmSoftDeleteListing(context);
    if (!ok || !mounted) return;
    await _repo.softDelete(listingId: id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.listingDeletedFromView)),
    );
    _load();
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

  String? _subtitleExtra(AppStrings s, Map<String, dynamic> row) {
    final status = row['status']?.toString() ?? '';
    if (status == 'pending_review') {
      return s.listingPendingReviewHint;
    }
    if (status == 'published') {
      final daysLeft = ListingOwnerRepository.daysUntilAutoArchive(row);
      if (ListingOwnerRepository.needsBumpReminder(row)) {
        return s.listingBumpReminder(daysLeft);
      }
      return s.listingDaysUntilArchive(daysLeft);
    }
    if (status == 'archived') {
      if (row['reuse_blocked'] == true) {
        return s.listingSaleArchivedNote;
      }
      final again = row['available_again']?.toString();
      if (again != null && again.isNotEmpty) {
        return s.listingRentAvailableAgain(again);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final pending =
        _rows.where((r) => r['status']?.toString() == 'pending_review').toList();
    final published = _rows.where((r) => r['status'] == 'published').toList();
    final archived = _rows.where((r) => r['status'] == 'archived').toList();
    final other = _rows
        .where((r) {
          final st = r['status']?.toString() ?? '';
          return st != 'published' &&
              st != 'archived' &&
              st != 'pending_review';
        })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myListingsTitle),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? Center(child: Text(s.noListingsYet))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (pending.isNotEmpty) ...[
                      _sectionTitle(s.listingSectionPendingReview),
                      ...pending.map((r) => _tile(s, r, pending: true)),
                    ],
                    if (published.isNotEmpty) ...[
                      _sectionTitle(s.listingSectionActive),
                      ...published.map((r) => _tile(s, r)),
                    ],
                    if (archived.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _sectionTitle(s.listingSectionArchived),
                      ...archived.map((r) => _tile(s, r, archived: true)),
                    ],
                    if (other.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _sectionTitle(s.listingSectionOther),
                      ...other.map((r) => _tile(s, r)),
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
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => PostListingNavigation.openCreateWithAuthGate(context),
        icon: const Icon(Icons.add),
        label: Text(s.postListing),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      );

  Widget _tile(
    AppStrings s,
    Map<String, dynamic> r, {
    bool archived = false,
    bool pending = false,
  }) {
    final status = r['status']?.toString() ?? '';
    final extra = _subtitleExtra(s, r);
    final type = s.listingTransactionLabel(r['listing_type']?.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: pending ? AppTheme.accentAmberLight.withOpacity(0.35) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              r['title']?.toString() ?? '',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${r['listing_code']} · $type · ${_statusLabel(s, r)} · ฿${r['price_net']}',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            if (_viewingAccessLine(s, r) != null) ...[
              const SizedBox(height: 4),
              Text(
                _viewingAccessLine(s, r)!,
                style: TextStyle(fontSize: 12, color: AppTheme.primary, height: 1.35),
              ),
            ],
            if (extra != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: pending
                      ? AppTheme.accentAmberLight
                      : status == 'published' && ListingOwnerRepository.needsBumpReminder(r)
                          ? AppTheme.accentAmberLight
                          : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(extra, style: TextStyle(fontSize: 12, height: 1.35)),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (status == 'published') ...[
                  FilledButton.tonal(
                    onPressed: () => _bump(r['id'] as String),
                    child: Text(s.confirmAvailable),
                  ),
                  OutlinedButton(
                    onPressed: () => _closeListing(r),
                    child: Text(s.closeListingAction),
                  ),
                ],
                if (archived)
                  TextButton(
                    onPressed: () => _softDelete(r['id'] as String),
                    child: Text(
                      s.deleteListingConfirm,
                      style: TextStyle(color: AppTheme.accentDeep),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
