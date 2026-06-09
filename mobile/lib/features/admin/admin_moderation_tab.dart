import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/admin_repository.dart';
import 'admin_listing_public_preview_sheet.dart';
import '../../services/auth_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';

class AdminModerationTab extends StatefulWidget {
  const AdminModerationTab({super.key});

  @override
  State<AdminModerationTab> createState() => _AdminModerationTabState();
}

class _AdminModerationTabState extends State<AdminModerationTab> {
  final _admin = AdminRepository();
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _flags = [];
  List<Map<String, dynamic>> _pendingListings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final images = await _admin.pendingListingImages();
    final flags = await _admin.openModerationFlags();
    final pending = await _admin.pendingReviewListings();
    if (!mounted) return;
    setState(() {
      _images = images;
      _flags = flags;
      _pendingListings = pending;
      _loading = false;
    });
  }

  Future<void> _runLifecycle() async {
    final result = await _admin.runLifecycleCron();
    if (!mounted) return;
    final s = context.s;
    final summary = result == null
        ? '—'
        : 'expired=${result['expired'] ?? 0}, hidden=${result['hidden_stale'] ?? result['hidden'] ?? 0}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminLifecycleResult(summary))),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: Text(s.adminLifecycleTitle, style: AdminTheme.title),
              subtitle: Text(s.adminLifecycleSubtitle, style: AdminTheme.hint),
              trailing: FilledButton(
                onPressed: _runLifecycle,
                child: Text(s.adminRunNow),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${s.adminListingsPendingReview} (${_pendingListings.length})',
            style: AdminTheme.title.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (_pendingListings.isEmpty)
            AdminHint(s.adminNoPendingListings)
          else
            ..._pendingListings.map(_pendingListingCard),
          const SizedBox(height: 16),
          Text(
            s.adminPhotosPending(_images.length),
            style: AdminTheme.title.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (_images.isEmpty)
            AdminHint(s.adminNoPhotosPending)
          else
            ..._images.map(_imageCard),
          const SizedBox(height: 16),
          Text(
            s.adminFlagsSection(_flags.length),
            style: AdminTheme.title.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (_flags.isEmpty)
            AdminHint(s.adminNoFlags)
          else
            ..._flags.map(_flagCard),
        ],
      ),
    );
  }

  Widget _imageCard(Map<String, dynamic> row) {
    final s = context.s;
    final listing = row['listings'] as Map<String, dynamic>?;
    final code = listing?['listing_code'] ?? row['listing_id'];
    return Card(
      child: ListTile(
        leading: row['public_url'] != null
            ? Image.network(
                row['public_url'].toString(),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image),
              )
            : const Icon(Icons.image_not_supported),
        title: Text(listing?['title']?.toString() ?? s.adminDefaultProperty),
        subtitle: Text('$code · ${row['perceptual_hash'] ?? ''}'),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                await _admin.setImageModeration(row['id'] as String, approved: true);
                _load();
              },
            ),
            IconButton(
              icon: Icon(Icons.close, color: AppTheme.error),
              onPressed: () async {
                await _admin.setImageModeration(row['id'] as String, approved: false);
                _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingListingCard(Map<String, dynamic> row) {
    final s = context.s;
    final id = row['id'] as String;
    final code = row['listing_code']?.toString() ?? id;
    final type = s.listingTransactionLabel(row['listing_type']?.toString());
    return Card(
      color: const Color(0xFFFFF7ED),
      child: ListTile(
        title: Text(row['title']?.toString() ?? s.adminDefaultProperty),
        subtitle: Text(
          '$code · $type · ${row['district'] ?? ''}\n'
          '${row['project_name'] ?? s.createListingNoProject}',
          maxLines: 3,
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: s.adminListingPreview,
              onPressed: () => showAdminListingPublicPreview(
                context: context,
                listingId: id,
              ),
            ),
            PopupMenuButton<String>(
          onSelected: (v) async {
            final trial = AuthService.instance.trialSimulatesBackend;
            var ok = false;
            if (v == 'approve') {
              ok = await _admin.approveListingForPublish(id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? (trial
                            ? s.adminTrialListingApproved
                            : s.adminPublishedWithWatermark)
                        : s.adminTrialListingActionFailed,
                  ),
                ),
              );
            } else if (v == 'reject') {
              ok = await _admin.rejectListingToDraft(id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? (trial ? s.adminTrialListingRejected : s.adminRejectListing)
                        : s.adminTrialListingActionFailed,
                  ),
                ),
              );
            }
            _load();
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'approve', child: Text(s.adminApproveListing)),
            PopupMenuItem(value: 'reject', child: Text(s.adminRejectListing)),
          ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _flagCard(Map<String, dynamic> row) {
    final s = context.s;
    final listing = row['listings'] as Map<String, dynamic>?;
    return Card(
      child: ListTile(
        title: Text('${row['flag_type']} · ${listing?['listing_code'] ?? ''}'),
        subtitle: Text(row['raw_match']?.toString() ?? ''),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'resolve') {
              await _admin.resolveModerationFlag(row['id'] as String);
            } else if (v == 'hide' && row['listing_id'] != null) {
              await _admin.forceHideListing(row['listing_id'] as String);
              await _admin.resolveModerationFlag(row['id'] as String);
            }
            _load();
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'resolve', child: Text(s.adminResolveFlag)),
            PopupMenuItem(value: 'hide', child: Text(s.adminHideListing)),
          ],
        ),
      ),
    );
  }
}
