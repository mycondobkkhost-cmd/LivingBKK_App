import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/locale_controller.dart';
import '../theme/app_theme.dart';

/// สลับ ไทย / EN
class LanguageSwitchButton extends StatelessWidget {
  const LanguageSwitchButton({
    super.key,
    required this.controller,
    this.light = false,
  });

  final LocaleController controller;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = AppStrings(controller.isEnglish);
        final en = controller.isEnglish;
        return PopupMenuButton<bool>(
          tooltip: s.displayLanguage,
          padding: EdgeInsets.zero,
          onSelected: controller.setEnglish,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: false,
              child: Row(
                children: [
                  if (!en) Icon(Icons.check, size: 18, color: AppTheme.primary),
                  if (!en) const SizedBox(width: 8),
                  Text(s.languageTh),
                ],
              ),
            ),
            PopupMenuItem(
              value: true,
              child: Row(
                children: [
                  if (en) Icon(Icons.check, size: 18, color: AppTheme.primary),
                  if (en) const SizedBox(width: 8),
                  Text(s.languageEn),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: light ? Colors.white54 : AppTheme.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              en ? 'EN' : 'TH',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: light ? Colors.white : AppTheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
