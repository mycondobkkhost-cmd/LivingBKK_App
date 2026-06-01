import 'package:geolocator/geolocator.dart';

import 'supabase_service.dart';

class ListingCreateInput {
  const ListingCreateInput({
    required this.title,
    required this.listingType,
    required this.propertyType,
    required this.priceNet,
    required this.district,
    this.description,
    this.areaSqm,
    this.bedrooms,
    this.coAgentListingType,
  });

  final String title;
  final String listingType;
  final String propertyType;
  final double priceNet;
  final String district;
  final String? description;
  final double? areaSqm;
  final int? bedrooms;
  final String? coAgentListingType;
}

class ListingCreateRepository {
  Future<String> createDraft(ListingCreateInput input) async {
    if (!SupabaseService.isReady) {
      throw Exception('ต้องล็อกอินและตั้งค่า Supabase');
    }

    final uid = SupabaseService.client!.auth.currentUser!.id;

    double? lat;
    double? lng;
    try {
      final pos = await Geolocator.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {
      lat = 13.7367;
      lng = 100.5608;
    }

    final row = await SupabaseService.client!
        .from('listings')
        .insert({
          'owner_id': uid,
          'created_by_id': uid,
          'listed_by_role': 'owner',
          'owner_verified': true,
          'title': input.title,
          'listing_type': input.listingType,
          'property_type': input.propertyType,
          'price_net': input.priceNet,
          'district': input.district,
          'description_public': input.description,
          'area_sqm': input.areaSqm,
          'bedrooms': input.bedrooms,
          'co_agent_listing_type': input.coAgentListingType,
          'status': 'draft',
          'location_exact': {
            'type': 'Point',
            'coordinates': [lng, lat],
          },
          'location_public': {
            'type': 'Point',
            'coordinates': [lng, lat],
          },
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<void> publish(String listingId) async {
    await SupabaseService.client!
        .from('listings')
        .update({
          'status': 'published',
          'published_at': DateTime.now().toUtc().toIso8601String(),
          'last_bump_at': DateTime.now().toUtc().toIso8601String(),
          'expires_at':
              DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
        })
        .eq('id', listingId);
  }
}
