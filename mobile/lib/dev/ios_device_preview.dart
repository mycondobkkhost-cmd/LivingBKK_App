import 'package:flutter/material.dart';

import '../utils/ios_device_layout.dart';
import '../widgets/iphone_device_frame.dart';

/// Flutter dev preview — เทียบ SwiftUI:
/// `.previewDevice(PreviewDevice(rawValue: "iPhone 17 Pro Max"))`
enum IosPreviewDevice {
  iPhone15Pro,
  iPhone17ProMax,
}

extension IosPreviewDeviceSpec on IosPreviewDevice {
  IosPhoneSpec get spec {
    switch (this) {
      case IosPreviewDevice.iPhone15Pro:
        return IosDeviceLayout.iPhone15Pro;
      case IosPreviewDevice.iPhone17ProMax:
        return IosDeviceLayout.iPhone17ProMax;
    }
  }
}

/// ห่อ widget สำหรับทดสอบ layout บน iPhone รุ่น Dynamic Island
class IosDevicePreview extends StatelessWidget {
  const IosDevicePreview({
    super.key,
    required this.child,
    this.device = IosPreviewDevice.iPhone17ProMax,
    this.showBezel = false,
    this.backgroundColor = const Color(0xFFF4F4F5),
  });

  final Widget child;
  final IosPreviewDevice device;
  final bool showBezel;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final spec = device.spec;

    Widget framed = MediaQuery(
      data: IosDeviceLayout.previewMediaQuery(spec),
      child: child,
    );

    if (showBezel && device == IosPreviewDevice.iPhone17ProMax) {
      framed = IPhone17ProMaxFrame(
        backgroundColor: backgroundColor,
        child: child,
      );
    } else if (showBezel) {
      framed = Container(
        width: spec.logicalWidth,
        height: spec.logicalHeight,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(spec.cornerRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(spec.cornerRadius - 3),
          child: MediaQuery(
            data: IosDeviceLayout.previewMediaQuery(spec),
            child: child,
          ),
        ),
      );
    } else {
      framed = SizedBox(
        width: spec.logicalWidth,
        height: spec.logicalHeight,
        child: framed,
      );
    }

    return ColoredBox(
      color: const Color(0xFF1C1C1E),
      child: Center(child: framed),
    );
  }
}
