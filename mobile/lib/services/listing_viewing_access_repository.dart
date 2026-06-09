import '../config/env.dart';
import '../models/listing_viewing_access.dart';
import 'local_prefs_service.dart';
import 'supabase_service.dart';

/// อ่าน/บันทึก `listings.viewing_access` — demo เก็บใน LocalPrefs
class ListingViewingAccessRepository {
  static const _prefsKey = 'listing_viewing_access_v1';

  String _key({String? listingId, String? listingCode}) =>
      listingId?.trim().isNotEmpty == true
          ? listingId!.trim()
          : (listingCode?.trim().isNotEmpty == true ? listingCode!.trim() : '');

  Future<ListingViewingAccess> fetch({
    String? listingId,
    String? listingCode,
  }) async {
    final key = _key(listingId: listingId, listingCode: listingCode);
    if (key.isEmpty) return const ListingViewingAccess();

    if (Env.isConfigured && SupabaseService.isReady) {
      try {
        var query = SupabaseService.client!
            .from('listings')
            .select('viewing_access');
        final row = listingId != null && listingId.isNotEmpty
            ? await query.eq('id', listingId).maybeSingle()
            : await query.eq('listing_code', listingCode!).maybeSingle();
        if (row != null) {
          final raw = row['viewing_access'];
          if (raw is Map<String, dynamic>) {
            return ListingViewingAccess.fromJson(raw);
          }
        }
      } catch (_) {}
    }

    final map = await LocalPrefsService.instance.getJsonMap(_prefsKey);
    if (map == null || !map.containsKey(key)) {
      return const ListingViewingAccess();
    }
    final raw = map[key];
    if (raw is Map) {
      return ListingViewingAccess.fromJson(Map<String, dynamic>.from(raw));
    }
    return const ListingViewingAccess();
  }

  Future<void> save({
    required ListingViewingAccess access,
    String? listingId,
    String? listingCode,
  }) async {
    final key = _key(listingId: listingId, listingCode: listingCode);
    if (key.isEmpty) return;
    final json = access.toJson();

    if (Env.isConfigured && SupabaseService.isReady) {
      try {
        if (listingId != null && listingId.isNotEmpty) {
          await SupabaseService.client!
              .from('listings')
              .update({'viewing_access': json})
              .eq('id', listingId);
        } else if (listingCode != null && listingCode.isNotEmpty) {
          await SupabaseService.client!
              .from('listings')
              .update({'viewing_access': json})
              .eq('listing_code', listingCode);
        }
      } catch (_) {}
    }

    final map = await LocalPrefsService.instance.getJsonMap(_prefsKey) ?? {};
    map[key] = json;
    await LocalPrefsService.instance.setJsonMap(_prefsKey, map);
  }
}
