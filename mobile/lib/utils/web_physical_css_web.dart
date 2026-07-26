import 'dart:html' as html;
import 'dart:math' as math;

double? _cachedMonitorPpi;

/// ประมาณ PPI จอจาก resolution + ขนาด MacBook ทั่วไป
/// (CSS `1in` = 96px เสมอ — ใช้วัดขนาดจริงไม่ได้)
double? webEstimatedMonitorPpi() {
  final cached = _cachedMonitorPpi;
  if (cached != null && cached > 100 && cached < 400) return cached;

  try {
    final dpr = html.window.devicePixelRatio;
    if (dpr <= 0) return null;

    final screen = html.window.screen;
    if (screen == null) return null;

    final sw = screen.width ?? 0;
    final sh = screen.height ?? 0;
    if (sw <= 0 || sh <= 0) return null;

    final physW = sw * dpr;
    final physH = sh * dpr;
    final physDiagPx = math.sqrt(physW * physW + physH * physH);

    // logical width (CSS px) → diagonal นิ้ว โดยประมาณ (MacBook หลัก)
    final logicalW = sw;
    double? diagIn;
    if (logicalW >= 1500 && logicalW <= 1520) {
      diagIn = 14.2; // MacBook Pro 14"
    } else if (logicalW >= 1700 && logicalW <= 1760) {
      diagIn = 16.2; // MacBook Pro 16"
    } else if (logicalW >= 1430 && logicalW <= 1460) {
      diagIn = 13.3; // MacBook Air 13"
    } else if (logicalW >= 1280 && logicalW <= 1310) {
      diagIn = 13.3; // scaled / older Air
    } else if (logicalW >= 1910 && logicalW <= 1930) {
      diagIn = 15.4;
    } else if (logicalW >= 2550 && logicalW <= 2580) {
      diagIn = 27; // external 4K-ish
    }

    if (diagIn != null && diagIn > 0) {
      final ppi = physDiagPx / diagIn;
      if (ppi > 100 && ppi < 400) {
        _cachedMonitorPpi = ppi;
        return ppi;
      }
    }

    // fallback: DPR × 110 (Retina Mac โดยประมาณ)
    final approx = (dpr * 110).toDouble();
    if (approx > 100 && approx < 400) {
      _cachedMonitorPpi = approx;
      return approx;
    }
  } catch (_) {}

  return null;
}

/// @deprecated CSS 1in = 96px เสมอ — ไม่ใช้
double? webCssPixelsPerInch() => null;
