import '../l10n/app_strings.dart';

/// สถานะทรัพย์ตอนลงประกาศ
abstract final class ListingOccupancyStatus {
  static const ready = 'ready';
  static const renovating = 'renovating';
  static const tenanted = 'tenanted';
  static const saleWithTenant = 'sale_with_tenant';

  static List<String> optionsFor(String listingType) {
    if (listingType == 'rent_and_sale') {
      return [ready, renovating, tenanted, saleWithTenant];
    }
    final isSale =
        listingType == 'sale' || listingType == 'sale_installment';
    if (isSale) {
      return [ready, renovating, saleWithTenant];
    }
    return [ready, renovating, tenanted];
  }

  static bool needsAvailableDate(String status) =>
      status == renovating || status == tenanted || status == saleWithTenant;

  static bool allowsViewingDuring(String status) =>
      status == renovating || status == tenanted;

  static bool needsTenantRent(String status, String listingType) =>
      status == saleWithTenant &&
      (listingType == 'sale' ||
          listingType == 'sale_installment' ||
          listingType == 'rent_and_sale');

  static double? yieldPercent({
    required double salePrice,
    required double monthlyRent,
  }) {
    if (salePrice <= 0 || monthlyRent <= 0) return null;
    return (monthlyRent * 12 / salePrice) * 100;
  }
}

class ListingOccupancyInput {
  const ListingOccupancyInput({
    this.status = ListingOccupancyStatus.ready,
    this.availableDate,
    this.viewingAllowedDuring = false,
    this.tenantMonthlyRent,
  });

  final String status;
  final DateTime? availableDate;
  final bool viewingAllowedDuring;
  final double? tenantMonthlyRent;

  ListingOccupancyInput copyWith({
    String? status,
    DateTime? availableDate,
    bool clearDate = false,
    bool? viewingAllowedDuring,
    double? tenantMonthlyRent,
    bool clearRent = false,
  }) {
    return ListingOccupancyInput(
      status: status ?? this.status,
      availableDate: clearDate ? null : (availableDate ?? this.availableDate),
      viewingAllowedDuring: viewingAllowedDuring ?? this.viewingAllowedDuring,
      tenantMonthlyRent:
          clearRent ? null : (tenantMonthlyRent ?? this.tenantMonthlyRent),
    );
  }

  String readyLabel(AppStrings s, String propertySlug) =>
      s.occupancyReadyLabel(propertySlug);

  String statusLabel(AppStrings s, String code) {
    switch (code) {
      case ListingOccupancyStatus.renovating:
        return s.occupancyRenovating;
      case ListingOccupancyStatus.tenanted:
        return s.occupancyTenanted;
      case ListingOccupancyStatus.saleWithTenant:
        return s.occupancySaleWithTenant;
      default:
        return readyLabel(s, 'condo');
    }
  }

  Map<String, dynamic> toDbFields({double? salePrice}) {
    final fields = <String, dynamic>{
      'occupancy_status': status,
      'viewing_allowed_during': viewingAllowedDuring,
    };
    String? dateIso;
    if (availableDate != null) {
      dateIso = DateTime(
        availableDate!.year,
        availableDate!.month,
        availableDate!.day,
      ).toIso8601String().split('T').first;
    }
    switch (status) {
      case ListingOccupancyStatus.renovating:
        if (dateIso != null) fields['available_from'] = dateIso;
        break;
      case ListingOccupancyStatus.tenanted:
        if (dateIso != null) {
          fields['available_again'] = dateIso;
          fields['contract_occupied_until'] = dateIso;
        }
        break;
      case ListingOccupancyStatus.saleWithTenant:
        fields['investor_category'] = 'with_tenant';
        if (tenantMonthlyRent != null) {
          fields['monthly_rent_for_yield'] = tenantMonthlyRent;
          if (salePrice != null && salePrice > 0) {
            final y = ListingOccupancyStatus.yieldPercent(
              salePrice: salePrice,
              monthlyRent: tenantMonthlyRent!,
            );
            if (y != null) fields['yield_percent'] = double.parse(y.toStringAsFixed(2));
          }
        }
        if (dateIso != null) fields['available_again'] = dateIso;
        break;
      default:
        fields['investor_category'] = 'none';
    }
    return fields;
  }

  String summary(AppStrings s, String propertySlug) {
    if (status == ListingOccupancyStatus.ready) {
      return readyLabel(s, propertySlug);
    }
    final dateStr = availableDate != null
        ? '${availableDate!.day}/${availableDate!.month}/${availableDate!.year}'
        : '—';
    switch (status) {
      case ListingOccupancyStatus.renovating:
        return '${s.occupancyRenovating} · ${s.occupancyReadyOnDate(dateStr)}';
      case ListingOccupancyStatus.tenanted:
        return '${s.occupancyTenanted} · ${s.occupancyReadyOnDate(dateStr)}';
      case ListingOccupancyStatus.saleWithTenant:
        final rent = tenantMonthlyRent?.toStringAsFixed(0) ?? '—';
        return '${s.occupancySaleWithTenant} · ${s.occupancyCurrentRent(rent)}';
      default:
        return readyLabel(s, propertySlug);
    }
  }
}
