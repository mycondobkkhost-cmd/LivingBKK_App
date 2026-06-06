import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../services/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_listing_nav.dart';
import '../../widgets/admin_mobile_layout.dart';
import '../../widgets/listings_map.dart';
import '../../widgets/reference_code_chip.dart';

class AdminLeadDetailPage extends StatefulWidget {
  const AdminLeadDetailPage({super.key, required this.leadId});

  final String leadId;

  @override
  State<AdminLeadDetailPage> createState() => _AdminLeadDetailPageState();
}

class _AdminLeadDetailPageState extends State<AdminLeadDetailPage> {
  final _admin = AdminRepository();
  bool _loading = true;
  Map<String, dynamic>? _lead;
  Map<String, dynamic>? _listingPoint;
  ListingPublic? _listingForMap;
  String? _linkedThreadId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final lead = await _admin.fetchLead(widget.leadId);
    final listingId = lead?['listing_id'] as String?;
    final listingCode = lead?['listing_code']?.toString();
    final point = await _admin.fetchListingMapPoint(
      listingId,
      listingCode: listingCode,
    );
    final threadId =
        lead == null ? null : await _admin.resolveLeadThreadId(lead);
    ListingPublic? listing;
    if (point != null && point['lat'] != null && point['lng'] != null) {
      final fallbackTitle = mounted ? context.s.adminDefaultProperty : 'Property';
      listing = ListingPublic(
        id: listingId ?? listingCode ?? 'map',
        listingCode: point['listing_code'] as String? ?? listingCode ?? '',
        listingType: point['listing_type']?.toString() ?? 'rent',
        title: point['title'] as String? ?? fallbackTitle,
        priceNet: (point['price_net'] as num?)?.toDouble() ?? 0,
        district: point['district'] as String?,
        projectName: point['project_name'] as String?,
        lat: (point['lat'] as num).toDouble(),
        lng: (point['lng'] as num).toDouble(),
      );
    }
    setState(() {
      _lead = lead;
      _listingPoint = point;
      _listingForMap = listing;
      _linkedThreadId = threadId;
      _loading = false;
    });
  }

  Future<void> _openLinkedChat() async {
    var threadId = _linkedThreadId;
    final lead = _lead;
    if (threadId == null && lead != null) {
      threadId = await _admin.resolveLeadThreadId(lead);
      if (mounted) setState(() => _linkedThreadId = threadId);
    }
    if (!mounted) return;
    if (threadId == null || threadId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.adminInboxEmptyUnclaimed)),
      );
      return;
    }
    context.push('/admin/chat/$threadId');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (_loading) {
      return AdminMobileLayout.scaffold(
        context: context,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final lead = _lead;
    if (lead == null) {
      return AdminMobileLayout.scaffold(
        context: context,
        body: Center(child: Text(s.notFoundLead)),
      );
    }

    final qual = lead['qualification_json'] as Map<String, dynamic>?;

    final listingCode = lead['listing_code']?.toString() ?? '—';
    final project = _listingPoint?['project_name']?.toString();
    final listingTitle = _listingPoint?['title']?.toString();

    return AdminMobileLayout.scaffold(
      context: context,
      appBar: AdminMobileLayout.appBar(
        context: context,
        title: Text(lead['transaction_ref']?.toString() ?? listingCode),
      ),
      body: ListView(
        padding: AdminMobileLayout.scrollPadding(context, top: 20, horizontal: 20, fabClearance: 16),
        children: [
          if (lead['transaction_ref'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ReferenceCodeChip(
                code: lead['transaction_ref'].toString(),
                label: s.transactionRefLabel,
              ),
            ),
          Card(
            color: AppTheme.primaryLight,
            child: InkWell(
              onTap: listingCode != '—'
                  ? () => openAdminListing(
                        context,
                        listingId: lead['listing_id']?.toString(),
                        listingCode: listingCode,
                      )
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.adminLeadPropertyCard,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        if (listingCode != '—')
                          Icon(Icons.open_in_new, size: 16, color: AppTheme.primary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project != null && project.isNotEmpty
                          ? '$project · $listingCode'
                          : listingCode,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  if (listingTitle != null && listingTitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      listingTitle,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                  if (_listingPoint?['price_net'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '฿${(_listingPoint!['price_net'] as num).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentDeep,
                      ),
                    ),
                  ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppTheme.accentMidLight,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: AppTheme.accentMid, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.adminConfirmViewingChatOnly,
                      style: TextStyle(fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openLinkedChat,
            icon: const Icon(Icons.forum_outlined),
            label: Text(s.adminOpenLinkedChat),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead['seeker_nickname']?.toString() ?? s.leadDefaultName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    lead['seeker_phone']?.toString() ?? '—',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (qual?['viewing_schedule'] != null)
                    _line(s.adminViewingRequestField, qual!['viewing_schedule'].toString()),
                  _line(s.statusLabel, lead['status']?.toString()),
                  _line(s.occupationLabel, lead['occupation']?.toString()),
                  _line(s.movePlanLabel, lead['move_plan']?.toString()),
                  _line(s.contractFieldLabel, lead['contract_duration']?.toString()),
                  _line(s.budgetLabel, lead['budget']?.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.adminViewingMap, style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _listingForMap != null
                ? ListingsMap(listings: [_listingForMap!])
                : Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(s.adminNoCoords),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _line(String k, String? v) {
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$k: $v'),
    );
  }
}
