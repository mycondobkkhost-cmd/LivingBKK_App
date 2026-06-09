import 'package:flutter/foundation.dart';

import '../models/listing_transaction_types.dart';
import '../models/search_filters.dart';
import '../utils/search_investor_filters.dart';

/// ตัวกรองร่วมระหว่างหน้ารายการกับแท็บแผนที่
class SearchSessionController extends ChangeNotifier {
  SearchFilters filters = const SearchFilters();
  String? categorySlug;

  bool get isSale => ListingTransactionTypes.isSaleFamily(filters.listingType);
  bool get isRent => !isSale;

  void setFilters(SearchFilters value) {
    filters = value;
    categorySlug = value.propertyType;
    notifyListeners();
  }

  void clearZoneFilters() {
    filters = filters.copyWith(
      clearGeoZones: true,
      clearTransit: true,
      clearProjectSlugs: true,
      clearEducation: true,
    );
    notifyListeners();
  }

  void setCategorySlug(String? slug) {
    categorySlug = slug;
    filters = slug == null
        ? filters.copyWith(clearPropertyType: true)
        : filters.copyWith(propertyType: slug);
    notifyListeners();
  }

  void setListingType(String? type) {
    if (type == null) {
      filters = filters.copyWith(clearListingType: true);
    } else {
      filters = filters.copyWith(
        listingType: type,
        clearInvestor: type == 'rent',
      );
    }
    notifyListeners();
  }

  void toggleSaleWithTenant() {
    filters = SearchInvestorFilters.toggleSaleWithTenant(filters);
    notifyListeners();
  }
}
