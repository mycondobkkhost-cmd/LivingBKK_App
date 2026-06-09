import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/code_glossary.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/reference_codes.dart';

/// แสดงรหัสทรัพย์ / หมายเลขธุรกรรม พร้อมปุ่มคัดลอก
class ReferenceCodeChip extends StatelessWidget {
  const ReferenceCodeChip({
    super.key,
    required this.code,
    required this.label,
    this.compact = false,
    this.onCopied,
    this.onNavigate,
  });

  final String code;
  final String label;
  final bool compact;
  final VoidCallback? onCopied;
  /// กดชิปเพื่อเปิดหน้าอื่น — ปุ่มคัดลอกขวาไม่เรียก onNavigate
  final VoidCallback? onNavigate;

  Future<void> _copy(BuildContext context) async {
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).referenceCopied(code))),
    );
    onCopied?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (code.isEmpty) return const SizedBox.shrink();

    final mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: compact ? 11 : 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: AppTheme.primary,
    );

    final radius = compact ? 6.0 : 8.0;
    final s = AppStrings.of(context);
    final caption = CodeGlossary.captionFor(code, isEn: s.isEnglish);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label ',
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                color: AppTheme.textSecondary,
              ),
            ),
            Flexible(
              child: Text(code, style: mono, overflow: TextOverflow.ellipsis),
            ),
            if (onNavigate != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.open_in_new,
                size: compact ? 12 : 14,
                color: AppTheme.primary.withOpacity(0.7),
              ),
            ] else ...[
              const SizedBox(width: 4),
              Icon(
                Icons.copy,
                size: compact ? 12 : 14,
                color: AppTheme.primary.withOpacity(0.7),
              ),
            ],
          ],
        ),
        if (!compact && caption.isNotEmpty)
          Text(
            caption,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
      ],
    );

    if (onNavigate == null) {
      return Material(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: () => _copy(context),
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 4 : 6,
            ),
            child: body,
          ),
        ),
      );
    }

    return Material(
      color: AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(radius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onNavigate,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(radius),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 8 : 10,
                compact ? 4 : 6,
                4,
                compact ? 4 : 6,
              ),
              child: body,
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: compact ? 14 : 16),
            padding: EdgeInsets.all(compact ? 4 : 6),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
            tooltip: AppStrings.of(context).t('คัดลอก', 'Copy'),
            onPressed: () => _copy(context),
          ),
        ],
      ),
    );
  }
}

/// แถบรหัส 2 ชั้น (ทรัพย์ + ธุรกรรม) ใช้ในหน้าแชท
class TransactionReferenceBar extends StatelessWidget {
  const TransactionReferenceBar({
    super.key,
    this.listingCode,
    this.transactionRef,
    this.listingLabel,
    this.transactionLabel,
    this.onListingNavigate,
    this.onTransactionNavigate,
    this.leadId,
    this.listingId,
    this.threadId,
  });

  final String? listingCode;
  final String? transactionRef;
  final String? listingLabel;
  final String? transactionLabel;
  final VoidCallback? onListingNavigate;
  final VoidCallback? onTransactionNavigate;
  final String? leadId;
  final String? listingId;
  final String? threadId;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final chips = <Widget>[];

    if (listingCode != null &&
        listingCode!.isNotEmpty &&
        !ReferenceCodes.isSpecialListingCode(listingCode!)) {
      chips.add(
        ReferenceCodeChip(
          code: listingCode!,
          label: listingLabel ?? s.propertyCodeLabel,
          compact: true,
          onNavigate: onListingNavigate,
        ),
      );
    }
    if (transactionRef != null && transactionRef!.isNotEmpty) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 6));
      chips.add(
        ReferenceCodeChip(
          code: transactionRef!,
          label: transactionLabel ?? s.transactionRefLabel,
          compact: true,
          onNavigate: onTransactionNavigate,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppTheme.surfaceWarm,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips,
      ),
    );
  }
}
