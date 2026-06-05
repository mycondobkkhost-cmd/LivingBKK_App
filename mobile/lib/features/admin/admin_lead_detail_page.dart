import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../services/admin_repository.dart';
import '../../services/appointment_repository.dart';
import '../../theme/app_theme.dart';
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
  final _appointments = AppointmentRepository();
  bool _loading = true;
  Map<String, dynamic>? _lead;
  Map<String, dynamic>? _listingPoint;
  ListingPublic? _listingForMap;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final lead = await _admin.fetchLead(widget.leadId);
    final listingId = lead?['listing_id'] as String?;
    final point = await _admin.fetchListingMapPoint(listingId);
    ListingPublic? listing;
    if (point != null && point['lat'] != null && point['lng'] != null) {
      final fallbackTitle = mounted ? context.s.adminDefaultProperty : 'Property';
      listing = ListingPublic(
        id: listingId ?? 'map',
        listingCode: point['listing_code'] as String? ?? '',
        listingType: 'rent',
        title: point['title'] as String? ?? fallbackTitle,
        priceNet: 0,
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
      _loading = false;
    });
  }

  Future<void> _schedule() async {
    final lead = _lead;
    if (lead == null) return;
    final s = context.s;
    final timeSlots = s.adminTimeSlots;

    final qual = lead['qualification_json'] as Map<String, dynamic>?;
    var preferredSlot = qual?['viewing_schedule']?.toString();
    if (preferredSlot != null && preferredSlot.contains('·')) {
      preferredSlot = preferredSlot.split('·').last.trim();
    }

    DateTime? date = DateTime.now().add(const Duration(days: 1));
    String? slot = timeSlots.contains(preferredSlot) ? preferredSlot : timeSlots[2];
    final notesCtrl = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final sheetS = context.s;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.paddingOf(context).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    sheetS.adminConfirmViewingTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setModal(() => date = picked);
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      date == null
                          ? sheetS.selectDate
                          : '${date!.day}/${date!.month}/${date!.year + (sheetS.isEnglish ? 0 : 543)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: slot,
                    decoration: InputDecoration(
                      labelText: sheetS.adminTimeSlotLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: timeSlots
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setModal(() => slot = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: sheetS.adminNotesLabel,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: date != null && slot != null
                        ? () => Navigator.pop(ctx, true)
                        : null,
                    child: Text(sheetS.adminSaveViewing),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final adminNotes = notesCtrl.text.trim();
    notesCtrl.dispose();
    if (ok != true || date == null || slot == null) return;

    try {
      await _appointments.scheduleFromLead(
        leadId: widget.leadId,
        seekerNickname: lead['seeker_nickname']?.toString() ?? s.leadDefaultName,
        seekerPhone: lead['seeker_phone']?.toString(),
        listingId: lead['listing_id'] as String?,
        listingCode: lead['listing_code']?.toString(),
        scheduledDate: date!,
        timeSlot: slot!,
        locationLabel: _listingPoint?['project_name']?.toString() ??
            _listingPoint?['district']?.toString() ??
            s.adminApproxZone,
        lat: (_listingPoint?['lat'] as num?)?.toDouble(),
        lng: (_listingPoint?['lng'] as num?)?.toDouble(),
        adminNotes: adminNotes.isEmpty ? null : adminNotes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminViewingSavedSnack)),
      );
      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final lead = _lead;
    if (lead == null) {
      return Scaffold(body: Center(child: Text(s.notFoundLead)));
    }

    final qual = lead['qualification_json'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: Text(lead['transaction_ref']?.toString() ?? lead['listing_code']?.toString() ?? 'Lead'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (lead['transaction_ref'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReferenceCodeChip(
                code: lead['transaction_ref'].toString(),
                label: s.transactionRefLabel,
              ),
            ),
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
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _schedule,
            icon: const Icon(Icons.event_available),
            label: Text(s.adminCoordinateViewing),
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
