import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/env.dart';
import '../config/legal_config.dart';

/// เปิดนโยบาย/เงื่อนไข — URL จาก env/เว็บ หรือหน้าในแอป (ฉบับเดียวกัน)
class LegalNavigation {
  LegalNavigation._();

  static Future<void> openTerms(BuildContext context) =>
      _open(context, LegalDocumentType.terms, Env.termsOfServiceUrl);

  static Future<void> openPrivacy(BuildContext context) =>
      _open(context, LegalDocumentType.privacy, Env.privacyPolicyUrl);

  static Future<void> _open(
    BuildContext context,
    LegalDocumentType type,
    String url,
  ) async {
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (context.mounted) context.push('/legal/${type.pathSegment}');
  }
}
