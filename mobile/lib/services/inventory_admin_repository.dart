import 'supabase_service.dart';

/// Admin: property inventory groups (dedupe + multi-agent + owner priority).
class InventoryAdminRepository {
  Future<List<Map<String, dynamic>>> fetchRoster({int limit = 80}) async {
    if (!SupabaseService.isReady) return [];
    final data = await SupabaseService.client!
        .from('inventory_admin_roster')
        .select()
        .order('updated_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Map<String, dynamic>>> fetchMembers(String inventoryId) async {
    if (!SupabaseService.isReady) return [];
    final data = await SupabaseService.client!
        .from('inventory_admin_members')
        .select()
        .eq('inventory_id', inventoryId);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Map<String, dynamic>>> fetchOpenAlerts(String inventoryId) async {
    if (!SupabaseService.isReady) return [];
    final data = await SupabaseService.client!
        .from('property_inventory_alerts')
        .select()
        .eq('inventory_id', inventoryId)
        .filter('acknowledged_at', 'is', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> setPrimaryContact({
    required String inventoryId,
    required String listingId,
  }) async {
    await SupabaseService.client!.rpc(
      'admin_set_inventory_primary_contact',
      params: {
        'p_inventory_id': inventoryId,
        'p_listing_id': listingId,
      },
    );
  }

  Future<void> acknowledgeAlert(String alertId) async {
    await SupabaseService.client!.rpc(
      'admin_ack_inventory_alert',
      params: {'p_alert_id': alertId},
    );
  }
}
