import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/listing_form_options.dart';
import '../../models/listing_transaction_types.dart';
import '../../l10n/app_strings.dart';
import '../../models/listing_occupancy.dart';
import '../../models/listing_pet_policy.dart';
import '../../models/listing_viewing_access.dart';
import '../../models/property_care_owner_data_input.dart';
import '../../services/property_care_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/owner_listing_media.dart';
import '../../widgets/listing_hashtag_picker.dart';
import '../../widgets/listing_occupancy_section.dart';
import '../../widgets/listing_pet_policy_section.dart';
import '../../widgets/listing_viewing_access_section.dart';
import '../../widgets/listing_price_form_section.dart';
import '../../utils/listing_draft_translate.dart';
import 'property_care_listing_preview_panel.dart';
import 'property_care_owner_data_result.dart';

Future<PropertyCareOwnerDataResult?> showPropertyCareOwnerDataSheet(
  BuildContext context, {
  required Map<String, dynamic> row,
  required String inventoryId,
  String? inventoryCode,
  bool isEdit = false,
}) {
  return showModalBottomSheet<PropertyCareOwnerDataResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _OwnerDataSheet(
      row: row,
      inventoryId: inventoryId,
      inventoryCode: inventoryCode,
      isEdit: isEdit,
    ),
  );
}

class _OwnerDataSheet extends StatefulWidget {
  const _OwnerDataSheet({
    required this.row,
    required this.inventoryId,
    this.inventoryCode,
    this.isEdit = false,
  });

  final Map<String, dynamic> row;
  final String inventoryId;
  final String? inventoryCode;
  final bool isEdit;

  @override
  State<_OwnerDataSheet> createState() => _OwnerDataSheetState();
}

class _OwnerDataSheetState extends State<_OwnerDataSheet> {
  static const _stepCount = 4;

  final _repo = PropertyCareRepository.instance;
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _salePrice = TextEditingController();
  final _rentPromo = TextEditingController();
  final _salePromo = TextEditingController();
  bool _rentPromoEnabled = false;
  bool _salePromoEnabled = false;
  final _beds = TextEditingController();
  final _baths = TextEditingController();
  final _area = TextEditingController();
  final _floor = TextEditingController();
  final _ownerNote = TextEditingController();
  final _viewingNote = TextEditingController();
  final _petMaxWeight = TextEditingController();
  final _petMaxCount = TextEditingController();
  final _tenantRent = TextEditingController();
  final _titleEn = TextEditingController();
  final _descEn = TextEditingController();

  ListingOccupancyInput _occupancy = const ListingOccupancyInput();
  ListingViewingAccess _viewingAccess = const ListingViewingAccess();
  ListingPetPolicyInput _petPolicy = const ListingPetPolicyInput();
  final Set<String> _hashtagIds = {};
  final Set<String> _facilityIds = {};
  bool _showEn = false;

  int _step = 0;
  bool _busy = false;
  String? _formError;
  String? _contactWarning;
  late String _baselineTitle;

  late String _listingType;

  bool get _titleChanged =>
      _title.text.trim().toLowerCase() != _baselineTitle.toLowerCase();

  bool get _isDualListing =>
      ListingTransactionTypes.isRentAndSale(_listingType);

  String get _propertySlug => widget.row['property_type']?.toString() ?? 'condo';

