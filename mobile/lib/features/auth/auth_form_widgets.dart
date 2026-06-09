import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../widgets/proppiter_brand_hero.dart';
import '../../widgets/app_mobile_scaffold.dart';

/// หัวข้อฟอร์ม auth — สูงพอ อ่านง่าย ไม่เตี้ย
TextStyle authTitleTextStyle() => GoogleFonts.prompt(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.35,
      letterSpacing: 0.15,
      color: AppTheme.textPrimary,
    );

TextStyle authSubtitleTextStyle() => GoogleFonts.prompt(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppTheme.textSecondary,
    );

TextStyle authFormFieldTextStyle() => GoogleFonts.prompt(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: AppTheme.textPrimary,
    );

TextStyle authBodyTextStyle({Color? color}) => GoogleFonts.prompt(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: color ?? AppTheme.textSecondary,
    );

/// ช่องกรอกฟอร์ม auth ร่วม (login / signup)
class AuthFormField extends StatelessWidget {
  const AuthFormField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.prefix,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autocorrect: false,
      style: authFormFieldTextStyle(),
      decoration: InputDecoration(
        labelText: label,
        hintText: label == null ? hint : null,
        filled: true,
        fillColor: AppTheme.inputFill,
        prefixIcon: prefix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          borderSide: const BorderSide(color: LivingBkkBrand.homeHeaderBlockColor, width: 2),
        ),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

/// Hero ม่วงด้านบน — ธีมเดียวกับ `HomeStickySearchHeader`
class AuthHeroPanel extends StatelessWidget {
  const AuthHeroPanel({
    super.key,
    this.onBack,
    this.trailing,
    this.height = 220,
    this.brandSize,
    this.brandAlignment = const Alignment(0, -0.3),
  });

  final VoidCallback? onBack;
  final Widget? trailing;
  final double height;
  final ProppiterBrandHeroSize? brandSize;
  /// จัดโลโก้ในโซนม่วง — ค่าติดลบ = ขึ้นจากกึ่งกลาง
  final Alignment brandAlignment;

  @override
  Widget build(BuildContext context) {
    // viewPadding = island/notch บน Web preview + iPhone จริง (padding.top อาจเป็น 0)
    final mq = MediaQuery.of(context);
    final topInset = mq.viewPadding.top > 0 ? mq.viewPadding.top : mq.padding.top;
    final headerTop = topInset > 0 ? topInset + 6.0 : 8.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LivingBkkBrand.homeHeaderBlockGradientOf(context),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -50,
                right: -40,
                child: _authGlowOrb(180, 0.2),
              ),
              Positioned(
                bottom: -20,
                left: -30,
                child: _authGlowOrb(140, 0.12),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12, headerTop, 12, 20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (onBack != null)
                          _AuthIconChip(
                            icon: Icons.arrow_back_rounded,
                            onTap: onBack!,
                          )
                        else
                          const SizedBox(width: 40),
                        const Spacer(),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    Expanded(
                      child: Align(
                        alignment: brandAlignment,
                        child: ProppiterBrandHero(
                          size: brandSize ??
                              (height <= 200
                                  ? ProppiterBrandHeroSize.compact
                                  : ProppiterBrandHeroSize.standard),
                          centered: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _authGlowOrb(double size, double opacity) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Colors.white.withOpacity(opacity),
          Colors.transparent,
        ],
      ),
    ),
  );
}

class _AuthIconChip extends StatelessWidget {
  const _AuthIconChip({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// โครงหน้า auth — hero ม่วง + ฟอร์มพื้นเทาอ่อน (เหมือนหน้าแรก)
class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    this.onBack,
    this.trailing,
    required this.form,
    this.heroHeight = 220,
    this.heroBrandSize,
    this.heroBrandAlignment = const Alignment(0, -0.3),
    this.formOverlap = -20,
  });

  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget form;
  final double heroHeight;
  final ProppiterBrandHeroSize? heroBrandSize;
  final Alignment heroBrandAlignment;
  final double formOverlap;

