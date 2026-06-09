import '../utils/owner_listing_media.dart';
import 'auth_service.dart';
import 'supabase_service.dart';
import 'trial_listing_store.dart';

class ListingOwnerRepository {
  Future<List<Map<String, dynamic>>> myListings({bool includeArchived = true}) async {
    if (AuthService.instance.isTrialSignedIn ||
        AuthService.instance.trialSimulatesBackend) {
      final rows =
          TrialListingStore.instance.myListings(includeArchived: includeArchived);
      _ensureCoverUrls(rows);
      return rows;
    }
    if (!SupabaseService.isReady) return [];
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return [];

    var query = SupabaseService.client!
        .from('listings')
        .select(
          'id, listing_code, title, status, listing_type, price_net, '
          'last_bump_at, published_at, expires_at, available_again, '
          'closed_at, closed_reason, reuse_blocked, last_reminder_at, viewing_access',
        )
        .or('owner_id.eq.$uid,created_by_id.eq.$uid')
        .filter('owner_deleted_at', 'is', null);

    if (!includeArchived) {
      query = query.eq('status', 'published');
    }

    final data = await query.order('updated_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(data as List);
    await _enrichCoverUrlsFromDb(rows);
    return rows;
  }

  static void _ensureCoverUrls(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      row.putIfAbsent('cover_image_url', () => OwnerListingMedia.coverUrl(row));
    }
  }

