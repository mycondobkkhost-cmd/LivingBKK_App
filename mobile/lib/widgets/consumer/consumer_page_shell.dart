import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_palette.dart';
import '../../theme/li_layout.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/page_safe_insets.dart';
import '../../shell/main_shell_scope.dart';
import '../app_mobile_scaffold.dart';
import 'consumer_bottom_nav.dart';

/// หัวม่วง + พื้นหลังเทาอ่อน — ธีมเดียวกับหน้าแรก (นอก sticky search)
class ConsumerPageShell extends StatelessWidget {
  const ConsumerPageShell({
    super.key,
    required this.title,
    required this.body,
    this.titleWidget,
    this.titleFontSize,
    this.onBack,
    this.actions = const [],
    this.headerBottom,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.safeBottomBody = true,
    this.showBottomNav,
  });

  final String title;
  /// แทนที่ข้อความหัวข้อ — ใช้ dropdown หมวดทรัพย์บนหน้า browse
  final Widget? titleWidget;
  /// หัวข้อยาว — ลดขนาดให้พอดีแถบ
  final double? titleFontSize;
  final Widget body;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? headerBottom;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool safeBottomBody;
  /// null = แสดงเมนูล่างอัตโนมัติเมื่ออยู่นอก MainShell
  final bool? showBottomNav;

  @override
  Widget build(BuildContext context) {
    final inShell = MainShellScope.maybeOf(context) != null;
    final navVisible = showBottomNav ?? !inShell;

    return AppMobileScaffold(
      backgroundColor: LivingBkkBrand.pageBackgroundOf(context),
      safeBottomBody: safeBottomBody && !navVisible,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: navVisible ? const ConsumerBottomNav() : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConsumerPageHeader(
            title: title,
            titleWidget: titleWidget,
            titleFontSize: titleFontSize,
            onBack: onBack,
            actions: actions,
            bottom: headerBottom,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class ConsumerPageHeader extends StatelessWidget {
  const ConsumerPageHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.titleFontSize,
    this.onBack,
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final Widget? titleWidget;
  final double? titleFontSize;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? bottom;

  static const double _toolbarHeight = 48;
  static const double _hPad = LiLayout.pagePadding;

  @override
  Widget build(BuildContext context) {
    final top = PageSafeInsets.top(context);
    // Dynamic Island / notch — เว้นระยะเพิ่มเมื่อมี safe top สูง
    final headerTop = top >= 50 ? top + 10.0 : (top > 0 ? top + 8.0 : 12.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LivingBkkBrand.homeHeaderBlockGradientOf(context),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(_hPad, headerTop, _hPad, bottom != null ? 12 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _toolbarHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (onBack != null) ...[
                      ConsumerHeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: onBack!,
                        edgeInset: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: titleWidget ??
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.prompt(
                                        fontSize: titleFontSize ?? 20,
                                        fontWeight: FontWeight.w700,
                                        height: 1.15,
                                        color: Colors.white,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          if (actions.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: actions,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (bottom != null) ...[
                const SizedBox(height: 10),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ปุ่มไอคอนบนหัวม่วง — สไตล์เดียวกับ home toolbar / auth
class ConsumerHeaderIconButton extends StatelessWidget {
  const ConsumerHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badgeLabel,
    this.showBadge = false,
    this.edgeInset = const EdgeInsets.only(left: 6),
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Widget? badgeLabel;
  final bool showBadge;
  /// ปุ่มย้อนกลับใช้ [EdgeInsets.zero] — ปุ่มอื่นเว้นซ้ายเล็กน้อย
  final EdgeInsets edgeInset;

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 20, color: Colors.white);
    return Padding(
      padding: edgeInset,
      child: Material(
        color: Colors.white.withOpacity(0.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: _size,
            height: _size,
            child: Center(
              child: showBadge
                  ? Badge(
                      isLabelVisible: badgeLabel != null,
                      label: badgeLabel,
                      child: iconWidget,
                    )
                  : iconWidget,
            ),
          ),
        ),
      ),
    );
  }
}

/// ช่องค้นหาใต้หัวม่วง (หน้า discovery ฯลฯ)
/// ลิงก์ข้อความบนหัวม่วง (เช่น ล้างตัวกรอง)
class ConsumerHeaderTextButton extends StatelessWidget {
  const ConsumerHeaderTextButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

class ConsumerHeaderSearchField extends StatelessWidget {
  const ConsumerHeaderSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hint,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(LiLayout.searchHeight / 2),
      clipBehavior: Clip.antiAlias,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: TextStyle(fontSize: 14, height: 1.2, color: p.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: p.textSecondary),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 22,
            color: p.primary,
          ),
          filled: true,
          fillColor: p.inputFill,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
