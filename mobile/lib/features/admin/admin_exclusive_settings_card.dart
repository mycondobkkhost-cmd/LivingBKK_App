import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';
import '../../models/platform_exclusive_settings.dart';
import '../../services/admin_repository.dart';
import '../../services/platform_settings_service.dart';
import '../../theme/app_theme.dart';

/// แอดมิน — ตั้งช่วงดันฟีดอัตโนมัติและคะแนนฟีด Exclusive
class AdminExclusiveSettingsCard extends StatefulWidget {
  const AdminExclusiveSettingsCard({super.key});

  @override
  State<AdminExclusiveSettingsCard> createState() => _AdminExclusiveSettingsCardState();
}

class _AdminExclusiveSettingsCardState extends State<AdminExclusiveSettingsCard> {
  final _admin = AdminRepository();
  final _rentHours = TextEditingController();
  final _saleHours = TextEditingController();
  final _ownerBoost = TextEditingController();
  final _agentBoost = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rentHours.dispose();
    _saleHours.dispose();
    _ownerBoost.dispose();
    _agentBoost.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await PlatformSettingsService.instance.load();
    final c = PlatformSettingsService.instance.exclusive;
    _rentHours.text = '${c.rentBumpHours}';
    _saleHours.text = '${c.saleBumpHours}';
    _ownerBoost.text = '${c.ownerFeedBoost}';
    _agentBoost.text = '${c.agentFeedBoost}';
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final s = context.s;
    final rent = int.tryParse(_rentHours.text.trim());
    final sale = int.tryParse(_saleHours.text.trim());
    final owner = int.tryParse(_ownerBoost.text.trim());
    final agent = int.tryParse(_agentBoost.text.trim());
    if (rent == null || sale == null || owner == null || agent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminExclusiveSettingsInvalid)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final next = PlatformExclusiveSettings(
        rentBumpHours: rent.clamp(1, 168),
        saleBumpHours: sale.clamp(1, 720),
        ownerFeedBoost: owner.clamp(0, 200),
        agentFeedBoost: agent.clamp(0, 200),
      );
      await _admin.updateExclusiveSettings(next);
      PlatformSettingsService.instance.applyExclusive(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminExclusiveSettingsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_outlined, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.adminExclusiveSettingsTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(s.adminExclusiveSettingsHint, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              const SizedBox(height: 16),
              _field(s.adminExclusiveRentBumpHours, _rentHours),
              _field(s.adminExclusiveSaleBumpHours, _saleHours),
              _field(s.adminExclusiveOwnerFeedBoost, _ownerBoost),
              _field(s.adminExclusiveAgentFeedBoost, _agentBoost),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(s.save),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
