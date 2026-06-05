import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

Future<void> ensureGoogleMapsWebSdk(String apiKey) async {
  if (apiKey.isEmpty) return;

  if (_hasGoogleMaps()) return;

  final existing = html.document.querySelector('script[data-livingbkk-gmaps]');
  if (existing != null) {
    await _waitForGoogleMaps();
    return;
  }

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..type = 'text/javascript'
    ..async = true
    ..defer = true
    ..dataset['livingbkkGmaps'] = '1'
    ..src =
        'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeComponent(apiKey)}';

  script.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });
  script.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError('Google Maps script failed to load');
    }
  });

  html.document.head!.append(script);
  await completer.future.timeout(
    const Duration(seconds: 20),
    onTimeout: () => throw TimeoutException('Google Maps load timeout'),
  );
  await _waitForGoogleMaps();
}

bool _hasGoogleMaps() {
  final google = js_util.getProperty(html.window, 'google');
  if (google == null) return false;
  return js_util.getProperty(google, 'maps') != null;
}

Future<void> _waitForGoogleMaps() async {
  for (var i = 0; i < 100; i++) {
    if (_hasGoogleMaps()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('Google Maps API not available after script load');
}
