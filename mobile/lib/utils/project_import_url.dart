/// ตรวจและจัดรูปแบบลิงก์นำเข้าโครงการ (ฝั่งแอป)
enum ProjectImportSource { propertyHub, livingInsider, unknown }

abstract final class ProjectImportUrl {
  static String normalize(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  static ProjectImportSource detect(String raw) {
    final url = normalize(raw);
    if (url.isEmpty) return ProjectImportSource.unknown;
    try {
      final host = Uri.parse(url).host.toLowerCase();
      if (host.contains('propertyhub.in.th') &&
          RegExp(r'/projects/[a-z0-9-]+', caseSensitive: false).hasMatch(url)) {
        return ProjectImportSource.propertyHub;
      }
      if (host.contains('livinginsider.com')) {
        return ProjectImportSource.livingInsider;
      }
    } catch (_) {}
    return ProjectImportSource.unknown;
  }

  static String slugify(String raw) {
    final s = raw
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (s.length < 2) return '';
    return s.length > 80 ? s.substring(0, 80) : s;
  }
}
