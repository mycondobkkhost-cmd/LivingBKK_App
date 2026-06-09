import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/profile_tag.dart';
import '../../services/profile_tag_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/price_slider_scale.dart';
import '../../widgets/budget_range_slider.dart';

Future<ProfileTag?> showProfileTagFormSheet(
  BuildContext context, {
  required ProfileTagRole role,
  ProfileTag? basedOn,
}) {
  return showModalBottomSheet<ProfileTag>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _ProfileTagForm(role: role, basedOn: basedOn),
    ),
  );
}

class _ProfileTagForm extends StatefulWidget {
  const _ProfileTagForm({required this.role, this.basedOn});

  final ProfileTagRole role;
  final ProfileTag? basedOn;

  @override
  State<_ProfileTagForm> createState() => _ProfileTagFormState();
}

class _ProfileTagFormState extends State<_ProfileTagForm> {
  final _nickname = TextEditingController();
  final _phone = TextEditingController();
  final _occupation = TextEditingController();
  final _workplace = TextEditingController();
  final _displayName = TextEditingController();
  final _agency = TextEditingController();
  final _license = TextEditingController();
  String? _occupants;
  String? _contract;
  double _budgetMinPos = 0;
  double _budgetMaxPos = PriceSliderScale.rentBahtToPosition(30000);
  String? _error;

  @override
  void initState() {
    super.initState();
    final snap = widget.basedOn?.snapshot ?? {};
    _nickname.text = snap['nickname'] ?? '';
    _phone.text = snap['phone'] ?? '';
    _occupation.text = snap['occupation'] ?? '';
    _workplace.text = snap['workplace'] ?? '';
    _displayName.text = snap['displayName'] ?? '';
    _agency.text = snap['agencyName'] ?? '';
    _license.text = snap['licenseNo'] ?? '';
    _occupants = snap['occupants'];
    _contract = snap['contract'];
  }

  @override
  void dispose() {
    _nickname.dispose();
    _phone.dispose();
    _occupation.dispose();
    _workplace.dispose();
    _displayName.dispose();
    _agency.dispose();
    _license.dispose();
    super.dispose();
  }

  String get _title => switch (widget.role) {
        ProfileTagRole.seekerSelf => context.s.profileTagFormSeeker,
        ProfileTagRole.coAgentPresenter => context.s.profileTagFormPresenter,
        ProfileTagRole.clientSubject => context.s.profileTagFormClient,
      };

  void _save() {
    final s = context.s;
    final snap = <String, String>{};

    switch (widget.role) {
      case ProfileTagRole.coAgentPresenter:
        if (_displayName.text.trim().isEmpty) {
          setState(() => _error = s.profileTagErrDisplayName);
          return;
        }
        snap['displayName'] = _displayName.text.trim();
        if (_agency.text.trim().isNotEmpty) snap['agencyName'] = _agency.text.trim();
        if (_license.text.trim().isNotEmpty) snap['licenseNo'] = _license.text.trim();
        if (_phone.text.trim().isNotEmpty) snap['phone'] = _phone.text.trim();
      case ProfileTagRole.seekerSelf:
      case ProfileTagRole.clientSubject:
        if (_nickname.text.trim().isEmpty || _phone.text.trim().length < 9) {
          setState(() => _error = s.errNicknamePhone);
          return;
        }
        if (_occupants == null || _occupation.text.trim().isEmpty || _contract == null) {
          setState(() => _error = s.errRequiredFields);
          return;
        }
        snap['nickname'] = _nickname.text.trim();
        snap['phone'] = _phone.text.trim();
        snap['occupants'] = _occupants!;
        snap['occupation'] = _occupation.text.trim();
        snap['contract'] = _contract!;
        if (_workplace.text.trim().isNotEmpty) snap['workplace'] = _workplace.text.trim();
        final min = PriceSliderScale.rentPositionToBaht(_budgetMinPos);
        final max = PriceSliderScale.rentPositionToBaht(_budgetMaxPos);
        snap['budget'] =
            '${PriceSliderScale.formatBaht(min, isSale: false)} – ${PriceSliderScale.formatBaht(max, isSale: false)}';
    }

    final tag = ProfileTagService.instance.createTag(
      role: widget.role,
      snapshot: snap,
      subjectDisplayName: snap['nickname'] ?? snap['displayName'],
      basedOn: widget.basedOn,
    );
    Navigator.pop(context, tag);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (widget.basedOn != null) ...[
              const SizedBox(height: 4),
              Text(s.profileTagEditCreatesNew, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
            const SizedBox(height: 16),
            if (widget.role == ProfileTagRole.coAgentPresenter) ...[
              TextField(
                controller: _displayName,
                decoration: InputDecoration(
                  labelText: s.t('ชื่อผู้พานัด', 'Presenter name'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _agency,
                decoration: InputDecoration(
                  labelText: s.t('สังกัด/บริษัท', 'Agency'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _license,
                decoration: InputDecoration(
                  labelText: s.t('เลขใบอนุญาต', 'License no.'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: s.summaryPhone, border: const OutlineInputBorder()),
              ),
            ] else ...[
              TextField(
                controller: _nickname,
                decoration: InputDecoration(labelText: s.summaryNickname, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: s.summaryPhone, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _occupants,
                decoration: InputDecoration(labelText: s.summaryOccupants, border: const OutlineInputBorder()),
                items: ['1', '2', '3', '4', '5+']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _occupants = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _occupation,
                decoration: InputDecoration(labelText: s.summaryOccupation, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _contract,
                decoration: InputDecoration(labelText: s.summaryContract, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: '6m', child: Text(s.contract6Months)),
                  DropdownMenuItem(value: '12m', child: Text(s.contract1Year)),
                  DropdownMenuItem(value: '24m', child: Text(s.contract2Years)),
                ],
                onChanged: (v) => setState(() => _contract = v),
              ),
              const SizedBox(height: 12),
              Text(s.summaryBudget, style: const TextStyle(fontWeight: FontWeight.w600)),
              BudgetRangeSlider(
                minPos: _budgetMinPos,
                maxPos: _budgetMaxPos,
                onChanged: (range) => setState(() {
                  _budgetMinPos = range.start;
                  _budgetMaxPos = range.end;
                }),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: AppTheme.error, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: Text(s.profileTagSave)),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
          ],
        ),
      ),
    );
  }
}
