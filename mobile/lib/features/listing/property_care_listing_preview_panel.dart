import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../models/listing_transaction_types.dart';
import '../../models/property_care_owner_data_input.dart';
import '../../theme/app_theme.dart';
import '../../utils/owner_listing_media.dart';
import '../../widgets/listing_public_preview_body.dart';

/// พรีวิวก่อนบันทึก — แยกหน้าบ้าน (ทีม) vs ฉบับเจ้าของ
class PropertyCareListingPreviewPanel extends StatefulWidget {
  const PropertyCareListingPreviewPanel({
    super.key,
    required this.row,
    required this.input,
    required this.isEnglish,
    this.listingType,
  });

  final Map<String, dynamic> row;
  final PropertyCareOwnerDataInput input;
  final bool isEnglish;
  final String? listingType;

  @override
  State<PropertyCareListingPreviewPanel> createState() =>
      _PropertyCareListingPreviewPanelState();
}

class _PropertyCareListingPreviewPanelState
    extends State<PropertyCareListingPreviewPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _layerTabs;

  @override
  void initState() {
    super.initState();
    _layerTabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _layerTabs.dispose();
    super.dispose();
  }

  String get _effectiveType =>
      widget.listingType ??
      widget.row['listing_type']?.toString() ??
      'rent';

  ListingPublic _publicListing() => _ownerListing();

  ListingPublic _ownerListing() {
    final cover = OwnerListingMedia.coverUrl(widget.row);
    final images = cover == null ? const <String>[] : [cover];
    return ListingPublic(
      id: widget.row['id']?.toString() ?? '',
      listingCode: widget.row['listing_code']?.toString() ?? '',
      listingType: _effectiveType,
      title: widget.input.title.trim(),
      titleEn: widget.input.titleEn,
      priceNet: widget.input.priceNet,
      priceSaleNet: widget.input.priceSaleNet,
      promoPriceNet: widget.input.promoPriceNet,
      promoSalePriceNet: widget.input.promoSalePriceNet,
      district: widget.row['district']?.toString(),
      projectName: widget.row['project_name']?.toString(),
      propertyType: widget.row['property_type']?.toString() ?? 'condo',
      bedrooms: widget.input.bedrooms,
      bathrooms: widget.input.bathrooms,
      areaSqm: widget.input.areaSqm,
      floorRange: widget.input.floorRange,
      petAllowed: widget.input.petPolicy.allowed,
      petPolicy: widget.input.petPolicy,
      imageUrls: images,
      description: widget.input.composedDescriptionOwner(isEnglish: widget.isEnglish),
      descriptionEn: widget.input.descriptionEn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.careOwnerDataPreviewIntro,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${s.careOwnerDataPreviewListingTypeLabel}: ',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Chip(
              label: Text(
                s.listingTransactionLabel(_effectiveType),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: AppTheme.primaryLight.withOpacity(0.45),
            ),
            if (ListingTransactionTypes.isRentAndSale(_effectiveType)) ...[
              const SizedBox(width: 6),
              Icon(Icons.sell_outlined, size: 14, color: AppTheme.primary),
              const SizedBox(width: 2),
              Icon(Icons.key_outlined, size: 14, color: AppTheme.primary),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: AppTheme.surfaceElevated,
          child: TabBar(
            controller: _layerTabs,
            labelColor: AppTheme.primary,
            tabs: [
              Tab(text: s.careOwnerDataPreviewPublicTab),
              Tab(text: s.careOwnerDataPreviewOwnerTab),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _layerTabs,
            children: [
              ListingPublicPreviewBody(
                listing: _publicListing(),
                banner: s.careOwnerDataPreviewPublicBanner,
                bannerNote: s.careOwnerDataPreviewPublicNote,
              ),
              ListingPublicPreviewBody(
                listing: _ownerListing(),
                banner: s.careOwnerDataPreviewOwnerBanner,
                bannerNote: s.careOwnerDataPreviewOwnerNote,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// เปิดพรีวิวแบบเต็มจอ (ใช้จากหน้าลงประกาศ)
Future<void> showListingPublicPreviewSheet(
  BuildContext context, {
  required ListingPublic listing,
  String? banner,
  String? bannerNote,
}) {
  final maxH = MediaQuery.sizeOf(context).height * 0.92;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => SizedBox(
      height: maxH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              AppStrings.of(ctx).careOwnerDataPreviewTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListingPublicPreviewBody(
              listing: listing,
              banner: banner,
              bannerNote: bannerNote,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.of(ctx).cancel),
            ),
          ),
        ],
      ),
    ),
  );
}
