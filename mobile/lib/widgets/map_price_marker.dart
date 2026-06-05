import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_theme.dart';
import 'design_system/app_map_marker.dart';

/// Purple price pill markers (wireframe-style map pins).
class MapPriceMarker {
  MapPriceMarker._();

  static final _cache = <String, BitmapDescriptor>{};

  static String labelFor(double priceNet, {required bool isRent, bool isEnglish = false}) =>
      formatMapMarkerPrice(priceNet, isRent: isRent, isEnglish: isEnglish);

  static Future<BitmapDescriptor> iconFor(
    double priceNet, {
    required bool isRent,
    bool selected = false,
    bool isEnglish = false,
  }) async {
    final label = labelFor(priceNet, isRent: isRent, isEnglish: isEnglish);
    final key = '$label-$selected-${AppTheme.primary.value}-${AppTheme.cta.value}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final icon = await _build(label, selected: selected);
    _cache[key] = icon;
    return icon;
  }

  static Future<BitmapDescriptor> _build(String label, {required bool selected}) async {
    const scale = 3.0;
    const height = 28.0;
    const padH = 10.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11 * scale,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final width = textPainter.width / scale + padH * 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = (width * scale).ceil();
    final h = (height * scale).ceil();

    final bg = Paint()
      ..shader = LinearGradient(
        colors: selected
            ? [AppTheme.primaryDark, AppTheme.cta]
            : [AppTheme.primary, AppTheme.cta.withOpacity(0.92)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()))
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Radius.circular((height * scale) / 2),
    );
    canvas.drawRRect(rrect, bg);

    textPainter.paint(
      canvas,
      Offset(
        (w - textPainter.width) / 2,
        (h - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}
