import 'package:flutter/material.dart';

import '../../config/legal_config.dart';
import '../../data/legal_documents.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/legal_navigation.dart';

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.type});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEnglish = s.isEnglish;
    final title = type == LegalDocumentType.privacy ? s.signUpPrivacyLink : s.signUpTermsLink;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (type == LegalDocumentType.terms)
            TextButton(
              onPressed: () => LegalNavigation.openPrivacy(context),
              child: Text(s.signUpPrivacyLink, style: const TextStyle(fontSize: 13)),
            )
          else
            TextButton(
              onPressed: () => LegalNavigation.openTerms(context),
              child: Text(s.signUpTermsLink, style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            LegalDocuments.header(type, isEnglish),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          for (final section in LegalDocuments.sections(type)) ...[
            Text(
              isEnglish ? section.titleEn : section.titleTh,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isEnglish ? section.bodyEn : section.bodyTh,
              style: TextStyle(fontSize: 14, height: 1.55, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            isEnglish
                ? 'Contact: ${LegalConfig.contactEmail}'
                : 'ติดต่อ: ${LegalConfig.contactEmail}',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
