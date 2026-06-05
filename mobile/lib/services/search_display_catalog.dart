import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/bangkok_projects.dart';
import '../l10n/app_strings.dart';
import '../models/search_suggestion.dart';
import '../utils/localized_content.dart';
import 'project_catalog.dart';

/// สมุดแสดงผลค้นหาแบบ Property Hub — ทำเล/โครงการ/รถไฟฟ้า ตามตัวอักษร (ห → ห้วยขวาง)
class SearchDisplayCatalog extends ChangeNotifier {
  SearchDisplayCatalog._();

  static final SearchDisplayCatalog instance = SearchDisplayCatalog._();

  static const _assetPath = 'assets/data/search_display_index.json';

  Map<String, List<Map<String, dynamic>>> _byQuery = {};
  List<Map<String, dynamic>> _entries = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  int get entryCount => _entries.length;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      _applyJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('SearchDisplayCatalog.load: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  void _applyJson(Map<String, dynamic> data) {
    final byRaw = data['by_query'];
    if (byRaw is Map) {
      _byQuery = byRaw.map(
        (k, v) => MapEntry(
          k.toString(),
          (v as List? ?? []).whereType<Map>().map(Map<String, dynamic>.from).toList(),
        ),
      );
    }
    _entries = (data['entries'] as List? ?? [])
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();
  }

  /// ค้นหาสำหรับดรอปดาวน์ — รองรับ 1 ตัวอักษรขึ้นไป
  /// กรองให้ชื่อ/slug ตรงกับที่พิมพ์ (ไม่โชว์ทุกรายการจากหน้าเว็บ PH)
  List<SearchSuggestion> suggest(String query, {bool isEnglish = false}) {
    final q = query.trim();
    if (q.isEmpty) return [];

    final lower = q.toLowerCase();
    final s = AppStrings(isEnglish);
    final scored = <String, Map<String, dynamic>>{};

    void consider(Map<String, dynamic> e) {
      final score = _matchScore(e, lower);
      if (score <= 0) return;
      final key = _entryKey(e);
      final prev = scored[key];
      if (prev != null && _matchScore(prev, lower) >= score) return;
      scored[key] = e;
    }

    final exact = _byQuery[q] ?? _byQuery[lower];
    if (exact != null) {
      for (final e in exact) {
        consider(e);
      }
    }

    if (scored.length < 15) {
      for (final e in _entries) {
        if (scored.length >= 30) break;
        consider(e);
      }
    }

    if (q.length >= 2) {
      for (final p in ProjectCatalog.instance.search(q)) {
        consider({
          'kind': 'project',
          'title_th': p.nameTh,
          'title_en': p.nameEn,
          'subtitle_th': p.bts ?? p.district,
          'subtitle_en': p.bts ?? p.district,
          'project_slug': p.slug,
          'geo_zone_slugs': <String>[],
          'source': 'project_catalog',
        });
      }
    }

    final ranked = scored.entries.toList()
      ..sort((a, b) {
        final sa = _matchScore(a.value, lower);
        final sb = _matchScore(b.value, lower);
        if (sa != sb) return sb.compareTo(sa);
        final ka = a.value['kind'] as String? ?? '';
        final kb = b.value['kind'] as String? ?? '';
        if (ka == 'project' && kb != 'project') return -1;
        if (kb == 'project' && ka != 'project') return 1;
        return (a.value['title_th'] as String? ?? '')
            .compareTo(b.value['title_th'] as String? ?? '');
      });

    return ranked
        .take(15)
        .map((e) => _toSuggestion(e.value, s))
        .toList();
  }

  String _entryKey(Map<String, dynamic> e) {
    return [
      e['kind'],
      e['title_th'],
      e['title_en'],
      e['project_slug'],
      (e['geo_zone_slugs'] as List?)?.join(','),
    ].join('|');
  }

  int _matchScore(Map<String, dynamic> e, String lower) {
    if (lower.isEmpty) return 0;

    final th = (e['title_th'] as String? ?? '').toLowerCase();
    final en = (e['title_en'] as String? ?? '').toLowerCase();
    final slug = (e['project_slug'] as String? ?? '').toLowerCase();
    final fields = [th, en, slug.replaceAll('-', ' ')];

    final tokens = lower.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.length > 1) {
      for (final field in fields) {
        if (field.isEmpty) continue;
        if (tokens.every(field.contains)) return 95;
      }
    }

