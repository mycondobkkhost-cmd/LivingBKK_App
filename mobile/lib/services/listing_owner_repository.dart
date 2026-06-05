import 'auth_service.dart';
import 'supabase_service.dart';
import 'trial_listing_store.dart';

class ListingOwnerRepository {
  Future<List<Map<String, dynamic>>> myListings({bool includeArchived = true}) async {
    if (AuthService.instance.trialSimulatesBackend) {
      return TrialListingStore.instance.myListings(includeArchived: includeArchived);
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
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// ยืนยันว่าง = bump + รีเซ็ตรอบแจ้งเตือน 7 วัน
  Future<void> bumpListing(String listingId) async {
    if (AuthService.instance.trialSimulatesBackend) {
      TrialListingStore.instance.bump(listingId);
      return;
    }
    await SupabaseService.client!.from('listings').update({
      'last_bump_at': DateTime.now().toUtc().toIso8601String(),
      'last_reminder_at': null,
      'expires_at':
          DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
      'status': 'published',
    }).eq('id', listingId);
  }

  Future<void> closeRent({
    required String listingId,
    required DateTime availableAgain,
  }) async {
    await SupabaseService.client!.rpc(
      'owner_close_listing_rent',
      params: {
        'p_listing_id': listingId,
        'p_available_again': availableAgain.toIso8601String().split('T').first,
      },
    );
  }

  Future<void> closeSale({required String listingId}) async {
    await SupabaseService.client!.rpc(
      'owner_close_listing_sale',
      params: {'p_listing_id': listingId},
    );
  }

  Future<void> softDelete({required String listingId}) async {
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

}
