import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/hub_demo_seed.dart';
import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../models/viewing_request.dart';
import '../../services/chat_service.dart';
import '../../services/listing_repository.dart';
import '../../services/rental_lease_service.dart';
import '../../services/viewing_request_repository.dart';
import '../../theme/admin_theme.dart';
import '../../utils/chat_room_display.dart';
import '../contact/chat_link_detail_sheets.dart';
import 'admin_enterprise_page.dart';

/// Listing 360° — ทรัพย์ · นัดดู · Owner Hub · threads
class AdminListing360Panel extends StatefulWidget {
  const AdminListing360Panel({super.key, this.initialListingCode});

  final String? initialListingCode;

  @override
  State<AdminListing360Panel> createState() => _AdminListing360PanelState();
}

class _AdminListing360PanelState extends State<AdminListing360Panel> {
  final _codeCtrl = TextEditingController();
  final _listingRepo = ListingRepository();
  bool _loading = false;
  String? _listingId;
  String? _listingCode;
  String? _listingTitle;
  String? _projectName;
  List<ViewingRequest> _viewings = [];
  List<ChatRoom> _threads = [];

  @override
  void initState() {
    super.initState();
    final code = widget.initialListingCode?.trim();
    if (code != null && code.isNotEmpty) {
      _codeCtrl.text = code;
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
    }
  }

  @override
  void didUpdateWidget(covariant AdminListing360Panel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final code = widget.initialListingCode?.trim();
    if (code != null &&
        code.isNotEmpty &&
        code != oldWidget.initialListingCode &&
        code != _codeCtrl.text) {
      _codeCtrl.text = code;
      _lookup();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    HubDemoSeed.ensure();
    final listing = await _listingRepo.fetchByListingCode(code);
    if (listing == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _listingId = null;
        _viewings = [];
        _threads = [];
      });
      return;
    }

    await ViewingRequestRepository.instance.fetchAllForAdmin();
    await RentalLeaseService.instance.ensureLoaded();
    final viewings =
        ViewingRequestRepository.instance.forListing(listing.id);
    final threads = <ChatRoom>[
      ...ChatService.instance.allRoomsForSearch().where((r) {
        return r.listingId == listing.id ||
            r.listingCode.toUpperCase() == listing.listingCode.toUpperCase();
      }),
    ];
    for (final lease in RentalLeaseService.instance.allLeases) {
      if (lease.listingId != listing.id) continue;
      final tid = lease.threadId;
      if (tid == null || tid.isEmpty) continue;
      threads.add(
        ChatService.instance.ensureRentalLeaseGroup(
          threadId: tid,
          leaseId: lease.id,
          listingCode: lease.listingCode,
          listingTitle: lease.title,
          projectName: lease.projectName,
        ),
      );
    }
    final deduped = <String, ChatRoom>{};
    for (final r in threads) {
      deduped[r.id] = r;
    }

    if (!mounted) return;
    setState(() {
      _listingId = listing.id;
      _listingCode = listing.listingCode;
      _listingTitle = listing.title;
      _projectName = listing.projectName;
      _viewings = viewings;
      _threads = deduped.values.toList();
      _loading = false;
    });
  }

  void _openOwnerHub() {
    if (_listingId == null || _listingCode == null || _listingTitle == null) {
      return;
    }
    final room = ChatService.instance.ensureOwnerHubForListing(
      listingId: _listingId!,
      listingCode: _listingCode!,
      listingTitle: _listingTitle!,
      projectName: _projectName,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.s.ownerHubChatTitle(_listingCode!),
              style: AdminTheme.title,
            ),
            const SizedBox(height: 12),
            for (final msg in room.messages)
              ListTile(
                title: Text(msg.text, maxLines: 4, overflow: TextOverflow.ellipsis),
                subtitle: Text(msg.role.name),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateFmt = DateFormat('d MMM yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminEnterprisePageHeader(
          title: s.adminListing360Title,
          subtitle: s.adminListing360Hint,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codeCtrl,
                decoration: InputDecoration(
                  hintText: s.adminListing360SearchHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _lookup(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _loading ? null : _lookup,
              child: Text(s.t('ค้นหา', 'Search')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _listingId == null
                  ? AdminEnterpriseEmptyState(message: s.adminListing360Empty)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        Card(
                          child: ListTile(
                            title: Text(
                              _listingTitle ?? '—',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(_listingCode ?? ''),
                            trailing: OutlinedButton(
                              onPressed: _openOwnerHub,
                              child: Text(s.adminListing360OwnerHub),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.adminListing360Viewings(_viewings.length),
                          style: AdminTheme.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        ..._viewings.map(
                          (v) => ListTile(
                            dense: true,
                            title: Text('${v.code} · ${v.clientTagCode}'),
                            subtitle: Text(
                              '${dateFmt.format(v.scheduledAt)} · ${v.status.name}',
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => showViewingRequestDetailSheet(
                              context,
                              v.code,
                              adminView: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.adminListing360Threads(_threads.length),
                          style: AdminTheme.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        for (final room in _threads)
                          ListTile(
                            dense: true,
                            title: Text(room.displayTitle),
                            subtitle: Text(
                              room.inboxPreviewText(s),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }
}
