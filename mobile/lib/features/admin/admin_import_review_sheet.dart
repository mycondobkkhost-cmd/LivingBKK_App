import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../services/listing_import_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';

/// ตรวจสอบและแก้ไข draft ก่อนเผยแพร่ — คล้ายฟอร์มโครงการ
class AdminImportReviewSheet extends StatefulWidget {
  const AdminImportReviewSheet({
    super.key,
    required this.importId,
    required this.scrollController,
    required this.onChanged,
  });

  final String importId;
  final ScrollController scrollController;
  final VoidCallback onChanged;

  @override
  State<AdminImportReviewSheet> createState() => _AdminImportReviewSheetState();
}

class _AdminImportReviewSheetState extends State<AdminImportReviewSheet> {
  final _repo = ListingImportRepository.instance;

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _area = TextEditingController();
  final _bedrooms = TextEditingController();
  final _district = TextEditingController();
  final _project = TextEditingController();

  ListingImportDetail? _detail;
  bool _loading = true;
  bool _busy = false;
  String _listingType = 'rent';
  String _propertyType = 'condo';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _area.dispose();
    _bedrooms.dispose();
    _district.dispose();
    _project.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final detail = await _repo.getImportDetail(widget.importId);
      if (!mounted) return;
      _detail = detail;
      _applyDraft(detail);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyDraft(ListingImportDetail detail) {
    final listing = detail.listing;
    final imp = detail.import;
    _title.text = listing?.title ?? imp.titlePreview ?? '';
    _desc.text = listing?.description ?? '';
    _price.text = (listing?.priceNet ?? imp.pricePreview)?.toStringAsFixed(0) ?? '';
    _area.text = listing?.areaSqm?.toStringAsFixed(1) ?? '';
    _bedrooms.text = listing?.bedrooms?.toString() ?? '';
    _district.text = listing?.district ?? '';
    _project.text = listing?.projectName ?? imp.projectPreview ?? '';
    _listingType = listing?.listingType ?? 'rent';
    _propertyType = listing?.propertyType ?? 'condo';
  }

  Future<void> _saveDraft({bool silent = false}) async {
    final s = context.s;
    final listingId = _detail?.import.listingId;
    if (listingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportNoDraft)),
      );
      return;
    }
    if (_title.text.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      await _repo.updateListingDraft(
        importId: widget.importId,
        listingId: listingId,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        listingType: _listingType,
        propertyType: _propertyType,
        priceNet: double.tryParse(_price.text.replaceAll(',', '')),
        areaSqm: double.tryParse(_area.text),
        bedrooms: int.tryParse(_bedrooms.text),
        district: _district.text.trim().isEmpty ? null : _district.text.trim(),
        projectName: _project.text.trim().isEmpty ? null : _project.text.trim(),
      );
      await _load();
      widget.onChanged();
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportDraftSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ListingImportRepository.friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retryFetch() async {
    setState(() => _busy = true);
    try {
      await _repo.retry(widget.importId);
      await _load();
      widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.adminImportRefetched)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ListingImportRepository.friendlyError(e))),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve() async {
    final s = context.s;
    if (_detail?.import.canApprove != true) return;

    final price = double.tryParse(_price.text.replaceAll(',', ''));
    if (price == null || price <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportPriceRequired)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await _saveDraft(silent: true);
      await _repo.approve(widget.importId);
      widget.onChanged();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportApproved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ListingImportRepository.friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _archive() async {
    setState(() => _busy = true);
    try {
      await _repo.archive(widget.importId);
      widget.onChanged();
      if (!mounted) return;
      Navigator.of(context).pop(false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ListingImportRepository.friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final locale = s.isEnglish ? 'en' : 'th';

    if (_loading) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final imp = _detail!.import;
    final listing = _detail!.listing;
    final priceFmt = NumberFormat.currency(locale: locale, symbol: '฿', decimalDigits: 0);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(s.adminImportReviewTitle, style: AdminTheme.title.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          AdminHint(s.adminImportReviewHint),
          if (_detail!.parseFlags.isNotEmpty) ...[
            const SizedBox(height: 8),
            AdminNote(s.adminImportParseWarnings(_detail!.parseFlags)),
          ],
          if (imp.errorMessage != null && imp.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: AdminTheme.card(alert: true),
              child: Text(imp.errorMessage!, style: TextStyle(color: AppTheme.error, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              children: [
                Text(imp.sourceUrl, style: AdminTheme.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text(s.adminImportSourceLabel(imp.sourcePlatform)),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text(s.adminImportStatus(imp.status)),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (imp.sourceExternalId != null)
                      Chip(
                        label: Text('LI ${imp.sourceExternalId}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    Chip(
                      label: Text(s.adminImportImages(imp.imageCount)),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (listing?.listingCode != null)
                      Chip(
                        label: Text(listing!.listingCode!),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (imp.pricePreview != null)
                      Chip(
                        label: Text(priceFmt.format(imp.pricePreview)),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: '${s.offerTitleField} *',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _desc,
                  decoration: InputDecoration(
                    labelText: s.offerDetailsField,
                    border: const OutlineInputBorder(),
                  ),
                  minLines: 4,
                  maxLines: 8,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _price,
                  decoration: InputDecoration(
                    labelText: s.adminMaxPriceLabel,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _area,
                        decoration: InputDecoration(
                          labelText: s.adminMinAreaLabel,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _bedrooms,
                        decoration: InputDecoration(
                          labelText: s.adminImportBedrooms,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _project,
                  decoration: InputDecoration(
                    labelText: s.adminImportProjectName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _district,
                  decoration: InputDecoration(
                    labelText: s.adminImportDistrict,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _listingType,
                  decoration: InputDecoration(
                    labelText: s.adminImportTxnType,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'rent', child: Text(s.rent)),
                    DropdownMenuItem(value: 'sale', child: Text(s.sale)),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _listingType = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _propertyType,
                  decoration: InputDecoration(
                    labelText: s.adminImportPropertyType,
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'condo', child: Text('คอนโด / Condo')),
                    DropdownMenuItem(value: 'house', child: Text('บ้าน / House')),
                    DropdownMenuItem(value: 'townhouse', child: Text('ทาวน์เฮาส์')),
                    DropdownMenuItem(value: 'apartment', child: Text('อพาร์ทเมนต์')),
                    DropdownMenuItem(value: 'other', child: Text('อื่นๆ')),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _propertyType = v!),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (imp.canApprove)
                FilledButton(
                  onPressed: _busy ? null : _approve,
                  child: Text(s.adminImportApprove),
                ),
              OutlinedButton(
                onPressed: _busy ? null : () => _saveDraft(),
                child: Text(s.adminImportSaveDraft),
              ),
              if (imp.canRetry)
                OutlinedButton(
                  onPressed: _busy ? null : _retryFetch,
                  child: Text(s.adminImportRetry),
                ),
              if (!imp.isArchived)
                TextButton(
                  onPressed: _busy ? null : _archive,
                  child: Text(s.adminImportArchive),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
