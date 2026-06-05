import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/create_listing_wizard_config.dart';
import '../../config/env.dart';
import '../../data/bangkok_projects.dart';
import '../../data/listing_form_options.dart';
import '../../data/property_catalog.dart';
import '../../models/listing_transaction_types.dart';
import '../../l10n/app_strings.dart';
import '../../models/listing_create_rules.dart';
import '../../models/listing_exclusive_options.dart';
import '../../models/listing_occupancy.dart';
import '../../widgets/listing_occupancy_section.dart';
import '../../models/offer_commission_scheme.dart';
import '../../navigation/post_listing_navigation.dart';
import '../../services/auth_service.dart';
import '../../services/listing_create_repository.dart';
import '../../services/platform_settings_service.dart';
import 'owner_exclusive_terms_sheet.dart';
import '../../services/listing_notes_service.dart';
import '../../services/moderation_service.dart';
import '../../services/project_catalog.dart';
import '../../services/storage_service.dart';
import '../../state/user_role_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading_overlay.dart';
import '../../utils/listing_draft_translate.dart';
import '../../widgets/legal_policy_rich_text.dart';
import '../../widgets/listing_viewing_access_section.dart';
import '../../models/listing_viewing_access.dart';
import '../../widgets/project_picker_field.dart';
import '../../utils/legal_navigation.dart';

