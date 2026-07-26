import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../widgets/proppiter_brand_hero.dart';
import '../../widgets/app_mobile_scaffold.dart';

/// หัวข้อฟอร์ม auth — Prompt ชัด อ่านง่าย (ธีมเดียวกับทั้งแอป)
TextStyle authTitleTextStyle() => GoogleFonts.prompt(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.35,
      letterSpacing: -0.2,
      color: AppTheme.textPrimary,
    );

TextStyle authSubtitleTextStyle() => GoogleFonts.prompt(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.55,
      color: AppTheme.textSecondary,
    );

TextStyle authFormFieldTextStyle() => GoogleFonts.prompt(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: AppTheme.textPrimary,
    );

TextStyle authBodyTextStyle({Color? color, FontWeight weight = FontWeight.w400}) =>
    GoogleFonts.prompt(
      fontSize: 13,
      fontWeight: weight,
      height: 1.5,
      color: color ?? AppTheme.textSecondary,
    );

TextStyle authButtonLabelStyle({required Color color}) => GoogleFonts.prompt(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: color,
    );

TextStyle authLinkStyle({required Color color}) => GoogleFonts.prompt(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: color,
      decoration: TextDecoration.underline,
      decorationColor: color,
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

/// ไอคอนโทรศัพท์บนปุ่มหลัก
class PhoneLogoIcon extends StatelessWidget {
  const PhoneLogoIcon({super.key, this.size = 22, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.phone_iphone_rounded, size: size, color: color);
  }
}

/// Apple logo — SVG มาตรฐาน (Simple Icons, inline ไม่พึ่ง asset)
class AppleLogoIcon extends StatelessWidget {
  const AppleLogoIcon({super.key, this.size = 22, this.color = Colors.black});

  final double size;
  final Color color;

  static const _svg =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
      '<path fill="currentColor" d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: 'Apple',
    );
  }
}

/// Google "G" สี่สี
class GoogleLogoIcon extends StatelessWidget {
  const GoogleLogoIcon({super.key, this.size = 22});

  final double size;

  static const _svg =
      '<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">'
      '<path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.389-3.917z"/>'
      '<path fill="#FF3D00" d="M6.306 14.691l6.571 3.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>'
      '<path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238C29.211 35.091 26.715 36 24 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/>'
      '<path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303c-.792 2.237-2.231 4.166-4.087 5.571l.003-.002 6.19 5.238C36.971 39.205 44 34 44 24c0-1.341-.138-2.65-.389-3.917z"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
      semanticsLabel: 'Google',
    );
  }
}

/// LINE logo — SVG มาตรฐาน (Simple Icons)
class LineLogoIcon extends StatelessWidget {
  const LineLogoIcon({super.key, this.size = 22});

  final double size;

  static const _svg =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
      '<path fill="#06C755" fill-rule="evenodd" d="M19.365 9.863c.349 0 .63.285.63.631 0 .345-.281.63-.63.63H17.61v1.125h1.755c.349 0 .63.283.63.63 0 .344-.281.629-.63.629h-2.386c-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63h2.386c.346 0 .627.285.627.63 0 .349-.281.63-.63.63H17.61v1.125h1.755zm-3.855 3.016c0 .27-.174.51-.432.596-.064.021-.133.031-.199.031-.211 0-.391-.09-.51-.25l-2.443-3.317v2.94c0 .344-.279.629-.631.629-.346 0-.626-.285-.626-.629V8.108c0-.27.173-.51.43-.595.06-.023.136-.033.194-.033.195 0 .375.104.495.254l2.462 3.33V8.108c0-.345.282-.63.63-.63.345 0 .63.285.63.63v4.771zm-5.741 0c0 .344-.282.629-.631.629-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63.346 0 .628.285.628.63v4.771zm-2.466.629H4.917c-.345 0-.63-.285-.63-.629V8.108c0-.345.285-.63.63-.63.348 0 .63.285.63.63v4.141h1.756c.348 0 .629.283.629.63 0 .344-.282.629-.629.629M24 10.314C24 4.943 18.615.572 12 .572S0 4.943 0 10.314c0 4.811 4.27 8.842 10.035 9.608.391.082.923.258 1.058.59.12.301.079.766.038 1.08l-.164 1.02c-.045.301-.24 1.186 1.049.645 1.291-.539 6.916-4.078 9.436-6.975C23.176 14.393 24 12.458 24 10.314"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
      semanticsLabel: 'LINE',
    );
  }
}

/// ปุ่มเต็มความกว้าง — หลัก (เติมสี) หรือรอง (ขอบ)
class AuthContinueButton extends StatelessWidget {
  const AuthContinueButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.filled = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool filled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = filled ? p.primary : p.surface;
    final fg = filled ? p.onPrimary : p.textPrimary;
    final border = filled
        ? null
        : Border.all(color: const Color(0xFFE5E7EB), width: 1.2);

    return Material(
      color: enabled ? bg : bg.withOpacity(0.55),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: filled ? 0 : 0,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: border,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Center(child: leading),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: authButtonLabelStyle(color: fg),
                ),
              ),
              const SizedBox(width: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// ปุ่มหลัก auth — โทน primary ของแบรนด์
ButtonStyle authPrimaryButtonStyle(BuildContext context) {
  final p = context.palette;
  return FilledButton.styleFrom(
    backgroundColor: p.primary,
    foregroundColor: p.onPrimary,
    disabledBackgroundColor: p.primary.withOpacity(0.45),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    textStyle: authButtonLabelStyle(color: p.onPrimary).copyWith(fontSize: 16),
  );
}
