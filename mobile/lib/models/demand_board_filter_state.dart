import 'demand_offer_acceptance.dart';

/// ตัวกรองบอร์ดประกาศหาทรัพย์ — ใช้ร่วมกับ [DemandBoardFilterSheet]
class DemandBoardFilterState {
  const DemandBoardFilterState({
    this.matchMyStock = false,
    this.seekerStatus = DemandBoardSeekerFilter.all,
    this.transaction = DemandBoardTransactionFilter.all,
    this.propertySlugs = const {},
    this.includeCommercial = true,
    this.offerAcceptance = DemandBoardOfferAcceptFilter.all,
    this.priceSort = DemandBoardPriceSort.recent,
  });

  final bool matchMyStock;
  final DemandBoardSeekerFilter seekerStatus;
  final DemandBoardTransactionFilter transaction;
  final Set<String> propertySlugs;
  final bool includeCommercial;
  final DemandBoardOfferAcceptFilter offerAcceptance;
  final DemandBoardPriceSort priceSort;

  static const commercialSlugs = <String>{
    'office',
    'commercial',
    'home_office',
    'showroom',
    'business',
    'warehouse',
    'factory',
    'co_working',
  };

  static const residentialFilterSlugs = <String>{
    'condo',
    'house',
    'land',
  };

  DemandBoardFilterState copyWith({
    bool? matchMyStock,
    DemandBoardSeekerFilter? seekerStatus,
    DemandBoardTransactionFilter? transaction,
    Set<String>? propertySlugs,
    bool? includeCommercial,
    DemandBoardOfferAcceptFilter? offerAcceptance,
    DemandBoardPriceSort? priceSort,
  }) {
    return DemandBoardFilterState(
      matchMyStock: matchMyStock ?? this.matchMyStock,
      seekerStatus: seekerStatus ?? this.seekerStatus,
      transaction: transaction ?? this.transaction,
      propertySlugs: propertySlugs ?? this.propertySlugs,
      includeCommercial: includeCommercial ?? this.includeCommercial,
      offerAcceptance: offerAcceptance ?? this.offerAcceptance,
      priceSort: priceSort ?? this.priceSort,
    );
  }

  static const initial = DemandBoardFilterState();

  DemandBoardFilterState cleared() => const DemandBoardFilterState();

  int get activeCount {
    var n = 0;
    if (matchMyStock) n++;
    if (seekerStatus != DemandBoardSeekerFilter.all) n++;
    if (transaction != DemandBoardTransactionFilter.all) n++;
    if (propertySlugs.isNotEmpty) n++;
    if (!includeCommercial) n++;
    if (offerAcceptance != DemandBoardOfferAcceptFilter.all) n++;
    if (priceSort != DemandBoardPriceSort.recent) n++;
    return n;
  }

  bool get hasActive => activeCount > 0;
}

enum DemandBoardSeekerFilter { all, customerDirect, agentSourced }

enum DemandBoardTransactionFilter { all, rent, sale }

enum DemandBoardOfferAcceptFilter { all, ownerOnly, ownerAndCoAgent }

enum DemandBoardPriceSort { recent, highToLow, lowToHigh }

extension DemandBoardSeekerFilterX on DemandBoardSeekerFilter {
  DemandLeadSource? get leadSource {
    switch (this) {
      case DemandBoardSeekerFilter.customerDirect:
        return DemandLeadSource.customerDirect;
      case DemandBoardSeekerFilter.agentSourced:
        return DemandLeadSource.coAgentSourced;
      case DemandBoardSeekerFilter.all:
        return null;
    }
  }
}
