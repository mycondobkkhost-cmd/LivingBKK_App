import 'package:flutter/material.dart';

import '../../config/legal_config.dart';
import '../../data/legal_documents.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/legal_navigation.dart';
import '../../utils/page_safe_insets.dart';
import '../../theme/li_layout.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.type});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEnglish = s.isEnglish;
    final title = type == LegalDocumentType.privacy ? s.signUpPrivacyLink : s.signUpTermsLink;

    return ConsumerPageShell(
      title: title,
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        ConsumerHeaderTextButton(
          label: type == LegalDocumentType.terms
              ? s.signUpPrivacyLink
              : s.signUpTermsLink,
          onTap: () => type == LegalDocumentType.terms
              ? LegalNavigation.openPrivacy(context)
              : LegalNavigation.openTerms(context),
        ),
      ],
      body: ListView(
        padding: PageSafeInsets.padLTRB(
          context,
          left: LiLayout.pagePadding,
          top: 12,
          right: LiLayout.pagePadding,
          bottom: 32,
          addHomeIndicator: false,
        ),
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
