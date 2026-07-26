import '../models/demand_post.dart';
import '../models/listing_public.dart';
import '../models/offer_commission_scheme.dart';

/// ดึงข้อมูลเสนอทรัพย์จากประกาศที่ลงไว้แล้ว (ฐานะเจ้าของ/โคนายหน้า ฯลฯ)
abstract final class ListingOfferMeta {
  static String offererCapacity(ListingPublic listing) {
    final type = listing.coAgentListingType;
    if (type == 'co_agent_50_50') return 'co_agent_50_50';
    return 'owner_direct_100';
  }

  static bool isAgentPoster(ListingPublic listing) =>
      listing.coAgentListingType == 'co_agent_50_50';

  static String transactionType(ListingPublic listing, DemandPost post) {
    final fromListing =
        OfferCommissionScheme.transactionForListing(listing.listingType);
    if (post.transactionType == 'rent' && fromListing == 'rent') return 'rent';
    if (post.transactionType == 'sale' &&
        (fromListing == 'sale' || listing.listingType == 'sale_installment')) {
      return 'sale';
    }
    return fromListing;
  }

  static String defaultCommissionFor(
    ListingPublic listing,
    DemandPost post,
  ) {
    return OfferCommissionScheme.optionsFor(
      transactionType: transactionType(listing, post),
      offererCapacity: offererCapacity(listing),
    ).first;
  }

  static String displayTitle(ListingPublic listing) {
    final project = listing.projectName?.trim();
    if (project != null && project.isNotEmpty) {
      return '$project · ${listing.title}';
    }
    return listing.title;
  }

  static String? coverUrl(ListingPublic listing) {
    if (listing.imageUrls.isNotEmpty) return listing.imageUrls.first;
    return null;
  }
}
