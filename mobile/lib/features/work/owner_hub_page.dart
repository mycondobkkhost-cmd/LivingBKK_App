import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../data/hub_demo_seed.dart';
import '../../models/viewing_request.dart';
import '../../services/chat_service.dart';
import '../../services/owner_hub_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/consumer/consumer_page_shell.dart';
import '../contact/chat_link_detail_sheets.dart';
import '../contact/property_chat_page.dart';
import 'owner_viewing_decline_sheet.dart';
import 'owner_viewing_response_sheet.dart';

/// Owner Hub — คำขอนัดดูรอตอบ + แชทกลางต่อทรัพย์
class OwnerHubPage extends StatefulWidget {
  const OwnerHubPage({super.key});

  @override
  State<OwnerHubPage> createState() => _OwnerHubPageState();
}

class _OwnerHubPageState extends State<OwnerHubPage> {
  bool _loading = true;
  List<ViewingRequest> _pending = [];
  List<OwnerListingRef> _listings = [];

  @override
  void initState() {
    super.initState();
    HubDemoSeed.ensure();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pending = await OwnerHubRepository.instance.fetchPendingViewings();
    final listings = await OwnerHubRepository.instance.fetchOwnerListings();
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _listings = listings;
      _loading = false;
    });
  }

  Future<void> _confirm(ViewingRequest req) async {
    final s = context.s;
    final schedule = DateFormat('d/M/yyyy HH:mm').format(req.scheduledAt);
    final response = await showOwnerViewingResponseSheet(
      context,
      requestedSchedule: schedule,
      listingCode: req.listingCode,
      listingId: req.listingId,
    );
    if (response == null || !mounted) return;

    await OwnerHubRepository.instance.confirmViewing(
      viewingRequest: req,
      response: response,
      s: s,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.ownerHubConfirmedSnack(req.code))),
    );
    _load();
  }

  Future<void> _decline(ViewingRequest req) async {
    final s = context.s;
    final result = await showOwnerViewingDeclineSheet(
      context,
      viewingCode: req.code,
    );
    if (result == null || !mounted) return;

    await OwnerHubRepository.instance.declineViewing(
      viewingRequest: req,
      s: s,
      note: result.note,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.ownerHubDeclinedSnack(req.code))),
    );
    _load();
  }

  void _openHubChat(OwnerListingRef listing) {
    final room = ChatService.instance.ensureOwnerHubForListing(
      listingId: listing.id,
      listingCode: listing.listingCode,
      listingTitle: listing.title,
      projectName: listing.projectName,
    );
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PropertyChatPage(room: room),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateFmt = DateFormat('d MMM yyyy HH:mm');

    return ConsumerPageShell(
      title: s.ownerHubTitle,
      onBack: () => context.pop(),
      actions: [
        ConsumerHeaderIconButton(
          icon: Icons.refresh_rounded,
          onTap: _load,
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: PageSafeInsets.padLTRB(
                  context,
                  left: 16,
                  top: 16,
                  right: 16,
                  bottom: 16,
                  addHomeIndicator: false,
                ),
                children: [
                  Text(
                    s.ownerHubPendingSection(_pending.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_pending.isEmpty)
                    Text(
                      s.ownerHubNoPending,
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else
                    ..._pending.map((req) => _pendingCard(req, dateFmt, s)),
                  const SizedBox(height: 20),
                  Text(
                    s.ownerHubListingsSection,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_listings.isEmpty)
                    Text(
                      s.ownerHubNoListings,
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else
                    ..._listings.map((l) => _listingTile(l, s)),
                ],
              ),
            ),
    );
  }

  Widget _pendingCard(ViewingRequest req, DateFormat dateFmt, AppStrings s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${req.code} · ${req.listingCode}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              req.listingTitle,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              '${dateFmt.format(req.scheduledAt)} · ${req.clientTagCode}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => showViewingRequestDetailSheet(
                    context,
                    req.code,
                    adminView: false,
                    ownerView: true,
                    onConfirm: () => _confirm(req),
                    onDecline: () => _decline(req),
                  ),
                  child: Text(s.t('รายละเอียด', 'Details')),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => _decline(req),
                  child: Text(s.ownerHubDeclineBtn),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _confirm(req),
                  child: Text(s.ownerHubConfirmBtn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _listingTile(OwnerListingRef listing, AppStrings s) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.home_work_outlined, color: AppTheme.primary),
        title: Text(listing.title),
        subtitle: Text(listing.listingCode),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openHubChat(listing),
      ),
    );
  }
}
