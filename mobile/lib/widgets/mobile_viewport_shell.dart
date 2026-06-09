import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/admin_viewport_controller.dart';
import '../theme/living_bkk_brand.dart';
import '../utils/admin_desktop.dart';
import '../utils/web_browser_path.dart';

/// บน Web: จำกัดความกว้างแบบมือถือ (~iPhone) กลางจอ
const kMobilePreviewMaxWidth = 430.0;

/// iPhone 17 Pro Max — logical points (ใช้จำลอง safe area บน Web)
class IPhone17ProMaxPreview {
  IPhone17ProMaxPreview._();

  static const double width = 440;
  static const double height = 956;
  static const double safeTop = 59;
  /// Safe area ล่าง (34 + 34 pt)
  static const double safeBottom = 68;
  static const double cornerRadius = 54;
  static const double islandWidth = 126;
  static const double islandHeight = 37;
  static const double islandTop = 11;
}

class MobileViewportShell extends StatelessWidget {
  const MobileViewportShell({
    super.key,
    required this.child,
    this.fullWidth = false,
    this.path = '/',
  });

  final Widget? child;

  /// บน Web: ไม่จำกัดความกว้าง (ใช้กับ /admin/*)
  final bool fullWidth;

  /// เส้นทางปัจจุบัน — ใช้บังคับไม่แสดงกรอบ iPhone บนหลังบ้าน
  final String path;

  bool get _useFullWidth {
    if (!kIsWeb) return fullWidth;
    // หลังบ้านบนเว็บ — เต็มจอเสมอ (ไม่ใส่กรอบ iPhone แม้โหมด「แบบแอป」)
    if (isAdminPath(path)) return true;
    final browser = webBrowserPath();
    if (isAdminPath(browser)) return true;
    if (isAdminPath(Uri.base.path)) return true;
    return fullWidth;
  }

  @override
  Widget build(BuildContext context) {
    if (child == null) {
      return const SizedBox.shrink();
    }

    // Native app — ใช้ safe area จากระบบ (ปุ่มล่างจัดใน AdminMobileLayout)
    if (!kIsWeb) {
      return child!;
    }

    // Admin / full-width — จอกว้างใช้พื้นที่ล่างเต็มจอ
    if (_useFullWidth) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= kMobilePreviewMaxWidth + 48) {
            return _injectSafeArea(context, child!, bleedBottom: true);
          }
          return _stripBottomInset(context, child!);
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= kMobilePreviewMaxWidth + 24) {
          return _injectSafeArea(context, child!);
        }

        return ColoredBox(
          color: const Color(0xFF1C1C1E),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: FittedBox(
                fit: BoxFit.contain,
                child: _IPhone17ProMaxFrame(child: child!),
              ),
            ),
          ),
        );
      },
    );
  }

  /// จอแคบ (เต็มความกว้าง) — ยังใส่ safe area ให้ใกล้ iPhone จริง
  static Widget _injectSafeArea(
    BuildContext context,
    Widget child, {
    bool bleedBottom = false,
  }) {
    final mq = MediaQuery.of(context);
    if (mq.viewPadding.top >= IPhone17ProMaxPreview.safeTop - 4) {
      return bleedBottom ? _stripBottomInset(context, child) : child;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LivingBkkBrand.homeHeaderBlockGradientOf(context),
          ),
        ),
        MediaQuery(
          data: mq.copyWith(
            padding: mq.padding.copyWith(
              top: IPhone17ProMaxPreview.safeTop,
              bottom: bleedBottom ? 0 : IPhone17ProMaxPreview.safeBottom,
            ),
            viewPadding: mq.viewPadding.copyWith(
              top: IPhone17ProMaxPreview.safeTop,
              bottom: bleedBottom ? 0 : IPhone17ProMaxPreview.safeBottom,
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  static Widget _stripBottomInset(BuildContext context, Widget child) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(bottom: 0),
        viewPadding: mq.viewPadding.copyWith(bottom: 0),
      ),
      child: child,
    );
  }
}

class _IPhone17ProMaxFrame extends StatelessWidget {
  const _IPhone17ProMaxFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      width: IPhone17ProMaxPreview.width,
      height: IPhone17ProMaxPreview.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius:
            BorderRadius.circular(IPhone17ProMaxPreview.cornerRadius),
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
          IPhone17ProMaxPreview.cornerRadius - 3,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LivingBkkBrand.homeHeaderBlockGradientOf(context),
              ),
            ),
            MediaQuery(
              data: mq.copyWith(
                size: const Size(
                  IPhone17ProMaxPreview.width,
                  IPhone17ProMaxPreview.height,
                ),
                padding: mq.padding.copyWith(
                  top: IPhone17ProMaxPreview.safeTop,
                  bottom: IPhone17ProMaxPreview.safeBottom,
                ),
                viewPadding: mq.viewPadding.copyWith(
                  top: IPhone17ProMaxPreview.safeTop,
                  bottom: IPhone17ProMaxPreview.safeBottom,
                ),
              ),
              child: child,
            ),
            Positioned(
              top: IPhone17ProMaxPreview.islandTop,
              left: (IPhone17ProMaxPreview.width -
                      IPhone17ProMaxPreview.islandWidth) /
                  2,
              child: IgnorePointer(
                child: Container(
                  width: IPhone17ProMaxPreview.islandWidth,
                  height: IPhone17ProMaxPreview.islandHeight,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(
                      IPhone17ProMaxPreview.islandHeight / 2,
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
