import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../config/env.dart';
import '../../l10n/app_strings.dart';
import '../../models/demand_post.dart';
import '../../services/lead_repository.dart';
import '../../services/demand_offer_duplicate_service.dart';
import '../../utils/phone_suffix_util.dart';
import '../../models/offer_commission_scheme.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/demand_repository.dart';
import '../../services/storage_service.dart';
import '../../shell/main_shell_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/demand/demand_offer_warning_banner.dart';
import '../contact/property_chat_page.dart';
import '../../utils/page_safe_insets.dart';
import '../../theme/li_layout.dart';
import '../../widgets/consumer/consumer_page_shell.dart';
import '../../config/demand_board_menu_config.dart';
import '../../widgets/auth/auth_gate.dart';

class SubmitOfferPage extends StatefulWidget {
  const SubmitOfferPage({super.key, required this.post});

  final DemandPost post;

  @override
  State<SubmitOfferPage> createState() => _SubmitOfferPageState();
}

class _SubmitOfferPageState extends State<SubmitOfferPage> {
  final _repo = DemandRepository();
  final _storage = StorageService();
  final _priceFmt = NumberFormat('#,##0', 'th');

  String _capacity = 'owner_direct_100';
  String? _commissionScheme;
  String _transactionType = 'sale';
  String? _transferTerms;
  bool _submitting = false;
  bool _checkingDuplicate = false;
  bool _duplicateFound = false;
  List<XFile> _images = [];

  bool get _needsCustomerLast4 => widget.post.requiresCustomerPhoneLast4;

  final _nameCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _customerLast4Ctrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _askingCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _transferOtherCtrl = TextEditingController();
  final _commissionOtherCtrl = TextEditingController();

