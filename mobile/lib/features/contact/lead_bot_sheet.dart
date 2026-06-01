import 'package:flutter/material.dart';

import '../../services/lead_repository.dart';
import '../../theme/app_theme.dart';

void showLeadBotSheet(
  BuildContext context, {
  String? listingCode,
  String? listingId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    builder: (ctx) => LeadBotSheet(
      listingCode: listingCode ?? 'LB-AUTO',
      listingId: listingId,
    ),
  );
}

class LeadBotSheet extends StatefulWidget {
  const LeadBotSheet({
    super.key,
    required this.listingCode,
    this.listingId,
  });

  final String listingCode;
  final String? listingId;

  @override
  State<LeadBotSheet> createState() => _LeadBotSheetState();
}

class _LeadBotSheetState extends State<LeadBotSheet> {
  final _repo = LeadRepository();
  int _step = 0;
  bool _submitting = false;

  final _nickname = TextEditingController();
  final _phone = TextEditingController();
  final _occupants = TextEditingController();
  final _gender = TextEditingController();
  final _occupation = TextEditingController();
  final _workplace = TextEditingController();
  final _movePlan = TextEditingController();
  final _contract = TextEditingController();
  final _budget = TextEditingController();
  final _pets = TextEditingController();
  final _areas = TextEditingController();
  bool? _hasCar;
  String? _smoking;

  static const _steps = 4;

  @override
  void dispose() {
    _nickname.dispose();
    _phone.dispose();
    _occupants.dispose();
    _gender.dispose();
    _occupation.dispose();
    _workplace.dispose();
    _movePlan.dispose();
    _contract.dispose();
    _budget.dispose();
    _pets.dispose();
    _areas.dispose();
    super.dispose();
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        return _nickname.text.trim().isNotEmpty && _phone.text.trim().length >= 9;
      case 1:
        return _occupation.text.trim().isNotEmpty;
      case 2:
        return _contract.text.trim().isNotEmpty && _budget.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await _repo.submit(
        LeadSubmission(
          listingCode: widget.listingCode,
          listingId: widget.listingId,
          seekerNickname: _nickname.text.trim(),
          seekerPhone: _phone.text.trim(),
          occupantsCount: int.tryParse(_occupants.text),
          gender: _gender.text.trim().isEmpty ? null : _gender.text.trim(),
          occupation: _occupation.text.trim(),
          workplace: _workplace.text.trim().isEmpty ? null : _workplace.text.trim(),
          movePlan: _movePlan.text.trim().isEmpty ? null : _movePlan.text.trim(),
          contractDuration: _contract.text.trim(),
          budget: double.tryParse(_budget.text.replaceAll(',', '')),
          hasCar: _hasCar,
          pets: _pets.text.trim().isEmpty ? null : _pets.text.trim(),
          smoking: _smoking,
          preferredAreas: _areas.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่งคำขอแล้ว ทีม LivingBKK จะติดต่อกลับ'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ติดต่อ / นัดชม (${_step + 1}/$_steps)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            'รหัสประกาศ: ${widget.listingCode}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_step + 1) / _steps,
            backgroundColor: AppTheme.border,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 16),
          if (_step == 0) ...[
            TextField(
              controller: _nickname,
              decoration: const InputDecoration(labelText: 'ชื่อเล่น *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'เบอร์โทร *'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _occupants,
              decoration: const InputDecoration(labelText: 'จำนวนผู้เข้าพัก'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _gender,
              decoration: const InputDecoration(labelText: 'เพศ'),
            ),
          ],
          if (_step == 1) ...[
            TextField(
              controller: _occupation,
              decoration: const InputDecoration(labelText: 'อาชีพ *'),
            ),
            TextField(
              controller: _workplace,
              decoration: const InputDecoration(labelText: 'สถานที่ทำงาน'),
            ),
            TextField(
              controller: _movePlan,
              decoration: const InputDecoration(labelText: 'แพลนย้าย'),
            ),
          ],
          if (_step == 2) ...[
            TextField(
              controller: _contract,
              decoration: const InputDecoration(labelText: 'ระยะสัญญา *'),
            ),
            TextField(
              controller: _budget,
              decoration: const InputDecoration(labelText: 'งบประมาณ (บาท) *'),
              keyboardType: TextInputType.number,
            ),
            const Text('ใช้รถ', style: TextStyle(fontWeight: FontWeight.w500)),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('ใช่'),
                  selected: _hasCar == true,
                  onSelected: (_) => setState(() => _hasCar = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('ไม่ใช่'),
                  selected: _hasCar == false,
                  onSelected: (_) => setState(() => _hasCar = false),
                ),
              ],
            ),
          ],
          if (_step == 3) ...[
            TextField(
              controller: _pets,
              decoration: const InputDecoration(labelText: 'สัตว์เลี้ยง'),
            ),
            const Text('สูบบุหรี่'),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('สูบ'),
                  selected: _smoking == 'yes',
                  onSelected: (_) => setState(() => _smoking = 'yes'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('ไม่สูบ'),
                  selected: _smoking == 'no',
                  onSelected: (_) => setState(() => _smoking = 'no'),
                ),
              ],
            ),
            TextField(
              controller: _areas,
              decoration: const InputDecoration(
                labelText: 'ทำเล/โครงการที่สนใจ (คั่นด้วย ,)',
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (_step > 0)
                TextButton(
                  onPressed: _submitting ? null : () => setState(() => _step--),
                  child: const Text('ย้อน'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _submitting
                    ? null
                    : () {
                        if (!_validateStep()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('กรุณากรอกข้อมูลที่จำเป็น')),
                          );
                          return;
                        }
                        if (_step < _steps - 1) {
                          setState(() => _step++);
                        } else {
                          _submit();
                        }
                      },
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_step < _steps - 1 ? 'ถัดไป' : 'ส่งคำขอ'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
