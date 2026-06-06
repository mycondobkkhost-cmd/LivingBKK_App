import '../config/env.dart';
import '../models/property_project_admin.dart';
import '../utils/project_import_url.dart';
import '../utils/project_location_tags.dart';
import 'auth_service.dart';
import 'project_catalog.dart';
import 'supabase_service.dart';

class ProjectImportResult {
  const ProjectImportResult({
    required this.project,
    required this.updated,
  });

  final PropertyProjectRow project;
  final bool updated;
}

class ProjectRepository {
  ProjectRepository._();
  static final ProjectRepository instance = ProjectRepository._();

  static const _selectCols =
      'id, slug, name_th, name_en, district, bts_station, nearby_transit, property_type, '
      'lat, lng, aliases, year_built, facilities, geo_zone_id, is_active, '
      'source_url, source_platform, description_th, description_en, '
      'cover_image_url, admin_notes';

  bool get _ready => Env.isConfigured && SupabaseService.isReady;

  /// ตรวจก่อนดึงลิงก์ / บันทึก — คืนข้อความภาษาไทยถ้ายังทำไม่ได้
  Future<String?> importBlockReason() async {
    if (!Env.isConfigured) {
      return 'ยังไม่ได้ตั้งค่าเชื่อมคลาวด์ — ตรวจไฟล์ mobile/assets/env';
    }
    if (!SupabaseService.isReady) {
      return 'แอปเชื่อมคลาวด์ไม่สำเร็จ — กด R รีเฟรช หรือรันแอปใหม่';
    }
    if (AuthService.instance.trialSimulatesBackend) {
      return 'โหมดทดลองบันทึกลงคลาวด์ไม่ได้ — ล็อกอินด้วยอีเมล/รหัสจริง';
    }
    if (!AuthService.instance.isRealSupabaseSession) {
      return 'กรุณาเข้าสู่ระบบด้วยอีเมลและรหัสผ่านก่อน';
    }
    try {
      final uid = SupabaseService.client!.auth.currentUser!.id;
      final row = await SupabaseService.client!
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      if (row?['role'] != 'admin') {
        return 'ต้องใช้บัญชีหลังบ้าน (แอดมิน) — ตั้ง role ใน Supabase';
      }
    } catch (_) {
      return 'อ่านสิทธิ์บัญชีไม่ได้ — ลองล็อกอินใหม่';
    }
    return null;
  }

  Future<void> _ensureImportAllowed() async {
    final reason = await importBlockReason();
    if (reason != null) throw Exception(reason);
  }

  Future<List<PropertyProjectRow>> listAll({bool includeInactive = true}) async {
    if (!_ready) {
      return ProjectCatalog.instance.projects
          .map(
            (p) => PropertyProjectRow(
              id: p.id ?? p.slug,
              slug: p.slug,
              nameTh: p.nameTh,
              nameEn: p.nameEn,
              district: p.district,
              btsStation: p.bts,
              propertyType: p.propertyType,
              lat: p.lat,
              lng: p.lng,
              isActive: true,
              aliases: p.aliases,
              yearBuilt: p.yearBuilt,
              facilities: p.facilities,
              geoZoneId: p.geoZoneId,
              sourcePlatform: 'bootstrap',
            ),
          )
          .toList();
    }

    var query = SupabaseService.client!.from('property_projects').select(_selectCols);
    if (!includeInactive) {
      query = query.eq('is_active', true);
    }
    final rows = await query.order('name_th');
    return (rows as List)
        .map((e) => PropertyProjectRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<PropertyProjectRow> create(PropertyProjectRow draft) async {
    await _ensureImportAllowed();
    final enriched = enrichTransit(draft);
    final row = await SupabaseService.client!
        .from('property_projects')
        .insert(enriched.toInsertJson())
        .select(_selectCols)
        .single();
    await ProjectCatalog.instance.load();
    return PropertyProjectRow.fromJson(Map<String, dynamic>.from(row));
  }

  Future<PropertyProjectRow> update(String id, PropertyProjectRow draft) async {
    await _ensureImportAllowed();
    final enriched = enrichTransit(draft);
    final row = await SupabaseService.client!
        .from('property_projects')
        .update(enriched.toInsertJson())
        .eq('id', id)
        .select(_selectCols)
        .single();
    await ProjectCatalog.instance.load();
    return PropertyProjectRow.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> setActive(String id, bool active) async {
    await _ensureImportAllowed();
    await SupabaseService.client!
        .from('property_projects')
        .update({'is_active': active})
        .eq('id', id);
    await ProjectCatalog.instance.load();
  }

  Future<ProjectImportResult> importFromUrl(String sourceUrl) async {
    await _ensureImportAllowed();
    final res = await SupabaseService.client!.functions.invoke(
      'project-import-fetch',
      body: {'source_url': sourceUrl.trim(), 'upsert': true},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'project-import-fetch failed');
    }
    final project = PropertyProjectRow.fromJson(
      Map<String, dynamic>.from(data['project'] as Map),
    );
    await ProjectCatalog.instance.load();
    return ProjectImportResult(
      project: project,
      updated: data['updated'] == true,
    );
  }

  /// ลบโครงการทั้งหมด (ถอด project_id จากประกาศ) — ใช้ก่อนรีซิงค์เต็ม
  Future<Map<String, dynamic>> purgeAllProjects() async {
    await _ensureImportAllowed();
    final res = await SupabaseService.client!.functions.invoke(
      'project-import-propertyhub',
      body: {'mode': 'purge_all', 'confirm': true},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'purge_all failed');
    }
    await ProjectCatalog.instance.load();
    return data;
  }

  /// ค้นหาชื่อโครงการจาก Property Hub (โซน BTS/MRT กรุงเทพ — 0 = ทุกโซน)
  Future<List<String>> discoverPropertyHubSlugs({int maxZones = 0}) async {
    await _ensureImportAllowed();
    final res = await SupabaseService.client!.functions.invoke(
      'project-import-propertyhub',
      body: {'mode': 'discover', 'max_zones': maxZones},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'discover failed');
    }
    return List<String>.from(data['slugs'] as List? ?? []);
  }

