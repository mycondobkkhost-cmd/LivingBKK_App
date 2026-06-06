/// ตรวจและจัดรูปแบบลิงก์นำเข้าประกาศ (LI / Facebook / ทั่วไป)
enum ListingImportSource { livingInsider, facebook, generic, invalid }

abstract final class ListingImportUrl {
  static String normalize(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    try {
      final u = Uri.parse(url);
      return u.replace(fragment: '').toString();
    } catch (_) {
      return url;
    }
  }

  static ListingImportSource detect(String raw) {
    final url = normalize(raw);
    if (url.isEmpty) return ListingImportSource.invalid;
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return ListingImportSource.invalid;
      }
      if (uri.host.isEmpty || uri.host == 'localhost') {
        return ListingImportSource.invalid;
      }
      final host = uri.host.toLowerCase();
      if (host.contains('livinginsider.com')) {
        final p = uri.path.toLowerCase();
        if (p.contains('istockdetail') ||
            p.contains('livingdetail') ||
            p.contains('/detail/')) {
          return ListingImportSource.livingInsider;
        }
      }
      if (host.contains('facebook.com') ||
          host.contains('fb.com') ||
          host == 'fb.me' ||
          host.contains('fb.watch')) {
        return ListingImportSource.facebook;
      }
      return ListingImportSource.generic;
    } catch (_) {
      return ListingImportSource.invalid;
    }
  }

  static bool isAllowed(String raw) => detect(raw) != ListingImportSource.invalid;
}
