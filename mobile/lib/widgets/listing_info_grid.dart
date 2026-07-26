import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/listing_public.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../utils/localized_content.dart';

/// Grid ข้อมูลอสังหาฯ 2 คอลัมน์ — สไตล์ LivingInsider
class ListingInfoGrid extends StatelessWidget {
  const ListingInfoGrid({super.key, required this.listing});

  final ListingPublic listing;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final en = s.isEnglish;
    final locale = Localizations.localeOf(context).toString();
    final currency = NumberFormat.currency(
      locale: locale,
      symbol: '฿',
      decimalDigits: 0,
    );

    final cells = <_InfoCell>[];
    if (listing.areaSqm != null && listing.areaSqm! > 0) {
      cells.add(_InfoCell(
        icon: Icons.square_foot_outlined,
        label: s.listingInfoAreaLabel,
        value: s.sqmShort(listing.areaSqm!.round()),
      ));
    }
    if (listing.bedrooms != null) {
      cells.add(_InfoCell(
        icon: Icons.bed_outlined,
        label: s.listingInfoBedLabel,
        value: listing.bedrooms == 0
            ? s.filterStudio
            : s.bedCount(listing.bedrooms!),
      ));
    }
    if (listing.bathrooms != null) {
      cells.add(_InfoCell(
        icon: Icons.bathtub_outlined,
        label: s.listingInfoBathLabel,
        value: s.bathCount(listing.bathrooms!),
      ));
    }
    final floor = listing.localizedFloorRange(en);
    if (floor != null && floor.isNotEmpty) {
      cells.add(_InfoCell(
        icon: Icons.stairs_outlined,
        label: s.floorLabel,
        value: floor,
      ));
    }
    cells.add(_InfoCell(
      icon: Icons.apartment_outlined,
      label: s.listingInfoTypeLabel,
      value: s.propertyTypeChip(listing.propertyType),
    ));
    cells.add(_InfoCell(
      icon: Icons.sell_outlined,
      label: s.listingInfoTxnLabel,
      value: s.listingTransactionLabel(listing.listingType),
    ));
    if (listing.areaSqm != null && listing.areaSqm! > 0) {
      final perSqm = (listing.priceNet / listing.areaSqm!).round();
      cells.add(_InfoCell(
        icon: Icons.payments_outlined,
        label: s.listingInfoPriceSqmLabel,
        value: currency.format(perSqm),
      ));
    }

    if (cells.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.listingInfoSectionTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: p.border.withOpacity(0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final colW = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: [
                    for (final cell in cells)
                      SizedBox(
                        width: colW,
                        child: _InfoTile(cell: cell, palette: p),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCell {
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.cell, required this.palette});

  final _InfoCell cell;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(cell.icon, size: 18, color: palette.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cell.label,
                style: TextStyle(
                  fontSize: 11,
                  color: palette.textSecondary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cell.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