  void _onListingTypeChanged(String code) {
    setState(() {
      final prev = _listingType;
      _listingType = code;
      if (code == ListingTransactionTypes.rentAndSale && prev == 'sale') {
        _salePrice.text = _price.text;
        _price.clear();
      } else if (code == 'sale' &&
          ListingTransactionTypes.isRentAndSale(prev)) {
        if (_salePrice.text.trim().isNotEmpty) {
          _price.text = _salePrice.text;
        }
        _salePrice.clear();
      } else if (code == 'rent' && ListingTransactionTypes.isRentAndSale(prev)) {
        _salePrice.clear();
      } else if (code == 'rent' && prev == 'sale') {
        _price.clear();
      }
      final occOpts = ListingOccupancyStatus.optionsFor(code);
      if (!occOpts.contains(_occupancy.status)) {
        _occupancy = const ListingOccupancyInput();
        _tenantRent.clear();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _listingType = widget.row['listing_type']?.toString() ?? 'rent';
    final seed = PropertyCareOwnerDataInput.fromListingRow(widget.row);
    _baselineTitle = seed.title.trim();
    _title.text = seed.title;
    _desc.text = seed.description;
    _price.text = seed.priceNet > 0 ? '${seed.priceNet.round()}' : '';
    if (seed.priceSaleNet != null && seed.priceSaleNet! > 0) {
      _salePrice.text = '${seed.priceSaleNet!.round()}';
    }
    if (seed.promoPriceNet != null && seed.promoPriceNet! > 0) {
      _rentPromo.text = '${seed.promoPriceNet!.round()}';
      _rentPromoEnabled = true;
    }
    if (seed.promoSalePriceNet != null && seed.promoSalePriceNet! > 0) {
      _salePromo.text = '${seed.promoSalePriceNet!.round()}';
      _salePromoEnabled = true;
    }
    if (seed.bedrooms != null) _beds.text = '${seed.bedrooms}';
    if (seed.bathrooms != null) _baths.text = '${seed.bathrooms}';
    if (seed.areaSqm != null) _area.text = '${seed.areaSqm}';
    if (seed.floorRange != null) _floor.text = seed.floorRange!;
    if (seed.ownerNote != null) _ownerNote.text = seed.ownerNote!;
    _occupancy = seed.occupancy;
    _viewingAccess = seed.viewingAccess;
    _viewingNote.text = seed.viewingAccess.note ?? '';
    _petPolicy = seed.petPolicy;
    if (seed.petPolicy.maxWeightKg != null) {
      _petMaxWeight.text = seed.petPolicy.maxWeightKg!.toStringAsFixed(0);
    }
    if (seed.petPolicy.maxCount != null) {
      _petMaxCount.text = '${seed.petPolicy.maxCount}';
    }
    if (seed.occupancy.tenantMonthlyRent != null) {
      _tenantRent.text = seed.occupancy.tenantMonthlyRent!.toStringAsFixed(0);
    }
    _hashtagIds.addAll(seed.hashtagIds);
    _facilityIds.addAll(seed.facilityIds);
    _showEn = seed.listingLanguages.contains('en');
    if (seed.titleEn != null) _titleEn.text = seed.titleEn!;
    if (seed.descriptionEn != null) _descEn.text = seed.descriptionEn!;
    _desc.addListener(() => setState(() {}));
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _salePrice.dispose();
    _rentPromo.dispose();
    _salePromo.dispose();
    _beds.dispose();
    _baths.dispose();
    _area.dispose();
    _floor.dispose();
    _ownerNote.dispose();
    _viewingNote.dispose();
    _petMaxWeight.dispose();
    _petMaxCount.dispose();
    _tenantRent.dispose();
    _titleEn.dispose();
    _descEn.dispose();
    super.dispose();
  }

  PropertyCareOwnerDataInput? _buildInput() {
    final price = double.tryParse(_price.text.replaceAll(',', '').trim());
    if (price == null || price <= 0) return null;
    final sale = _isDualListing
        ? double.tryParse(_salePrice.text.replaceAll(',', '').trim())
        : null;
    if (_isDualListing && (sale == null || sale <= 0)) return null;
    final promos = _resolvePromoPrices();
    final beds = int.tryParse(_beds.text.trim());
    final baths = int.tryParse(_baths.text.trim());
    final area = double.tryParse(_area.text.replaceAll(',', '').trim());
    final langs = <String>['th'];
    if (_showEn) langs.add('en');
    return PropertyCareOwnerDataInput(
      title: _title.text,
      description: _desc.text,
      priceNet: price,
      priceSaleNet: sale,
      promoPriceNet: promos.rentPromo,
      promoSalePriceNet: promos.salePromo,
      bedrooms: beds,
      bathrooms: baths,
      areaSqm: area,
      floorRange: _floor.text.trim().isEmpty ? null : _floor.text.trim(),
      petPolicy: _petPolicy,
      occupancy: _occupancy,
      viewingAccess: _viewingAccess.copyWith(note: _viewingNote.text.trim()),
      hashtagIds: _hashtagIds.toList(),
      facilityIds: _facilityIds.toList(),
      ownerNote: _ownerNote.text.trim().isEmpty ? null : _ownerNote.text.trim(),
      listingLanguages: langs,
      titleEn: _showEn && _titleEn.text.trim().isNotEmpty
          ? _titleEn.text.trim()
          : null,
      descriptionEn: _showEn && _descEn.text.trim().isNotEmpty
          ? _descEn.text.trim()
          : null,
    );
  }

  ({double? rentPromo, double? salePromo}) _resolvePromoPrices() {
    double? rentPromo;
    double? salePromo;
    if (ListingTransactionTypes.hasRentComponent(_listingType) &&
        _rentPromoEnabled) {
      rentPromo = double.tryParse(_rentPromo.text.replaceAll(',', '').trim());
    }
    if (ListingTransactionTypes.hasSaleComponent(_listingType) &&
        _salePromoEnabled) {
      salePromo = double.tryParse(_salePromo.text.replaceAll(',', '').trim());
    }
    return (rentPromo: rentPromo, salePromo: salePromo);
  }

  String? _validatePromoPrices(AppStrings s) {
    final price = double.tryParse(_price.text.replaceAll(',', '').trim());
    if (price == null || price <= 0) return s.careOwnerDataPriceRequired;
    if (ListingTransactionTypes.hasRentComponent(_listingType) &&
        _rentPromoEnabled) {
      final promo = double.tryParse(_rentPromo.text.replaceAll(',', '').trim());
      if (promo == null || promo <= 0 || promo >= price) {
        return s.createListingPromoMustBeLower;
      }
    }
    if (ListingTransactionTypes.hasSaleComponent(_listingType) &&
        _salePromoEnabled) {
      final full = _isDualListing
          ? double.tryParse(_salePrice.text.replaceAll(',', '').trim())
          : price;
      final promo = double.tryParse(_salePromo.text.replaceAll(',', '').trim());
      if (full == null ||
          full <= 0 ||
          promo == null ||
          promo <= 0 ||
          promo >= full) {
        return s.createListingPromoMustBeLower;
      }
    }
    return null;
  }

  String? _validationError(AppStrings s, PropertyCareOwnerDataInput input) {
    if (input.title.trim().length < 5) return s.careOwnerDataTitleTooShort;
    if (input.description.trim().length < 20) return s.careOwnerDataDescTooShort;
    if (input.bedrooms == null ||
        input.bedrooms! <= 0 ||
        input.bathrooms == null ||
        input.bathrooms! <= 0 ||
        input.areaSqm == null ||
        input.areaSqm! <= 0) {
      return s.careOwnerDataSpecsRequired;
    }
    if (!input.petPolicy.typesValidWhenAllowed) {
      return s.careOwnerDataPetTypesRequired;
    }
    if (input.priceNet <= 0) return s.careOwnerDataPriceRequired;
    if (_isDualListing &&
        (input.priceSaleNet == null || input.priceSaleNet! <= 0)) {
      return s.careOwnerDataSalePriceRequired;
    }
    if (!input.occupancy.isValidForListingType(_listingType)) {
      return s.careOwnerDataOccupancyDateRequired;
    }
    if (ListingOccupancyStatus.needsTenantRent(
      input.occupancy.status,
      _listingType,
    )) {
      final rent = input.occupancy.tenantMonthlyRent;
      if (rent == null || rent <= 0) return s.occupancyRentRequired;
    }
    return null;
  }

  String? _validateDetailsStep(AppStrings s) {
    if (_title.text.trim().length < 5) return s.careOwnerDataTitleTooShort;
    if (_desc.text.trim().length < 20) return s.careOwnerDataDescTooShort;
    final beds = int.tryParse(_beds.text.trim());
    final baths = int.tryParse(_baths.text.trim());
    final area = double.tryParse(_area.text.replaceAll(',', '').trim());
    if (beds == null ||
        beds <= 0 ||
        baths == null ||
        baths <= 0 ||
        area == null ||
        area <= 0) {
      return s.careOwnerDataSpecsRequired;
    }
    if (!_petPolicy.typesValidWhenAllowed) {
      return s.careOwnerDataPetTypesRequired;
    }
    if (ListingOccupancyStatus.needsAvailableDate(_occupancy.status) &&
        _occupancy.availableDate == null) {
      return s.careOwnerDataOccupancyDateRequired;
    }
    if (ListingOccupancyStatus.needsTenantRent(
      _occupancy.status,
      _listingType,
    )) {
      final rent = double.tryParse(_tenantRent.text.replaceAll(',', '').trim());
      if (rent == null || rent <= 0) return s.occupancyRentRequired;
    }
    return null;
  }

  void _setFormError(String? message) {
    setState(() => _formError = message);
  }

  void _translateFromThai(AppStrings s) {
    final thTitle = _title.text.trim();
    final thDesc = _desc.text.trim();
    if (thTitle.isEmpty && thDesc.isEmpty) {
      _setFormError(s.createListingTranslateNeedThai);
      return;
    }
    setState(() {
      _showEn = true;
      if (thTitle.isNotEmpty) {
        _titleEn.text = ListingDraftTranslate.titleEn(thTitle);
      }
      if (thDesc.isNotEmpty) {
        _descEn.text = ListingDraftTranslate.descriptionEn(
          thTitle,
          thDesc,
          hashtagIds: _hashtagIds.toList(),
          facilityIds: _facilityIds.toList(),
        );
      }
    });
  }

  void _next() {
    final s = AppStrings.of(context);
    _setFormError(null);
    if (_step == 1) {
      final err = _validateDetailsStep(s);
      if (err != null) {
        _setFormError(err);
        return;
      }
    }
    if (_step == 2) {
      final promoErr = _validatePromoPrices(s);
      if (promoErr != null) {
        _setFormError(promoErr);
        return;
      }
      final input = _buildInput();
      if (input == null) {
        _setFormError(s.careOwnerDataPriceRequired);
        return;
      }
      final err = _validationError(s, input);
      if (err != null) {
        _setFormError(err);
        return;
      }
    }
    if (_step < _stepCount - 1) setState(() => _step++);
  }

  void _back() {
    _setFormError(null);
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    _setFormError(null);
    final input = _buildInput();
    if (input == null) {
      _setFormError(s.careOwnerDataPriceRequired);
      return;
    }
    final err = _validationError(s, input);
    if (err != null) {
      _setFormError(err);
      return;
    }

    final leak = ListingContactGuard.containsLeak(input.description) ||
        ListingContactGuard.containsLeak(input.title) ||
        (input.descriptionEn != null &&
            ListingContactGuard.containsLeak(input.descriptionEn!));
    setState(() => _contactWarning = leak ? s.careOwnerDataContactLeakWarning : null);

    final listingId = widget.row['id']?.toString();
    final code = widget.row['listing_code']?.toString();
    if (listingId == null ||
        listingId.isEmpty ||
        code == null ||
        code.isEmpty) {
      _setFormError(s.careOwnerDataListingRefMissing);
      return;
    }

    setState(() => _busy = true);
    try {
      final titleReview = await _repo.submitListingOwnerData(
        inventoryId: widget.inventoryId,
        inventoryCode: widget.inventoryCode,
        listingId: listingId,
        listingCode: code,
        listingType: _listingType,
        propertyType: _propertySlug,
        input: input,
        isEnglish: s.isEnglish,
        titleChanged: _titleChanged,
        currentStatus: widget.row['status']?.toString(),
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        PropertyCareOwnerDataResult(
          saved: true,
          titleSentForReview: titleReview,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _setFormError('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;
    final code = widget.row['listing_code']?.toString() ?? '';

    return SizedBox(
      height: maxH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit
                      ? s.careOwnerDataFormEditTitle
                      : s.careOwnerDataFormTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEdit
                      ? s.careOwnerDataEditIntro
                      : s.careOwnerDataFirstIntro,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 10),
                _StepBar(step: _step, labels: [
                  s.careOwnerDataStepOverview,
                  s.careOwnerDataStepDetails,
                  s.careOwnerDataStepConfirm,
                  s.careOwnerDataStepPreview,
                ]),
              ],
            ),
          ),
          Expanded(
            child: _step == 3
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: _previewStep(s),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: _step == 0
                        ? _overviewStep(s, code)
                        : _step == 1
                            ? _detailsStep(s)
                            : _confirmStep(s),
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_contactWarning != null) ...[
                  _infoBox(_contactWarning!, color: AppTheme.accentAmberLight),
                  const SizedBox(height: 8),
                ],
                if (_formError != null) ...[
                  _errorBox(_formError!),
                  const SizedBox(height: 8),
                ],
                if (_busy) const LinearProgressIndicator(),
                Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _back,
                          child: Text(s.createListingBack),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _busy
                            ? null
                            : (_step < _stepCount - 1 ? _next : _submit),
                        child: Text(
                          _step < _stepCount - 1
                              ? s.createListingNext
                              : (widget.isEdit
                                  ? s.careOwnerDataFormSaveEdit
                                  : s.careOwnerDataFormSubmit),
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: Text(s.cancel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewStep(AppStrings s, String code) {
    final displayTitle = PropertyCareOwnerDataInput.displayTitle(widget.row);
    final displayDesc = PropertyCareOwnerDataInput.displayDescription(widget.row);
    final project = widget.row['project_name']?.toString();
    final district = widget.row['district']?.toString();
    final cover = OwnerListingMedia.coverUrl(widget.row);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(code, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        _sectionTitle(s.careOwnerDataAdminBlockTitle),
        const SizedBox(height: 6),
        Text(
          s.careOwnerDataAdminBlockHint,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cover != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(cover, width: 72, height: 54, fit: BoxFit.cover),
                ),
              if (cover != null) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    if (project != null || district != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [project, district].whereType<String>().join(' · '),
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                    if (displayDesc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        displayDesc.length > 160
                            ? '${displayDesc.substring(0, 160)}…'
                            : displayDesc,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _infoBox(s.careOwnerDataOverviewHint),
      ],
    );
  }

  Widget _listingIntentSection(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(s.createListingIntentLabel),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final code in ListingTransactionTypes.createFormOrder)
              ChoiceChip(
                label: Text(s.listingTransactionLabel(code)),
                selected: _listingType == code,
                onSelected: (_) => _onListingTypeChanged(code),
              ),
          ],
        ),
        if (_isDualListing) ...[
          const SizedBox(height: 8),
          _infoBox(s.createListingRentAndSaleHint),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _detailsStep(AppStrings s) {
    final descLen = _desc.text.trim().length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _listingIntentSection(s),
        TextField(
          controller: _title,
          decoration: InputDecoration(
            labelText: s.careOwnerDataTitleLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_titleChanged) ...[
          const SizedBox(height: 8),
          _infoBox(s.careOwnerDataTitleReviewWarning),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _desc,
          minLines: 4,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: '${s.descriptionLabel} *',
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
            helperText: s.careOwnerDataDescCounter(descLen),
            helperStyle: TextStyle(
              color: descLen >= 20 ? AppTheme.primary : AppTheme.accentDeep,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.createListingDescLangEn),
          value: _showEn,
          onChanged: (v) => setState(() => _showEn = v),
        ),
        if (_showEn) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _translateFromThai(s),
              icon: const Icon(Icons.translate, size: 18),
              label: Text(s.createListingAutoTranslate),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleEn,
            decoration: InputDecoration(
              labelText: s.createListingTitleEnLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descEn,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: s.createListingDescEnLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _beds,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${s.bedroomsFieldLabel} *',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _baths,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${s.t('ห้องน้ำ', 'Bathrooms')} *',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _area,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${s.areaSqmLabel} *',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _floor,
                decoration: InputDecoration(
                  labelText: s.careOwnerDataFloorLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListingPetPolicySection(
          value: _petPolicy,
          maxWeightController: _petMaxWeight,
          maxCountController: _petMaxCount,
          onChanged: (v) => setState(() => _petPolicy = v),
        ),
        const SizedBox(height: 16),
        Text(s.createListingHashtagsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        ListingHashtagPicker(
          selectedIds: _hashtagIds,
          listingType: _listingType,
          propertyType: _propertySlug,
          onChanged: (v) => setState(() {
            _hashtagIds
              ..clear()
              ..addAll(v);
          }),
        ),
        const SizedBox(height: 12),
        Text(s.createListingFacilitiesTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in ListingFormOptions.facilities)
              FilterChip(
                label: Text(f.label(s.isEnglish)),
                selected: _facilityIds.contains(f.id),
                onSelected: (v) => setState(() {
                  if (v) {
                    _facilityIds.add(f.id);
                  } else {
                    _facilityIds.remove(f.id);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ownerNote,
          minLines: 2,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: s.myNoteLabel,
            hintText: s.myNoteHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ListingOccupancySection(
          listingType: _listingType,
          propertySlug: _propertySlug,
          value: _occupancy,
          salePrice: _isDualListing
              ? double.tryParse(_salePrice.text.replaceAll(',', ''))
              : (ListingTransactionTypes.hasSaleComponent(_listingType)
                  ? double.tryParse(_price.text.replaceAll(',', ''))
                  : null),
          tenantRentController: _tenantRent,
          onChanged: (v) => setState(() => _occupancy = v),
        ),
        const SizedBox(height: 16),
        ListingViewingAccessSection(
          value: _viewingAccess,
          onChanged: (v) => setState(() => _viewingAccess = v),
          noteController: _viewingNote,
        ),
      ],
    );
  }

  Widget _previewStep(AppStrings s) {
    final input = _buildInput();
    if (input == null) {
      return Center(
        child: Text(
          s.careOwnerDataValidationError,
          style: TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }
    return PropertyCareListingPreviewPanel(
      row: widget.row,
      input: input,
      isEnglish: s.isEnglish,
      listingType: _listingType,
    );
  }

  Widget _confirmStep(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_titleChanged) ...[
          _infoBox(s.careOwnerDataTitleReviewWarning),
          const SizedBox(height: 12),
        ],
        ListingPriceFormSection(
          listingType: _listingType,
          rentPriceController: _price,
          salePriceController: _salePrice,
          rentPromoController: _rentPromo,
          salePromoController: _salePromo,
          rentPromoEnabled: _rentPromoEnabled,
          salePromoEnabled: _salePromoEnabled,
          onRentPromoEnabled: (v) => setState(() => _rentPromoEnabled = v),
          onSalePromoEnabled: (v) => setState(() => _salePromoEnabled = v),
          onChanged: () => setState(() {}),
          inputBorder: const OutlineInputBorder(),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15));

  Widget _errorBox(String text) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.accentDeep.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.accentDeep.withOpacity(0.35)),
        ),
        child: Text(text,
            style: TextStyle(
              color: AppTheme.accentDeep,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            )),
      );

  Widget _infoBox(String text, {Color? color}) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryLight).withOpacity(0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, height: 1.35)),
      );
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.labels});

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= step
                    ? AppTheme.primary
                    : AppTheme.textSecondary.withOpacity(0.2),
              ),
            ),
          Column(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: i <= step
                    ? AppTheme.primary
                    : AppTheme.textSecondary.withOpacity(0.25),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: i <= step ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: i == step ? FontWeight.w700 : FontWeight.w500,
                  color: i == step ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
