import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../state/admin_viewport_controller.dart';
import '../../widgets/iphone_device_frame.dart';

/// ห่อหน้าหลังบ้านด้วยกรอบ iPhone บนเว็บ (ทดสอบมือถือ)
class AdminPhoneFrameHost extends StatelessWidget {
  const AdminPhoneFrameHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = AdminViewportController.instance;
    if (!kIsWeb || controller == null) return child;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.phoneFramePreview) return child;

        return ColoredBox(
          color: const Color(0xFF1C1C1E),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: FittedBox(
                fit: BoxFit.contain,
                child: IPhoneDeviceFrame(child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ปุ่มเปิด/ปิดกรอบมือถือ — เว็บเท่านั้น
class AdminPhoneFrameToggleButton extends StatelessWidget {
  const AdminPhoneFrameToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    final controller = AdminViewportController.instance;
    if (controller == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = context.s;
        final on = controller.phoneFramePreview;
        return IconButton(
          tooltip: on ? s.adminPhoneFrameOff : s.adminPhoneFrameOn,
          icon: Icon(
            on ? Icons.smartphone : Icons.smartphone_outlined,
            size: 20,
            color: on ? const Color(0xFF1D4ED8) : null,
          ),
          onPressed: controller.togglePhoneFramePreview,
        );
      },
    );
  }
}
