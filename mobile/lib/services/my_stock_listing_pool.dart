import '../config/env.dart';
import '../models/listing_public.dart';
import 'auth_service.dart';
import 'listing_owner_repository.dart';
import 'supabase_service.dart';

/// โหลดประกาศใน MyStock ของผู้ใช้ — ใช้จับคู่กับบอร์ดหาทรัพย์
class MyStockListingPool {
  MyStockListingPool._();
  static final MyStockListingPool instance = MyStockListingPool._();

  final _ownerRepo = ListingOwnerRepository();
  List<ListingPublic>? _cache;
  DateTime? _cachedAt;

  static const _cacheTtl = Duration(minutes: 2);

  Future<List<ListingPublic>> load({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cache!;
    }

    final rows = await _ownerRepo.myListings(includeArchived: false);
    final pool = <ListingPublic>[];
    for (final row in rows) {
      final status = row['status']?.toString() ?? '';
      if (status != 'published' && status != 'pending_review') continue;
      try {
        pool.add(_listingFromOwnerRow(row));
      } catch (_) {}
    }

    _cache = pool;
    _cachedAt = DateTime.now();
    return pool;
  }

  void invalidate() {
    _cache = null;
    _cachedAt = null;
  }

  int get cachedCount => _cache?.length ?? 0;

  ListingPublic _listingFromOwnerRow(Map<String, dynamic> row) {
    return ListingPublic(
      id: row['id'] as String,
      listingCode: row['listing_code']?.toString() ?? '',
      listingType: row['listing_type']?.toString() ?? 'rent',
      title: row['title']?.toString() ?? '',
      priceNet: (row['price_net'] as num?)?.toDouble() ?? 0,
      propertyType: row['property_type']?.toString() ?? 'condo',
      district: row['district']?.toString(),
      projectName: row['project_name']?.toString(),
      areaSqm: (row['area_sqm'] as num?)?.toDouble(),
      geoZoneSlug: row['geo_zone_slug']?.toString(),
    );
  }

  bool get canLoadStock =>
      AuthService.instance.trialSimulatesBackend ||
      (Env.isConfigured && SupabaseService.isReady);
}
