import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/rental_lease.dart';
import '../../services/rental_lease_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../rental/rental_group_chat_page.dart';
import '../rental/rental_lease_dates_display.dart';
import 'admin_rental_lease_sheet.dart';
import 'admin_rental_payment_sheet.dart';

/// หลังบ้าน — บริหารจัดการทรัพย์ให้เช่า + แชทกลุ่ม
class AdminRentalManagementTab extends StatefulWidget {
  const AdminRentalManagementTab({super.key});

  @override
  State<AdminRentalManagementTab> createState() =>
      _AdminRentalManagementTabState();
}

class _AdminRentalManagementTabState extends State<AdminRentalManagementTab> {
  final _service = RentalLeaseService.instance;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _service.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
    _service.addListener(_onChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    _search.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<RentalLease> get _filtered {
    final q = _query.trim().toLowerCase();
    final all = _service.allLeases;
    if (q.isEmpty) return all;
    return all
        .where(
          (l) =>
              l.listingCode.toLowerCase().contains(q) ||
              l.title.toLowerCase().contains(q) ||
              l.id.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = DateFormat(s.isEnglish ? 'd MMM yyyy' : 'd MMM yyyy');
    final leases = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(s.adminRentalManagementIntro, style: AdminTheme.hint),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.rentalGroupBlindHint,
                    style: AdminTheme.caption.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: s.adminRentalSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _FeatureChip(icon: Icons.groups_outlined, label: s.rentalTabChat),
              _FeatureChip(
                icon: Icons.description_outlined,
                label: s.rentalTabDocuments,
              ),
              _FeatureChip(
                icon: Icons.photo_album_outlined,
                label: s.rentalTabAlbum,
              ),
              _FeatureChip(
                icon: Icons.payments_outlined,
                label: s.rentalTabPayments,
              ),
              _FeatureChip(
                icon: Icons.build_outlined,
                label: s.rentalTabMaintenance,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: leases.isEmpty
              ? Center(
                  child: Text(s.adminRentalManagementEmpty, style: AdminTheme.hint),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: leases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final lease = leases[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lease.isActive
                                        ? AppTheme.accentMid.withOpacity(0.15)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lease.isActive
                                        ? s.adminRentalStatusActive
                                        : s.adminRentalStatusEnded,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: lease.isActive
                                          ? AppTheme.accentMid
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lease.listingCode,
                                    style: AdminTheme.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lease.title,
                              style: AdminTheme.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.rentalRentAmount(lease.rentAmount),
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (lease.nextPaymentDue != null)
                              Text(
                                s.rentalNextPayment(
                                  fmt.format(lease.nextPaymentDue!),
                                ),
                                style: AdminTheme.caption,
                              ),
                            const SizedBox(height: 8),
                            RentalLeaseDatesDisplay(
                              lease: lease,
                              dateFmt: fmt,
                              dense: true,
                              textStyle: AdminTheme.caption,
                            ),
                            if (lease.contractAttachments.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.attach_file,
                                      size: 14, color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    s.adminRentalContractFileCount(
                                      lease.contractAttachments.length,
                                    ),
                                    style: AdminTheme.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: lease.members
                                  .map(
                                    (m) => Chip(
                                      label: Text(
                                        m.displayLabel,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => RentalGroupChatPage(
                                        lease: lease,
                                        isAdminView: true,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.forum_outlined, size: 18),
                                  label: Text(s.adminRentalOpenGroupChat),
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => showAdminRentalPaymentSheet(
                                    context: context,
                                    lease: lease,
                                  ),
                                  icon: const Icon(Icons.payments_outlined, size: 18),
                                  label: Text(s.adminRentalPaymentSettings),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => showAdminRentalLeaseSheet(
                                    context: context,
                                    lease: lease,
                                  ),
                                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                                  label: Text(s.adminRentalEditContract),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(s.rentalFeatureComingSoon),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.person_add_outlined, size: 18),
                                  label: Text(s.adminRentalAddMember),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }
}
