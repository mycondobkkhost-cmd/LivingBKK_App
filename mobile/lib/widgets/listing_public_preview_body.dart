import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/listing_public.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/localized_content.dart';
import '../utils/listing_price_helpers.dart';
import 'design_system/app_property_card.dart';
import 'listing_image_gallery.dart';

/// พรีวิวการ์ดฟีด + หน้ารายละเอียด (ใช้ได้ทั้งแอดมินและเจ้าของ)
class ListingPublicPreviewBody extends StatefulWidget {
  const ListingPublicPreviewBody({
    super.key,
    required this.listing,
    this.banner,
    this.bannerNote,
  });

  final ListingPublic listing;
  final String? banner;
  final String? bannerNote;

  @override
  State<ListingPublicPreviewBody> createState() =>
      _ListingPublicPreviewBodyState();
}

class _ListingPublicPreviewBodyState extends State<ListingPublicPreviewBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.banner != null) _banner(widget.banner!, widget.bannerNote),
        Material(
          color: AppTheme.surfaceElevated,
          child: TabBar(
            controller: _tabs,
            labelColor: AppTheme.primary,
            tabs: [
              Tab(text: s.adminListingPreviewFeedTab),
              Tab(text: s.adminListingPreviewDetailTab),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _FeedPreviewTab(listing: widget.listing),
              _DetailPreviewTab(listing: widget.listing),
            ],
          ),
        ),
      ],
    );
  }

  Widget _banner(String text, String? note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppTheme.accentAmberLight.withOpacity(0.55),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(note, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedPreviewTab extends StatelessWidget {
  const _FeedPreviewTab({required this.listing});

  final ListingPublic listing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: AppPropertyCard(
            listing: listing,
            showFavorite: false,
            onTap: null,
          ),
        ),
      ),
    );
  }
}

class _DetailPreviewTab extends StatelessWidget {
  const _DetailPreviewTab({required this.listing});

  final ListingPublic listing;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final en = s.isEnglish;
    final currency = NumberFormat.currency(
      locale: en ? 'en_US' : 'th_TH',
      symbol: '฿',
      decimalDigits: 0,
    );
    final dual = ListingPriceHelpers.showDualPrices(listing);
    final priceLine = dual
        ? '${currency.format(ListingPriceHelpers.displayAmount(listing, rentSide: true))}${s.perMonth} · ${currency.format(ListingPriceHelpers.displayAmount(listing, rentSide: false))}'
        : '${currency.format(ListingPriceHelpers.effectivePrice(listing))}${ListingPriceHelpers.showPerMonth(listing) ? s.perMonth : ''}';
    final localizedDesc = listing.localizedDescription(en);
    final description = localizedDesc.isNotEmpty
        ? localizedDesc
        : (en ? 'Property description preview.' : 'ตัวอย่างรายละเอียดประกาศ');

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ListingImageGallery(imageUrls: listing.imageUrls),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.localizedTitle(en),
                      style: AppTypography.textTheme(p).headlineMedium!.copyWith(
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        s.listingTransactionLabel(listing.listingType),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppTheme.primaryLight.withOpacity(0.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing.listingCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      priceLine,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: p.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 16, color: p.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              listing.localizedDistrict(en),
                              listing.localizedProjectName(en) ?? listing.projectName,
                            ]
                                .whereType<String>()
                                .where((e) => e.isNotEmpty)
                                .join(' · '),
                            style: TextStyle(fontSize: 14, color: p.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PreviewFactsRow(listing: listing),
                    const SizedBox(height: 16),
                    Text(
                      s.listingDetailsSection,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(height: 1.55, fontSize: 15, color: p.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewFactsRow extends StatelessWidget {
  const _PreviewFactsRow({required this.listing});

  final ListingPublic listing;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final en = s.isEnglish;
    final items = <({IconData icon, String label})>[
      if (listing.bedrooms != null)
        (
          icon: Icons.bed_outlined,
          label: listing.bedrooms == 0
              ? s.filterStudio
              : s.bedCount(listing.bedrooms!),
        ),
      if (listing.bathrooms != null)
        (icon: Icons.bathtub_outlined, label: '${listing.bathrooms}'),
      if (listing.areaSqm != null)
        (
          icon: Icons.square_foot_outlined,
          label: s.sqmShort(listing.areaSqm!.toInt()),
        ),
      if (listing.localizedFloorRange(en) != null)
        (icon: Icons.layers_outlined, label: listing.localizedFloorRange(en)!),
      (icon: Icons.apartment_outlined, label: s.propertyTypeChip(listing.propertyType)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: p.divider),
          bottom: BorderSide(color: p.divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map(
              (f) => Expanded(
                child: Column(
                  children: [
                    Icon(f.icon, size: 22, color: p.textSecondary),
                    const SizedBox(height: 6),
                    Text(
                      f.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
