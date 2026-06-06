import 'package:flutter/material.dart';

/// Safe area + spacing หลังบ้าน — อ่าน `viewPadding` แบบหน้าแรก (Dynamic Island / notch)
abstract final class AdminMobileLayout {
  static const double compactBreakpoint = 600;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  /// Inset บน — ใช้ viewPadding ก่อน (เหมือน `HomeStickySearchHeader.topInset`)
  static double topInset(BuildContext context) {
    final mq = MediaQuery.of(context);
    return mq.viewPadding.top > 0 ? mq.viewPadding.top : mq.padding.top;
  }

  /// Inset ล่าง — home indicator
  static double bottomInset(BuildContext context, {double extra = 0}) {
    final mq = MediaQuery.of(context);
    final raw = mq.viewPadding.bottom > 0 ? mq.viewPadding.bottom : mq.padding.bottom;
    return raw + extra;
  }

  static double fabBottom(BuildContext context) => bottomInset(context, extra: 16);

  /// ผสาน viewPadding → padding ให้ Scaffold / SafeArea อ่านค่าเดียวกับหน้าหลัก
  static Widget withInsets(BuildContext context, Widget child) {
    final mq = MediaQuery.of(context);
    final top = topInset(context);
    final bottom = mq.viewPadding.bottom > 0 ? mq.viewPadding.bottom : mq.padding.bottom;
    if ((top - mq.padding.top).abs() < 0.5 && (bottom - mq.padding.bottom).abs() < 0.5) {
      return child;
    }
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(top: top, bottom: bottom),
      ),
      child: child,
    );
  }

  /// Padding ล่างสำหรับ ListView ที่มีปุ่มลอย/แถบล่าง
  static EdgeInsets scrollPadding(
    BuildContext context, {
    double top = 12,
    double horizontal = 16,
    double fabClearance = 80,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      top + fabClearance + bottomInset(context),
    );
  }

  /// ห่อเนื้อหาแท็บแอดมิน — กันปุ่มล่างโดน home indicator
  static Widget tabBody(
    BuildContext context, {
    required Widget child,
    bool top = false,
  }) {
    return SafeArea(
      top: top,
      bottom: true,
      minimum: EdgeInsets.only(bottom: bottomInset(context) > 0 ? 4 : 8),
      child: child,
    );
  }

  /// ปุ่ม/แถบตรึงล่าง (FAB, บันทึก, เผยแพร่)
  static Widget stickyFooter(
    BuildContext context, {
    required Widget child,
    double horizontal = 16,
  }) {
    return Positioned(
      left: horizontal,
      right: horizontal,
      bottom: fabBottom(context),
      child: child,
    );
  }

  /// ห่อหน้าแอดมินทั้งหน้า — header อยู่ใต้ Dynamic Island
  static Widget page({
    required BuildContext context,
    required Widget child,
  }) {
    return withInsets(context, child);
  }

  /// AppBar กะทัดรัดบนมือถือ
  static PreferredSizeWidget appBar({
    required BuildContext context,
    required Widget title,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    Widget? leading,
    bool? centerTitle,
  }) {
    final compact = isCompact(context);
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle ?? compact,
      toolbarHeight: compact ? 48 : kToolbarHeight,
      scrolledUnderElevation: 0,
    );
  }

  /// Scaffold แอดมินมาตรฐาน — top + bottom safe area
  static Widget scaffold({
    required BuildContext context,
    PreferredSizeWidget? appBar,
    required Widget body,
    Widget? floatingActionButton,
    Color? backgroundColor,
    bool safeBottom = true,
  }) {
    return page(
      context: context,
      child: Scaffold(
        appBar: appBar,
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        body: safeBottom ? tabBody(context, child: body) : body,
      ),
    );
  }
}
