import 'package:flutter/foundation.dart';

import '../models/listing_transaction_types.dart';
import '../models/search_filters.dart';

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

  void setCategorySlug(String? slug) {
    categorySlug = slug;
    filters = slug == null
        ? filters.copyWith(clearPropertyType: true)
        : filters.copyWith(propertyType: slug);
    notifyListeners();
  }

  void setListingType(String? type) {
    filters = type == null
        ? filters.copyWith(clearListingType: true)
        : filters.copyWith(listingType: type);
    notifyListeners();
  }
}
