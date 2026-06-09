import '../data/bangkok_project_meta.dart';
import '../data/bangkok_projects.dart';
import 'search_zone_catalog.dart';
import 'local_prefs_service.dart';

/// ประวัติและเทรนด์การค้นหา (เก็บในเครื่อง)
class SearchHistoryService {
  SearchHistoryService._();
  static final instance = SearchHistoryService._();

  static const _historyKey = 'search_history_v1';
  static const _maxHistory = 5;
  static const displayLimit = 5;

  static const trendsTh = [
    '89 เรสซิเดนซ์ รัชดา - พระราม 9',
    'สุขุมวิท อโศก',
    'ลาดพร้าว',
    'ไลฟ์ อโศก',
    'ทองหล่อ',
  ];

  static const trendsEn = [
    '89 Residence Ratchada',
    'Sukhumvit Asoke',
    'Lat Phrao',
    'Life Asoke',
    'Thong Lo',
  ];

  Future<List<String>> history({required bool isEnglish}) async {
    final list = await LocalPrefsService.instance.getStringList(_historyKey);
    return list;
  }

  Future<void> addQuery(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    final list = await LocalPrefsService.instance.getStringList(_historyKey);
    final next = [q, ...list.where((e) => e != q)].take(_maxHistory).toList();
    await LocalPrefsService.instance.setStringList(_historyKey, next);
  }

  /// แปลงข้อความในประวัติเป็นสลักโครงการ (ถ้ามี)
  String? resolveSlugFromLabel(String label) {
    final q = label.trim();
    if (q.isEmpty) return null;
    final byMeta = BangkokProjectMeta.findProject(q);
    if (byMeta != null) return byMeta.slug;
    final bySlug = BangkokProjects.bySlug(q);
    if (bySlug != null) return bySlug.slug;
    if (SearchZoneCatalog.instance.isLoaded) {
      final matches = SearchZoneCatalog.instance.search(
        q,
        category: 'project',
        limit: 1,
      );
      if (matches.isNotEmpty) {
        return matches.first.projectSlug ?? matches.first.id;
      }
    }
    return null;
  }

  /// บันทึกประวัติโครงการ — แสดงชื่อตาม locale แต่ dedupe ด้วย slug
  Future<void> addProjectSlug(String slug, String displayLabel) async {
    final label = displayLabel.trim();
    if (label.length < 2 || slug.isEmpty) return;
    final list = await LocalPrefsService.instance.getStringList(_historyKey);
    final filtered = <String>[];
    for (final entry in list) {
      final entrySlug = resolveSlugFromLabel(entry);
      if (entrySlug != slug) filtered.add(entry);
    }
    final next = [label, ...filtered.where((e) => e != label)]
        .take(_maxHistory)
        .toList();
    await LocalPrefsService.instance.setStringList(_historyKey, next);
  }

  Future<void> clearHistory() async {
    await LocalPrefsService.instance.setStringList(_historyKey, const []);
  }

  List<String> trends({required bool isEnglish}) =>
      isEnglish ? trendsEn : trendsTh;
}