  /// ดึงโครงการจาก Property Hub ทีละชุด (สูงสุด 200 ต่อครั้ง)
  Future<Map<String, dynamic>> batchImportPropertyHub({
    required List<String> slugs,
    int limit = 20,
  }) async {
    await _ensureImportAllowed();
    final res = await SupabaseService.client!.functions.invoke(
      'project-import-propertyhub',
      body: {'mode': 'batch', 'slugs': slugs, 'limit': limit},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'batch import failed');
    }
    await ProjectCatalog.instance.load();
    return data;
  }

  Future<ProjectImportResult> importPropertyHubUrl(String sourceUrl) async {
    await _ensureImportAllowed();
    final res = await SupabaseService.client!.functions.invoke(
      'project-import-propertyhub',
      body: {'source_url': ProjectImportUrl.normalize(sourceUrl)},
    );
    final data = _parseFunctionData(res.data, fallback: 'ดึงจาก Property Hub ไม่สำเร็จ');
    final project = PropertyProjectRow.fromJson(
      Map<String, dynamic>.from(data['project'] as Map),
    );
    await ProjectCatalog.instance.load();
    return ProjectImportResult(
      project: project,
      updated: data['updated'] == true,
    );
  }

  /// ดึงโครงการจากลิงก์ — Property Hub หรือ Living Insider
  Future<ProjectImportResult> importFromAnyUrl(String sourceUrl) async {
    final url = ProjectImportUrl.normalize(sourceUrl);
    if (url.isEmpty) throw Exception('ใส่ลิงก์ก่อน');

    switch (ProjectImportUrl.detect(url)) {
      case ProjectImportSource.propertyHub:
        return importPropertyHubUrl(url);
      case ProjectImportSource.livingInsider:
        return importFromUrl(url);
      case ProjectImportSource.unknown:
        throw Exception(
          'ลิงก์ไม่รองรับ — ใช้ propertyhub.in.th/projects/... หรือ livinginsider.com\n'
          'หรือกด「เพิ่มด้วยมือ」กรอกเอง',
        );
    }
  }

  /// ดึงข้อมูลจาก LI มาเติมฟอร์ม (ยังไม่บันทึก)
  Future<PropertyProjectRow> previewFromUrl(String sourceUrl) async {
    await _ensureImportAllowed();
    final url = ProjectImportUrl.normalize(sourceUrl);
    final source = ProjectImportUrl.detect(url);
    if (source == ProjectImportSource.unknown) {
      throw Exception('ลิงก์ไม่รองรับสำหรับดึงมาเติมฟอร์ม');
    }

    if (source == ProjectImportSource.livingInsider) {
      final res = await SupabaseService.client!.functions.invoke(
        'project-import-fetch',
        body: {'source_url': url, 'upsert': false},
      );
      final data = _parseFunctionData(res.data, fallback: 'ดึงข้อมูลจาก LI ไม่สำเร็จ');
      final parsed = Map<String, dynamic>.from(data['parsed'] as Map);
      return _rowFromParsed(parsed, sourceUrl: url);
    }

    return _previewPropertyHubUrl(url);
  }

  Future<PropertyProjectRow> _previewPropertyHubUrl(String url) async {
    final res = await SupabaseService.client!.functions.invoke(
      'project-import-propertyhub',
      body: {'source_url': url, 'mode': 'parse'},
    );
    final data = _parseFunctionData(res.data, fallback: 'ดึงจาก Property Hub ไม่สำเร็จ');
    final parsed = Map<String, dynamic>.from(data['parsed'] as Map);
    return _rowFromPropertyHub(parsed, sourceUrl: url);
  }

  PropertyProjectRow enrichTransit(PropertyProjectRow row) {
    final stored = row.nearbyTransit.isNotEmpty
        ? row.nearbyTransit
        : ProjectLocationTags.labelsFromTags(
            ProjectLocationTags.detect(
              lat: row.lat,
              lng: row.lng,
              district: row.district,
              htmlOrDesc: row.descriptionTh,
              existingBts: row.btsStation,
            ).autoSelected,
          );
    if (stored.isEmpty) return row;
    final extraAliases = ProjectLocationTags.extraAliases(stored);
    return PropertyProjectRow(
      id: row.id,
      slug: row.slug,
      nameTh: row.nameTh,
      nameEn: row.nameEn,
      district: row.district,
      btsStation: ProjectLocationTags.formatBtsField(stored) ?? row.btsStation,
      nearbyTransit: stored,
      propertyType: row.propertyType,
      lat: row.lat,
      lng: row.lng,
      isActive: row.isActive,
      aliases: [...row.aliases, ...extraAliases.where((a) => !row.aliases.contains(a))],
      yearBuilt: row.yearBuilt,
      facilities: row.facilities,
      geoZoneId: row.geoZoneId,
      sourceUrl: row.sourceUrl,
      sourcePlatform: row.sourcePlatform,
      descriptionTh: row.descriptionTh,
      descriptionEn: row.descriptionEn,
      coverImageUrl: row.coverImageUrl,
      adminNotes: row.adminNotes,
    );
  }

  PropertyProjectRow _rowFromPropertyHub(
    Map<String, dynamic> parsed, {
    required String sourceUrl,
  }) {
    final aliasesRaw = parsed['aliases'];
    final facilitiesRaw = parsed['facilities'];
    final nearbyRaw = parsed['nearbyTransit'] ?? parsed['nearby_transit'];
    final nearbyList = nearbyRaw is List
        ? nearbyRaw.map((e) => e.toString()).toList()
        : <String>[];
    return PropertyProjectRow(
      id: '',
      slug: parsed['slug'] as String? ?? '',
      nameTh: parsed['nameTh'] as String? ?? parsed['name_th'] as String? ?? '',
      nameEn: parsed['nameEn'] as String? ?? parsed['name_en'] as String? ?? '',
      district: parsed['district'] as String? ?? 'กรุงเทพฯ',
      btsStation: parsed['btsStation'] as String? ?? parsed['bts_station'] as String?,
      nearbyTransit: nearbyList,
      propertyType: parsed['propertyType'] as String? ?? parsed['property_type'] as String? ?? 'condo',
      lat: (parsed['lat'] as num?)?.toDouble() ?? 13.7367,
      lng: (parsed['lng'] as num?)?.toDouble() ?? 100.5608,
      isActive: true,
      aliases: aliasesRaw is List
          ? aliasesRaw.map((e) => e.toString()).toList()
          : const [],
      yearBuilt: (parsed['yearBuilt'] as num?)?.toInt() ?? (parsed['year_built'] as num?)?.toInt(),
      facilities: facilitiesRaw is List
          ? facilitiesRaw.map((e) => e.toString()).toList()
          : const [],
      sourceUrl: sourceUrl,
      sourcePlatform: 'propertyhub',
      descriptionTh: parsed['descriptionTh'] as String? ?? parsed['description_th'] as String?,
      coverImageUrl: parsed['coverImageUrl'] as String? ?? parsed['cover_image_url'] as String?,
    );
  }

  PropertyProjectRow _rowFromParsed(
    Map<String, dynamic> parsed, {
    required String sourceUrl,
  }) {
    final aliasesRaw = parsed['aliases'];
    final facilitiesRaw = parsed['facilities'];
    return PropertyProjectRow(
      id: '',
      slug: ProjectImportUrl.slugify(
        (parsed['name_en'] as String?) ?? (parsed['name_th'] as String?) ?? '',
      ),
      nameTh: parsed['name_th'] as String? ?? '',
      nameEn: parsed['name_en'] as String? ?? '',
      district: parsed['district'] as String? ?? 'กรุงเทพฯ',
      btsStation: parsed['bts_station'] as String?,
      propertyType: parsed['property_type'] as String? ?? 'condo',
      lat: (parsed['lat'] as num?)?.toDouble() ?? 13.7367,
      lng: (parsed['lng'] as num?)?.toDouble() ?? 100.5608,
      isActive: true,
      aliases: aliasesRaw is List
          ? aliasesRaw.map((e) => e.toString()).toList()
          : const [],
      yearBuilt: (parsed['year_built'] as num?)?.toInt(),
      facilities: facilitiesRaw is List
          ? facilitiesRaw.map((e) => e.toString()).toList()
          : const [],
      sourceUrl: sourceUrl,
      sourcePlatform: parsed['source_platform'] as String? ?? 'livinginsider',
      descriptionTh: parsed['description_th'] as String?,
      coverImageUrl: parsed['cover_image_url'] as String?,
    );
  }

  static String friendlyImportError(Object error) {
    final raw = error.toString();
    final detailsMatch = RegExp(r'details:\s*(\{[^}]+\}|[^,}]+)').firstMatch(raw);
    final details = detailsMatch?.group(1)?.trim();
    if (details != null && details.isNotEmpty && !details.startsWith('{')) {
      final msg = details.replaceAll(RegExp(r'^Exception:\s*'), '');
      if (msg.contains('ไม่พบข้อมูลโครงการ')) {
        return 'ดึงข้อมูลจาก Property Hub ไม่ได้ — ลองลิงก์หน้าโครงการอื่น หรือกรอกเอง';
      }
      if (msg.length < 200) return msg;
    }
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
          return 'ฟังก์ชันดึงข้อมูลยังไม่ขึ้นเซิร์ฟเวอร์ — รัน ./scripts/deploy-projects-cloud.sh';
      }
    }

    final msg = raw.replaceFirst('Exception: ', '');
    if (msg.contains('Unauthorized') || msg.contains('status: 401')) {
      return 'กรุณาเข้าสู่ระบบด้วยอีเมลและรหัสผ่านก่อน';
    }
    if (msg.contains('Admin only') || msg.contains('status: 403')) {
      return 'ต้องใช้บัญชีหลังบ้าน (แอดมิน) เท่านั้น';
    }
    if (msg.contains('outside_metro')) {
      return 'โครงการอยู่นอก กทม.+ปริมณฑล — ระบบไม่รับ';
    }
    if (msg.contains('supabase_url and supabase_key') ||
        msg.contains('edge_secrets_missing') ||
        msg.contains('edge_config_missing')) {
      return 'เซิร์ฟเวอร์ยังไม่ได้ตั้งรหัสลับ — ใส่ SUPABASE_SERVICE_ROLE_KEY ใน .env.local แล้วรัน ./scripts/set-edge-secrets.sh';
    }
    if (msg.contains('Failed to fetch') || msg.contains('ClientException')) {
      return 'เชื่อมคลาวด์ไม่ได้ — ตรวจอินเทอร์เน็ต หรือลองรีเฟรชแอป (กด R)';
    }
    if (msg.contains('status: 404')) {
      return 'ฟังก์ชันดึงข้อมูลยังไม่ขึ้นเซิร์ฟเวอร์ — รัน ./scripts/deploy-projects-cloud.sh';
    }
    return msg;
  }

  Map<String, dynamic> _parseFunctionData(
    dynamic raw, {
    required String fallback,
  }) {
    final data = raw as Map<String, dynamic>?;
    if (data == null) throw Exception(fallback);
    final err = data['error'];
    if (err != null) throw Exception(err.toString());
    return data;
  }
}
