import 'listing_public.dart';

class HomeSectionRouteExtra {
  const HomeSectionRouteExtra({
    required this.title,
    required this.items,
    required this.isAgent,
  });

  final String title;
  final List<ListingPublic> items;
  final bool isAgent;
}