/// สร้างประกาศ — wizard อ้างอิง LI (เจ้าของ/เอเจนท์ · ลิงก์แผนที่เมื่อนอกโครงการ)
class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _createRepo = ListingCreateRepository();
  final _storage = StorageService();
  final _moderation = ModerationService();

  int _step = 0;
  bool _busy = false;

  ListingPosterRole _posterRole = ListingPosterRole.owner;
  String _listingType = 'rent';
  String _propertySlug = 'house';
  ListingLocationScope _locationScope = ListingLocationScope.catalogProject;

  BangkokProject? _selectedProject;
  bool _customProject = false;
  bool _standalone = false;

  final _customProjectName = TextEditingController();
  final _districtArea = TextEditingController();
  final _locationLink = TextEditingController();
  final _locationLinkFocus = FocusNode();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _propertyCode = TextEditingController();
  final _price = TextEditingController();
  final _promoPrice = TextEditingController();
  final _area = TextEditingController();
  final _bedrooms = TextEditingController();
  final _bathrooms = TextEditingController();
  final _floor = TextEditingController();
  final _videoUrl = TextEditingController();
  final _tiktok = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _lineId = TextEditingController();
  final _titleEn = TextEditingController();
  final _descEn = TextEditingController();
  final _titleZh = TextEditingController();
  final _descZh = TextEditingController();
  final _myNote = TextEditingController();
  final _commissionOther = TextEditingController();
  final _netReceive = TextEditingController();
  final _brokerCommissionPct = TextEditingController();
  final _transferOther = TextEditingController();
  final _leaseMonths = TextEditingController(text: '12');

  String? _commissionScheme;
  String? _transferTerms;
  bool _promoEnabled = false;
  bool _acceptedPublishPolicy = false;
  bool _ownerExclusiveInterest = false;
  int _ownerExclusiveContractDays = 30;
  bool _agentExclusive = false;
  ListingViewingAccess _viewingAccess = const ListingViewingAccess();
  final _viewingAccessNote = TextEditingController();
  ListingOccupancyInput _occupancy = const ListingOccupancyInput();
  final _tenantRent = TextEditingController();
  final Set<String> _listingLangs = {'th'};
  List<XFile> _images = [];
  final Set<String> _hashtagIds = {};
  final Set<String> _facilityIds = {};

  static const _inputBorder = OutlineInputBorder();
  static const _stepCount = CreateListingWizardConfig.stepCount;

  String get _propertyTypeDb =>
      PropertyCatalog.dbValueForSlug(_propertySlug) ?? _propertySlug;

  bool get _isAgentPoster => _posterRole == ListingPosterRole.agent;

  bool get _isSaleListing => OfferCommissionScheme.isSaleListing(_listingType);

  void _syncListedPriceFromNetCommission() {
    if (!mounted) return;
    if (!OfferCommissionScheme.isNetSelfAdd(_commissionScheme) || _isAgentPoster) {
      return;
    }
    final net = double.tryParse(_netReceive.text.replaceAll(',', ''));
    final pct = double.tryParse(_brokerCommissionPct.text.replaceAll(',', ''));
    if (net == null || net <= 0 || pct == null || pct < 0) return;
    final listed = net * (1 + pct / 100);
    final next = listed.toStringAsFixed(0);
    if (_price.text != next) {
      _price.text = next;
    }
    setState(() {});
  }

  double? _listedPriceForSubmit() {
    final raw = double.tryParse(_price.text.replaceAll(',', ''));
    if (raw != null && raw > 0) return raw;
    if (!OfferCommissionScheme.isNetSelfAdd(_commissionScheme) || _isAgentPoster) {
      return null;
    }
    final net = double.tryParse(_netReceive.text.replaceAll(',', ''));
    final pct = double.tryParse(_brokerCommissionPct.text.replaceAll(',', ''));
    if (net == null || net <= 0 || pct == null || pct < 0) return null;
    return net * (1 + pct / 100);
  }

  void _syncCommissionScheme() {
    final options = OfferCommissionScheme.optionsForListing(
      listingType: _listingType,
      isAgentPoster: _isAgentPoster,
    );
    if (_commissionScheme == null || !options.contains(_commissionScheme)) {
      _commissionScheme = options.isNotEmpty ? options.first : null;
    }
    if (!_isSaleListing) _transferTerms = null;
  }

  bool get _requiresLocationLink => ListingCreateRules.requiresLocationLink(
        scope: _locationScope,
        propertyTypeDb: _propertyTypeDb,
      );

  @override
  void initState() {
    super.initState();
    _posterRole = ListingCreateRules.defaultPosterRole(
      widget.roleController.isAgent,
    );
    final trialName = AuthService.instance.trialDisplayName;
    if (trialName != null && trialName.isNotEmpty) {
      _contactName.text = trialName;
    }
    ProjectCatalog.instance.load();
    PlatformSettingsService.instance.load();
    _ownerExclusiveContractDays =
        ListingExclusiveOptions.defaultContractDays(_listingType);
    _netReceive.addListener(_syncListedPriceFromNetCommission);
    _brokerCommissionPct.addListener(_syncListedPriceFromNetCommission);
    _syncCommissionScheme();
    void onPriceChanged() {
      if (mounted) setState(() {});
    }
    _price.addListener(onPriceChanged);
    _promoPrice.addListener(onPriceChanged);
  }

  @override
  void dispose() {
    _customProjectName.dispose();
    _districtArea.dispose();
    _locationLink.dispose();
    _locationLinkFocus.dispose();
    _title.dispose();
    _desc.dispose();
    _propertyCode.dispose();
    _price.dispose();
    _promoPrice.dispose();
    _area.dispose();
    _bedrooms.dispose();
    _bathrooms.dispose();
    _floor.dispose();
    _videoUrl.dispose();
    _tiktok.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _lineId.dispose();
    _titleEn.dispose();
    _descEn.dispose();
    _titleZh.dispose();
    _descZh.dispose();
    _myNote.dispose();
    _commissionOther.dispose();
    _netReceive.dispose();
    _brokerCommissionPct.dispose();
    _transferOther.dispose();
    _leaseMonths.dispose();
    _viewingAccessNote.dispose();
    _tenantRent.dispose();
    super.dispose();
  }

  void _syncLocationScope() {
    if (_selectedProject != null) {
      _locationScope = ListingLocationScope.catalogProject;
      _customProject = false;
      _standalone = false;
    } else if (_standalone) {
      _locationScope = ListingLocationScope.standalone;
      _customProject = false;
    } else if (_customProject) {
      _locationScope = ListingLocationScope.customProject;
      _standalone = false;
    }
  }

  void _onProjectSelected(BangkokProject project) {
    setState(() {
      _selectedProject = project;
      _customProject = false;
      _standalone = false;
      _propertySlug = project.propertyType;
      if (_title.text.trim().isEmpty) _title.text = project.nameTh;
      if (_districtArea.text.trim().isEmpty) _districtArea.text = project.district;
      _syncLocationScope();
    });
  }

  void _clearProject() {
    setState(() {
      _selectedProject = null;
      _customProject = false;
      _standalone = false;
      _locationScope = ListingLocationScope.catalogProject;
    });
  }

  String? _projectNameForSubmit() {
    if (_selectedProject != null) return _selectedProject!.nameTh;
    if (_standalone) return null;
    if (_customProject) return _customProjectName.text.trim();
    return null;
  }

  String _districtForSubmit() {
    if (_selectedProject != null) return _selectedProject!.district;
    final area = _districtArea.text.trim();
    if (area.isNotEmpty) return area;
    final custom = _customProjectName.text.trim();
    return custom.isEmpty ? 'กรุงเทพฯ' : custom;
  }

  Future<void> _pickImages() async {
    final files = await _storage.pickImages();
    setState(() => _images = files);
  }

  bool get _isRentListing => _listingType == 'rent';

  String _primaryPriceLabel(AppStrings s) =>
      _isRentListing ? s.createListingRentPriceLabel : s.createListingSalePriceLabel;

  void _translateFromThai(AppStrings s) {
    final thTitle = _title.text.trim();
    final thDesc = _desc.text.trim();
    if (thTitle.isEmpty || thDesc.isEmpty) {
      _snack(s.createListingTranslateNeedThai);
      return;
    }
    setState(() {
      if (_listingLangs.contains('en')) {
        _titleEn.text = ListingDraftTranslate.titleEn(thTitle);
        _descEn.text = ListingDraftTranslate.descriptionEn(thTitle, thDesc);
      }
      if (_listingLangs.contains('zh')) {
        _titleZh.text = ListingDraftTranslate.titleZh(thTitle);
        _descZh.text = ListingDraftTranslate.descriptionZh(thTitle, thDesc);
      }
    });
  }

  void _toggleListingLang(String lang, bool selected) {
    if (lang == 'th') return;
    setState(() {
      if (selected) {
        _listingLangs.add(lang);
      } else {
        _listingLangs.remove(lang);
        if (lang == 'en') {
          _titleEn.clear();
          _descEn.clear();
        } else if (lang == 'zh') {
          _titleZh.clear();
          _descZh.clear();
        }
      }
    });
  }

  Future<void> _openLocationLink(AppStrings s) async {
    final raw = _locationLink.text.trim();
    if (raw.isEmpty) {
      _snack(s.createListingLocationLinkRequired);
      return;
    }
    if (!ListingCreateRules.isValidLocationUrl(raw)) {
      _snack(s.createListingMapLinkInvalid);
      return;
    }
    final uri = Uri.parse(raw);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack(s.createListingMapLinkInvalid);
    }
  }

  Widget? _promoPreviewCard(AppStrings s) {
    if (!_promoEnabled) return null;
    final main = double.tryParse(_price.text.replaceAll(',', ''));
    final promo = double.tryParse(_promoPrice.text.replaceAll(',', ''));
    if (main == null || main <= 0 || promo == null || promo <= 0 || promo >= main) {
      return null;
    }
    final fmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    final suffix = _listingType == 'rent' ? s.perMonth : '';
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: AppTheme.primaryLight.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.createListingPromoPreviewTitle,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '${fmt.format(main)}$suffix',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            Text(
              '${fmt.format(promo)}$suffix',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.accentDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateStep(AppStrings s) {
    switch (_step) {
      case 0:
        return true;
      case 1:
        _syncLocationScope();
        if (_locationScope == ListingLocationScope.catalogProject &&
            _selectedProject == null) {
          _snack(s.projectRequired);
          return false;
        }
        if (_customProject && _customProjectName.text.trim().isEmpty) {
          _snack(s.t('ระบุชื่อโครงการหรือทำเล', 'Enter project or area'));
          return false;
        }
        if (_standalone && _districtArea.text.trim().isEmpty) {
          _snack(s.districtLabel);
          return false;
        }
        if (_requiresLocationLink) {
          if (_locationLink.text.trim().isEmpty) {
            _snack(s.createListingLocationLinkRequired);
            return false;
          }
          if (!ListingCreateRules.isValidLocationUrl(_locationLink.text)) {
            _snack(s.createListingLocationLinkInvalid);
            return false;
          }
        }
        return true;
      case 2:
        if (_title.text.trim().isEmpty) {
          _snack(s.listingTitleRequired);
          return false;
        }
        if (_desc.text.trim().isEmpty) {
          _snack(s.t('กรอกรายละเอียด', 'Enter description'));
          return false;
        }
        if (_hashtagIds.isEmpty) {
          _snack(s.createListingHashtagsHint);
          return false;
        }
        if (_contactName.text.trim().isEmpty) {
          _snack(s.offerValidationContactName);
          return false;
        }
        if (_contactPhone.text.trim().isEmpty) {
          _snack(s.offerValidationContactPhone);
          return false;
        }
        if (ListingOccupancyStatus.needsAvailableDate(_occupancy.status) &&
            _occupancy.availableDate == null) {
          _snack(s.occupancyDateRequired);
          return false;
        }
        if (ListingOccupancyStatus.needsTenantRent(
          _occupancy.status,
          _listingType,
        )) {
          final rent = double.tryParse(_tenantRent.text.replaceAll(',', ''));
          if (rent == null || rent <= 0) {
            _snack(s.occupancyRentRequired);
            return false;
          }
        }
        if (_listingLangs.contains('en')) {
          if (_titleEn.text.trim().isEmpty || _descEn.text.trim().isEmpty) {
            _snack(s.t(
              'กรอกหรือกดแปลภาษาอังกฤษให้ครบ',
              'Complete English title & description (or translate)',
            ));
            return false;
          }
        }
        if (_listingLangs.contains('zh')) {
          if (_titleZh.text.trim().isEmpty || _descZh.text.trim().isEmpty) {
            _snack(s.t(
              'กรอกหรือกดแปลภาษาจีนให้ครบ',
              'Complete Chinese title & description (or translate)',
            ));
            return false;
          }
        }
        return true;
      case 3:
        return true;
      case 4:
        final price = double.tryParse(_price.text.replaceAll(',', ''));
        if (price == null || price <= 0) {
          _snack(s.titlePriceRequired);
          return false;
        }
        if (_promoEnabled) {
          final promo = double.tryParse(_promoPrice.text.replaceAll(',', ''));
          if (promo == null || promo <= 0 || promo >= price) {
            _snack(s.t('ราคาโปรโมชั่นต้องต่ำกว่าราคาหลัก', 'Promo must be below main price'));
            return false;
          }
        }
        if (_commissionScheme == null) {
          _snack(s.offerValidationCommission);
          return false;
        }
        if (OfferCommissionScheme.requiresNote(_commissionScheme!)) {
          if (_commissionOther.text.trim().isEmpty) {
            _snack(s.offerValidationCommissionOther);
            return false;
          }
        }
        if (OfferCommissionScheme.isNetSelfAdd(_commissionScheme)) {
          final net = double.tryParse(_netReceive.text.replaceAll(',', ''));
          if (net == null || net <= 0) {
            _snack(s.createListingNetReceiveRequired);
            return false;
          }
          if (!_isAgentPoster) {
            final pct = double.tryParse(_brokerCommissionPct.text.replaceAll(',', ''));
            if (pct == null || pct < 0) {
              _snack(s.createListingBrokerCommissionRequired);
              return false;
            }
            final listed = _listedPriceForSubmit();
            if (listed == null || listed <= 0) {
              _snack(s.titlePriceRequired);
              return false;
            }
          }
        }
        if (_isSaleListing) {
          if (_transferTerms == null) {
            _snack(s.offerValidationTransfer);
            return false;
          }
          if (_transferTerms == 'other' && _transferOther.text.trim().isEmpty) {
            _snack(s.offerTransferOtherHint);
            return false;
          }
        }
        if (!_acceptedPublishPolicy) {
          _snack(s.createListingPublishTermsRequired);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Map<String, String> _buildSummary(AppStrings s) {
    final price = double.tryParse(_price.text.replaceAll(',', ''));
    final summary = <String, String>{
      s.createListingPosterLabel.replaceAll(' *', ''):
          _posterRole == ListingPosterRole.owner
              ? s.createListingPosterOwner
              : s.createListingPosterAgent,
      s.createListingIntentLabel.replaceAll(' *', ''):
          s.listingTransactionLabel(_listingType),
      s.propertyTypeLabel:
          PropertyCatalog.bySlug(_propertySlug)?.label(s.isEnglish) ?? _propertySlug,
      s.listingTitleRequired.replaceAll(' *', ''): _title.text.trim(),
    };
    final project = _projectNameForSubmit();
    if (project != null && project.isNotEmpty) {
      summary[s.projectPickerLabel.replaceAll(' *', '')] = project;
    } else if (_standalone) {
      summary[s.projectPickerLabel.replaceAll(' *', '')] = s.createListingNoProject;
    }
    summary[s.districtLabel] = _districtForSubmit();
    if (_requiresLocationLink && _locationLink.text.trim().isNotEmpty) {
      summary[s.createListingLocationLinkLabel.replaceAll(' *', '')] =
          _locationLink.text.trim();
    }
    if (price != null) {
      summary[_primaryPriceLabel(s).replaceAll(' *', '')] =
          '฿${price.toStringAsFixed(0)}';
      if (_promoEnabled) {
        final promo = double.tryParse(_promoPrice.text.replaceAll(',', ''));
        if (promo != null) {
          summary[s.t('ราคาโปรโมชั่น', 'Promo price')] = '฿${promo.toStringAsFixed(0)}';
        }
      }
    }
    if (_commissionScheme != null) {
      summary[s.createListingCommissionTitle.replaceAll(' *', '')] =
          s.offerCommissionSchemeLabel(_commissionScheme!);
      if (OfferCommissionScheme.isNetSelfAdd(_commissionScheme)) {
        summary[s.createListingNetReceiveLabel.replaceAll(' *', '')] =
            _netReceive.text.trim();
        if (!_isAgentPoster && _brokerCommissionPct.text.trim().isNotEmpty) {
          summary[s.createListingBrokerCommissionLabel.replaceAll(' *', '')] =
              '${_brokerCommissionPct.text.trim()}%';
        }
      }
      if (_isSaleListing && _transferTerms != null) {
        summary[s.offerTransferLabel.replaceAll(' *', '')] = _transferTermsLabel(s);
      }
    }
    summary[s.occupancySectionTitle] =
        _occupancy.summary(s, _propertySlug);
    if (_images.isNotEmpty) {
      summary[s.propertyPhotos] = s.pickPhotos(_images.length);
    }
    return summary;
  }

  Future<bool> _showConfirmDialog(Map<String, String> summary) async {
    final s = AppStrings.of(context);
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(s.createListingConfirmTitle),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.createListingConfirmIntro,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final e in summary.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              e.key,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(fontSize: 13, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.createListingConfirmEdit),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.createListingConfirmSubmit),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _next() async {
    final s = AppStrings.of(context);
    if (!_validateStep(s)) return;
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      return;
    }
    final confirmed = await _showConfirmDialog(_buildSummary(s));
    if (!confirmed || !mounted) return;
    await _submit(publish: true);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit({required bool publish}) async {
    final s = AppStrings.of(context);
    if (!_validateStep(s)) return;

    if (!AuthService.instance.isSignedIn) {
      _snack(s.configuredNotLoggedIn);
      context.push('/login');
      return;
    }

    setState(() => _busy = true);
    try {
      await AppLoadingOverlay.run(context, () async {
        var description = _desc.text.trim();
        final tagsBlock = ListingFormOptions.formatTagsSection(
          _hashtagIds.toList(),
          _facilityIds.toList(),
          isEnglish: s.isEnglish,
        );
        if (tagsBlock.isNotEmpty) {
          description = description.isEmpty ? tagsBlock : '$description\n$tagsBlock';
        }
        if (_propertyCode.text.trim().isNotEmpty) {
          description =
              '${description.isEmpty ? '' : '$description\n'}${s.t('รหัสทรัพย์', 'Property ID')}: ${_propertyCode.text.trim()}';
        }
        description =
            '${description.isEmpty ? '' : '$description\n'}${s.offerContactNameField}: ${_contactName.text.trim()}';
        description = '$description\n${s.offerContactPhoneField}: ${_contactPhone.text.trim()}';
        if (_lineId.text.trim().isNotEmpty) {
          description =
              '$description\n${s.createListingLineIdLabel.replaceAll(' (ถ้ามี)', '').replaceAll(' (optional)', '')}: ${_lineId.text.trim()}';
        }

        final project = _selectedProject;
        final coType =
            _isAgentPoster ? 'co_agent_50_50' : 'owner_direct';
        final scheme = _commissionScheme!;
        final commissionNote = OfferCommissionScheme.requiresNote(scheme)
            ? _commissionOther.text.trim()
            : null;
        final listedPrice = _listedPriceForSubmit();
        if (listedPrice == null) {
          throw Exception(s.titlePriceRequired);
        }
        final brokerPct = (!_isAgentPoster &&
                OfferCommissionScheme.isNetSelfAdd(scheme))
            ? double.tryParse(_brokerCommissionPct.text.replaceAll(',', ''))
            : null;

        final id = await _createRepo.createDraft(
          ListingCreateInput(
            title: _title.text.trim(),
            listingType: _listingType,
            propertyType: _propertyTypeDb,
            priceNet: listedPrice,
            district: _districtForSubmit(),
            posterRole: _posterRole,
            description: description,
            areaSqm: double.tryParse(_area.text),
            bedrooms: int.tryParse(_bedrooms.text),
            bathrooms: int.tryParse(_bathrooms.text),
            floorRange: _floor.text.trim().isEmpty ? null : _floor.text.trim(),
            coAgentListingType: coType,
            promoPriceNet: _promoEnabled
                ? double.tryParse(_promoPrice.text.replaceAll(',', ''))
                : null,
            videoUrl: _videoUrl.text.trim().isEmpty ? null : _videoUrl.text.trim(),
            tiktokUrl: _tiktok.text.trim().isEmpty ? null : _tiktok.text.trim(),
            locationLink:
                _requiresLocationLink ? _locationLink.text.trim() : null,
            projectId: project?.id,
            projectName: _projectNameForSubmit(),
            projectSlug: project?.slug,
            geoZoneId: project?.geoZoneId,
            lat: project?.lat,
            lng: project?.lng,
            btsStation: project?.bts,
            acceptCoAgent: true,
            commissionScheme: scheme,
            commissionNote: commissionNote,
            netReceiveTarget: OfferCommissionScheme.isNetSelfAdd(scheme)
                ? double.tryParse(_netReceive.text.replaceAll(',', ''))
                : null,
            brokerCommissionPercent: brokerPct,
            transferTerms: _isSaleListing ? _transferTermsLabel(s) : null,
            leaseMonths: int.tryParse(_leaseMonths.text) ?? 12,
            petAllowed: _hashtagIds.contains('pet_friendly'),
            lineId: _lineId.text.trim().isEmpty ? null : _lineId.text.trim(),
            listingLanguages: _listingLangs.toList()..sort(),
            titleEn: _listingLangs.contains('en') ? _titleEn.text.trim() : null,
            descriptionEn:
                _listingLangs.contains('en') ? _descEn.text.trim() : null,
            titleZh: _listingLangs.contains('zh') ? _titleZh.text.trim() : null,
            descriptionZh:
                _listingLangs.contains('zh') ? _descZh.text.trim() : null,
            policyAccepted: _acceptedPublishPolicy,
            ownerExclusiveMandate: _ownerExclusiveInterest,
            ownerExclusiveContractDays:
                _ownerExclusiveInterest ? _ownerExclusiveContractDays : null,
            agentExclusive: _agentExclusive && _isAgentPoster,
            viewingAccess: _viewingAccess.copyWith(note: _viewingAccessNote.text),
            occupancy: _occupancy.copyWith(
              tenantMonthlyRent: double.tryParse(
                _tenantRent.text.replaceAll(',', ''),
              ),
            ),
          ),
        );

        if (_images.isNotEmpty && !AuthService.instance.trialSimulatesBackend) {
          await _storage.uploadListingImages(listingId: id, files: _images);
        }

        if (publish) {
          final mod = await _moderation.checkText('${_title.text} $description');
          if (!mod.allowed) {
            throw Exception(mod.message ??
                s.t(
                  'พบข้อมูลติดต่อหรือลิงก์นอกระบบ — แก้ก่อนส่ง',
                  'Contact or external links detected — fix before submit',
                ));
          }
          await _createRepo.submitForReview(id);
        }

        final note = _myNote.text.trim();
        if (note.isNotEmpty) {
          await ListingNotesService.instance.setNote(id, note);
        }

        if (!mounted) return;
        final trial = AuthService.instance.trialSimulatesBackend;
        if (publish) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              icon: Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 48),
              title: Text(s.createListingSubmittedTitle, textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.createListingSubmittedBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
                  ),
                  if (_ownerExclusiveInterest) ...[
                    const SizedBox(height: 12),
                    Text(
                      s.ownerExclusiveSubmitted,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.pop();
                    PostListingNavigation.openMyListings(context);
                  },
                  child: Text(s.createListingGoToMine),
                ),
              ],
            ),
          );
          return;
        }
        if (trial) {
          _snack(AuthService.trialWriteHint);
        } else {
          _snack(s.listingDraftSaved);
        }
        context.pop();
      });
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEnglish = s.isEnglish;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _busy ? null : () => context.pop(),
        ),
        title: Text(s.createListingTitle),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => _submit(publish: false),
            child: Text(s.createListingSaveDraft),
          ),
        ],
      ),
      body: Column(
        children: [
          _ProgressBar(step: _step, total: _stepCount),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                CreateListingWizardConfig.stepTitle(_step, isEnglish),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_step == 4) ...[
                  Text(
                    s.createListingPriceHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ..._stepBody(s),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _back,
                        child: Text(s.createListingBack),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _busy ? null : _next,
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _step == _stepCount - 1 ? s.publish : s.createListingNext,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _stepBody(AppStrings s) {
    switch (_step) {
      case 0:
        return _stepPoster(s);
      case 1:
        return _stepLocation(s);
      case 2:
        return _stepDetails(s);
      case 3:
        return _stepMedia(s);
      case 4:
        return _stepPrice(s);
      default:
        return [];
    }
  }

  List<Widget> _stepPoster(AppStrings s) {
    return [
      Text(s.createListingPosterLabel, style: _labelStyle),
      const SizedBox(height: 8),
      SegmentedButton<ListingPosterRole>(
        segments: [
          ButtonSegment(value: ListingPosterRole.owner, label: Text(s.createListingPosterOwner)),
          ButtonSegment(value: ListingPosterRole.agent, label: Text(s.createListingPosterAgent)),
        ],
        selected: {_posterRole},
        onSelectionChanged: (v) => setState(() {
          _posterRole = v.first;
          if (_isAgentPoster) {
            _ownerExclusiveInterest = false;
          } else {
            _agentExclusive = false;
          }
          _syncCommissionScheme();
        }),
      ),
      const SizedBox(height: 8),
      _infoBox(
        _posterRole == ListingPosterRole.owner
            ? s.createListingPosterOwnerHint
            : s.createListingPosterAgentHint,
      ),
      const SizedBox(height: 24),
      Text(s.createListingIntentLabel, style: _labelStyle),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final code in ListingTransactionTypes.createFormOrder)
            ChoiceChip(
              label: Text(s.listingTransactionLabel(code)),
              selected: _listingType == code,
              onSelected: (_) => setState(() {
                _listingType = code;
                final opts = ListingExclusiveOptions.contractDaysFor(code);
                if (!opts.contains(_ownerExclusiveContractDays)) {
                  _ownerExclusiveContractDays =
                      ListingExclusiveOptions.defaultContractDays(code);
                }
                final occOpts = ListingOccupancyStatus.optionsFor(code);
                if (!occOpts.contains(_occupancy.status)) {
                  _occupancy = const ListingOccupancyInput();
                  _tenantRent.clear();
                }
                _syncCommissionScheme();
              }),
            ),
        ],
      ),
      if (_isAgentPoster) ...[
        const SizedBox(height: 20),
        _agentExclusiveBlock(s),
      ],
      const SizedBox(height: 20),
      Text(s.propertyTypeLabel, style: _labelStyle),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final cat in PropertyCatalog.categories)
            ChoiceChip(
              label: Text(cat.label(s.isEnglish)),
              selected: _propertySlug == cat.slug,
              onSelected: (_) => setState(() => _propertySlug = cat.slug),
            ),
        ],
      ),
    ];
  }

  List<Widget> _stepLocation(AppStrings s) {
    return [
      ProjectPickerField(
        selected: _selectedProject,
        customMode: _customProject,
        standaloneMode: _standalone,
        onProjectSelected: _onProjectSelected,
        onEnableCustom: () => setState(() {
          _customProject = true;
          _standalone = false;
          _selectedProject = null;
          _syncLocationScope();
        }),
        onNoProject: () => setState(() {
          _standalone = true;
          _customProject = false;
          _selectedProject = null;
          if (_propertySlug == 'condo') _propertySlug = 'house';
          _syncLocationScope();
        }),
        onClear: _clearProject,
      ),
      if (_customProject) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _customProjectName,
          decoration: InputDecoration(
            labelText: s.t('ชื่อโครงการหรือทำเล', 'Project or area name'),
            border: _inputBorder,
          ),
        ),
      ],
      if (_standalone || _customProject || _selectedProject == null) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _districtArea,
          decoration: InputDecoration(
            labelText: '${s.districtLabel} *',
            border: _inputBorder,
          ),
        ),
      ],
      const SizedBox(height: 16),
      if (!_requiresLocationLink)
        _infoBox(s.createListingCatalogNoLink)
      else ...[
        TextField(
          controller: _locationLink,
          focusNode: _locationLinkFocus,
          decoration: InputDecoration(
            labelText: s.createListingLocationLinkLabel,
            hintText: s.createListingLocationLinkHint,
            prefixIcon: const Icon(Icons.map_outlined),
            border: _inputBorder,
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openLocationLink(s),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(s.createListingOpenMapLink),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _locationLinkFocus.requestFocus(),
                icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                label: Text(s.createListingEditMapLink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          s.createListingLocationLinkRequired,
          style: TextStyle(fontSize: 12, color: AppTheme.error),
        ),
      ],
    ];
  }

  List<Widget> _stepDetails(AppStrings s) {
    return [
      TextField(
        controller: _title,
        decoration: InputDecoration(labelText: s.listingTitleRequired, border: _inputBorder),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _desc,
        decoration: InputDecoration(
          labelText: '${s.descriptionLabel} *',
          border: _inputBorder,
        ),
        maxLines: 5,
      ),
      const SizedBox(height: 16),
      Text(s.createListingListingLangTitle, style: _labelStyle),
      const SizedBox(height: 4),
      Text(
        s.createListingListingLangHint,
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: Text(s.createListingDescLangTh),
            selected: true,
            onSelected: null,
          ),
          FilterChip(
            label: Text(s.createListingDescLangEn),
            selected: _listingLangs.contains('en'),
            onSelected: (v) => _toggleListingLang('en', v),
          ),
          FilterChip(
            label: Text(s.createListingDescLangZh),
            selected: _listingLangs.contains('zh'),
            onSelected: (v) => _toggleListingLang('zh', v),
          ),
        ],
      ),
      if (_listingLangs.contains('en') || _listingLangs.contains('zh')) ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _translateFromThai(s),
            icon: const Icon(Icons.translate, size: 18),
            label: Text(s.createListingAutoTranslate),
          ),
        ),
      ],
      if (_listingLangs.contains('en')) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _titleEn,
          decoration: InputDecoration(
            labelText: s.createListingTitleEnLabel,
            border: _inputBorder,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descEn,
          decoration: InputDecoration(
            labelText: s.createListingDescEnLabel,
            border: _inputBorder,
          ),
          maxLines: 4,
        ),
      ],
      if (_listingLangs.contains('zh')) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _titleZh,
          decoration: InputDecoration(
            labelText: s.createListingTitleZhLabel,
            border: _inputBorder,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descZh,
          decoration: InputDecoration(
            labelText: s.createListingDescZhLabel,
            border: _inputBorder,
          ),
          maxLines: 4,
        ),
      ],
      const SizedBox(height: 12),
      TextField(
        controller: _propertyCode,
        decoration: InputDecoration(
          labelText: s.t('รหัสทรัพย์ (ถ้ามี)', 'Property ID (optional)'),
          border: _inputBorder,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _contactName,
        decoration: InputDecoration(labelText: s.offerContactNameField, border: _inputBorder),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _contactPhone,
        decoration: InputDecoration(labelText: s.offerContactPhoneField, border: _inputBorder),
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _lineId,
        decoration: InputDecoration(
          labelText: s.createListingLineIdLabel,
          border: _inputBorder,
          prefixIcon: const Icon(Icons.chat_bubble_outline),
        ),
      ),
      const SizedBox(height: 24),
      ListingOccupancySection(
        listingType: _listingType,
        propertySlug: _propertySlug,
        value: _occupancy,
        tenantRentController: _tenantRent,
        onChanged: (v) => setState(() => _occupancy = v),
      ),
      const SizedBox(height: 24),
      ListingViewingAccessSection(
        value: _viewingAccess,
        noteController: _viewingAccessNote,
        onChanged: (v) => setState(() => _viewingAccess = v),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _bedrooms,
              decoration: InputDecoration(labelText: s.bedroomsFieldLabel, border: _inputBorder),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _bathrooms,
              decoration: InputDecoration(
                labelText: s.t('ห้องน้ำ', 'Bathrooms'),
                border: _inputBorder,
              ),
              keyboardType: TextInputType.number,
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
              decoration: InputDecoration(labelText: s.areaSqmLabel, border: _inputBorder),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _floor,
              decoration: InputDecoration(
                labelText: s.t('ชั้น', 'Floor'),
                border: _inputBorder,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Text(s.createListingHashtagsTitle, style: _labelStyle),
      const SizedBox(height: 4),
      Text(s.createListingHashtagsHint, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tag in ListingFormOptions.hashtags)
            FilterChip(
              label: Text(tag.label(s.isEnglish)),
              selected: _hashtagIds.contains(tag.id),
              onSelected: (v) => setState(() {
                if (v) {
                  _hashtagIds.add(tag.id);
                } else {
                  _hashtagIds.remove(tag.id);
                }
              }),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Text(s.createListingFacilitiesTitle, style: _labelStyle),
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
        controller: _myNote,
        decoration: InputDecoration(labelText: s.myNoteLabel, hintText: s.myNoteHint, border: _inputBorder),
        maxLines: 2,
      ),
    ];
  }

  String _transferTermsLabel(AppStrings s) {
    switch (_transferTerms) {
      case 'seller_pays_all':
        return s.offerTransferSellerAll;
      case 'split_50_50':
        return s.offerTransferSplit;
      case 'buyer_pays_all':
        return s.offerTransferBuyerAll;
      case 'other':
        return _transferOther.text.trim();
      default:
        return _transferTerms ?? '';
    }
  }

  List<Widget> _stepMedia(AppStrings s) {
    return [
      Text(s.propertyPhotos, style: _labelStyle),
      OutlinedButton.icon(
        onPressed: _pickImages,
        icon: const Icon(Icons.photo_library_outlined),
        label: Text(s.pickPhotos(_images.length)),
      ),
      if (_images.isNotEmpty) _photoStrip(),
      const SizedBox(height: 20),
      Text(s.createListingVideoSectionHint, style: _labelStyle),
      const SizedBox(height: 8),
      TextField(
        controller: _videoUrl,
        decoration: InputDecoration(
          labelText: s.videoUrlLabel,
          hintText: 'https://youtube.com/...',
          prefixIcon: const Icon(Icons.play_circle_outline),
          border: _inputBorder,
        ),
        keyboardType: TextInputType.url,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _tiktok,
        decoration: InputDecoration(
          labelText: s.createListingTiktokLabel,
          hintText: 'https://tiktok.com/...',
          prefixIcon: const Icon(Icons.music_note_outlined),
          border: _inputBorder,
        ),
        keyboardType: TextInputType.url,
      ),
    ];
  }

  List<Widget> _stepPrice(AppStrings s) {
    return [
      TextField(
        controller: _price,
        decoration: InputDecoration(
          labelText: _primaryPriceLabel(s),
          border: _inputBorder,
        ),
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
      ),
      if (ListingOccupancyStatus.needsTenantRent(_occupancy.status, _listingType))
        _occupancyYieldOnPriceStep(s),
      const SizedBox(height: 16),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(s.t('ตั้งราคาโปรโมชั่น', 'Promotion price')),
        value: _promoEnabled,
        onChanged: (v) => setState(() => _promoEnabled = v),
      ),
      if (_promoEnabled) ...[
        TextField(
          controller: _promoPrice,
          decoration: InputDecoration(
            labelText: s.t('ราคาโปรโมชั่น *', 'Promo price *'),
            border: _inputBorder,
          ),
          keyboardType: TextInputType.number,
        ),
        if (_promoPreviewCard(s) != null) _promoPreviewCard(s)!,
      ],
      if (!_isAgentPoster) ...[
        const SizedBox(height: 8),
        _ownerExclusiveBlock(s),
      ],
      const SizedBox(height: 8),
      ..._commissionSection(s),
      const SizedBox(height: 16),
      _infoBox(s.createListingPublishPrivacyNotice),
      const SizedBox(height: 12),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _acceptedPublishPolicy,
        onChanged: (v) => setState(() => _acceptedPublishPolicy = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: LegalPolicyRichText(
          s: s,
          prefix: s.createListingPublishTermsPrefix,
          middle: s.createListingPublishTermsMiddle,
          suffix: s.createListingPublishTermsSuffix,
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => LegalNavigation.openTerms(context),
          child: Text(s.legalReadFull),
        ),
      ),
      const SizedBox(height: 4),
      _infoBox(s.t(
        'กด「เผยแพร่」เพื่อส่งให้ทีมตรวจ — ดูสถานะได้ที่ประกาศของฉัน',
        'Tap Publish to submit for review — check status under My listings',
      )),
    ];
  }

  List<Widget> _commissionSection(AppStrings s) {
    final options = OfferCommissionScheme.optionsForListing(
      listingType: _listingType,
      isAgentPoster: _isAgentPoster,
    );
    final labels = {for (final o in options) o: s.offerCommissionSchemeLabel(o)};
    final price = double.tryParse(_price.text.replaceAll(',', ''));
    final leaseMo = int.tryParse(_leaseMonths.text) ?? 12;

    return [
      if (_listingType == 'sale_installment')
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            s.createListingSaleInstallmentCommissionNote,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
      _infoBox(
        _isAgentPoster
            ? s.createListingCommissionPolicyAgent
            : s.createListingCommissionPolicyOwner,
      ),
      const SizedBox(height: 12),
      Text(s.createListingCommissionTitle, style: _labelStyle),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _commissionScheme,
        decoration: const InputDecoration(border: _inputBorder),
        items: labels.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: const TextStyle(fontSize: 14)),
              ),
            )
            .toList(),
        onChanged: (v) {
          setState(() => _commissionScheme = v);
          _syncListedPriceFromNetCommission();
        },
      ),
      if (_commissionScheme == OfferCommissionScheme.custom) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _commissionOther,
          decoration: InputDecoration(
            labelText: s.offerCommissionOtherHint,
            border: _inputBorder,
          ),
          maxLines: 2,
        ),
      ],
      if (OfferCommissionScheme.isNetSelfAdd(_commissionScheme)) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _netReceive,
          decoration: InputDecoration(
            labelText: s.createListingNetReceiveLabel,
            border: _inputBorder,
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => _syncListedPriceFromNetCommission(),
        ),
        if (!_isAgentPoster) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _brokerCommissionPct,
            decoration: InputDecoration(
              labelText: s.createListingBrokerCommissionLabel,
              hintText: '3',
              border: _inputBorder,
              suffixText: '%',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _syncListedPriceFromNetCommission(),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          s.createListingNetSelfAddHint,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
        ),
        if (!_isAgentPoster) _netSelfAddListedPreview(s),
      ],
      if (!_isSaleListing) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _leaseMonths,
          decoration: InputDecoration(
            labelText: s.createListingLeaseMonthsLabel,
            border: _inputBorder,
            suffixText: s.t('เดือน', 'mo'),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
      ],
      if (price != null && _commissionScheme != null) ...[
        const SizedBox(height: 12),
        _commissionEstimateBox(s, price, leaseMo),
      ],
      if (_isSaleListing) ...[
        const SizedBox(height: 16),
        Text(s.offerTransferLabel, style: _labelStyle),
        const SizedBox(height: 4),
        ...[
          ('seller_pays_all', s.offerTransferSellerAll),
          ('split_50_50', s.offerTransferSplit),
          ('buyer_pays_all', s.offerTransferBuyerAll),
          ('other', s.offerTransferOther),
        ].map(
          (opt) => RadioListTile<String>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(opt.$2, style: const TextStyle(fontSize: 14)),
            value: opt.$1,
            groupValue: _transferTerms,
            onChanged: (v) => setState(() => _transferTerms = v),
          ),
        ),
        if (_transferTerms == 'other')
          TextField(
            controller: _transferOther,
            decoration: InputDecoration(
              labelText: s.offerTransferOtherHint,
              border: _inputBorder,
            ),
            maxLines: 2,
          ),
      ],
    ];
  }

  Widget _occupancyYieldOnPriceStep(AppStrings s) {
    final price = _listedPriceForSubmit() ??
        double.tryParse(_price.text.replaceAll(',', ''));
    final rent = double.tryParse(_tenantRent.text.replaceAll(',', ''));
    if (price == null || price <= 0 || rent == null || rent <= 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          s.occupancyYieldAfterPrice,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      );
    }
    final yield = ListingOccupancyStatus.yieldPercent(
      salePrice: price,
      monthlyRent: rent,
    );
    if (yield == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _infoBox(s.occupancyYieldPreview(yield.toStringAsFixed(2))),
    );
  }

  Widget _netSelfAddListedPreview(AppStrings s) {
    final listed = _listedPriceForSubmit();
    if (listed == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _infoBox(s.createListingListedPriceFromNet(listed.toStringAsFixed(0))),
    );
  }

  Widget _commissionEstimateBox(AppStrings s, double price, int leaseMonths) {
    if (OfferCommissionScheme.isNetSelfAdd(_commissionScheme) && !_isAgentPoster) {
      return const SizedBox.shrink();
    }
    final scheme = _commissionScheme!;
    double? est;
    if (_isSaleListing) {
      final pct = OfferCommissionScheme.salePercent(scheme);
      if (pct != null) est = price * pct / 100;
    } else {
      est = OfferCommissionScheme.rentCommissionEstimate(
        scheme: scheme,
        monthlyRent: price,
        leaseMonths: leaseMonths,
      );
    }
    if (est == null) return const SizedBox.shrink();
    return _infoBox(s.createListingCommissionEstimate(est.toStringAsFixed(0)));
  }

  Widget _photoStrip() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _images.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => FutureBuilder<Uint8List>(
            future: _images[i].readAsBytes(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SizedBox(
                  width: 88,
                  height: 88,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(snap.data!, width: 88, height: 88, fit: BoxFit.cover),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _agentExclusiveBlock(AppStrings s) {
    return Card(
      elevation: 0,
      color: AppTheme.primaryLight.withOpacity(0.35),
      child: SwitchListTile(
        title: Text(s.agentExclusiveToggle, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(s.agentExclusiveSubtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        value: _agentExclusive,
        activeColor: AppTheme.primary,
        onChanged: (v) => setState(() => _agentExclusive = v),
      ),
    );
  }

  Widget _ownerExclusiveBlock(AppStrings s) {
    final isSale = ListingExclusiveOptions.isSaleType(_listingType);
    final dayOptions = ListingExclusiveOptions.contractDaysFor(_listingType);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.ownerExclusiveTitle,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              s.ownerExclusivePitchFor(isSale, _ownerExclusiveContractDays),
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 10),
            Material(
              color: _ownerExclusiveInterest
                  ? AppTheme.primaryLight.withOpacity(0.45)
                  : AppTheme.inputFill,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _onOwnerExclusiveChanged(!_ownerExclusiveInterest),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.ownerExclusiveToggle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (!_ownerExclusiveInterest)
                              Text(
                                s.ownerExclusiveToggleHint,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _ownerExclusiveInterest,
                        activeColor: AppTheme.primary,
                        onChanged: _onOwnerExclusiveChanged,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_ownerExclusiveInterest) ...[
              const SizedBox(height: 12),
              Text(s.ownerExclusiveContractLabel, style: _labelStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in dayOptions)
                    ChoiceChip(
                      label: Text(
                        ListingExclusiveOptions.contractLabel(
                          d,
                          s.isEnglish,
                          isSale: isSale,
                        ),
                      ),
                      selected: _ownerExclusiveContractDays == d,
                      onSelected: (_) => setState(() => _ownerExclusiveContractDays = d),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onOwnerExclusiveChanged(bool? v) async {
    if (v != true) {
      setState(() => _ownerExclusiveInterest = false);
      return;
    }
    final ok = await showOwnerExclusiveTermsSheet(
      context,
      listingType: _listingType,
      contractDays: _ownerExclusiveContractDays,
    );
    if (!mounted) return;
    if (ok == true) setState(() => _ownerExclusiveInterest = true);
  }

  TextStyle get _labelStyle => const TextStyle(fontWeight: FontWeight.w600);

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: List.generate(total, (i) {
          final active = i <= step;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: active ? AppTheme.success : AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
