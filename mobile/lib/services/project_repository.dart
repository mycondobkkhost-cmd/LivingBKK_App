import '../config/env.dart';
import '../models/property_project_admin.dart';
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
      'id, slug, name_th, name_en, district, bts_station, property_type, '
      'lat, lng, aliases, year_built, facilities, geo_zone_id, is_active, '
      'source_url, source_platform, description_th, description_en, '
      'cover_image_url, admin_notes';

  bool get _ready => Env.isConfigured && SupabaseService.isReady;

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
    if (!_ready) throw Exception('ต้องเชื่อม Supabase ก่อน');
    final row = await SupabaseService.client!
        .from('property_projects')
        .insert(draft.toInsertJson())
        .select(_selectCols)
        .single();
    await ProjectCatalog.instance.load();
    return PropertyProjectRow.fromJson(Map<String, dynamic>.from(row));
  }

  Future<PropertyProjectRow> update(String id, PropertyProjectRow draft) async {
    if (!_ready) throw Exception('ต้องเชื่อม Supabase ก่อน');
    final row = await SupabaseService.client!
        .from('property_projects')
        .update(draft.toInsertJson())
        .eq('id', id)
        .select(_selectCols)
        .single();
    await ProjectCatalog.instance.load();
    return PropertyProjectRow.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> setActive(String id, bool active) async {
    if (!_ready) throw Exception('ต้องเชื่อม Supabase ก่อน');
    await SupabaseService.client!
        .from('property_projects')
        .update({'is_active': active})
        .eq('id', id);
    await ProjectCatalog.instance.load();
  }

  Future<ProjectImportResult> importFromUrl(String sourceUrl) async {
    if (!_ready) throw Exception('ต้องเชื่อม Supabase ก่อน');
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

  /// ค้นหาชื่อโครงการจาก Property Hub (โซน BTS/MRT กรุงเทพ — 0 = ทุกโซน)
  Future<List<String>> discoverPropertyHubSlugs({int maxZones = 0}) async {
    if (!_ready) throw Exception('ต้องเชื่อม Supabase ก่อน');
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
    if (!_ready) throw Exception('ต้องเชื่อม Supabase ก่อน');
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
    if (!_ready) throw Exception('ต้องเชื่อม Supabase ก่อน');
    final res = await SupabaseService.client!.functions.invoke(
      'project-import-propertyhub',
      body: {'source_url': sourceUrl.trim()},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'propertyhub import failed');
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
}
