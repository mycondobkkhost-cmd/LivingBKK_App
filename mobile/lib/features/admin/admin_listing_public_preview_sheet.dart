import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../services/admin_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/localized_content.dart';
import '../../widgets/design_system/app_property_card.dart';
import '../../utils/admin_listing_image_download.dart';
import '../../utils/admin_reference_nav.dart';
import '../../widgets/listing_image_gallery.dart';
import '../../widgets/reference_code_chip.dart';

/// พรีวิวหน้าตาประกาศบนเว็บ/แอป — ก่อนอนุมัติหรือหลังแก้ไขในคลัง
Future<void> showAdminListingPublicPreview({
  required BuildContext context,
  required String listingId,
  String? titleOverride,
  String? descriptionOverride,
}) async {
  final s = context.s;
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  final admin = AdminRepository();
  final listing = await admin.fetchListingForPublicPreview(
    listingId,
    titleOverride: titleOverride,
    descriptionOverride: descriptionOverride,
  );
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  if (listing == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminListingPreviewNotFound)),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _AdminListingPreviewDialog(listing: listing),
  );
}

class _AdminListingPreviewDialog extends StatefulWidget {
  const _AdminListingPreviewDialog({required this.listing});

  final ListingPublic listing;

  @override
  State<_AdminListingPreviewDialog> createState() =>
      _AdminListingPreviewDialogState();
}

class _AdminListingPreviewDialogState extends State<_AdminListingPreviewDialog>
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
    final s = context.s;
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 920,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(s),
            _banner(s),
            Material(
              color: const Color(0xFFF1F5F9),
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
        ),
      ),
    );
  }

  Widget _header(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.adminListingPreviewTitle, style: AdminTheme.title),
                const SizedBox(height: 2),
                Text(
                  widget.listing.listingCode,
                  style: AdminTheme.caption.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () => AdminListingImageDownload.downloadOriginals(
              context,
              listingId: widget.listing.id,
              listingCode: widget.listing.listingCode,
            ),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(s.adminDownloadOriginalPhotos),
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: s.cancel,
          ),
        ],
      ),
    );
  }

  Widget _banner(AppStrings s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFFF7ED),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.adminListingPreviewBanner,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  s.adminListingPreviewWatermarkNote,
                  style: AdminTheme.caption,
                ),
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
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPropertyCard(
                listing: listing,
                showFavorite: false,
                onTap: null,
              ),
            ],
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
    final s = context.s;
    final p = context.palette;
    final en = s.isEnglish;
    final currency = NumberFormat.currency(
      locale: en ? 'en_US' : 'th_TH',
      symbol: '฿',
      decimalDigits: 0,
    );
    final price = currency.format(listing.priceNet);
    final priceSuffix = listing.listingType == 'rent' ? s.perMonth : '';
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
                    ReferenceCodeChip(
                      code: listing.listingCode,
                      label: s.propertyCodeLabel,
                      onNavigate: adminReferenceNavigateHandler(
                        context,
                        code: listing.listingCode,
                        listingId: listing.id,
                        listingCode: listing.listingCode,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price + priceSuffix,
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
    final s = context.s;
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
