import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/legal_navigation.dart';

/// ข้อความยอมรับเงื่อนไข + นโยบาย — ลิงก์กดเปิดได้
class LegalPolicyRichText extends StatelessWidget {
  const LegalPolicyRichText({
    super.key,
    required this.s,
    required this.prefix,
    this.middle,
    required this.suffix,
    this.fontSize = 13,
  });

  final AppStrings s;
  final String prefix;
  final String? middle;
  final String suffix;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: AppTheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      fontSize: fontSize,
    );
    final mid = middle ?? s.signUpTermsAnd;
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: fontSize, height: 1.45, color: AppTheme.textSecondary),
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: s.signUpTermsLink,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => LegalNavigation.openTerms(context),
          ),
          TextSpan(text: mid),
          TextSpan(
            text: s.signUpPrivacyLink,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => LegalNavigation.openPrivacy(context),
          ),
          TextSpan(text: suffix),
        ],
      ),
    );
  }
}
