import '../models/search_filters.dart';

/// Quick filters for investor / sale-with-tenant search.
abstract final class SearchInvestorFilters {
  static const withTenant = 'with_tenant';

  static bool isSaleWithTenant(SearchFilters filters) =>
      filters.investorCategory == withTenant;

  static SearchFilters toggleSaleWithTenant(SearchFilters filters) {
    if (isSaleWithTenant(filters)) {
      return filters.copyWith(clearInvestor: true);
    }
    return filters.copyWith(
      listingType: 'sale',
      investorCategory: withTenant,
    );
  }
}
