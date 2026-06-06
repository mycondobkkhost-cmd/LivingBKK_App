import 'auth_service.dart';
import 'supabase_service.dart';

class ListingImportFetchException implements Exception {
  ListingImportFetchException(this.message, {this.importId});

  final String message;
  final String? importId;

  @override
  String toString() => message;
}

class ListingImportRow {
  ListingImportRow({
    required this.id,
    required this.sourceUrl,
    required this.status,
    this.sourcePlatform = 'generic',
    this.sourceExternalId,
    this.titlePreview,
    this.projectPreview,
    this.pricePreview,
    this.imageCount = 0,
    this.listingId,
    this.errorMessage,
    this.parseFlags = const [],
    this.createdAt,
  });

  final String id;
  final String sourceUrl;
  final String status;
  final String sourcePlatform;
  final String? sourceExternalId;
  final String? titlePreview;
  final String? projectPreview;
  final double? pricePreview;
  final int imageCount;
  final String? listingId;
  final String? errorMessage;
  final List<String> parseFlags;
  final DateTime? createdAt;

  bool get needsAdminAttention =>
      parseFlags.contains('facebook_login_wall') ||
      parseFlags.contains('missing_price') ||
      parseFlags.contains('missing_images') ||
      parseFlags.contains('needs_admin_review') ||
      status == 'needs_fix';

  factory ListingImportRow.fromJson(Map<String, dynamic> j) {
    final parsed = j['parsed'];
    final flags = parsed is Map
        ? (parsed['flags'] as List?)?.map((e) => e.toString()).toList() ?? const []
        : const <String>[];

    return ListingImportRow(
      id: j['id'] as String,
      sourceUrl: j['source_url'] as String? ?? '',
      status: j['status'] as String? ?? 'queued',
      sourcePlatform: j['source_platform'] as String? ?? 'generic',
      sourceExternalId: j['source_external_id'] as String?,
      titlePreview: j['title_preview'] as String?,
      projectPreview: j['project_preview'] as String?,
      pricePreview: (j['price_preview'] as num?)?.toDouble(),
      imageCount: (j['image_count'] as num?)?.toInt() ?? 0,
      listingId: j['listing_id'] as String?,
      errorMessage: j['error_message'] as String?,
      parseFlags: flags,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString())
          : null,
    );
  }

  bool get canApprove => status == 'draft_ready' || status == 'needs_fix';

  bool get canRetry => status == 'failed' || status == 'needs_fix';

  bool get canReview =>
      listingId != null &&
      (status == 'draft_ready' ||
          status == 'needs_fix' ||
          status == 'failed');

  bool get isArchived => status == 'archived';

  bool get isApproved => status == 'approved';
}

class ListingImportDraft {
  ListingImportDraft({
    required this.id,
    required this.title,
    required this.description,
    required this.listingType,
    required this.propertyType,
    this.priceNet,
    this.areaSqm,
    this.bedrooms,
    this.district,
    this.projectName,
    this.listingCode,
    this.status = 'draft',
  });

  final String id;
  final String title;
  final String description;
  final String listingType;
  final String propertyType;
  final double? priceNet;
  final double? areaSqm;
  final int? bedrooms;
  final String? district;
  final String? projectName;
  final String? listingCode;
  final String status;

  factory ListingImportDraft.fromJson(Map<String, dynamic> j) {
    return ListingImportDraft(
      id: j['id'] as String,
      title: j['title'] as String? ?? '',
      description: j['description_public'] as String? ?? '',
      listingType: j['listing_type'] as String? ?? 'rent',
      propertyType: j['property_type'] as String? ?? 'condo',
      priceNet: (j['price_net'] as num?)?.toDouble(),
      areaSqm: (j['area_sqm'] as num?)?.toDouble(),
      bedrooms: (j['bedrooms'] as num?)?.toInt(),
      district: j['district'] as String?,
      projectName: j['project_name'] as String?,
      listingCode: j['listing_code'] as String?,
      status: j['status'] as String? ?? 'draft',
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'title': title.length > 200 ? title.substring(0, 200) : title,
        'description_public':
            description.length > 8000 ? description.substring(0, 8000) : description,
        'listing_type': listingType,
        'property_type': propertyType,
        'price_net': priceNet,
        'area_sqm': areaSqm,
        'bedrooms': bedrooms,
        'district': district,
        'project_name': projectName,
      };
}

class ListingImportDetail {
  const ListingImportDetail({
    required this.import,
    this.listing,
    this.parseFlags = const [],
  });

