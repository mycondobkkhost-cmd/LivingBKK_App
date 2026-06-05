import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/admin_repository.dart';
import '../../widgets/demand/requirement_urgent_rush_toggle.dart';

class AdminCreateDemandPage extends StatefulWidget {
  const AdminCreateDemandPage({super.key, required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<AdminCreateDemandPage> createState() => _AdminCreateDemandPageState();
}

class _AdminCreateDemandPageState extends State<AdminCreateDemandPage> {
  final _admin = AdminRepository();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _maxPrice = TextEditingController();
  final _minArea = TextEditingController();
  final _btsKm = TextEditingController(text: '1.5');
  String _type = 'rent';
  bool _urgentRush = false;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _maxPrice.dispose();
    _minArea.dispose();
    _btsKm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await _admin.createDemandPost(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        transactionType: _type,
        maxPriceNet: double.tryParse(_maxPrice.text),
        minAreaSqm: double.tryParse(_minArea.text),
        maxDistanceBtsKm: double.tryParse(_btsKm.text),
        urgentRush: _urgentRush,
      );
      widget.onCreated();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.adminBoardCreated)),
      );
      _title.clear();
      _desc.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          s.adminCreateBoardIntro,
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _title,
          decoration: InputDecoration(labelText: '${s.offerTitleField} *'),
        ),
        TextField(
          controller: _desc,
          decoration: InputDecoration(
            labelText: s.offerDetailsField,
            hintText: s.adminCreateBoardHint,
          ),
          maxLines: 4,
        ),
        TextField(
          controller: _maxPrice,
          decoration: InputDecoration(labelText: s.adminMaxPriceLabel),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _minArea,
          decoration: InputDecoration(labelText: s.adminMinAreaLabel),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _btsKm,
          decoration: InputDecoration(labelText: s.adminBtsDistanceLabel),
          keyboardType: TextInputType.number,
        ),
        DropdownButtonFormField<String>(
          value: _type,
          items: [
            DropdownMenuItem(value: 'rent', child: Text(s.rent)),
            DropdownMenuItem(value: 'sale', child: Text(s.sale)),
          ],
          onChanged: (v) => setState(() => _type = v!),
        ),
        const SizedBox(height: 12),
        RequirementUrgentRushToggle(
          value: _urgentRush,
          onChanged: (v) => setState(() => _urgentRush = v),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(s.adminPublishBoard),
        ),
      ],
    );
  }
}
