import 'package:flutter/material.dart';

/// Safe area / home indicator — ใช้ร่วมทุกหน้า (เหมือนหน้าแรก)
abstract final class PageSafeInsets {
  static double top(BuildContext context) {
    final mq = MediaQuery.of(context);
    return mq.viewPadding.top > 0 ? mq.viewPadding.top : mq.padding.top;
  }

  static double bottom(BuildContext context) {
    final mq = MediaQuery.of(context);
    return mq.viewPadding.bottom > 0 ? mq.viewPadding.bottom : mq.padding.bottom;
  }

  /// Padding ล่างสำหรับ ListView / ScrollView นอก MainShell
  static EdgeInsets scrollBottom(
    BuildContext context, {
    double base = 24,
  }) =>
      EdgeInsets.only(bottom: base + bottom(context));

  /// Padding ล่างในแท็บ MainShell — ไม่รวม home indicator (มี bottom nav แล้ว)
  static EdgeInsets shellScrollBottom({double base = 16}) =>
      EdgeInsets.only(bottom: base);

  static EdgeInsets padLTRB(
    BuildContext context, {
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
    bool addHomeIndicator = true,
  }) =>
      EdgeInsets.fromLTRB(
        left,
        top,
        right,
        bottom + (addHomeIndicator ? PageSafeInsets.bottom(context) : 0),
      );
}
