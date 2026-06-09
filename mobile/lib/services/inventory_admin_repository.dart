import '../data/admin_demo_data.dart';
import '../utils/demo_inventory_resolve.dart';
import 'property_care_repository.dart';
import 'supabase_service.dart';

/// Admin: property inventory groups (dedupe + multi-agent + owner priority).
class InventoryAdminRepository {
  Future<List<Map<String, dynamic>>> fetchRoster({int limit = 80}) async {
    if (!SupabaseService.isReady) return AdminDemoData.inventoryRoster();
    try {
      final data = await SupabaseService.client!
          .from('inventory_admin_roster')
          .select()
          .order('updated_at', ascending: false)
          .limit(limit);
      final list = List<Map<String, dynamic>>.from(data as List);
      if (AdminDemoData.useWhenEmpty(list)) return AdminDemoData.inventoryRoster();
      return list;
    } catch (_) {
      return AdminDemoData.enabled ? AdminDemoData.inventoryRoster() : [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMembers(
    String inventoryId, {
    String? inventoryCode,
  }) async {
    final id = resolveDemoInventoryId(inventoryId, inventoryCode: inventoryCode);
    if (id.startsWith('demo-inv-')) {
      return _enrichedDemoMembers(id, inventoryCode: inventoryCode);
    }
    if (!SupabaseService.isReady) {
      return _enrichedDemoMembers(id, inventoryCode: inventoryCode);
    }
    try {
      final data = await SupabaseService.client!
          .from('inventory_admin_members')
          .select()
          .eq('inventory_id', id);
      final list = List<Map<String, dynamic>>.from(data as List);
      if (AdminDemoData.useWhenEmpty(list)) {
        return _enrichedDemoMembers(id, inventoryCode: inventoryCode);
      }
      return list;
    } catch (_) {
      return AdminDemoData.enabled
          ? _enrichedDemoMembers(id, inventoryCode: inventoryCode)
          : [];
    }
  }

  List<Map<String, dynamic>> _enrichedDemoMembers(
    String inventoryId, {
    String? inventoryCode,
  }) {
    return AdminDemoData.inventoryMembers(inventoryId)
        .map(
          (m) => PropertyCareRepository.enrichInventoryMember(
            m,
            inventoryId: inventoryId,
            inventoryCode: inventoryCode,
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchOpenAlerts(String inventoryId) async {
    if (!SupabaseService.isReady) return [];
    try {
      final data = await SupabaseService.client!
          .from('property_inventory_alerts')
          .select()
          .eq('inventory_id', inventoryId)
          .filter('acknowledged_at', 'is', null)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
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
