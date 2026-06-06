import '../config/env.dart';
import '../data/demo_listings_factory.dart';
import '../data/property_catalog.dart';
import '../models/listing_public.dart';
import '../models/listing_transaction_types.dart';
import '../models/search_filters.dart';
import '../utils/geo_zone_match.dart';
import '../utils/metro_region.dart';
import 'supabase_service.dart';

class ListingRepository {
  /// true = แสดงทรัพย์ตัวอย่างในแอป (Supabase ว่างหรือยังไม่ seed)
  static bool lastFetchUsedDemo = false;

  Future<String?> resolveIdByCode(String listingCode) async {
    if (!SupabaseService.isReady || listingCode.isEmpty) return null;
    final row = await SupabaseService.client!
        .from('listings')
        .select('id')
        .eq('listing_code', listingCode)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<List<ListingPublic>> fetchPublished({
    String? listingType,
    bool coAgentEligibleOnly = false,
    SearchFilters? filters,
  }) async {
    lastFetchUsedDemo = false;

    if (!Env.isConfigured || !SupabaseService.isReady) {
      lastFetchUsedDemo = true;
      return _applyFilters(
        DemoListingsFactory.cached,
        listingType: listingType,
        coAgentEligibleOnly: coAgentEligibleOnly,
        filters: filters,
      );
    }

    try {
      return await _fetchFromSupabase(
        listingType: listingType,
        coAgentEligibleOnly: coAgentEligibleOnly,
        filters: filters,
      );
    } catch (_) {
      lastFetchUsedDemo = true;
      return _applyFilters(
        DemoListingsFactory.cached,
        listingType: listingType,
        coAgentEligibleOnly: coAgentEligibleOnly,
        filters: filters,
      );
    }
  }

  Future<List<ListingPublic>> _fetchFromSupabase({
    String? listingType,
    bool coAgentEligibleOnly = false,
    SearchFilters? filters,
  }) async {
    var query = SupabaseService.client!.from('listings_public').select();

    final f = filters;
    final effectiveType = f?.listingType ?? listingType;
    if (effectiveType == ListingTransactionTypes.sale) {
      query = query.inFilter('listing_type', [
        ListingTransactionTypes.sale,
        ListingTransactionTypes.saleInstallment,
      ]);
    } else if (effectiveType != null) {
      query = query.eq('listing_type', effectiveType);
    }
    if (coAgentEligibleOnly) {
      query = query.eq('co_agent_eligible', true);
    }
    if (f?.propertyType != null) {
      final db = PropertyCatalog.dbValueForSlug(f!.propertyType!) ?? f.propertyType!;
      query = query.eq('property_type', db);
    }
    if (f?.minPrice != null) {
      query = query.gte('price_net', f!.minPrice!);
    }
    if (f?.maxPrice != null) {
      query = query.lte('price_net', f!.maxPrice!);
    }
    if (f?.bedrooms != null) {
      query = query.eq('bedrooms', f!.bedrooms!);
    }
    if (f?.petAllowed == true) {
      query = query.eq('pet_allowed', true);
    }
    if (f?.investorCategory != null) {
      query = query.eq('investor_category', f!.investorCategory!);
    }
    if (f?.minYield != null) {
      query = query.gte('yield_percent', f!.minYield!);
    }
    if (f?.projectName != null && f!.projectName!.isNotEmpty) {
      query = query.ilike('project_name', '%${f.projectName}%');
    }
    if (f?.geoZoneSlugs != null && f!.geoZoneSlugs!.isNotEmpty) {
      query = query.inFilter('geo_zone_slug', f.geoZoneSlugs!);
    }

    final data = await query.order('published_at', ascending: false);
    var list = (data as List)
        .map((e) => ListingPublic.fromJson(e as Map<String, dynamic>))
        .toList();

    if (f?.geoZoneSlugs != null && f!.geoZoneSlugs!.isNotEmpty) {
      list = list
          .where((l) =>
              l.geoZoneSlug != null && f.geoZoneSlugs!.contains(l.geoZoneSlug))
          .toList();
    }

    list = _applyClientOnlyFilters(list, f, skipGeo: f?.geoZoneSlugs != null);
    list = MetroRegion.filterListings(list);

    if (list.isEmpty) {
      lastFetchUsedDemo = true;
      return _applyFilters(
        DemoListingsFactory.cached,
        listingType: listingType,
        coAgentEligibleOnly: coAgentEligibleOnly,
        filters: filters,
      );
    }
    return list;
  }

  List<ListingPublic> _applyFilters(
    List<ListingPublic> list, {
    String? listingType,
    bool coAgentEligibleOnly = false,
    SearchFilters? filters,
  }) {
    final f = filters;
    final effectiveType = f?.listingType ?? listingType;

    if (effectiveType != null) {
      list = list
          .where((l) => ListingTransactionTypes.matchesBrowseFilter(
                effectiveType,
                l.listingType,
              ))
          .toList();
    }
    if (coAgentEligibleOnly) {
      list = list.where((l) => l.coAgentEligible).toList();
    }
    if (f?.propertyType != null) {
      final db = PropertyCatalog.dbValueForSlug(f!.propertyType!) ?? f.propertyType!;
      list = list
          .where((l) => l.propertyType == db || l.propertyType == f.propertyType)
          .toList();
    }
    if (f?.minPrice != null) {
      list = list.where((l) => l.priceNet >= f!.minPrice!).toList();
    }
    if (f?.maxPrice != null) {
      list = list.where((l) => l.priceNet <= f!.maxPrice!).toList();
    }
    if (f?.bedrooms != null) {
      list = list.where((l) => (l.bedrooms ?? 0) == f!.bedrooms).toList();
    }
    if (f?.petAllowed == true) {
      list = list.where((l) => l.petAllowed).toList();
    }
    if (f?.investorCategory != null) {
      list = list.where((l) => l.investorCategory == f!.investorCategory).toList();
    }
    if (f?.minYield != null) {
      list = list
          .where((l) => (l.yieldPercent ?? 0) >= f!.minYield!)
          .toList();
    }
    if (f?.projectName != null) {
      final p = f!.projectName!.toLowerCase();
      list = list
          .where((l) =>
              (l.projectName?.toLowerCase().contains(p) ?? false) ||
              l.title.toLowerCase().contains(p))
          .toList();
    }
    return MetroRegion.filterListings(
      _applyClientOnlyFilters(list, f, skipGeo: f?.geoZoneSlugs != null),
    );
  }

  List<ListingPublic> _applyClientOnlyFilters(
    List<ListingPublic> list,
    SearchFilters? f, {
    bool skipGeo = false,
  }) {
    if (f == null) return list;

    if (!skipGeo && f.geoZoneSlugs != null && f.geoZoneSlugs!.isNotEmpty) {
      list = list
          .where((l) => listingMatchesGeoZones(
                slugs: f.geoZoneSlugs!,
                district: l.district,
                projectName: l.projectName,
                title: l.title,
              ))
          .toList();
    }

    if (f.query != null && f.query!.trim().isNotEmpty) {
      final q = f.query!.toLowerCase();
      list = list.where((l) {
        final hay = [
          l.title,
          l.projectName,
          l.district,
          l.listingCode,
        ].whereType<String>().join(' ').toLowerCase();
        return q.split(RegExp(r'\s+')).every((t) => t.length < 2 || hay.contains(t));
      }).toList();
    }
    return list;
  }

  /// โหลดทรัพย์เดียวจาก id (ลิงก์แชร์ / deep link)
  Future<ListingPublic?> fetchById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;

    ListingPublic? fromDemo() {
      for (final l in DemoListingsFactory.cached) {
        if (l.id == trimmed) return l;
      }
      return null;
    }

    if (!Env.isConfigured || !SupabaseService.isReady) {
      return fromDemo();
    }

    try {
      final row = await SupabaseService.client!
          .from('listings_public')
          .select()
          .eq('id', trimmed)
          .maybeSingle();
      if (row != null) {
        return ListingPublic.fromJson(Map<String, dynamic>.from(row));
      }
    } catch (_) {
      return fromDemo();
    }

    return fromDemo();
  }
}