  final ListingImportRow import;
  final ListingImportDraft? listing;
  final List<String> parseFlags;
}

class ListingImportRepository {
  static final ListingImportRepository instance = ListingImportRepository._();
  ListingImportRepository._();

  final List<ListingImportRow> _demo = [];
  final Map<String, ListingImportDraft> _demoListings = {};

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  static String friendlyError(Object error) {
    final raw = error.toString();
    if (error is ListingImportFetchException) return error.message;

    final errInJson = RegExp(r'error:\s*([^,}]+)').firstMatch(raw)?.group(1)?.trim();
    if (errInJson != null && errInJson.length < 200) {
      return errInJson.replaceAll("'", '').replaceAll('"', '');
    }

    final statusMatch = RegExp(r'status:\s*(\d+)').firstMatch(raw);
    final status = statusMatch != null ? int.tryParse(statusMatch.group(1)!) : null;
    if (status != null) {
      switch (status) {
        case 401:
          return 'กรุณาเข้าสู่ระบบด้วยอีเมลและรหัสผ่านก่อน';
        case 403:
          return 'ต้องใช้บัญชีหลังบ้าน (แอดมิน) เท่านั้น';
        case 404:
          return 'ฟังก์ชันดึงข้อมูลยังไม่ขึ้นเซิร์ฟเวอร์ — deploy listing-import-fetch';
        case 409:
          return 'ลิงก์นี้อยู่ในคิวแล้ว — เปิดรายการเดิมเพื่อตรวจสอบ';
        case 422:
          return 'ดึงข้อมูลจาก LI ไม่สำเร็จ — ตรวจลิงก์หรือกดลองใหม่';
        default:
          return 'ดึงข้อมูลไม่สำเร็จ (HTTP $status)';
      }
    }

    if (raw.contains('livinginsider')) return raw.replaceFirst('Exception: ', '');
    return 'ดึงข้อมูลจาก LI ไม่สำเร็จ — ลองลิงก์อื่นหรือกดลองใหม่';
  }

  Future<List<ListingImportRow>> listImports({bool includeArchived = false}) async {
    if (!_live) {
      if (_demo.isEmpty) _seedDemo();
      if (includeArchived) return List.from(_demo);
      return _demo.where((r) => !r.isArchived).toList();
    }

    var q = SupabaseService.client!.from('listing_imports').select('*');

    if (!includeArchived) {
      q = q.neq('status', 'archived');
    }

    final data = await q.order('created_at', ascending: false).limit(100);
    return (data as List)
        .map((e) => ListingImportRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ListingImportDetail> getImportDetail(String importId) async {
    if (!_live) {
      if (_demo.isEmpty) _seedDemo();
      final row = _demo.firstWhere(
        (r) => r.id == importId,
        orElse: () => _demo.first,
      );
      return ListingImportDetail(
        import: row,
        listing: _demoListings[row.id] ?? _demoDraftFor(row),
      );
    }

    final data = await SupabaseService.client!
        .from('listing_imports')
        .select('*')
        .eq('id', importId)
        .single();
    final map = Map<String, dynamic>.from(data);
    final import = ListingImportRow.fromJson(map);
    final parsed = map['parsed'];
    final flags = parsed is Map
        ? (parsed['flags'] as List?)?.map((e) => e.toString()).toList() ?? const []
        : import.parseFlags;

    ListingImportDraft? listing;
    if (import.listingId != null) {
      final row = await SupabaseService.client!
          .from('listings')
          .select(
            'id, listing_code, title, description_public, listing_type, '
            'property_type, price_net, area_sqm, bedrooms, district, '
            'project_name, status',
          )
          .eq('id', import.listingId!)
          .maybeSingle();
      if (row != null) {
        listing = ListingImportDraft.fromJson(Map<String, dynamic>.from(row));
      }
    }

    return ListingImportDetail(import: import, listing: listing, parseFlags: flags);
  }

  Future<ListingImportRow> _loadImportRow(String importId) async {
    if (!_live) {
      return _demo.firstWhere((r) => r.id == importId, orElse: () => _demo.first);
    }
    final data = await SupabaseService.client!
        .from('listing_imports')
        .select('*')
        .eq('id', importId)
        .single();
    return ListingImportRow.fromJson(Map<String, dynamic>.from(data));
  }

  ListingImportRow _parseFetchResponse(dynamic raw) {
    final data = raw is Map ? Map<String, dynamic>.from(raw) : null;
    if (data == null) {
      throw Exception('listing-import-fetch failed');
    }

    if (data['import'] != null) {
      return ListingImportRow.fromJson(
        Map<String, dynamic>.from(data['import'] as Map),
      );
    }

    final importId = data['import_id']?.toString();
    final err = data['error']?.toString();
    if (importId != null) {
      throw ListingImportFetchException(
        err ?? 'ดึงข้อมูลไม่สำเร็จ',
        importId: importId,
      );
    }
    throw Exception(err ?? 'listing-import-fetch failed');
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
        listingId: 'demo-listing-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
      );
      _demo.insert(0, row);
      _demoListings[row.id] = ListingImportDraft(
        id: row.listingId!,
        title: row.titlePreview!,
        description: 'รายละเอียดตัวอย่างจาก LI (เบอร์/Line ถูกตัดแล้ว)',
        listingType: 'rent',
        propertyType: 'condo',
        priceNet: row.pricePreview,
        areaSqm: 71.8,
        bedrooms: 1,
        district: 'วัฒนา',
        projectName: row.projectPreview,
        listingCode: 'DEMO-LI',
      );
      return row;
    }

    final res = await SupabaseService.client!.functions.invoke(
      'listing-import-fetch',
      body: {'source_url': sourceUrl.trim()},
    );
    return _parseFetchResponse(res.data);
  }

