import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// บน Web: จำกัดความกว้างแบบมือถือ (~iPhone) กลางจอ
const kMobilePreviewMaxWidth = 430.0;

class MobileViewportShell extends StatelessWidget {
  const MobileViewportShell({
    super.key,
    required this.child,
    this.fullWidth = false,
  });

  final Widget? child;

  /// บน Web: ไม่จำกัดความกว้าง (ใช้กับ /admin/*)
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || child == null || fullWidth) {
      return child ?? const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= kMobilePreviewMaxWidth + 24) {
          return child!;
        }

        return ColoredBox(
          color: const Color(0xFF12122B),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMobilePreviewMaxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.cardTint,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRect(child: child!),
              ),
            ),
          ),
        );
      },
    );
  }
}