  @override
  Widget build(BuildContext context) {
    return AppMobileScaffold(
      backgroundColor: LivingBkkBrand.pageBackgroundOf(context),
      body: Column(
        children: [
          AuthHeroPanel(
            onBack: onBack,
            trailing: trailing,
            height: heroHeight,
            brandSize: heroBrandSize,
            brandAlignment: heroBrandAlignment,
          ),
          Expanded(
            child: Transform.translate(
              offset: Offset(0, formOverlap),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: form,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: p.primary.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.color,
    this.icon,
    this.iconColor,
    this.child,
    this.border,
    this.iconSize = 24,
    this.onTap,
  });

  final Color color;
  final IconData? icon;
  final Color? iconColor;
  final Widget? child;
  final Color? border;
  final double iconSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border != null ? Border.all(color: border!) : null,
          ),
          alignment: Alignment.center,
          child: child ??
              Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );
  }
}

/// Apple logo สำหรับปุ่ม Sign in with Apple
class AppleLogoIcon extends StatelessWidget {
  const AppleLogoIcon({super.key, this.size = 22, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppleLogoPainter(color: color),
      ),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  _AppleLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.54, h * 0.08)
      ..cubicTo(w * 0.50, h * 0.02, w * 0.42, 0, w * 0.34, 0)
      ..cubicTo(w * 0.22, 0, w * 0.12, h * 0.08, w * 0.12, h * 0.22)
      ..cubicTo(w * 0.12, h * 0.36, w * 0.22, h * 0.44, w * 0.34, h * 0.44)
      ..cubicTo(w * 0.40, h * 0.44, w * 0.46, h * 0.42, w * 0.50, h * 0.38)
      ..cubicTo(w * 0.54, h * 0.42, w * 0.60, h * 0.44, w * 0.66, h * 0.44)
      ..cubicTo(w * 0.78, h * 0.44, w * 0.88, h * 0.36, w * 0.88, h * 0.22)
      ..cubicTo(w * 0.88, h * 0.10, w * 0.80, h * 0.02, w * 0.70, 0)
      ..cubicTo(w * 0.64, 0, w * 0.58, h * 0.02, w * 0.54, h * 0.08)
      ..close();
    canvas.drawPath(path, paint);

    final body = Path()
      ..moveTo(w * 0.50, h * 0.40)
      ..cubicTo(w * 0.34, h * 0.40, w * 0.18, h * 0.52, w * 0.18, h * 0.72)
      ..cubicTo(w * 0.18, h * 0.92, w * 0.34, h, w * 0.50, h)
      ..cubicTo(w * 0.66, h, w * 0.82, h * 0.92, w * 0.82, h * 0.72)
      ..cubicTo(w * 0.82, h * 0.52, w * 0.66, h * 0.40, w * 0.50, h * 0.40)
      ..close();
    canvas.drawPath(body, paint);

    final leaf = Path()
      ..moveTo(w * 0.58, h * 0.06)
      ..cubicTo(w * 0.66, h * 0.02, w * 0.74, h * 0.04, w * 0.78, h * 0.12)
      ..cubicTo(w * 0.70, h * 0.14, w * 0.64, h * 0.12, w * 0.58, h * 0.06)
      ..close();
    canvas.drawPath(leaf, paint);
  }

  @override
  bool shouldRepaint(covariant _AppleLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Google "G" มาตรฐาน (4 สี)
class GoogleLogoIcon extends StatelessWidget {
  const GoogleLogoIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, w - stroke, h - stroke);

    void arc(Color color, double start, double sweep) {
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, p);
    }

    arc(const Color(0xFF4285F4), -0.45, 1.55);
    arc(const Color(0xFF34A853), 1.1, 1.05);
    arc(const Color(0xFFFBBC05), 2.15, 1.05);
    arc(const Color(0xFFEA4335), 3.2, 1.05);

    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.48, h * 0.44, w * 0.42, stroke * 0.85),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ปุ่มหลัก auth — โทนม่วง header หน้าแรก
ButtonStyle authPrimaryButtonStyle(BuildContext context) {
  final p = context.palette;
  return FilledButton.styleFrom(
    backgroundColor: p.primary,
    foregroundColor: p.onPrimary,
    disabledBackgroundColor: p.primary.withOpacity(0.45),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    textStyle: GoogleFonts.prompt(fontWeight: FontWeight.w700, fontSize: 16),
  );
}
