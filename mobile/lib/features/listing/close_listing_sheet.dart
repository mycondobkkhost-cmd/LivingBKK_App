import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

class CloseListingRentResult {
  const CloseListingRentResult({required this.availableAgain});

  final DateTime availableAgain;
}

Future<CloseListingRentResult?> showCloseListingRentSheet(BuildContext context) {
  return showModalBottomSheet<CloseListingRentResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => const _CloseRentBody(),
  );
}

class _CloseRentBody extends StatefulWidget {
  const _CloseRentBody();

  @override
  State<_CloseRentBody> createState() => _CloseRentBodyState();
}

class _CloseRentBodyState extends State<_CloseRentBody> {
  DateTime? _availableAgain;

  String _label(AppStrings s, DateTime? d) =>
      d == null ? s.selectDate : '${d.day}/${d.month}/${d.year + 543}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _availableAgain ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _availableAgain = picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.closeListingRentTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            s.closeListingRentHint,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_available_outlined, size: 18),
            label: Text(s.availableAgain(_label(s, _availableAgain))),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _availableAgain == null
                ? null
                : () => Navigator.pop(
                      context,
                      CloseListingRentResult(availableAgain: _availableAgain!),
                    ),
            child: Text(s.closeListingConfirm),
          ),
        ],
      ),
    );
  }
}

Future<bool?> confirmCloseListingSale(BuildContext context) {
  final s = AppStrings.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.archive_outlined, color: AppTheme.accentMid),
      title: Text(s.closeListingSaleTitle),
      content: Text(s.closeListingSaleHint, style: TextStyle(height: 1.45)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.closeListingConfirm)),
      ],
    ),
  );
}

Future<bool> confirmSoftDeleteListing(BuildContext context) async {
  final s = AppStrings.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.deleteListingTitle),
      content: Text(s.deleteListingHint, style: TextStyle(height: 1.45)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.accentDeep),
          child: Text(s.deleteListingConfirm),
        ),
      ],
    ),
  );
  return ok == true;
}
