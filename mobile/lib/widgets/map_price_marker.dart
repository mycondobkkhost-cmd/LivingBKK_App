import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/living_bkk_brand.dart';
import 'design_system/app_map_marker.dart';

/// ปักหมุดราคาแนว Google Maps — พื้นขาว · ตัวอักษรเข้ม · เงาเบา
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
    final key = 'gm2-$label-$selected';
    final cached = _cache[key];
    if (cached != null) return cached;

    final icon = await _build(label, selected: selected);
    _cache[key] = icon;
    return icon;
  }

  static Future<BitmapDescriptor> clusterIcon(int count) async {
    final key = 'gm2-cluster-$count';
    final cached = _cache[key];
    if (cached != null) return cached;
    final icon = await _buildCluster(count);
    _cache[key] = icon;
    return icon;
  }

  static Future<BitmapDescriptor> _build(String label, {required bool selected}) async {
    const scale = 3.0;
    const height = 28.0;
    const padH = 10.0;
    const tipH = 6.0;

    final textColor = selected ? LivingBkkBrand.brandRed : const Color(0xFF202124);
    final borderColor = selected ? LivingBkkBrand.brandRed : const Color(0xFFDADCE0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: textColor,
          fontSize: 12 * scale,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: -0.2 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final width = textPainter.width / scale + padH * 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = (width * scale).ceil();
    final h = ((height + tipH) * scale).ceil();
    final pillH = height * scale;
    final pillW = w.toDouble();
    final radius = pillH / 2;

    // soft drop shadow (Google Maps chip)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1.5 * scale, 2.5 * scale, pillW - 3 * scale, pillH - 2 * scale),
        Radius.circular(radius),
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 * scale),
    );

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, pillW, pillH),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (selected ? 2.0 : 1.0) * scale,
    );

    // tip under pill (filled white + border edges)
    final tip = Path()
      ..moveTo(pillW / 2 - 5.5 * scale, pillH - 0.5 * scale)
      ..lineTo(pillW / 2, pillH + tipH * scale)
      ..lineTo(pillW / 2 + 5.5 * scale, pillH - 0.5 * scale)
      ..close();
    canvas.drawPath(tip, Paint()..color = Colors.white);
    canvas.drawPath(
      tip,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale,
    );
    // cover tip top seam
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(pillW / 2, pillH - 1 * scale),
        width: 8 * scale,
        height: 3 * scale,
      ),
      Paint()..color = Colors.white,
    );

    textPainter.paint(
      canvas,
      Offset(
        (w - textPainter.width) / 2,
        (pillH - textPainter.height) / 2,
      ),
    );

    final img = await recorder.endRecording().toImage(w, h);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> _buildCluster(int count) async {
    const scale = 3.0;
    const size = 42.0;
    final label = count > 99 ? '99+' : '$count';
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: (count > 99 ? 11 : 13) * scale,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final s = (size * scale).ceil();
    final center = Offset(s / 2, s / 2);
    final r = size * scale / 2;

    canvas.drawCircle(
      center.translate(0, 1.5 * scale),
      r,
      Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale),
    );
    // Google-like blue cluster (not brand purple)
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF1A73E8));
    canvas.drawCircle(
      center,
      r - 2.2 * scale,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * scale,
    );
    textPainter.paint(
      canvas,
      Offset((s - textPainter.width) / 2, (s - textPainter.height) / 2),
    );

    final img = await recorder.endRecording().toImage(s, s);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}
