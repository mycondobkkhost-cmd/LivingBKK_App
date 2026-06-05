import 'local_prefs_service.dart';

/// ประวัติและเทรนด์การค้นหา (เก็บในเครื่อง)
class SearchHistoryService {
  SearchHistoryService._();
  static final instance = SearchHistoryService._();

  static const _historyKey = 'search_history_v1';
  static const _maxHistory = 8;

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

  Future<void> clearHistory() async {
    await LocalPrefsService.instance.setStringList(_historyKey, const []);
  }

  List<String> trends({required bool isEnglish}) =>
      isEnglish ? trendsEn : trendsTh;
}
