import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ส้มเด่นสำหรับ badge ปฏิทิน (อ่านง่ายบนพื้นหลังอ่อน)
const kAdminCalendarNotifyOrange = Color(0xFFFF5722);

/// ตัวเลขแจ้งเตือนบนไอคอน — ส้ม/แดง เด่น (ปฏิทิน / งานที่ยังไม่เปิดดู)
class AdminAttentionIconBadge extends StatelessWidget {
  const AdminAttentionIconBadge({
    super.key,
    required this.child,
    required this.count,
    this.useRed = false,
  });

  final Widget child;
  final int count;
  final bool useRed;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    final display = count > 99 ? '99+' : '$count';
    final bg = useRed ? AppTheme.error : kAdminCalendarNotifyOrange;
    final fontSize = count >= 10 ? 9.0 : 11.0;
    final size = count >= 100 ? 26.0 : (count >= 10 ? 24.0 : 20.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -5,
          top: -5,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: bg.withOpacity(0.5),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              display,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ปุ่มปฏิทินหลังบ้านพร้อม badge งานที่ยังไม่เปิดดู
class AdminCalendarNavIconButton extends StatelessWidget {
  const AdminCalendarNavIconButton({
    super.key,
    required this.unreadCount,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 24,
    this.compact = false,
  });

  final int unreadCount;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: unreadCount > 0 ? '$tooltip ($unreadCount)' : tooltip,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      icon: AdminAttentionIconBadge(
        count: unreadCount,
        child: Icon(Icons.calendar_month_outlined, size: iconSize),
      ),
    );
  }
}
