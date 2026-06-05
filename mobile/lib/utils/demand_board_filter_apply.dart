import '../data/property_catalog.dart';
import '../models/demand_board_filter_state.dart';
import '../models/demand_offer_acceptance.dart';
import '../models/demand_post.dart';
import '../models/listing_public.dart';
import '../services/demand_mystock_match_service.dart';

List<DemandPost> applyDemandBoardFilters({
  required List<DemandPost> posts,
  required DemandBoardFilterState filters,
  required Map<String, int> myStockScores,
}) {
  var list = List<DemandPost>.from(posts);

  if (filters.matchMyStock) {
    list = list.where((p) => myStockScores.containsKey(p.id)).toList();
  }

  final seeker = filters.seekerStatus.leadSource;
  if (seeker != null) {
    list = list.where((p) => p.leadSource == seeker).toList();
  }

  switch (filters.transaction) {
    case DemandBoardTransactionFilter.rent:
      list = list.where((p) => p.transactionType == 'rent').toList();
      break;
    case DemandBoardTransactionFilter.sale:
      list = list.where((p) => p.transactionType == 'sale').toList();
      break;
    case DemandBoardTransactionFilter.all:
      break;
  }

  if (filters.propertySlugs.isNotEmpty) {
    final allowedDb = _allowedDbTypes(filters);
    list = list.where((p) => allowedDb.contains(p.propertyType)).toList();
  }

  switch (filters.offerAcceptance) {
    case DemandBoardOfferAcceptFilter.ownerOnly:
      list = list
          .where(
            (p) =>
                p.offerAcceptancePolicy ==
                DemandOfferAcceptancePolicy.ownerOnly,
          )
          .toList();
      break;
    case DemandBoardOfferAcceptFilter.ownerAndCoAgent:
      list = list
          .where(
            (p) =>
                p.offerAcceptancePolicy ==
                DemandOfferAcceptancePolicy.ownerAndCoAgent,
          )
          .toList();
      break;
    case DemandBoardOfferAcceptFilter.all:
      break;
  }

  return list;
}

Set<String> _allowedDbTypes(DemandBoardFilterState filters) {
  final allowed = <String>{};
  for (final slug in filters.propertySlugs) {
    if (slug == 'house') {
      allowed.addAll(['house', 'townhouse']);
      continue;
    }
    final db = PropertyCatalog.dbValueForSlug(slug);
    if (db != null) allowed.add(db);
  }
  return allowed;
}

int compareDemandPostsByPriceSort(
  DemandPost a,
  DemandPost b,
  DemandBoardPriceSort sort,
) {
  final pa = a.maxPriceNet ?? 0;
  final pb = b.maxPriceNet ?? 0;
  switch (sort) {
    case DemandBoardPriceSort.highToLow:
      return pb.compareTo(pa);
    case DemandBoardPriceSort.lowToHigh:
      return pa.compareTo(pb);
    case DemandBoardPriceSort.recent:
      return b.displayTime.compareTo(a.displayTime);
  }
}

void sortDemandPosts(
  List<DemandPost> list,
  DemandBoardPriceSort sort, {
  bool openOnly = true,
}) {
  final open = list.where((p) => p.status == 'open').toList();
  final closed = list.where((p) => p.status != 'open').toList();
  open.sort((a, b) {
    if (a.isUrgentRush != b.isUrgentRush) return a.isUrgentRush ? -1 : 1;
    if (a.isCashCase != b.isCashCase) return a.isCashCase ? -1 : 1;
    if (sort == DemandBoardPriceSort.recent) {
      return compareDemandPostsByPriceSort(a, b, sort);
    }
    return compareDemandPostsByPriceSort(a, b, sort);
  });
  closed.sort((a, b) => b.displayTime.compareTo(a.displayTime));
  list
    ..clear()
    ..addAll([...open, ...closed]);
}
