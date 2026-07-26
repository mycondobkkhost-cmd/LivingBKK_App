import 'package:flutter/material.dart';

import '../utils/ios_device_layout.dart';
import '../utils/page_safe_insets.dart';

/// หัว gradient เต็มจอ — พื้นหลังล้ำ safe area แต่คอนเทนต์หลบ Dynamic Island
///
/// เทียบ SwiftUI: พื้นหลัง `.ignoresSafeArea(.top)` + เนื้อหาใน safe area
class DynamicIslandHeader extends StatelessWidget {
  const DynamicIslandHeader({
    super.key,
    required this.background,
    required this.child,
    this.bottomPadding = 14,
    this.horizontalPadding = 14,
    this.topExtra = 4,
  });

  final Decoration background;
  final Widget child;
  final double bottomPadding;
  final double horizontalPadding;
  final double topExtra;

  @override
  Widget build(BuildContext context) {
    final topPad = IosDeviceLayout.interactiveTopPadding(
      context,
      extra: topExtra,
    );

    return DecoratedBox(
      decoration: background,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topPad,
          horizontalPadding,
          bottomPadding,
        ),
        child: child,
      ),
    );
  }
}

/// ครอบหน้าที่ต้องการ edge-to-edge บน iPhone — คอนเทนต์หลักอยู่ใน safe area
class DynamicIslandSafeShell extends StatelessWidget {
  const DynamicIslandSafeShell({
    super.key,
    required this.body,
    this.background,
    this.backgroundColor,
    this.topOverlay,
    this.extendBodyBehindTop = false,
    this.safeBottom = true,
  });

  final Widget body;
  final Gradient? background;
  final Color? backgroundColor;
  final Widget? topOverlay;
  final bool extendBodyBehindTop;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    final topInset = PageSafeInsets.top(context);
    final bottomInset = safeBottom ? PageSafeInsets.bottom(context) : 0.0;

    Widget content = body;

    if (!extendBodyBehindTop && topInset > 0) {
      content = Padding(
        padding: EdgeInsets.only(top: topInset),
        child: body,
      );
    }

    if (safeBottom && bottomInset > 0) {
      content = Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: content,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (background != null)
          DecoratedBox(decoration: BoxDecoration(gradient: background))
        else if (backgroundColor != null)
          ColoredBox(color: backgroundColor!),
        if (extendBodyBehindTop && background != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + 120,
            child: DecoratedBox(decoration: BoxDecoration(gradient: background)),
          ),
        content,
        if (topOverlay != null)
          Positioned(
            top: IosDeviceLayout.interactiveTopPadding(context),
            left: 0,
            right: 0,
            child: topOverlay!,
          ),
      ],
    );
  }
}
