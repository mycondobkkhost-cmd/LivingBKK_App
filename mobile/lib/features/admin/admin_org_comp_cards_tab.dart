import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/admin_comp_card.dart';
import '../../services/admin_comp_card_service.dart';
import '../../theme/admin_theme.dart';
import 'admin_comp_card_widgets.dart';

/// ตั้งค่าโปรไฟล์ย่อย — คอมพ์การ์ดทุกคนในองค์กร + แท็กที่ผูกไว้
class AdminOrgCompCardsTab extends StatefulWidget {
  const AdminOrgCompCardsTab({super.key});

  @override
  State<AdminOrgCompCardsTab> createState() => _AdminOrgCompCardsTabState();
}

class _AdminOrgCompCardsTabState extends State<AdminOrgCompCardsTab> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await AdminCompCardService.instance.ensureSeeded();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _editCard(AdminCompCard card) async {
    final updated = await showModalBottomSheet<AdminCompCard>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _CompCardEditSheet(card: card),
    );
    if (updated == null) return;
    await AdminCompCardService.instance.updateCard(updated);
    await AdminCompCardService.instance.refreshTag(updated);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final cards = AdminCompCardService.instance.all;

    return ListenableBuilder(
      listenable: AdminCompCardService.instance,
      builder: (context, _) {
        final list = AdminCompCardService.instance.all;
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdminNote(s.adminCompCardIntro),
              const SizedBox(height: 12),
              Text(
                s.adminCompCardListTitle(list.length),
                style: AdminTheme.section,
              ),
              const SizedBox(height: 8),
              ...list.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AdminCompCardPreviewTile(
                    card: c,
                    onEdit: () => _editCard(c),
                  ),
                ),
              ),
              if (cards.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    s.adminCompCardEmpty,
                    textAlign: TextAlign.center,
                    style: AdminTheme.hint,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CompCardEditSheet extends StatefulWidget {
  const _CompCardEditSheet({required this.card});

  final AdminCompCard card;

  @override
  State<_CompCardEditSheet> createState() => _CompCardEditSheetState();
}

class _CompCardEditSheetState extends State<_CompCardEditSheet> {
  late final TextEditingController _nameTh;
  late final TextEditingController _nameEn;
  late final TextEditingController _phone;
  late final TextEditingController _agency;
  late final TextEditingController _license;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _nameTh = TextEditingController(text: c.displayNameTh);
    _nameEn = TextEditingController(text: c.displayNameEn);
    _phone = TextEditingController(text: c.phone ?? '');
    _agency = TextEditingController(text: c.agencyName);
    _license = TextEditingController(text: c.licenseNo ?? '');
  }

  @override
  void dispose() {
    _nameTh.dispose();
    _nameEn.dispose();
    _phone.dispose();
    _agency.dispose();
    _license.dispose();
    super.dispose();
  }

  void _save() {
    final th = _nameTh.text.trim();
    if (th.isEmpty) return;
    Navigator.pop(
      context,
      widget.card.copyWith(
        displayNameTh: th,
        displayNameEn: _nameEn.text.trim().isEmpty ? th : _nameEn.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        agencyName: _agency.text.trim().isEmpty ? 'RealXtate' : _agency.text.trim(),
        licenseNo: _license.text.trim().isEmpty ? null : _license.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.adminCompCardEditTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              s.adminCompCardEditHint(widget.card.tagCode),
              style: AdminTheme.caption,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameTh,
              decoration: InputDecoration(
                labelText: s.t('ชื่อ (ไทย)', 'Name (TH)'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameEn,
              decoration: InputDecoration(
                labelText: s.t('ชื่อ (EN)', 'Name (EN)'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _agency,
              decoration: InputDecoration(
                labelText: s.t('สังกัด', 'Agency'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _license,
              decoration: InputDecoration(
                labelText: s.t('เลขใบอนุญาต', 'License'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: s.summaryPhone,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: Text(s.profileTagSave),
            ),
          ],
        ),
      ),
    );
  }
}
