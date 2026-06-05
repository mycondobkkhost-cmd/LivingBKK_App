import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/commission_tier.dart';
import '../../theme/app_theme.dart';

Future<bool?> showEContractSheet(
  BuildContext context, {
  required CommissionTier tier,
  required String listingCode,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _EContractBody(tier: tier, listingCode: listingCode),
  );
}

class _EContractBody extends StatefulWidget {
  const _EContractBody({required this.tier, required this.listingCode});

  final CommissionTier tier;
  final String listingCode;

  @override
  State<_EContractBody> createState() => _EContractBodyState();
}

class _EContractBodyState extends State<_EContractBody> {
  bool _agreed = false;

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
            s.eContractTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            s.listingCodeLabel(widget.listingCode),
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.tier.name,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(widget.tier.splitSummary),
                const SizedBox(height: 12),
                Text(
                  s.eContractPolicy,
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            title: Text(s.eContractAcceptCommission),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _agreed ? () => Navigator.pop(context, true) : null,
            child: Text(s.eContractConfirm),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
        ],
      ),
    );
  }
}
