/// Client-side geo zone matching (slug → district / title keywords).
bool listingMatchesGeoZones({
  required List<String> slugs,
  String? district,
  String? projectName,
  String? title,
}) {
  if (slugs.isEmpty) return true;
  final hay = [
    district?.toLowerCase(),
    projectName?.toLowerCase(),
    title?.toLowerCase(),
  ].whereType<String>().join(' ');

  for (final slug in slugs) {
    if (_slugMatches(slug, hay)) return true;
  }
  return false;
}

bool _slugMatches(String slug, String hay) {
  const hints = <String, List<String>>{
    'thonglor': ['ทองหล่อ', 'thong', 'ทรู'],
    'asok': ['อโศก', 'asok', 'มศว'],
    'sukhumvit': ['สุขุมวิท', 'sukhumvit', 'เอกมัย', 'พร้อมพงษ์', 'อโศก'],
    'bangna': ['บางนา', 'bang na', 'bangna', 'udom', 'อุดม'],
    'ari': ['อารีย์', 'ari'],
    'silom': ['สีลม', 'silom', 'sathorn', 'สาทร', 'ศาลาแดง'],
    'ladprao': ['ลาดพร้าว', 'lat phrao', 'ladprao', 'รัชโยธิน'],
    'bangkok-all': ['กรุงเทพ', 'bangkok', 'วัฒนา', 'คลองเตย'],
    'nonthaburi': ['นนทบุรี', 'nonthaburi'],
    'pathum-thani': ['ปทุม', 'pathum'],
    'samut-prakan': ['สมุทรปราการ', 'samut'],
  };
  final keys = hints[slug] ?? [slug.replaceAll('-', ' ')];
  return keys.any((k) => hay.contains(k));
}
