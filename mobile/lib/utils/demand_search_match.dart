import '../data/popular_areas.dart';
import '../models/demand_post.dart';

/// ค้นหาประกาศความต้องการ — แมตช์ชื่อโครงการ ย่าน ทำเล (อ้างอิง PopularAreas + คำพ้อง)
bool demandPostMatchesSearchQuery(DemandPost post, String rawQuery) {
  final query = rawQuery.trim();
  if (query.isEmpty) return true;

  final haystack = _normalizedHaystack(post);
  final terms = _expandQueryTerms(query);

  for (final term in terms) {
    if (term.length < 2) continue;
    if (haystack.contains(term)) return true;
  }

  for (final area in PopularAreas.all) {
    if (!_queryMentionsArea(query, area)) continue;
    if (_postMatchesPopularArea(post, area)) return true;
  }

  return false;
}

String _normalize(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[\s\-–—_/\.]+'), '')
      .trim();
}

String _normalizedHaystack(DemandPost post) {
  final parts = <String>[
    post.title,
    post.titleEn ?? '',
    post.description ?? '',
    post.descriptionEn ?? '',
    post.preferredProject ?? '',
    ...post.zones,
  ];
  return _normalize(parts.where((s) => s.trim().isNotEmpty).join(' '));
}

Set<String> _expandQueryTerms(String query) {
  final terms = <String>{_normalize(query)};

  for (final word in query.toLowerCase().split(RegExp(r'[\s,]+'))) {
    final w = _normalize(word);
    if (w.length >= 2) terms.add(w);
  }

  for (final entry in _searchSynonyms.entries) {
    final keyNorm = _normalize(entry.key);
    final queryNorm = _normalize(query);
    final hit = queryNorm.contains(keyNorm) ||
        terms.any((t) => t.contains(keyNorm) || keyNorm.contains(t));
    if (hit) {
      for (final alt in entry.value) {
        terms.add(_normalize(alt));
      }
    }
  }

  for (final area in PopularAreas.all) {
    if (!_queryMentionsArea(query, area)) continue;
    terms.add(_normalize(area.nameTh));
    terms.add(_normalize(area.nameEn));
    terms.add(_normalize(area.subtitleTh));
    terms.add(_normalize(area.subtitleEn));
    for (final hint in _areaHints(area.slug)) {
      terms.add(_normalize(hint));
    }
  }

  return terms.where((t) => t.length >= 2).toSet();
}

bool _queryMentionsArea(String query, PopularArea area) {
  final q = query.toLowerCase();
  return q.contains(area.nameTh.toLowerCase()) ||
      q.contains(area.nameEn.toLowerCase()) ||
      area.subtitleTh.toLowerCase().contains(q) ||
      _areaHints(area.slug).any((h) => q.contains(h.toLowerCase()));
}

bool _postMatchesPopularArea(DemandPost post, PopularArea area) {
  final hay = _normalizedHaystack(post);
  final hints = [
    area.nameTh,
    area.nameEn,
    area.subtitleTh,
    area.subtitleEn,
    ..._areaHints(area.slug),
  ];
  return hints.any((h) {
    final n = _normalize(h);
    return n.length >= 2 && hay.contains(n);
  });
}

List<String> _areaHints(String slug) {
  const hints = <String, List<String>>{
    'thonglor': ['ทองหล่อ', 'thonglor', 'thong lo', 'เอกมัย', 'ekkamai', 'bts'],
    'asok': ['อโศก', 'asok', 'sukhumvit'],
    'sukhumvit': ['สุขุมวิท', 'sukhumvit', 'เอกมัย', 'ekkamai', 'ทองหล่อ', 'พร้อมพงษ์'],
    'bangna': ['บางนา', 'bangna', 'อุดมสุข', 'udom'],
    'ari': ['อารีย์', 'ari'],
    'silom': ['สีลม', 'silom', 'สาทร', 'sathorn'],
    'ladprao': ['ลาดพร้าว', 'ladprao', 'รัชโยธิน'],
    'rama9': ['พระราม9', 'พระราม 9', 'rama 9', 'rca', 'รัชดา', 'ห้วยขวาง'],
    'bangkok-all': ['กรุงเทพ', 'bangkok', 'วัฒนา'],
    'nonthaburi': ['นนทบุรี', 'nonthaburi'],
    'pathum-thani': ['ปทุม', 'pathum'],
    'samut-prakan': ['สมุทรปราการ', 'samut'],
  };
  return hints[slug] ?? [slug.replaceAll('-', ' ')];
}

/// คำค้นหา ↔ ทำเล/โครงการที่เกี่ยวข้อง
const _searchSynonyms = <String, List<String>>{
  'ทองหล่อ': ['thonglor', 'thong lo', 'ทองหล่อเอกมัย', 'btsทองหล่อ'],
  'เอกมัย': ['ekkamai', 'ekamai', 'เอกมัย', 'ทองหล่อ'],
    'thonglor': ['ทองหล่อ', 'เอกมัย', 'ekkamai'],
    'ekkamai': ['เอกมัย', 'ทองหล่อ', 'thonglor'],
    'พระราม9': ['rama9', 'rama 9', 'rca', 'รัชดา', 'ratchada', 'ห้วยขวาง'],
    'rama9': ['พระราม9', 'พระราม 9', 'rama 9', 'rca'],
    'rama 9': ['พระราม9', 'rca', 'รัชดา'],
    'รัชดา': ['ratchada', 'rca', 'พระราม9'],
    'อโศก': ['asok', 'sukhumvit', 'สุขุมวิท'],
    'asok': ['อโศก', 'สุขุมวิท'],
    'สุขุมวิท': ['sukhumvit', 'อโศก', 'เอกมัย', 'ทองหล่อ'],
    'พระโขนง': ['phrakhanong', 'onnut', 'อ่อนนุช'],
  'อ่อนนุช': ['onnut', 'on nut'],
  'บางนา': ['bangna', 'udom', 'อุดมสุข'],
};
