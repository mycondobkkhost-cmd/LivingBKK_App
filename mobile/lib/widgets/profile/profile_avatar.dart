import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

/// รูปโปรไฟล์ — URL หรือ bytes ชั่วคราวหลังเลือกรูป
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.memoryBytes,
    this.size = 44,
    this.iconSize,
    this.selected = false,
    this.ringColor,
    this.onTap,
  });

  final String? imageUrl;
  final Uint8List? memoryBytes;
  final double size;
  final double? iconSize;
  final bool selected;
  final Color? ringColor;
  final VoidCallback? onTap;

  bool get _hasImage =>
      (memoryBytes != null && memoryBytes!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ring = selected ? (ringColor ?? p.accent) : Colors.transparent;
    final iconSz = iconSize ?? size * 0.48;

    Widget avatar = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.surfaceVariant,
        border: Border.all(
          color: _hasImage ? ring : p.border,
          width: selected ? 2 : 1,
        ),
        image: _imageDecoration(),
      ),
      child: _hasImage
          ? null
          : Icon(
              Icons.person_outline_rounded,
              size: iconSz,
              color: p.textSecondary.withOpacity(0.75),
            ),
    );

    avatar = SizedBox(width: size, height: size, child: avatar);

    if (onTap != null) {
      avatar = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: avatar,
        ),
      );
    }

    return avatar;
  }

  DecorationImage? _imageDecoration() {
    if (memoryBytes != null && memoryBytes!.isNotEmpty) {
      return DecorationImage(
        image: MemoryImage(memoryBytes!),
        fit: BoxFit.cover,
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(imageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
}
