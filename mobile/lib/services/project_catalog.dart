import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../data/demo_listings_factory.dart';
import '../data/bangkok_projects.dart';
import '../utils/metro_region.dart';
import 'supabase_service.dart';

/// แคตตาล็อกโครงการ — offline bootstrap + cloud (Supabase client หรือ REST)
class ProjectCatalog extends ChangeNotifier {
  ProjectCatalog._();

  static final ProjectCatalog instance = ProjectCatalog._();

  static const _selectCols =
      'id,slug,name_th,name_en,district,bts_station,property_type,'
      'lat,lng,aliases,year_built,facilities,geo_zone_id';

  List<BangkokProject> _projects = BangkokProjects.bootstrap;
  bool _loadedFromCloud = false;

  List<BangkokProject> get projects => _projects;
  bool get loadedFromCloud => _loadedFromCloud;

  Map<String, String> get _restHeaders => {
        'apikey': Env.supabaseAnonKey,
        'Authorization': 'Bearer ${Env.supabaseAnonKey}',
        'Accept': 'application/json',
      };

  Future<void> load() async {
    if (!Env.isConfigured) return;

    if (SupabaseService.isReady) {
      try {
        await _loadFromClient();
        if (_loadedFromCloud) return;
      } catch (e) {
        debugPrint('ProjectCatalog.load client: $e');
      }
    }

    try {
      await _loadFromRest();
    } catch (e) {
      debugPrint('ProjectCatalog.load rest: $e');
    }
  }

  Future<void> _loadFromClient() async {
    final rows = await SupabaseService.client!
        .from('property_projects')
        .select(
          'id, slug, name_th, name_en, district, bts_station, property_type, '
          'lat, lng, aliases, year_built, facilities, geo_zone_id',
        )
        .eq('is_active', true)
        .order('name_th')
        .limit(5000);

    _applyRows(rows);
  }

  Future<void> _loadFromRest() async {
    final uri = Uri.parse(
      '${Env.supabaseUrl}/rest/v1/property_projects'
      '?select=$_selectCols&is_active=eq.true&order=name_th.asc&limit=5000',
    );
    final res = await http.get(uri, headers: _restHeaders);
    if (res.statusCode != 200) {
      throw Exception('REST ${res.statusCode}: ${res.body.substring(0, 120)}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) throw Exception('REST unexpected body');
    _applyRows(decoded);
  }

  void _applyRows(List<dynamic> rows) {
    if (rows.isEmpty) {
      debugPrint(
        'ProjectCatalog: 0 rows (bootstrap ${BangkokProjects.bootstrap.length})',
      );
      return;
    }

    final all = rows
        .whereType<Map>()
        .map((e) => _fromRow(Map<String, dynamic>.from(e)))
        .where((p) => p.slug.isNotEmpty)
        .toList();

    // รวม bootstrap ที่ Cloud ยังไม่มี (เช่น ทรู ทองหล่อ) — Cloud ชนะถ้า slug ซ้ำ
    final bySlug = <String, BangkokProject>{
      for (final p in all) p.slug: p,
    };
    for (final seed in BangkokProjects.bootstrap) {
      bySlug.putIfAbsent(seed.slug, () => seed);
    }

    _projects = MetroRegion.filterProjects(bySlug.values.toList());

    if (_projects.isEmpty) return;

    _loadedFromCloud = true;
    BangkokProjects.useCloud(_projects);
    DemoListingsFactory.invalidateCache();
    notifyListeners();
    debugPrint('ProjectCatalog: ${_projects.length} โครงการจาก Cloud');
  }

  /// ค้นหาในเครื่อง (bootstrap หรือ cache ที่โหลดแล้ว)
  List<BangkokProject> search(String query) => _filter(_projects, query);

  /// ค้นหา Cloud โดยตรง — ใช้ตอนพิมพ์ในช่อง (ไม่พึ่งโหลดทั้งสมุด)
  Future<List<BangkokProject>> searchOnline(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final local = search(q);
    if (!Env.isConfigured) return local.take(15).toList();

    try {
      final remote = await _searchRest(q);
      final bySlug = <String, BangkokProject>{};
      for (final p in [...local, ...remote]) {
        bySlug[p.slug] = p;
      }
      return bySlug.values.take(15).toList();
    } catch (e) {
      debugPrint('ProjectCatalog.searchOnline: $e');
      return local.take(15).toList();
    }
  }

  Future<List<BangkokProject>> _searchRest(String query) async {
    final q = query.trim();
    final tokens = q
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final needle = tokens.isNotEmpty ? tokens.first : q;
    final safe = Uri.encodeComponent('%$needle%');
    final uri = Uri.parse(
      '${Env.supabaseUrl}/rest/v1/property_projects'
      '?select=$_selectCols'
      '&is_active=eq.true'
      '&or=(name_th.ilike.$safe,name_en.ilike.$safe,slug.ilike.$safe)'
      '&order=name_th.asc'
      '&limit=40',
    );
    final res = await http.get(uri, headers: _restHeaders);
    if (res.statusCode != 200) {
      throw Exception('search REST ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    final hits = decoded
        .whereType<Map>()
        .map((e) => _fromRow(Map<String, dynamic>.from(e)))
        .where((p) => p.slug.isNotEmpty)
        .toList();
    return _filter(hits, query);
  }

  List<BangkokProject> _filter(List<BangkokProject> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];

    bool matches(BangkokProject p) {
      final fields = [
        p.nameTh.toLowerCase(),
        p.nameEn.toLowerCase(),
        p.slug.toLowerCase().replaceAll('-', ' '),
        p.district.toLowerCase(),
        p.bts?.toLowerCase(),
        ...p.aliases.map((a) => a.toLowerCase()),
      ].whereType<String>();

      final hay = fields.join(' ');
      final tokens = q.split(RegExp(r'\s+')).where((t) => t.length >= 2).toList();
      if (tokens.isEmpty) return hay.contains(q);
      return tokens.every(hay.contains);
    }

    return source.where(matches).toList();
  }

  BangkokProject? bySlug(String slug) {
    for (final p in _projects) {
      if (p.slug == slug) return p;
    }
    return null;
  }

  BangkokProject _fromRow(Map<String, dynamic> row) {
    final aliasesRaw = row['aliases'];
    final facilitiesRaw = row['facilities'];
    return BangkokProject(
      slug: row['slug']?.toString() ?? '',
      id: row['id']?.toString(),
      geoZoneId: row['geo_zone_id']?.toString(),
      nameTh: row['name_th']?.toString() ?? '',
      nameEn: row['name_en']?.toString() ?? '',
      district: row['district']?.toString() ?? '',
      lat: (row['lat'] as num?)?.toDouble() ?? 13.7563,
      lng: (row['lng'] as num?)?.toDouble() ?? 100.5018,
      bts: row['bts_station']?.toString(),
      propertyType: row['property_type']?.toString() ?? 'condo',
      aliases: aliasesRaw is List
          ? aliasesRaw.map((e) => e.toString()).toList()
          : const [],
      yearBuilt: (row['year_built'] as num?)?.toInt(),
      facilities: facilitiesRaw is List
          ? facilitiesRaw.map((e) => e.toString()).toList()
          : const [],
    );
  }
}
