import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../utils/listing_offer_meta.dart';

/// เลือกทรัพย์จาก「ของฉัน」เพื่อส่งข้อเสนอ — มีรูป · ติ๊ก · แสดงฐานะจากประกาศ
class StockOfferPicker extends StatelessWidget {
  const StockOfferPicker({
    super.key,
    required this.listings,
    required this.selectedIds,
    required this.onToggle,
    this.notes = const {},
    this.onNoteChanged,
    this.subtitle,
  });

  final List<ListingPublic> listings;
  final Set<String> selectedIds;
  final void Function(ListingPublic listing, bool selected) onToggle;
  final Map<String, String> notes;
  final void Function(ListingPublic listing, String note)? onNoteChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final currency =
        NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.offerPickFromStockTitle,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 12),
        ...listings.map((listing) {
          final selected = selectedIds.contains(listing.id);
          final cover = ListingOfferMeta.coverUrl(listing);
          final capacity = ListingOfferMeta.offererCapacity(listing);
          return Padding(
            padding: const EdgeInsets.only(bottom: LiLayout.homeBlockGap),
            child: Material(
              color: selected ? p.primaryLight.withOpacity(0.35) : p.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LiLayout.homePromoRadius),
                side: BorderSide(
                  color: selected
                      ? p.primary.withOpacity(0.55)
                      : p.border.withOpacity(0.75),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onToggle(listing, !selected),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: selected,
                              onChanged: (v) => onToggle(listing, v ?? false),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 88,
                                height: 66,
                                child: cover != null
                                    ? Image.network(
                                        cover,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _thumbPlaceholder(listing),
                                      )
                                    : _thumbPlaceholder(listing),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (listing.listingCode.isNotEmpty)
                                    Text(
                                      listing.listingCode,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: p.primary,
                                      ),
                                    ),
                                  Text(
                                    ListingOfferMeta.displayTitle(listing),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (listing.district != null &&
                                      listing.district!.isNotEmpty)
                                    Text(
                                      listing.district!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (listing.priceNet > 0)
                                        Text(
                                          currency.format(listing.priceNet),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: p.primary,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: p.primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          s.offererCapacityLabel(capacity),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: p.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selected && onNoteChanged != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        s.offerStockNoteFieldLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: ValueKey('note-${listing.id}'),
                        initialValue: notes[listing.id],
                        onChanged: (v) => onNoteChanged!(listing, v),
                        minLines: 1,
                        maxLines: 3,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: s.offerStockNoteHint,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary.withOpacity(0.85),
                            height: 1.25,
                          ),
                          filled: true,
                          fillColor: p.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _thumbPlaceholder(ListingPublic listing) {
    return ColoredBox(
      color: AppTheme.cardTint,
      child: Center(
        child: Icon(
          Icons.home_work_outlined,
          color: AppTheme.textSecondary.withOpacity(0.5),
          size: 28,
        ),
      ),
    );
  }
}
