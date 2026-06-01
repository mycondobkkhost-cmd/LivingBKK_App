import 'listing_public.dart';

class ListingRouteExtra {
  const ListingRouteExtra({
    required this.listing,
    this.isAgent = false,
  });

  final ListingPublic listing;
  final bool isAgent;
}
