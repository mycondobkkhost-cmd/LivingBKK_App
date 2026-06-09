import 'package:http/http.dart' as http;

/// ผลจากลิงก์แชร์ Google Maps — ใช้เฉพาะพิกัด ไม่ทับชื่อโครงการ
class GoogleMapsShareCoords {
  const GoogleMapsShareCoords({
    required this.lat,
    required this.lng,
    required this.resolvedUrl,
  });

  final double lat;
  final double lng;
  final String resolvedUrl;
}

abstract final class GoogleMapsShareUrl {
  static bool looksLikeMapsUrl(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (!t.startsWith('http://') && !t.startsWith('https://')) return false;
    return t.contains('maps.google') ||
        t.contains('google.com/maps') ||
        t.contains('goo.gl/maps') ||
        t.contains('maps.app.goo.gl');
  }

  /// ดึงพิกัดจาก URL (ไม่ follow redirect — ใช้กับลิงก์เต็ม)
  static GoogleMapsShareCoords? parseCoords(String raw) {
    final url = _normalize(raw);
    if (url.isEmpty) return null;
    final coords = _extractCoords(url);
    if (coords == null) return null;
    return GoogleMapsShareCoords(
      lat: coords.$1,
      lng: coords.$2,
      resolvedUrl: url,
    );
  }

  /// Follow redirect สำหรับลิงก์สั้น แล้ว parse พิกัด
  static Future<GoogleMapsShareCoords?> resolveAndParseCoords(String raw) async {
    var url = _normalize(raw);
    if (url.isEmpty) return null;

    if (_isShortMapsUrl(url)) {
      final expanded = await _followRedirects(url);
      if (expanded != null && expanded.isNotEmpty) {
        url = expanded;
      }
    }

    final coords = _extractCoords(url);
    if (coords == null) return null;
    return GoogleMapsShareCoords(
      lat: coords.$1,
      lng: coords.$2,
      resolvedUrl: url,
    );
  }

  static String _normalize(String raw) {
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

  static bool _isShortMapsUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host == 'goo.gl' ||
        host == 'maps.app.goo.gl' ||
        (host.endsWith('goo.gl') && url.contains('/maps'));
  }

  static Future<String?> _followRedirects(String url, {int maxHops = 6}) async {
    var current = url;
    final client = http.Client();
    try {
      for (var i = 0; i < maxHops; i++) {
        final uri = Uri.parse(current);
        final res = await client
            .send(http.Request('GET', uri)..followRedirects = false)
            .timeout(const Duration(seconds: 12));

        if (res.statusCode >= 300 && res.statusCode < 400) {
          final loc = res.headers['location'];
          await res.stream.drain();
          if (loc == null || loc.isEmpty) return current;
          current = loc.startsWith('http')
              ? loc
              : uri.resolve(loc).toString();
          continue;
        }
        await res.stream.drain();
        return current;
      }
      return current;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static (double, double)? _extractCoords(String url) {
    final decoded = Uri.decodeComponent(url);

    final pin = RegExp(r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)').firstMatch(decoded);
    if (pin != null) {
      return _pair(pin.group(1), pin.group(2));
    }

    final at = RegExp(r'@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)').firstMatch(decoded);
    if (at != null) {
      return _pair(at.group(1), at.group(2));
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      for (final key in ['q', 'query', 'll', 'center']) {
        final q = uri.queryParameters[key];
        if (q == null) continue;
        final fromQ = _coordsFromPairText(q);
        if (fromQ != null) return fromQ;
      }
    }

    final qInline = RegExp(
      r'[?&](?:q|query|ll|center)=(-?\d+(?:\.\d+)?)[,%20\+](-?\d+(?:\.\d+)?)',
    ).firstMatch(decoded);
    if (qInline != null) {
      return _pair(qInline.group(1), qInline.group(2));
    }

    return null;
  }

  static (double, double)? _coordsFromPairText(String text) {
    final cleaned = text.trim();
    final m = RegExp(r'^(-?\d+(?:\.\d+)?)\s*[, ]\s*(-?\d+(?:\.\d+)?)').firstMatch(cleaned);
    if (m == null) return null;
    return _pair(m.group(1), m.group(2));
  }

  static (double, double)? _pair(String? a, String? b) {
    if (a == null || b == null) return null;
    final lat = double.tryParse(a);
    final lng = double.tryParse(b);
    if (lat == null || lng == null) return null;
    if (!_isValidLatLng(lat, lng)) return null;
    return _maybeSwapBangkok(lat, lng);
  }

  static bool _isValidLatLng(double lat, double lng) {
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    if (lat == 0 && lng == 0) return false;
    return true;
  }

  /// แก้กรณีสลับ lat/lng ในพื้นที่ กทม.+ปริมณฑล
  static (double, double) _maybeSwapBangkok(double lat, double lng) {
    const minLat = 12.5;
    const maxLat = 15.5;
    const minLng = 99.0;
    const maxLng = 102.0;

    final inBox = (double la, double ln) =>
        la >= minLat && la <= maxLat && ln >= minLng && ln <= maxLng;

    if (inBox(lat, lng)) return (lat, lng);
    if (inBox(lng, lat)) return (lng, lat);
    return (lat, lng);
  }
}
