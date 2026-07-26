import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

bool _googleMapsJsReady() {
  try {
    final google = js_util.getProperty(html.window, 'google');
    if (google == null) return false;
    return js_util.getProperty(google, 'maps') != null;
  } catch (_) {
    return false;
  }
}

bool get isGoogleMapsWebBlocked {
  try {
    // ล้าง flag เก่า — เคย error แล้วแต่ Google Maps โหลดได้แล้ว
    if (_googleMapsJsReady()) {
      html.window.localStorage.remove('livingbkk_gmaps_failed');
      return js_util.getProperty(html.window, '__LIVINGBKK_GMAPS_FAILED') == true;
    }
    if (html.window.localStorage['livingbkk_gmaps_failed'] == '1') return true;
    return js_util.getProperty(html.window, '__LIVINGBKK_GMAPS_FAILED') == true;
  } catch (_) {
    return false;
  }
}

void listenGoogleMapsWebAuthFailure(void Function() onFailed) {
  html.window.addEventListener('livingbkk-gmaps-failed', (_) => onFailed());
}
