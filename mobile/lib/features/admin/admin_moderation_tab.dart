import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/admin_repository.dart';
import 'admin_listing_public_preview_sheet.dart';
import '../../services/auth_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import 'admin_enterprise_page.dart';

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

    final pendingTotal =
        _pendingListings.length + _images.length + _flags.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: adminEnterprisePagePadding(context),
        children: [
          AdminEnterprisePageHeader(
            title: s.adminTabModeration,
            subtitle: s.adminModerationPageSubtitle,
            badge: pendingTotal > 0 ? '$pendingTotal' : null,
            badgeAlert: pendingTotal > 0,
            actions: [
              FilledButton.icon(
                onPressed: _runLifecycle,
                icon: const Icon(Icons.play_arrow, size: 16),
                label: Text(s.adminRunNow),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AdminEnterpriseBanner(
            message: s.adminLifecycleSubtitle,
            icon: Icons.autorenew,
            tone: AdminEnterpriseBannerTone.info,
          ),
          const SizedBox(height: 14),
          AdminEnterprisePanel(
            title: '${s.adminListingsPendingReview} (${_pendingListings.length})',
            child: _pendingListings.isEmpty
                ? AdminEnterpriseEmptyState(message: s.adminNoPendingListings)
                : Column(
                    children: _pendingListings.map(_pendingListingCard).toList(),
                  ),
          ),
          const SizedBox(height: 12),
          AdminEnterprisePanel(
            title: s.adminPhotosPending(_images.length),
            child: _images.isEmpty
                ? AdminEnterpriseEmptyState(message: s.adminNoPhotosPending)
                : Column(children: _images.map(_imageCard).toList()),
          ),
          AdminEnterprisePanel(
            title: s.adminFlagsSection(_flags.length),
            child: _flags.isEmpty
                ? AdminEnterpriseEmptyState(message: s.adminNoFlags)
                : Column(children: _flags.map(_flagCard).toList()),
          ),
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
