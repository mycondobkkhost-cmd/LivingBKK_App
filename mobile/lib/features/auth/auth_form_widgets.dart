import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';

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
      style: TextStyle(color: AppTheme.textPrimary),
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
          borderSide: const BorderSide(color: LivingBkkBrand.loginAccentPurple, width: 2),
        ),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

/// สโลแกนหน้าล็อกอิน — หลักใหญ่ + รองบรรทัดเดียว
class LoginSloganBlock extends StatelessWidget {
  const LoginSloganBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            LivingBkkBrand.loginMainSlogan(locale),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.3,
              color: LivingBkkBrand.loginAccentPurple,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              LivingBkkBrand.loginSubSloganLine(locale),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.15,
                color: LivingBkkBrand.loginSubSloganColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// พื้นหลัง login — โทนม่วงพาสเทลไล่สี (สอดคล้องหน้าแรก)
class AuthSplashBackdrop extends StatelessWidget {
  const AuthSplashBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: LivingBkkBrand.loginSoftGradient)),
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  LivingBkkBrand.loginAccentPurpleSoft.withOpacity(0.35),
                  LivingBkkBrand.magenta.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: -20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  LivingBkkBrand.purple.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// พื้นหลัง auth รอง
class AuthPastelBackdrop extends StatelessWidget {
  const AuthPastelBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: LivingBkkBrand.loginSoftGradient)),
        Positioned(
          top: -40,
          right: -30,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  LivingBkkBrand.loginAccentPurpleSoft.withOpacity(0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.cardTint,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: LivingBkkBrand.loginAccentPurple.withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
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

/// ปุ่มหลัก login — โทนม่วง
ButtonStyle authPrimaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: LivingBkkBrand.loginAccentPurple,
    foregroundColor: Colors.white,
    disabledBackgroundColor: LivingBkkBrand.loginAccentPurple.withOpacity(0.45),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  );
}
