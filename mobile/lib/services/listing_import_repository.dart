import 'auth_service.dart';
import 'supabase_service.dart';

class ListingImportRow {
  ListingImportRow({
    required this.id,
    required this.sourceUrl,
    required this.status,
    this.sourceExternalId,
    this.titlePreview,
    this.projectPreview,
    this.pricePreview,
    this.imageCount = 0,
    this.listingId,
    this.errorMessage,
    this.createdAt,
  });

  final String id;
  final String sourceUrl;
  final String status;
  final String? sourceExternalId;
  final String? titlePreview;
  final String? projectPreview;
  final double? pricePreview;
  final int imageCount;
  final String? listingId;
  final String? errorMessage;
  final DateTime? createdAt;

  factory ListingImportRow.fromJson(Map<String, dynamic> j) {
    return ListingImportRow(
      id: j['id'] as String,
      sourceUrl: j['source_url'] as String? ?? '',
      status: j['status'] as String? ?? 'queued',
      sourceExternalId: j['source_external_id'] as String?,
      titlePreview: j['title_preview'] as String?,
      projectPreview: j['project_preview'] as String?,
      pricePreview: (j['price_preview'] as num?)?.toDouble(),
      imageCount: (j['image_count'] as num?)?.toInt() ?? 0,
      listingId: j['listing_id'] as String?,
      errorMessage: j['error_message'] as String?,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString())
          : null,
    );
  }

  bool get canApprove =>
      status == 'draft_ready' || status == 'needs_fix';

  bool get canRetry => status == 'failed' || status == 'needs_fix';

  bool get isArchived => status == 'archived';

  bool get isApproved => status == 'approved';
}

class ListingImportRepository {
  static final ListingImportRepository instance = ListingImportRepository._();
  ListingImportRepository._();

  final List<ListingImportRow> _demo = [];

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  Future<List<ListingImportRow>> listImports({bool includeArchived = false}) async {
    if (!_live) {
      if (_demo.isEmpty) _seedDemo();
      if (includeArchived) return List.from(_demo);
      return _demo.where((r) => !r.isArchived).toList();
    }

    var q = SupabaseService.client!
        .from('listing_imports')
        .select('*');

    if (!includeArchived) {
      q = q.neq('status', 'archived');
    }

    final data = await q
        .order('created_at', ascending: false)
        .limit(100);
    return (data as List)
        .map((e) => ListingImportRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ListingImportRow> fetchUrl(String sourceUrl) async {
    if (!_live) {
      await Future.delayed(const Duration(milliseconds: 800));
      final row = ListingImportRow(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        sourceUrl: sourceUrl,
        status: 'draft_ready',
        sourceExternalId: '3097128',
        titlePreview: 'Demo import from LI',
        projectPreview: 'Origin Play',
        pricePreview: 50000,
        imageCount: 9,
        listingId: 'demo-listing',
        createdAt: DateTime.now(),
      );
      _demo.insert(0, row);
      return row;
    }

    final res = await SupabaseService.client!.functions.invoke(
      'listing-import-fetch',
      body: {'source_url': sourceUrl.trim()},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'listing-import-fetch failed');
    }
    return ListingImportRow.fromJson(
      Map<String, dynamic>.from(data['import'] as Map),
    );
  }

  Future<ListingImportRow> retry(String importId) async {
    if (!_live) return _demo.first;

    final res = await SupabaseService.client!.functions.invoke(
      'listing-import-fetch',
      body: {'import_id': importId},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'retry failed');
    }
    return ListingImportRow.fromJson(
      Map<String, dynamic>.from(data['import'] as Map),
    );
  }

  Future<ListingImportRow> approve(String importId) async {
    if (!_live) {
      final i = _demo.indexWhere((r) => r.id == importId);
      if (i >= 0) {
        final old = _demo[i];
        final updated = ListingImportRow(
          id: old.id,
          sourceUrl: old.sourceUrl,
          status: 'approved',
          sourceExternalId: old.sourceExternalId,
          titlePreview: old.titlePreview,
          projectPreview: old.projectPreview,
          pricePreview: old.pricePreview,
          imageCount: old.imageCount,
          listingId: old.listingId,
          createdAt: old.createdAt,
        );
        _demo[i] = updated;
        return updated;
      }
      throw Exception('not found');
    }

    final res = await SupabaseService.client!.functions.invoke(
      'listing-import-approve',
      body: {'import_id': importId},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'approve failed');
    }
    return ListingImportRow.fromJson(
      Map<String, dynamic>.from(data['import'] as Map),
    );
  }

  Future<ListingImportRow> archive(String importId) async {
    if (!_live) {
      final i = _demo.indexWhere((r) => r.id == importId);
      if (i >= 0) {
        final old = _demo[i];
        final updated = ListingImportRow(
          id: old.id,
          sourceUrl: old.sourceUrl,
          status: 'archived',
          sourceExternalId: old.sourceExternalId,
          titlePreview: old.titlePreview,
          projectPreview: old.projectPreview,
          pricePreview: old.pricePreview,
          imageCount: old.imageCount,
          listingId: old.listingId,
          createdAt: old.createdAt,
        );
        _demo[i] = updated;
        return updated;
      }
      throw Exception('not found');
    }

    final res = await SupabaseService.client!.functions.invoke(
      'listing-import-archive',
      body: {'import_id': importId},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'archive failed');
    }
    return ListingImportRow.fromJson(
      Map<String, dynamic>.from(data['import'] as Map),
    );
  }

  void _seedDemo() {
    _demo.add(
      ListingImportRow(
        id: 'demo-seed',
        sourceUrl:
            'https://www.livinginsider.com/istockdetail/DIoooI_DojybCI.html',
        status: 'draft_ready',
        sourceExternalId: '3097128',
        titlePreview: '2 Commercial Units for rent on Udomsuk Road',
        projectPreview: 'Origin Play',
        pricePreview: 50000,
        imageCount: 9,
        createdAt: DateTime.now(),
      ),
    );
  }
}
