import 'package:flutter/material.dart';

/// ค่า layout iPhone รุ่น Dynamic Island (15 Pro → 17 Pro Max)
///
/// อ้างอิง Apple Human Interface Guidelines + Simulator
abstract final class IosDeviceLayout {
  /// iPhone 15 Pro — ใช้เป็น default สำหรับ dev preview / Simulator
  static const iPhone15Pro = IosPhoneSpec(
    id: 'iPhone 15 Pro',
    logicalWidth: 393,
    logicalHeight: 852,
    devicePixelRatio: 3,
    safeTop: 59,
    safeBottom: 34,
    islandWidth: 126,
    islandHeight: 37,
    islandTop: 11,
    cornerRadius: 55,
  );

  /// iPhone 17 Pro Max — กรอบ preview บนเว็บ
  static const iPhone17ProMax = IosPhoneSpec(
    id: 'iPhone 17 Pro Max',
    logicalWidth: 440,
    logicalHeight: 956,
    devicePixelRatio: 3,
    safeTop: 59,
    safeBottom: 34,
    islandWidth: 126,
    islandHeight: 37,
    islandTop: 11,
    cornerRadius: 55,
  );

  /// อุปกรณ์จำลองเริ่มต้น — iPhone 17 Pro Max (440×956 pt)
  static const IosPhoneSpec defaultPreview = iPhone17ProMax;

  /// ขอบล่าง Dynamic Island — คอนเทนต์กดได้ต้องอยู่ใต้เส้นนี้
  static double islandBottom(IosPhoneSpec spec) =>
      spec.islandTop + spec.islandHeight;

  /// padding บนสำหรับปุ่ม/ข้อความ — ไม่บดบัง island
  static double interactiveTopPadding(
    BuildContext context, {
    IosPhoneSpec fallback = defaultPreview,
    double extra = 4,
  }) {
    final inset = _topInset(context);
    if (inset <= 0) return fallback.safeTop + extra;
    return inset + extra;
  }

  static double _topInset(BuildContext context) {
    final mq = MediaQuery.of(context);
    return mq.viewPadding.top > 0 ? mq.viewPadding.top : mq.padding.top;
  }

  static bool hasDynamicIslandInset(BuildContext context) {
    return _topInset(context) >= defaultPreview.safeTop - 6;
  }

  static MediaQueryData previewMediaQuery(
    IosPhoneSpec spec, {
    bool bleedBottom = false,
  }) {
    final bottom = bleedBottom ? 0.0 : spec.safeBottom;
    return MediaQueryData(
      size: Size(spec.logicalWidth, spec.logicalHeight),
      devicePixelRatio: spec.devicePixelRatio,
      textScaler: TextScaler.noScaling,
      padding: EdgeInsets.only(top: spec.safeTop, bottom: bottom),
      viewPadding: EdgeInsets.only(top: spec.safeTop, bottom: bottom),
    );
  }
}

/// สเปก logical pt ต่อรุ่น iPhone
class IosPhoneSpec {
  const IosPhoneSpec({
    required this.id,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.devicePixelRatio,
    required this.safeTop,
    required this.safeBottom,
    required this.islandWidth,
    required this.islandHeight,
    required this.islandTop,
    required this.cornerRadius,
  });

  final String id;
  final double logicalWidth;
  final double logicalHeight;
  final double devicePixelRatio;
  final double safeTop;
  final double safeBottom;
  final double islandWidth;
  final double islandHeight;
  final double islandTop;
  final double cornerRadius;

  Size get logicalSize => Size(logicalWidth, logicalHeight);

  double get islandBottom => islandTop + islandHeight;
}
