import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/commission_agreement_context.dart';
import '../../models/lead_success_fee.dart';
import '../../services/commission_agreement_repository.dart';
import '../../theme/app_theme.dart';

/// ป๊อปอัพข้อตกลงค่าคอม — บังคับก่อนโพส / เสนอทรัพย์ / รับเคส / ยืนยันนัด
Future<bool> showCommissionAgreementSheet(
  BuildContext context, {
  required CommissionAgreementContext agreementContext,
  required String title,
  required List<String> summaryLines,
  Map<String, dynamic>? schemeSnapshot,
  String? listingId,
  String? leadId,
  String? offerId,
  String? viewingRequestId,
  LeadSuccessFeeSummary? successFee,
  String? listingCode,
}) async {
  final agreed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _CommissionAgreementBody(
      title: title,
      summaryLines: summaryLines,
      successFee: successFee,
      listingCode: listingCode,
    ),
  );
  if (agreed != true) return false;

  await CommissionAgreementRepository.instance.record(
    context: agreementContext,
    schemeSnapshot: schemeSnapshot ?? {
      'title': title,
      'lines': summaryLines,
      if (listingCode != null) 'listing_code': listingCode,
    },
    listingId: listingId,
    leadId: leadId,
    offerId: offerId,
    viewingRequestId: viewingRequestId,
  );
  return true;
}

class _CommissionAgreementBody extends StatefulWidget {
  const _CommissionAgreementBody({
    required this.title,
    required this.summaryLines,
    this.successFee,
    this.listingCode,
  });

  final String title;
  final List<String> summaryLines;
  final LeadSuccessFeeSummary? successFee;
  final String? listingCode;

  @override
  State<_CommissionAgreementBody> createState() =>
      _CommissionAgreementBodyState();
}

class _CommissionAgreementBodyState extends State<_CommissionAgreementBody> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final fee = widget.successFee;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (widget.listingCode != null && widget.listingCode!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.listingCodeLabel(widget.listingCode!),
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
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
                  s.t(
                    'สรุปข้อตกลงค่าคอมมิชชัน',
                    'Commission agreement summary',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (fee != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    fee.capacityLine,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fee.contractLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fee.feeRuleLine,
                    style: const TextStyle(fontSize: 15, height: 1.35),
                  ),
                  if (fee.feeAmountLine != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      fee.feeAmountLine!,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
                ...widget.summaryLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $line',
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.t(
                    'หากปิดดีลสำเร็จ ต้องชำระ Success Fee ตามที่ระบุ — '
                    'RealXtate เป็นตัวกลางประสานงานเท่านั้น',
                    'On successful deal, Success Fee applies as stated — '
                    'RealXtate acts as intermediary only',
                  ),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            title: Text(
              s.t(
                'ข้าพเจ้าอ่านและยอมรับข้อตกลงค่าคอมมิชชันข้างต้น',
                'I have read and accept the commission terms above',
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _agreed ? () => Navigator.pop(context, true) : null,
            child: Text(s.t('ยืนยันและดำเนินการต่อ', 'Confirm and continue')),
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