  static Future<void> _enrichCoverUrlsFromDb(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty || !SupabaseService.isReady) {
      _ensureCoverUrls(rows);
      return;
    }
    final ids = rows.map((r) => r['id']?.toString()).whereType<String>().toList();
    if (ids.isEmpty) return;
    try {
      final images = await SupabaseService.client!
          .from('listing_images')
          .select('listing_id, public_url, sort_order')
          .inFilter('listing_id', ids)
          .order('sort_order', ascending: true);
      final firstByListing = <String, String>{};
      for (final img in images as List) {
        final m = Map<String, dynamic>.from(img as Map);
        final lid = m['listing_id']?.toString();
        final url = m['public_url']?.toString();
        if (lid == null || url == null || url.isEmpty) continue;
        firstByListing.putIfAbsent(lid, () => url);
      }
      for (final row in rows) {
        final id = row['id']?.toString();
        row['cover_image_url'] =
            (id != null ? firstByListing[id] : null) ?? OwnerListingMedia.coverUrl(row);
      }
    } catch (_) {
      _ensureCoverUrls(rows);
    }
  }

  /// ยืนยันว่าง = bump + รีเซ็ตรอบแจ้งเตือน 7 วัน
  Future<bool> bumpListing(
    String listingId, {
    String? listingCode,
  }) async {
    if (AuthService.instance.isTrialSignedIn ||
        AuthService.instance.trialSimulatesBackend) {
      if (TrialListingStore.instance.bump(listingId)) return true;
      final code = listingCode?.trim();
      if (code != null && code.isNotEmpty) {
        return TrialListingStore.instance.bumpByCode(code);
      }
      return false;
    }
    await SupabaseService.client!.from('listings').update({
      'last_bump_at': DateTime.now().toUtc().toIso8601String(),
      'last_reminder_at': null,
      'expires_at':
          DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
      'status': 'published',
    }).eq('id', listingId);
    return true;
  }

  Future<void> closeRent({
    required String listingId,
    required bool permanent,
    DateTime? availableAgain,
    String? permanentReason,
  }) async {
    if (permanent) {
      if (AuthService.instance.isTrialSignedIn ||
          AuthService.instance.trialSimulatesBackend) {
        TrialListingStore.instance.archiveRentPermanent(
          listingId,
          reason: permanentReason ?? 'stop_rent',
        );
        return;
      }
      await SupabaseService.client!.from('listings').update({
        'status': 'archived',
        'closed_at': DateTime.now().toUtc().toIso8601String(),
        'closed_reason': permanentReason ?? 'stop_rent',
        'reuse_blocked': true,
        'available_again': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', listingId);
      return;
    }
    final again = availableAgain ?? DateTime.now().add(const Duration(days: 30));
    if (AuthService.instance.isTrialSignedIn ||
        AuthService.instance.trialSimulatesBackend) {
      TrialListingStore.instance.archiveRent(
        listingId,
        availableAgain: again,
      );
      return;
    }
    await SupabaseService.client!.rpc(
      'owner_close_listing_rent',
      params: {
        'p_listing_id': listingId,
        'p_available_again': again.toIso8601String().split('T').first,
      },
    );
  }

  Future<void> closeSale({
    required String listingId,
    String? permanentReason,
  }) async {
    if (AuthService.instance.isTrialSignedIn ||
        AuthService.instance.trialSimulatesBackend) {
      TrialListingStore.instance.archiveSale(
        listingId,
        reason: permanentReason,
      );
      return;
    }
    await SupabaseService.client!.rpc(
      'owner_close_listing_sale',
      params: {'p_listing_id': listingId},
    );
  }

  Future<bool> republishRentEarly({required String listingId}) async {
    if (AuthService.instance.isTrialSignedIn ||
        AuthService.instance.trialSimulatesBackend) {
      return TrialListingStore.instance.republishRentEarly(listingId);
    }
    await SupabaseService.client!.from('listings').update({
      'status': 'published',
      'closed_at': null,
      'closed_reason': null,
      'occupancy_status': 'tenanted',
      'reuse_blocked': false,
      'last_bump_at': DateTime.now().toUtc().toIso8601String(),
      'expires_at':
          DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', listingId);
    return true;
  }

  Future<bool> updateAvailableAgain({
    required String listingId,
    required DateTime date,
  }) async {
    if (AuthService.instance.isTrialSignedIn ||
        AuthService.instance.trialSimulatesBackend) {
      return TrialListingStore.instance.updateAvailableAgain(listingId, date);
    }
    await SupabaseService.client!.from('listings').update({
      'available_again': date.toIso8601String().split('T').first,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', listingId);
    return true;
  }

  Future<void> softDelete({required String listingId}) async {
    if (AuthService.instance.isTrialSignedIn ||
        AuthService.instance.trialSimulatesBackend) {
      TrialListingStore.instance.softDelete(listingId);
      return;
    }
    await SupabaseService.client!.rpc(
      'owner_soft_delete_listing',
      params: {'p_listing_id': listingId},
    );
  }

  static DateTime activityAnchor(Map<String, dynamic> row) {
    final bump = row['last_bump_at']?.toString();
    if (bump != null) {
      final d = DateTime.tryParse(bump);
      if (d != null) return d;
    }
    final pub = row['published_at']?.toString();
    if (pub != null) {
      final d = DateTime.tryParse(pub);
      if (d != null) return d;
    }
    return DateTime.now();
  }

  static int daysSinceBump(Map<String, dynamic> row) {
    final anchor = activityAnchor(row);
    return DateTime.now().difference(anchor).inDays;
  }

  static int daysUntilAutoArchive(Map<String, dynamic> row) {
    return (30 - daysSinceBump(row)).clamp(0, 30);
  }

  static bool needsBumpReminder(Map<String, dynamic> row) {
    if (row['status']?.toString() != 'published') return false;
    final days = daysSinceBump(row);
    return days >= 7 && days < 30;
  }

  static const bumpCooldown = Duration(hours: 12);

  static DateTime? lastBumpAt(Map<String, dynamic> row) {
    final raw = row['last_bump_at']?.toString();
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Duration? bumpCooldownRemaining(Map<String, dynamic> row) {
    final last = lastBumpAt(row);
    if (last == null) return null;
    final elapsed = DateTime.now().difference(last);
    if (elapsed >= bumpCooldown) return null;
    return bumpCooldown - elapsed;
  }

  static bool canBumpNow(Map<String, dynamic> row) {
    if (row['status']?.toString() != 'published') return false;
    return bumpCooldownRemaining(row) == null;
  }

}
