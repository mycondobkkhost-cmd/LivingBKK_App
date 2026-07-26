import '../models/admin_ai_feed_item.dart';
import 'supabase_service.dart';

class AdminAiFeedRepository {
  AdminAiFeedRepository._();
  static final instance = AdminAiFeedRepository._();

  Future<List<AdminAiFeedItem>> fetchOpen({int limit = 30}) async {
    if (!SupabaseService.isReady) return [];
    try {
      final res = await SupabaseService.client!.functions.invoke(
        'admin-ai-feed',
        body: {'action': 'list', 'status': 'open', 'limit': '$limit'},
      );
      final data = res.data as Map<String, dynamic>?;
      final items = data?['items'] as List? ?? [];
      return items
          .map((e) => AdminAiFeedItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> fetchOpenCount() async {
    if (!SupabaseService.isReady) return 0;
    try {
      final res = await SupabaseService.client!.functions.invoke(
        'admin-ai-feed',
        body: {'action': 'count_open'},
      );
      final data = res.data as Map<String, dynamic>?;
      return (data?['count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markStatus(String id, String status) async {
    if (!SupabaseService.isReady) return;
    await SupabaseService.client!.functions.invoke(
      'admin-ai-feed',
      body: {'action': 'update_status', 'id': id, 'status': status},
    );
  }

  Future<List<AdminUnifiedSearchHit>> unifiedSearch(String query) async {
    if (!SupabaseService.isReady || query.trim().length < 2) return [];
    try {
      final res = await SupabaseService.client!.functions.invoke(
        'admin-unified-search',
        body: {'query': query.trim(), 'limit': 20},
      );
      final data = res.data as Map<String, dynamic>?;
      final rows = data?['results'] as List? ?? [];
      return rows
          .map((e) => AdminUnifiedSearchHit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
