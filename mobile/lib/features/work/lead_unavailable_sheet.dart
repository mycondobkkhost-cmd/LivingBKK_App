import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

class LeadUnavailableResult {
  const LeadUnavailableResult({
    required this.unavailableUntil,
    this.availableAgain,
  });

  final DateTime unavailableUntil;
  final DateTime? availableAgain;
}

Future<LeadUnavailableResult?> showLeadUnavailableSheet(BuildContext context) {
  return showModalBottomSheet<LeadUnavailableResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _LeadUnavailableBody(),
  );
}

class _LeadUnavailableBody extends StatefulWidget {
  const _LeadUnavailableBody();

  @override
  State<_LeadUnavailableBody> createState() => _LeadUnavailableBodyState();
}

class _LeadUnavailableBodyState extends State<_LeadUnavailableBody> {
  DateTime? _unavailableUntil;
  DateTime? _availableAgain;

  String _label(AppStrings s, DateTime? d) =>
      d == null ? s.selectDate : '${d.day}/${d.month}/${d.year + 543}';

  Future<void> _pick({required bool isAvailableAgain}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isAvailableAgain
          ? (_availableAgain ?? now.add(const Duration(days: 30)))
          : (_unavailableUntil ?? now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isAvailableAgain) {
        _availableAgain = picked;
      } else {
        _unavailableUntil = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.propertyUnavailable,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            s.unavailableDatesHint,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _pick(isAvailableAgain: false),
            icon: const Icon(Icons.event_busy, size: 18),
            label: Text(s.contractUntil(_label(s, _unavailableUntil))),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _pick(isAvailableAgain: true),
            icon: const Icon(Icons.event_available, size: 18),
            label: Text(s.availableAgain(_label(s, _availableAgain))),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _unavailableUntil == null
                ? null
                : () => Navigator.pop(
                      context,
                      LeadUnavailableResult(
                        unavailableUntil: _unavailableUntil!,
                        availableAgain: _availableAgain,
                      ),
                    ),
            child: Text(s.save),
          ),
        ],
      ),
    );
  }
}