    var best = 0;
    for (final field in fields) {
      if (field.isEmpty) continue;
      if (field == lower) {
        best = best < 120 ? 120 : best;
        continue;
      }
      if (field.startsWith(lower)) {
        best = best < 100 ? 100 : best;
        continue;
      }
      for (final word in field.split(RegExp(r'[\s\-/()]+'))) {
        if (word.isEmpty) continue;
        if (word == lower) {
          best = best < 90 ? 90 : best;
        } else if (word.startsWith(lower)) {
          best = best < 80 ? 80 : best;
        }
      }
      if (lower.length >= 2 && field.contains(lower)) {
        best = best < 60 ? 60 : best;
      }
      if (lower.length == 1 && field.startsWith(lower)) {
        best = best < 70 ? 70 : best;
      }
    }
    return best;
  }

  String _bilingualTitle(Map<String, dynamic> e) {
    final slug = e['project_slug'] as String?;
    if (slug != null && slug.isNotEmpty) {
      for (final p in ProjectCatalog.instance.projects) {
        if (p.slug == slug) return p.displayBilingual;
      }
      final boot = BangkokProjects.bySlug(slug);
      if (boot != null) return boot.displayBilingual;
    }
    return bilingualProjectLabel(
      e['title_th'] as String?,
      e['title_en'] as String?,
    );
  }

  String _resolveProjectNameTh(Map<String, dynamic> e) {
    final slug = e['project_slug'] as String?;
    if (slug != null && slug.isNotEmpty) {
      for (final p in ProjectCatalog.instance.projects) {
        if (p.slug == slug) return p.nameTh;
      }
      final boot = BangkokProjects.bySlug(slug);
      if (boot != null) return boot.nameTh;
    }
    return e['title_th'] as String? ?? '';
  }

  SearchSuggestion _toSuggestion(Map<String, dynamic> e, AppStrings s) {
    final kindRaw = e['kind'] as String? ?? 'hint';
    final subtitleTh = e['subtitle_th'] as String? ?? '';
    final subtitleEn = e['subtitle_en'] as String? ?? subtitleTh;
    final projectSlug = e['project_slug'] as String?;
    final zones = (e['geo_zone_slugs'] as List?)?.map((x) => x.toString()).toList();

    SearchSuggestionKind kind;
    switch (kindRaw) {
      case 'project':
        kind = SearchSuggestionKind.project;
        break;
      case 'location':
      case 'transit':
        kind = SearchSuggestionKind.location;
        break;
      default:
        kind = SearchSuggestionKind.hint;
    }

    final resolvedTitleTh = e['title_th'] as String? ?? '';
    final resolvedTitleEn = e['title_en'] as String? ?? resolvedTitleTh;
    // รูปแบบเดียวทั้งแอป: ไทย (English)
    final title = _bilingualTitle(e);
    final subtitle = s.isEnglish
        ? (subtitleEn.isNotEmpty ? subtitleEn : subtitleTh)
        : (subtitleTh.isNotEmpty ? subtitleTh : subtitleEn);

    final group = kind == SearchSuggestionKind.location
        ? SearchSuggestionGroup.location
        : SearchSuggestionGroup.projectMatch;
    final tab = kindRaw == 'transit'
        ? SearchResultTab.transit
        : kind == SearchSuggestionKind.project
            ? SearchResultTab.project
            : SearchResultTab.location;
    final section = kindRaw == 'transit'
        ? SearchResultSection.btsMrt
        : kind == SearchSuggestionKind.project
            ? SearchResultSection.project
            : SearchResultSection.location;

    return SearchSuggestion(
      kind: kind,
      group: group,
      tab: tab,
      section: section,
      title: title,
      titleTh: resolvedTitleTh,
      titleEn: resolvedTitleEn,
      subtitle: subtitle,
      projectName: kind == SearchSuggestionKind.project ? _resolveProjectNameTh(e) : null,
      projectSlug: projectSlug,
      geoZoneSlugs: zones?.isNotEmpty == true ? zones : null,
    );
  }
}
