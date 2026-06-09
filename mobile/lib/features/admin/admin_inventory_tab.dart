import 'package:flutter/material.dart';

import '../../config/code_glossary.dart';
import '../../l10n/app_strings.dart';
import '../../models/property_care_right.dart';
import '../../services/inventory_admin_repository.dart';
import '../../utils/app_notice.dart';
import '../../utils/demo_inventory_resolve.dart';
import '../../services/property_care_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import 'admin_property_care_grant_sheet.dart';

/// ทะเบียนทรัพย์รวม (RXT) — หลายเอเจ้นท์ / เจ้าของตรง / ลำดับติดต่อ
class AdminInventoryTab extends StatefulWidget {
  const AdminInventoryTab({super.key});

  @override
  State<AdminInventoryTab> createState() => _AdminInventoryTabState();
}

class _AdminInventoryTabState extends State<AdminInventoryTab> {
  final _repo = InventoryAdminRepository();
  List<Map<String, dynamic>> _roster = [];
  bool _loading = true;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _repo.fetchRoster();
      if (!mounted) return;
      setState(() {
        _roster = rows;
        _loading = false;
        if (_selectedId == null && rows.isNotEmpty) {
          _selectedId = rows.first['id'] as String?;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppNotice.error(context, 'โหลดทะเบียนทรัพย์ไม่สำเร็จ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_roster.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'ยังไม่มีทรัพย์รวม (RXT)\nจะสร้างอัตโนมัติเมื่อมีประกาศเผยแพร่',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ทะเบียนทรัพย์ (RXT)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _load,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _roster.length,
                  itemBuilder: (context, i) {
                    final row = _roster[i];
                    final id = row['id'] as String;
                    final alerts = (row['open_alerts'] as num?)?.toInt() ?? 0;
                    final members = (row['member_count'] as num?)?.toInt() ?? 0;
                    final selected = id == _selectedId;
                    return ListTile(
                      selected: selected,
                      title: Text(
                        row['inventory_code']?.toString() ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${row['project_name'] ?? row['district'] ?? '—'} · $members ประกาศ',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: alerts > 0
                          ? Badge(
                              label: Text('$alerts'),
                              backgroundColor: LivingBkkBrand.pink,
                            )
                          : null,
                      onTap: () => setState(() => _selectedId = id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedId == null
              ? const Center(child: Text('เลือกทรัพย์'))
              : _InventoryDetailPanel(
                  key: ValueKey(_selectedId),
                  inventoryId: _selectedId!,
                  summary: _roster.firstWhere((r) => r['id'] == _selectedId),
                  repo: _repo,
                  onChanged: _load,
                ),
        ),
      ],
    );
  }
}

class _InventoryDetailPanel extends StatefulWidget {
  const _InventoryDetailPanel({
    super.key,
    required this.inventoryId,
    required this.summary,
    required this.repo,
    required this.onChanged,
  });

  final String inventoryId;
  final Map<String, dynamic> summary;
  final InventoryAdminRepository repo;
  final VoidCallback onChanged;

  @override
  State<_InventoryDetailPanel> createState() => _InventoryDetailPanelState();
}

class _InventoryDetailPanelState extends State<_InventoryDetailPanel> {
  final _careRepo = PropertyCareRepository.instance;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _alerts = [];
  List<PropertyCareRight> _caretakers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _careRepo.addListener(_onCareChanged);
    _load();
  }

  @override
  void dispose() {
    _careRepo.removeListener(_onCareChanged);
    super.dispose();
  }

  void _onCareChanged() {
    if (!mounted) return;
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final invCode = widget.summary['inventory_code']?.toString();
    final invId = resolveDemoInventoryId(
      widget.inventoryId,
      inventoryCode: invCode,
    );

    var members = <Map<String, dynamic>>[];
    var alerts = <Map<String, dynamic>>[];
    var caretakers = <PropertyCareRight>[];

    try {
      members = await widget.repo.fetchMembers(
        widget.inventoryId,
        inventoryCode: invCode,
      );
    } catch (_) {}

    try {
      alerts = await widget.repo.fetchOpenAlerts(widget.inventoryId);
    } catch (_) {}

    try {
      caretakers = await _careRepo.forInventory(
        invId,
        inventoryCode: invCode,
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _members = members;
      _alerts = alerts;
      _caretakers = caretakers;
      _loading = false;
    });
  }

  Future<void> _setPrimary(String listingId) async {
    try {
      await widget.repo.setPrimaryContact(
        inventoryId: widget.inventoryId,
        listingId: listingId,
      );
      widget.onChanged();
      await _load();
      if (!mounted) return;
      AppNotice.show(context, 'ตั้งลำดับติดต่อหลักแล้ว');
    } catch (e) {
      if (!mounted) return;
      AppNotice.error(context, 'ไม่สำเร็จ: $e');
    }
  }

  Future<void> _ackAlert(String alertId) async {
    await widget.repo.acknowledgeAlert(alertId);
    await _load();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final ownershipRemark = widget.summary['ownership_remark']?.toString() ?? '';
    final availability = widget.summary['availability']?.toString() ?? '';
    final invCode = widget.summary['inventory_code']?.toString() ?? 'RXT';
    final s = context.s;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          invCode,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          CodeGlossary.captionFor(invCode, isEn: s.isEnglish),
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => showAdminPropertyCareGrantSheet(
            context,
            inventoryId: widget.inventoryId,
            inventoryCode: invCode,
            onSaved: () async {
              widget.onChanged();
              await _load();
            },
          ),
          icon: const Icon(Icons.verified_user_outlined, size: 18),
          label: Text(s.adminCareOpenGrantSheet),
        ),
        const SizedBox(height: 12),
        Text(
          '${s.adminCareCurrentList} (${_caretakers.length})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        if (_caretakers.isEmpty) ...[
          const SizedBox(height: 4),
          Text(
            s.adminCareGrantHint,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ] else ...[
          const SizedBox(height: 6),
          ..._caretakers.map((c) {
            final role = CodeGlossary.careRoleLabel(c.careRole, isEn: s.isEnglish);
            final name = c.userDisplayName ?? c.userId;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                c.isPrimary ? Icons.star : Icons.person_outline,
                size: 20,
                color: c.isPrimary ? LivingBkkBrand.purplePrimary : AppTheme.textSecondary,
              ),
              title: Text(name, style: const TextStyle(fontSize: 13)),
              subtitle: Text(
                '$role · ${c.status}',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            );
          }),
        ],
        if (ownershipRemark.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LivingBkkBrand.purpleLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LivingBkkBrand.purplePrimary.withOpacity(0.35)),
            ),
            child: Text(
              ownershipRemark,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: LivingBkkBrand.navy,
              ),
            ),
          ),
        ],
        if (availability.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('สถานะทรัพย์: $availability', style: TextStyle(color: AppTheme.textSecondary)),
        ],
        const SizedBox(height: 16),
        if (_alerts.isNotEmpty) ...[
          ..._alerts.map(
            (a) => Card(
              color: LivingBkkBrand.peachLight,
              child: ListTile(
                leading: const Icon(Icons.campaign_outlined, color: LivingBkkBrand.pink),
                title: Text(a['message']?.toString() ?? ''),
                subtitle: Text(a['alert_type']?.toString() ?? ''),
                trailing: TextButton(
                  onPressed: () => _ackAlert(a['id'] as String),
                  child: const Text('รับทราบ'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'สมาชิกในทรัพย์เดียวกัน (${_members.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'ลูกค้าเห็นประกาศเดียวบนหน้าสาธารณะ · หลังบ้านเห็นทุกประกาศ · ลำดับ 1 = ติดต่อก่อน',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
        ),
        const SizedBox(height: 12),
        ..._members.map((m) {
          final priority = (m['inventory_contact_priority'] as num?)?.toInt() ?? 100;
          final roleNote = m['inventory_role_note']?.toString() ?? '';
          final syncRemark = m['inventory_sync_remark']?.toString();
          final listingId = m['listing_id']?.toString();
          final ownerDataStatus = m['owner_data_status']?.toString();
          final description = m['description_owner']?.toString().trim().isNotEmpty == true
              ? m['description_owner']!.toString().trim()
              : m['description']?.toString().trim() ?? '';
          final titleOwner = m['title_owner']?.toString();
          final occupancy = m['occupancy_status']?.toString();
          final beds = m['bedrooms'];
          final baths = m['bathrooms'];
          final area = m['area_sqm'];
          final contactClean = m['display_contact_clean'] != false;
          final ownerDataLabel = ownerDataStatus == 'complete'
              ? s.adminOwnerDataStatusComplete
              : ownerDataStatus == 'pending'
                  ? s.adminOwnerDataStatusPending
                  : null;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: priority == 1
                            ? LivingBkkBrand.mintLight
                            : LivingBkkBrand.surfaceElevated,
                        child: Text(
                          '$priority',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: priority == 1
                                ? LivingBkkBrand.mint
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${m['listing_code']} · ${m['poster_name'] ?? m['listed_by_role']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (priority != 1 &&
                          listingId != null &&
                          listingId.isNotEmpty)
                        TextButton(
                          onPressed: () => _setPrimary(listingId),
                          child: const Text('ตั้งเป็นติดต่อหลัก'),
                        ),
                    ],
                  ),
                  if (roleNote.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      roleNote,
                      style: TextStyle(
                        color: priority == 1
                            ? LivingBkkBrand.purplePrimary
                            : AppTheme.textSecondary,
                        fontWeight:
                            priority == 1 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                  if (syncRemark != null && syncRemark.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      syncRemark,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'สถานะ: ${m['status']} · ฿${m['price_net']}',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  if (ownerDataLabel != null) ...[
                    const SizedBox(height: 6),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(ownerDataLabel, style: const TextStyle(fontSize: 11)),
                      backgroundColor: ownerDataStatus == 'complete'
                          ? LivingBkkBrand.mintLight.withOpacity(0.5)
                          : LivingBkkBrand.peachLight,
                    ),
                  ],
                  if (occupancy != null && occupancy.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.adminOwnerDataOccupancyLine(occupancy),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                  if (titleOwner != null && titleOwner.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.t('หัวข้อเจ้าของ: $titleOwner', 'Owner title: $titleOwner'),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                  if (beds != null || baths != null || area != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.t(
                        'สเปกเจ้าของ: ${beds ?? '—'} นอน · ${baths ?? '—'} น้ำ · ${area ?? '—'} ตร.ม.',
                        'Owner specs: ${beds ?? '—'} bed · ${baths ?? '—'} bath · ${area ?? '—'} sqm',
                      ),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                  if (!contactClean) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.t(
                        '⚠ พบเบอร์/ไลน์ในข้อความเจ้าของ — ห้าม sync หน้าบ้านอัตโนมัติ',
                        '⚠ Contact info in owner text — block public sync',
                      ),
                      style: TextStyle(fontSize: 11, color: AppTheme.warning),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.adminOwnerDataDescriptionPreview(description),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
