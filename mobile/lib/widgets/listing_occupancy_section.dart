import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/listing_occupancy.dart';
import '../theme/app_theme.dart';

/// สถานะทรัพย์ — ว่าง/รีโนเวท/มีผู้เช่า/ขายพร้อมผู้เช่า
class ListingOccupancySection extends StatelessWidget {
  const ListingOccupancySection({
    super.key,
    required this.listingType,
    required this.propertySlug,
    required this.value,
    required this.onChanged,
    this.salePrice,
    this.tenantRentController,
  });

  final String listingType;
  final String propertySlug;
  final ListingOccupancyInput value;
  final ValueChanged<ListingOccupancyInput> onChanged;
  final double? salePrice;
  final TextEditingController? tenantRentController;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value.availableDate ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      onChanged(value.copyWith(availableDate: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final options = ListingOccupancyStatus.optionsFor(listingType);
    final needsDate = ListingOccupancyStatus.needsAvailableDate(value.status);
    final needsRent = ListingOccupancyStatus.needsTenantRent(
      value.status,
      listingType,
    );
    final canViewDuring = ListingOccupancyStatus.allowsViewingDuring(value.status);
    final yield = needsRent &&
            salePrice != null &&
            value.tenantMonthlyRent != null
        ? ListingOccupancyStatus.yieldPercent(
            salePrice: salePrice!,
            monthlyRent: value.tenantMonthlyRent!,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.occupancySectionTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 4),
        Text(
          s.occupancySectionHint,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
        ),
        const SizedBox(height: 12),
        ...options.map((code) {
          final label = code == ListingOccupancyStatus.ready
              ? value.readyLabel(s, propertySlug)
              : value.statusLabel(s, code);
          return RadioListTile<String>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(label, style: const TextStyle(fontSize: 14)),
            value: code,
            groupValue: value.status,
            activeColor: AppTheme.primary,
            onChanged: (v) {
              if (v == null) return;
              onChanged(
                value.copyWith(
                  status: v,
                  clearDate: v == ListingOccupancyStatus.ready,
                  clearRent: v != ListingOccupancyStatus.saleWithTenant,
                  viewingAllowedDuring: false,
                ),
              );
            },
          );
        }),
        if (needsDate) ...[
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => _pickDate(context),
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              value.availableDate == null
                  ? s.occupancyPickReadyDate
                  : s.occupancyReadyOnDate(
                      DateFormat('d MMM yyyy', s.isEnglish ? 'en' : 'th').format(
                        value.availableDate!,
                      ),
                    ),
            ),
          ),
        ],
        if (needsRent) ...[
          const SizedBox(height: 12),
          TextField(
            controller: tenantRentController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: s.occupancyTenantRentLabel,
              border: const OutlineInputBorder(),
              suffixText: s.t('บาท/เดือน', 'THB/mo'),
            ),
            onChanged: (raw) {
              final rent = double.tryParse(raw.replaceAll(',', ''));
              onChanged(value.copyWith(tenantMonthlyRent: rent));
            },
          ),
          if (yield != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.occupancyYieldPreview(yield.toStringAsFixed(2)),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ] else if (salePrice == null) ...[
            const SizedBox(height: 6),
            Text(
              s.occupancyYieldAfterPrice,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ],
        if (canViewDuring) ...[
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.occupancyViewingDuring, style: const TextStyle(fontSize: 14)),
            value: value.viewingAllowedDuring,
            activeColor: AppTheme.primary,
            onChanged: (v) =>
                onChanged(value.copyWith(viewingAllowedDuring: v ?? false)),
          ),
        ],
      ],
    );
  }
}
