import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

/// ขนาดจอ iPhone 17 Pro Max (logical) — ใช้จำลองบนเว็บ
abstract final class IPhoneDeviceSpec {
  static const double width = 440;
  static const double height = 956;
  static const double safeTop = 59;
  static const double safeBottom = 68;
  static const double cornerRadius = 54;
  static const double islandWidth = 126;
  static const double islandHeight = 37;
  static const double islandTop = 11;
}

/// กรอบมือถือ — ใช้ทดสอบหลังบ้านบนเว็บ
class IPhoneDeviceFrame extends StatelessWidget {
  const IPhoneDeviceFrame({
    super.key,
    required this.child,
    this.backgroundColor = AdminTheme.bg,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      width: IPhoneDeviceSpec.width,
      height: IPhoneDeviceSpec.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(IPhoneDeviceSpec.cornerRadius),
        border: Border.all(color: const Color(0xFF3A3A3C), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 48,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          IPhoneDeviceSpec.cornerRadius - 3,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: backgroundColor),
            MediaQuery(
              data: mq.copyWith(
                size: const Size(
                  IPhoneDeviceSpec.width,
                  IPhoneDeviceSpec.height,
                ),
                padding: mq.padding.copyWith(
                  top: IPhoneDeviceSpec.safeTop,
                  bottom: IPhoneDeviceSpec.safeBottom,
                ),
                viewPadding: mq.viewPadding.copyWith(
                  top: IPhoneDeviceSpec.safeTop,
                  bottom: IPhoneDeviceSpec.safeBottom,
                ),
              ),
              child: child,
            ),
            Positioned(
              top: IPhoneDeviceSpec.islandTop,
              left: (IPhoneDeviceSpec.width - IPhoneDeviceSpec.islandWidth) / 2,
              child: IgnorePointer(
                child: Container(
                  width: IPhoneDeviceSpec.islandWidth,
                  height: IPhoneDeviceSpec.islandHeight,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(
                      IPhoneDeviceSpec.islandHeight / 2,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 134,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
