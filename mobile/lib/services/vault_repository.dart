import '../data/vault_demo_data.dart';
import '../models/vault_asset.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class VaultListResult {
  const VaultListResult({
    required this.items,
    required this.total,
    this.isDemoPreview = false,
  });

  final List<VaultAssetSummary> items;
  final int total;
  final bool isDemoPreview;
}

class VaultRepository {
  static final VaultRepository instance = VaultRepository._();
  VaultRepository._();

  bool _demoPreview = false;
  bool get isDemoPreview => _demoPreview;

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  Future<VaultListResult> list({
    String? entityType,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!_live) return _demoList(entityType);

    try {
      final res = await SupabaseService.client!.functions.invoke(
        'vault-browse',
        body: {
          'action': 'list',
          if (entityType != null) 'entity_type': entityType,
          'limit': limit,
          'offset': offset,
        },
      );
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        return _demoList(entityType);
      }
      final items = (data['items'] as List? ?? [])
          .map((e) =>
              VaultAssetSummary.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (items.isEmpty) return _demoList(entityType);
      _demoPreview = false;
      return VaultListResult(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? items.length,
      );
    } catch (_) {
      return _demoList(entityType);
    }
  }

  Future<VaultAssetDetail> detail({
    required String entityType,
    required String entityId,
  }) async {
    if (_demoPreview || !_live) {
      return _demoDetail(entityType, entityId);
    }

    try {
      final res = await SupabaseService.client!.functions.invoke(
        'vault-browse',
        body: {
          'action': 'detail',
          'entity_type': entityType,
          'entity_id': entityId,
        },
      );
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        return _demoDetail(entityType, entityId);
      }
      final asset = data['asset'] as Map?;
      if (asset == null) return _demoDetail(entityType, entityId);
      return VaultAssetDetail.fromJson(Map<String, dynamic>.from(asset));
    } catch (_) {
      return _demoDetail(entityType, entityId);
    }
  }

  Future<int> syncAll() async {
    if (!_live || _demoPreview) {
      _demoPreview = true;
      return VaultDemoData.summaries().length;
    }

    try {
      final res = await SupabaseService.client!.functions.invoke(
        'vault-browse',
        body: {'action': 'sync'},
      );
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        _demoPreview = true;
        return VaultDemoData.summaries().length;
      }
      _demoPreview = false;
      return (data['total_assets'] as num?)?.toInt() ?? 0;
    } catch (_) {
      _demoPreview = true;
      return VaultDemoData.summaries().length;
    }
  }

  VaultListResult _demoList(String? entityType) {
    _demoPreview = true;
    final items = VaultDemoData.summaries(entityType: entityType);
    return VaultListResult(
      items: items,
      total: items.length,
      isDemoPreview: true,
    );
  }

  VaultAssetDetail _demoDetail(String entityType, String entityId) {
    return VaultDemoData.detailFor(entityType: entityType, entityId: entityId) ??
        VaultAssetDetail(
          summary: VaultAssetSummary(
            id: entityId,
            entityType: entityType,
            entityId: entityId,
            titlePreview: 'รายการจำลอง',
          ),
          payload: {'synced_from': 'demo', 'note': 'ไม่พบรายละเอียดจำลอง'},
          capturedAt: DateTime.now(),
        );
  }
}
