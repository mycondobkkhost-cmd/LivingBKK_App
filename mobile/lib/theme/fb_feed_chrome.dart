import 'package:flutter/material.dart';

/// โทนฟีดแบบ Facebook มือถือ — พื้นเทา · การ์ดขาวเต็มกว้าง · ช่องว่าง 8px
abstract final class FbFeedChrome {
  /// พื้นหลังฟีด (เห็นระหว่างการ์ด)
  static const Color background = Color(0xFFF0F2F5);

  /// เส้นคั่น / ขอบเบา
  static const Color hairline = Color(0xFFDADDE1);

  /// ข้อความรอง
  static const Color secondaryText = Color(0xFF65676B);

  /// พื้นไอคอน / กด
  static const Color chipFill = Color(0xFFF0F2F5);

  /// ช่องว่างระหว่างโมดูลฟีด
  static const double moduleGap = 8;

  /// padding ในหัวข้อเซกชัน
  static const EdgeInsets sectionHeaderPadding =
      EdgeInsets.fromLTRB(12, 10, 12, 8);

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.15,
    color: Color(0xFF050505),
  );
}

/// การ์ดฟีดขาวเต็มกว้าง — คั่นด้วยช่องเทา (ไม่ซ้อนเส้นขอบคู่)
class FbFeedCard extends StatelessWidget {
  const FbFeedCard({
    super.key,
    required this.child,
    this.padding,
    this.gapBelow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// เว้นช่องเทาใต้การ์ด (คั่นโมดูลถัดไป)
  final bool gapBelow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: gapBelow ? FbFeedChrome.moduleGap : 0),
      child: Material(
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          width: double.infinity,
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}
