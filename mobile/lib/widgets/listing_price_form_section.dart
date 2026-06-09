import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/listing_transaction_types.dart';
import '../theme/app_theme.dart';

/// ฟอร์มราคา — แยกเช่า/ขายเมื่อ rent_and_sale + โปรโมชั่นแบบราคาขีดฆ่า
class ListingPriceFormSection extends StatelessWidget {
  const ListingPriceFormSection({
    super.key,
    required this.listingType,
    required this.rentPriceController,
    required this.salePriceController,
    required this.rentPromoController,
    required this.salePromoController,
    required this.rentPromoEnabled,
    required this.salePromoEnabled,
    required this.onRentPromoEnabled,
    required this.onSalePromoEnabled,
    this.onChanged,
    this.inputBorder = const OutlineInputBorder(),
  });

  final String listingType;
  final TextEditingController rentPriceController;
  final TextEditingController salePriceController;
  final TextEditingController rentPromoController;
  final TextEditingController salePromoController;
  final bool rentPromoEnabled;
  final bool salePromoEnabled;
  final ValueChanged<bool> onRentPromoEnabled;
  final ValueChanged<bool> onSalePromoEnabled;
  final VoidCallback? onChanged;
  final InputBorder inputBorder;

  bool get _isDual => ListingTransactionTypes.isRentAndSale(listingType);
  bool get _showRent =>
      ListingTransactionTypes.hasRentComponent(listingType);
  bool get _showSale =>
      ListingTransactionTypes.hasSaleComponent(listingType);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showRent)
          _PriceTierCard(
            title: _isDual ? s.createListingRentPriceSection : s.createListingRentPriceLabel,
            fullLabel: s.createListingFullPriceLabel,
            fullController: rentPriceController,
            promoEnabled: rentPromoEnabled,
            onPromoEnabled: onRentPromoEnabled,
            promoController: rentPromoController,
            promoLabel: s.createListingPromoPriceLabel,
            perMonth: true,
            inputBorder: inputBorder,
            onChanged: onChanged,
          ),
        if (_showRent && _showSale) const SizedBox(height: 16),
        if (_showSale)
          _PriceTierCard(
            title: _isDual ? s.createListingSalePriceSection : s.createListingSalePriceLabel,
            fullLabel: s.createListingFullPriceLabel,
            fullController: _isDual ? salePriceController : rentPriceController,
            promoEnabled: salePromoEnabled,
            onPromoEnabled: onSalePromoEnabled,
            promoController: salePromoController,
            promoLabel: s.createListingPromoPriceLabel,
            perMonth: false,
            inputBorder: inputBorder,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

class _PriceTierCard extends StatelessWidget {
  const _PriceTierCard({
    required this.title,
    required this.fullLabel,
    required this.fullController,
    required this.promoEnabled,
    required this.onPromoEnabled,
    required this.promoController,
    required this.promoLabel,
    required this.perMonth,
    required this.inputBorder,
    this.onChanged,
  });

  final String title;
  final String fullLabel;
  final TextEditingController fullController;
  final bool promoEnabled;
  final ValueChanged<bool> onPromoEnabled;
  final TextEditingController promoController;
  final String promoLabel;
  final bool perMonth;
  final InputBorder inputBorder;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          TextField(
            controller: fullController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '$fullLabel *',
              border: inputBorder,
              prefixText: '฿ ',
              suffixText: perMonth ? s.perMonth.trim() : s.bahtUnit,
            ),
            onChanged: (_) => onChanged?.call(),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              s.createListingPromoToggle,
              style: const TextStyle(fontSize: 14),
            ),
            value: promoEnabled,
            onChanged: onPromoEnabled,
          ),
          if (promoEnabled) ...[
            TextField(
              controller: promoController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: promoLabel,
                border: inputBorder,
                prefixText: '฿ ',
                suffixText: perMonth ? s.perMonth.trim() : s.bahtUnit,
              ),
              onChanged: (_) => onChanged?.call(),
            ),
            const SizedBox(height: 8),
            _PromoPreviewCard(
              fullController: fullController,
              promoController: promoController,
              perMonth: perMonth,
            ),
          ],
        ],
      ),
    );
  }
}

class _PromoPreviewCard extends StatelessWidget {
  const _PromoPreviewCard({
    required this.fullController,
    required this.promoController,
    required this.perMonth,
  });

  final TextEditingController fullController;
  final TextEditingController promoController;
  final bool perMonth;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final main = double.tryParse(fullController.text.replaceAll(',', ''));
    final promo = double.tryParse(promoController.text.replaceAll(',', ''));
    if (main == null || main <= 0 || promo == null || promo <= 0 || promo >= main) {
      return const SizedBox.shrink();
    }
    final fmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    final suffix = perMonth ? s.perMonth : '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.createListingPromoPreviewTitle,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            '${fmt.format(main)}$suffix',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '${fmt.format(promo)}$suffix',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.accentDeep,
            ),
          ),
        ],
      ),
    );
  }
}
