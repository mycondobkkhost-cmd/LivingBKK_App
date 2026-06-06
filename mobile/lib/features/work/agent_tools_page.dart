import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_safe_insets.dart';
import '../../theme/li_layout.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

/// เครื่องมือเอเจนท์ — คำนวณค่าใช้จ่าย ณ วันโอน (แบบ LI AgentTool)
class AgentToolsPage extends StatefulWidget {
  const AgentToolsPage({super.key});

  @override
  State<AgentToolsPage> createState() => _AgentToolsPageState();
}

class _AgentToolsPageState extends State<AgentToolsPage> {
  final _price = TextEditingController(text: '3500000');
  final _transferFeePct = TextEditingController(text: '2');
  final _stampPct = TextEditingController(text: '0.5');
  final _mortgage = TextEditingController(text: '2500000');

  @override
  void dispose() {
    _price.dispose();
    _transferFeePct.dispose();
    _stampPct.dispose();
    _mortgage.dispose();
    super.dispose();
  }

  double? get _priceVal => double.tryParse(_price.text.replaceAll(',', ''));
  double? get _transferPct => double.tryParse(_transferFeePct.text);
  double? get _stampVal => double.tryParse(_stampPct.text);
  double? get _mortgageVal => double.tryParse(_mortgage.text.replaceAll(',', ''));

  double get _transferFee {
    final p = _priceVal ?? 0;
    return p * ((_transferPct ?? 2) / 100);
  }

  double get _stampDuty {
    final p = _priceVal ?? 0;
    return p * ((_stampVal ?? 0.5) / 100);
  }

  double get _total =>
      _transferFee + _stampDuty + 20000 + 5000; // 20k ค่าจด + 5k ประมาณอื่นๆ

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final fmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    return ConsumerPageShell(
      title: s.agentTools,
      onBack: () => Navigator.of(context).maybePop(),
      body: ListView(
        padding: PageSafeInsets.padLTRB(
          context,
          left: LiLayout.pagePadding,
          top: LiLayout.pagePadding,
          right: LiLayout.pagePadding,
          bottom: 16,
          addHomeIndicator: false,
        ),
        children: [
          Text(
            s.transferCostTitle,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: s.purchasePriceLabel),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _mortgage,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: s.mortgageAmountLabel),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _transferFeePct,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: s.transferFeePctLabel),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _stampPct,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: s.stampPctLabel),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppTheme.primaryLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _line(s.transferFeeLine, fmt.format(_transferFee)),
                  _line(s.stampDutyLine, fmt.format(_stampDuty)),
                  _line(s.mortgageRegApprox, fmt.format(20000)),
                  _line(s.otherFeesApprox, fmt.format(5000)),
                  const Divider(),
                  _line(s.totalApprox, fmt.format(_total), bold: true),
                  if (_mortgageVal != null && _priceVal != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      s.downPaymentApprox(
                        fmt.format((_priceVal! - _mortgageVal!).clamp(0, double.infinity)),
                      ),
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.agentToolsDisclaimer,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