  Future<ListingImportRow> retry(String importId) async {
    if (!_live) return _demo.first;

    final res = await SupabaseService.client!.functions.invoke(
      'listing-import-fetch',
      body: {'import_id': importId},
    );
    return _parseFetchResponse(res.data);
  }

  Future<void> updateListingDraft({
    required String importId,
    required String listingId,
    required String title,
    required String description,
    required String listingType,
    required String propertyType,
    double? priceNet,
    double? areaSqm,
    int? bedrooms,
    String? district,
    String? projectName,
  }) async {
    final draft = ListingImportDraft(
      id: listingId,
      title: title,
      description: description,
      listingType: listingType,
      propertyType: propertyType,
      priceNet: priceNet,
      areaSqm: areaSqm,
      bedrooms: bedrooms,
      district: district,
      projectName: projectName,
    );

    if (!_live) {
      _demoListings[importId] = draft;
      final i = _demo.indexWhere((r) => r.id == importId);
      if (i >= 0) {
        final old = _demo[i];
        _demo[i] = ListingImportRow(
          id: old.id,
          sourceUrl: old.sourceUrl,
          status: old.status,
          sourceExternalId: old.sourceExternalId,
          titlePreview: title,
          projectPreview: projectName ?? old.projectPreview,
          pricePreview: priceNet ?? old.pricePreview,
          imageCount: old.imageCount,
          listingId: old.listingId,
          errorMessage: old.errorMessage,
          createdAt: old.createdAt,
        );
      }
      return;
    }

    await SupabaseService.client!
        .from('listings')
        .update(draft.toUpdateJson())
        .eq('id', listingId);

    final current = await _loadImportRow(importId);
    await SupabaseService.client!.from('listing_imports').update({
      'title_preview': title,
      'price_preview': priceNet,
      'project_preview': projectName,
      if (current.status == 'needs_fix') 'status': 'draft_ready',
      'error_message': null,
    }).eq('id', importId);
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

  ListingImportDraft _demoDraftFor(ListingImportRow row) {
    return ListingImportDraft(
      id: row.listingId ?? 'demo-listing',
      title: row.titlePreview ?? 'Demo LI listing',
      description: 'รายละเอียดตัวอย่าง',
      listingType: 'rent',
      propertyType: 'condo',
      priceNet: row.pricePreview,
      areaSqm: 71.8,
      bedrooms: 1,
      district: 'วัฒนา',
      projectName: row.projectPreview,
      listingCode: 'DEMO-LI',
    );
  }

  void _seedDemo() {
    final row = ListingImportRow(
      id: 'demo-seed',
      sourceUrl: 'https://www.livinginsider.com/istockdetail/DIoooI_DojybCI.html',
      status: 'draft_ready',
      sourceExternalId: '3097128',
      titlePreview: '2 Commercial Units for rent on Udomsuk Road',
      projectPreview: 'Origin Play',
      pricePreview: 50000,
      imageCount: 9,
      listingId: 'demo-listing-seed',
      createdAt: DateTime.now(),
    );
    _demo.add(row);
    _demoListings[row.id] = _demoDraftFor(row);
  }
}