  static const _tabContact = 3;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.post.transactionType == 'rent' ? 'rent' : 'sale';
    final allowed = widget.post.allowedOffererCapacities;
    if (!allowed.contains(_capacity)) {
      _capacity = allowed.first;
    }
    _syncCommissionOptions();
  }

  List<DropdownMenuItem<String>> _capacityMenuItems(AppStrings s) {
    final allowed = widget.post.allowedOffererCapacities;
    final items = <DropdownMenuItem<String>>[];
    if (allowed.contains('owner_direct_100')) {
      items.add(
        DropdownMenuItem(
          value: 'owner_direct_100',
          child: Text(s.offerOwner100),
        ),
      );
    }
    if (allowed.contains('co_agent_50_50')) {
      items.add(
        DropdownMenuItem(
          value: 'co_agent_50_50',
          child: Text(s.offerCoAgent5050),
        ),
      );
    }
    return items;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _customerLast4Ctrl.dispose();
    _descCtrl.dispose();
    _askingCtrl.dispose();
    _maxCtrl.dispose();
    _urlCtrl.dispose();
    _transferOtherCtrl.dispose();
    _commissionOtherCtrl.dispose();
    super.dispose();
  }

  bool get _isSale => _transactionType == 'sale';

  bool get _needsCommission =>
      _capacity == 'owner_direct_100' || _capacity == 'co_agent_50_50';

  void _syncCommissionOptions() {
    if (!_needsCommission) {
      _commissionScheme = null;
      return;
    }
    final options = OfferCommissionScheme.optionsFor(
      transactionType: _transactionType,
      offererCapacity: _capacity,
    );
    if (_commissionScheme == null || !options.contains(_commissionScheme)) {
      _commissionScheme = options.first;
    }
  }

  Future<void> _checkCustomerLast4Duplicate() async {
    if (!_needsCustomerLast4) return;
    final raw = _customerLast4Ctrl.text.trim();
    if (!PhoneSuffixUtil.isValidLast4Input(raw)) {
      setState(() => _duplicateFound = false);
      return;
    }
    setState(() => _checkingDuplicate = true);
    try {
      final result = await DemandOfferDuplicateService.instance
          .checkCustomerPhoneLast4(
        raw,
        excludeDemandPostId: widget.post.id,
      );
      if (!mounted) return;
      setState(() => _duplicateFound = result.duplicate);
    } finally {
      if (mounted) setState(() => _checkingDuplicate = false);
    }
  }

  Future<void> _pickImages() async {
    final files = await _storage.pickImages();
    setState(() => _images = files);
  }

  String? _transferTermsLabel(AppStrings s) {
    switch (_transferTerms) {
      case 'seller_pays_all':
        return s.offerTransferSellerAll;
      case 'split_50_50':
        return s.offerTransferSplit;
      case 'buyer_pays_all':
        return s.offerTransferBuyerAll;
      case 'other':
        final custom = _transferOtherCtrl.text.trim();
        return custom.isEmpty ? s.offerTransferOther : custom;
      default:
        return null;
    }
  }

  String? _commissionLabel(AppStrings s) {
    if (!_needsCommission || _commissionScheme == null) return null;
    if (_commissionScheme == OfferCommissionScheme.custom) {
      final note = _commissionOtherCtrl.text.trim();
      return note.isEmpty ? s.offerCommissionOther : note;
    }
    return s.offerCommissionSchemeLabel(_commissionScheme!);
  }

  String _formatPrice(double value) => '${_priceFmt.format(value)} บาท';

  Map<String, String> _buildSummary(AppStrings s) {
    final asking = double.parse(_askingCtrl.text.trim());
    final maxPrice = double.parse(_maxCtrl.text.trim());
    final summary = <String, String>{
      s.t('ประกาศหาทรัพย์', 'Demand post'): widget.post.postCode,
      s.offerAsLabel.replaceAll(' *', ''): s.offererCapacityLabel(_capacity),
      s.offerTransactionLabel.replaceAll(' *', ''):
          _transactionType == 'sale' ? s.offerSale : s.offerRent,
      s.offerPropertyNameField.replaceAll(' *', ''): _nameCtrl.text.trim(),
      s.offerContactNameField.replaceAll(' *', ''): _contactNameCtrl.text.trim(),
      s.offerContactPhoneField.replaceAll(' *', ''): _contactPhoneCtrl.text.trim(),
    };
    if (_needsCustomerLast4) {
      summary[s.offerCustomerPhoneLast4Label.replaceAll(' *', '')] =
          '****${PhoneSuffixUtil.normalize(_customerLast4Ctrl.text.trim())}';
    }
    final commission = _commissionLabel(s);
    if (commission != null) {
      summary[s.offerCommissionLabel.replaceAll(' *', '')] = commission;
    }
    if (_descCtrl.text.trim().isNotEmpty) {
      summary[s.offerDetailsField] = _descCtrl.text.trim();
    }
    if (_urlCtrl.text.trim().isNotEmpty) {
      summary[s.offerPostLinkLabel] = _urlCtrl.text.trim();
    }
    summary[s.offerPriceAskingField.replaceAll(' *', '')] = _formatPrice(asking);
    summary[s.offerPriceMaxField.replaceAll(' *', '')] = _formatPrice(maxPrice);
    if (_isSale) {
      final transfer = _transferTermsLabel(s);
      if (transfer != null) {
        summary[s.offerTransferLabel.replaceAll(' *', '')] = transfer;
      }
    }
    if (_images.isNotEmpty) {
      summary[s.propertyPhotos] = s.pickPhotos(_images.length);
    }
    return summary;
  }

  bool _validate(AppStrings s) {
    if (!widget.post.allowsCapacity(_capacity)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.demandOfferCapacityNotAllowed)),
      );
      return false;
    }

    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.offerValidationName)),
      );
      return false;
    }
    if (_contactNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.offerValidationContactName)),
      );
      return false;
    }
    if (_contactPhoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.offerValidationContactPhone)),
      );
      return false;
    }

    if (_needsCustomerLast4) {
      final last4 = PhoneSuffixUtil.normalize(_customerLast4Ctrl.text.trim());
      if (last4.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.offerCustomerPhoneLast4Invalid)),
        );
        return false;
      }
      final expected = widget.post.customerPhoneLast4;
      if (expected != null && last4 != expected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.offerCustomerPhoneLast4Mismatch)),
        );
        return false;
      }
    }

    final asking = double.tryParse(_askingCtrl.text.trim());
    final maxPrice = double.tryParse(_maxCtrl.text.trim());
    if (asking == null || maxPrice == null || asking <= 0 || maxPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.offerValidationPrice)),
      );
      return false;
    }
    if (maxPrice > asking) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.offerValidationPriceOrder)),
      );
      return false;
    }

    if (_needsCommission) {
      if (_commissionScheme == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.offerValidationCommission)),
        );
        return false;
      }
      if (OfferCommissionScheme.requiresNote(_commissionScheme!) &&
          _commissionOtherCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.offerValidationCommissionOther)),
        );
        return false;
      }
    }

    if (_isSale) {
      if (_transferTerms == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.offerValidationTransfer)),
        );
        return false;
      }
      if (_transferTerms == 'other' && _transferOtherCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.offerTransferOtherHint)),
        );
        return false;
      }
    }

    return true;
  }

  Future<bool> _showConfirmDialog(Map<String, String> summary) async {
    final s = AppStrings.of(context);
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(s.offerConfirmTitle),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.offerConfirmIntro,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const DemandOfferWarningBanner(compact: true),
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
                child: Text(s.offerConfirmEdit),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.offerConfirmSubmit),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _onSubmitPressed() async {
    final s = AppStrings.of(context);
    if (!_validate(s)) return;

    if (Env.isConfigured &&
        !Env.trialMode &&
        !AuthService.instance.isRealSupabaseSession) {
      if (!await AuthGate.requireRealAccount(
        context,
        redirectRoute: DemandBoardMenuConfig.boardOfferRoute(widget.post.id),
      )) {
        return;
      }
    }

    final summary = _buildSummary(s);
    final confirmed = await _showConfirmDialog(summary);
    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);
    try {
      final asking = double.parse(_askingCtrl.text.trim());
      final maxPrice = double.parse(_maxCtrl.text.trim());

      final commissionScheme = _needsCommission ? _commissionScheme : null;
      final commissionNote = _needsCommission &&
              commissionScheme == OfferCommissionScheme.custom
          ? _commissionOtherCtrl.text.trim()
          : null;

      final result = await _repo.submitOffer(
        demandPostId: widget.post.id,
        offererCapacity: _capacity,
        offerType: 'in_app',
        transactionType: _transactionType,
        title: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        priceNet: asking,
        priceMaxNet: maxPrice,
        transferTerms: _isSale ? _transferTermsLabel(s) : null,
        commissionScheme: commissionScheme,
        commissionNote: commissionNote,
        contactName: _contactNameCtrl.text.trim(),
        contactPhone: _contactPhoneCtrl.text.trim(),
        customerPhoneLast4: _needsCustomerLast4
            ? PhoneSuffixUtil.normalize(_customerLast4Ctrl.text.trim())
            : null,
        externalUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
        demandPostCode: widget.post.postCode,
        demandPostTitle: widget.post.title,
      );

      if (_needsCustomerLast4) {
        LeadRepository().recordPhoneSuffix(
          PhoneSuffixUtil.normalize(_customerLast4Ctrl.text.trim()),
        );
      }

      if (_images.isNotEmpty && result.offerId.isNotEmpty) {
        try {
          await _storage.uploadDemandOfferImages(
            offerId: result.offerId,
            files: _images,
          );
        } catch (_) {
          /* รูปไม่บล็อกการส่งหลัก */
        }
      }

      final room = await ChatService.instance.recordDemandOffer(
        summary: summary,
        demandPostCode: result.demandPostCode ?? widget.post.postCode,
        demandPostTitle: result.demandPostTitle ?? widget.post.title,
        transactionRef: result.transactionRef,
      );

      if (!mounted) return;
      final txn = room.effectiveTransactionRef;
      MainShellScope.maybeOf(context)?.selectTab(_tabContact);
      if (context.canPop()) context.pop();
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PropertyChatPage(room: room),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.offerSentOpenChat}\n${s.transactionRefLabel}: $txn'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _commissionSection(AppStrings s) {
    if (!_needsCommission) return const SizedBox.shrink();

    final options = OfferCommissionScheme.optionsFor(
      transactionType: _transactionType,
      offererCapacity: _capacity,
    );
    final labels = <String, String>{
      for (final o in options) o: s.offerCommissionSchemeLabel(o),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          s.offerCommissionLabel,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _commissionScheme,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: labels.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _commissionScheme = v),
        ),
        if (_commissionScheme == OfferCommissionScheme.custom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _commissionOtherCtrl,
            decoration: InputDecoration(
              labelText: s.offerCommissionOtherHint,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ConsumerPageShell(
      title: s.submitOfferTitle,
      onBack: () => Navigator.of(context).maybePop(),
      body: ListView(
        padding: PageSafeInsets.padLTRB(
          context,
          left: LiLayout.pagePadding,
          top: LiLayout.pagePadding,
          right: LiLayout.pagePadding,
          bottom: 20,
          addHomeIndicator: false,
        ),
        children: [
          const DemandOfferWarningBanner(),
          const SizedBox(height: 20),
          Text(
            s.offerAsLabel,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _capacity,
            decoration: InputDecoration(border: OutlineInputBorder()),
            items: _capacityMenuItems(s),
            onChanged: (v) => setState(() {
              _capacity = v!;
              _syncCommissionOptions();
            }),
          ),
          const SizedBox(height: 8),
          Text(
            s.demandOfferPolicyDetail(widget.post.offerAcceptancePolicy),
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 4),
          Text(
            s.offerPrivateNote,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (_needsCustomerLast4) ...[
            const SizedBox(height: 20),
            Text(
              s.offerCustomerPhoneLast4Label,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              s.offerCustomerPhoneLast4Hint,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customerLast4Ctrl,
              decoration: InputDecoration(
                hintText: '••••',
                prefixIcon: const Icon(Icons.pin_outlined),
                counterText: '',
                suffixIcon: _checkingDuplicate
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              onChanged: (_) => _checkCustomerLast4Duplicate(),
            ),
            if (_duplicateFound)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  s.offerCustomerPhoneLast4Duplicate,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.warning,
                    height: 1.35,
                  ),
                ),
              ),
          ],
          _commissionSection(s),
          const SizedBox(height: 24),
          Text(
            s.offerTransactionLabel,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'sale', label: Text(s.offerSale)),
              ButtonSegment(value: 'rent', label: Text(s.offerRent)),
            ],
            selected: {_transactionType},
            onSelectionChanged: (v) => setState(() {
              _transactionType = v.first;
              if (_transactionType != 'sale') _transferTerms = null;
              _syncCommissionOptions();
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _urlCtrl,
            decoration: InputDecoration(
              labelText: s.offerPostLinkLabel,
              hintText: s.offerPostLinkHint,
              prefixIcon: const Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(labelText: s.offerPropertyNameField),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contactNameCtrl,
            decoration: InputDecoration(labelText: s.offerContactNameField),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactPhoneCtrl,
            decoration: InputDecoration(labelText: s.offerContactPhoneField),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: InputDecoration(
              labelText: s.offerDetailsField,
              hintText: s.offerDetailsVacancyHint,
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _askingCtrl,
            decoration: InputDecoration(labelText: s.offerPriceAskingField),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxCtrl,
            decoration: InputDecoration(labelText: s.offerPriceMaxField),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Text(
            s.offerPriceCommissionNote,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (_isSale) ...[
            const SizedBox(height: 20),
            Text(
              s.offerTransferLabel,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...[
              ('seller_pays_all', s.offerTransferSellerAll),
              ('split_50_50', s.offerTransferSplit),
              ('buyer_pays_all', s.offerTransferBuyerAll),
              ('other', s.offerTransferOther),
            ].map(
              (opt) => RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(opt.$2, style: TextStyle(fontSize: 14)),
                value: opt.$1,
                groupValue: _transferTerms,
                onChanged: (v) => setState(() => _transferTerms = v),
              ),
            ),
            if (_transferTerms == 'other')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextField(
                  controller: _transferOtherCtrl,
                  decoration: InputDecoration(
                    labelText: s.offerTransferOtherHint,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ),
          ],
          const SizedBox(height: 20),
          Text(s.propertyPhotos, style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(s.pickPhotos(_images.length)),
          ),
          if (_images.isNotEmpty)
            Padding(
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
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          snap.data!,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _submitting ? null : _onSubmitPressed,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(s.submitOffer),
          ),
        ],
      ),
    );
  }
}
