import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

/// เหตุผลปิดประกาศแบบถาวร
abstract final class CloseRentPermanentReason {
  static const sold = 'sold';
  static const stopRent = 'stop_rent';
  static const unavailable = 'unavailable';
}

enum _CloseMode { permanent, tenanted }

class CloseListingRentResult {
  const CloseListingRentResult.availableLater({required this.availableAgain})
      : permanent = false,
        permanentReason = null;

  const CloseListingRentResult.permanent({required this.permanentReason})
      : permanent = true,
        availableAgain = null;

  final bool permanent;
  final DateTime? availableAgain;
  final String? permanentReason;
}

Future<CloseListingRentResult?> showCloseListingRentSheet(
  BuildContext context, {
  String listingType = 'rent',
}) {
  return showModalBottomSheet<CloseListingRentResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _CloseRentBody(listingType: listingType),
  );
}

class _CloseRentBody extends StatefulWidget {
  const _CloseRentBody({required this.listingType});

  final String listingType;

  @override
  State<_CloseRentBody> createState() => _CloseRentBodyState();
}

class _CloseRentBodyState extends State<_CloseRentBody> {
  _CloseMode _mode = _CloseMode.tenanted;
  String _permanentReason = CloseRentPermanentReason.sold;
  DateTime? _availableAgain;

  bool get _isRent => widget.listingType == 'rent';

  bool get _canConfirm {
    if (!_isRent) return _permanentReason.isNotEmpty;
    if (_mode == _CloseMode.tenanted) return _availableAgain != null;
    return _permanentReason.isNotEmpty;
  }

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

  void _submit() {
    if (!_canConfirm) return;
    if (_isRent && _mode == _CloseMode.tenanted) {
      Navigator.pop(
        context,
        CloseListingRentResult.availableLater(availableAgain: _availableAgain!),
      );
      return;
    }
    Navigator.pop(
      context,
      CloseListingRentResult.permanent(permanentReason: _permanentReason),
    );
  }

  String _confirmLabel(AppStrings s) {
    if (_isRent && _mode == _CloseMode.tenanted) {
      return s.closeListingTenantedConfirm;
    }
    return s.closeListingPermanentDeleteConfirm;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return SizedBox(
      height: maxH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isRent ? s.closeListingRentTitle : s.closeListingSaleTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.closeListingRentHint,
                    style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                  ),
                  if (_isRent) ...[
                    const SizedBox(height: 16),
                    _modeCard(
                      selected: _mode == _CloseMode.tenanted,
                      title: s.closeListingModeTenanted,
                      subtitle: s.closeListingModeTenantedHint,
                      onTap: () => setState(() => _mode = _CloseMode.tenanted),
                    ),
                    const SizedBox(height: 8),
                    _modeCard(
                      selected: _mode == _CloseMode.permanent,
                      title: s.closeListingModePermanent,
                      subtitle: s.closeListingModePermanentHint,
                      onTap: () => setState(() => _mode = _CloseMode.permanent),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!_isRent || _mode == _CloseMode.permanent) ...[
                    Text(
                      s.closeListingRentPermanentSection,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    _reasonOption(
                      value: CloseRentPermanentReason.sold,
                      title: s.closeRentReasonSold,
                      subtitle: s.closeRentReasonSoldHint,
                    ),
                    _reasonOption(
                      value: CloseRentPermanentReason.stopRent,
                      title: _isRent
                          ? s.closeRentReasonStopRent
                          : s.closeSaleReasonStopSale,
                      subtitle: _isRent
                          ? s.closeRentReasonStopRentHint
                          : s.closeSaleReasonStopSaleHint,
                    ),
                    _reasonOption(
                      value: CloseRentPermanentReason.unavailable,
                      title: s.closeRentReasonUnavailable,
                      subtitle: s.closeRentReasonUnavailableHint,
                    ),
                  ],
                  if (_isRent && _mode == _CloseMode.tenanted) ...[
                    Text(
                      s.closeListingTenantedDateSection,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.closeListingTenantedDateHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event_available_outlined, size: 18),
                      label: Text(s.availableAgain(_label(s, _availableAgain))),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.closeListingTenantedReminderNote,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _canConfirm ? _submit : null,
                  child: Text(_confirmLabel(s)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.cancel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeCard({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: selected ? 1 : 0,
      color: selected ? AppTheme.primaryLight.withOpacity(0.55) : AppTheme.cardTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? AppTheme.primary.withOpacity(0.5)
              : AppTheme.textSecondary.withOpacity(0.2),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: selected ? AppTheme.primary : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reasonOption({
    required String value,
    required String title,
    required String subtitle,
  }) {
    final selected = _permanentReason == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: selected ? 1 : 0,
        color: selected ? AppTheme.primaryLight.withOpacity(0.35) : AppTheme.cardTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? AppTheme.primary.withOpacity(0.4)
                : AppTheme.textSecondary.withOpacity(0.15),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _permanentReason = value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> confirmCloseListingSale(BuildContext context) async {
  final result = await showCloseListingRentSheet(context, listingType: 'sale');
  if (result == null) return false;
  return true;
}

Future<bool> confirmSoftDeleteListing(BuildContext context) async {
  final s = AppStrings.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.deleteListingTitle),
      content: Text(s.deleteListingHint, style: const TextStyle(height: 1.45)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.accentDeep),
          child: Text(s.hideListingFromMine),
        ),
      ],
    ),
  );
  return ok == true;
}
