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
    this.compact = false,
    this.hero = false,
  });

  final LocaleController controller;
  final bool light;
  final bool compact;
  /// ขนาดใหญ่ขึ้นสำหรับ hero หน้า login/signup
  final bool hero;

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final s = AppStrings(controller.isEnglish);
    final en = controller.isEnglish;
    final origin = box.localToGlobal(Offset.zero);
    final selected = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + box.size.height + 4,
        origin.dx + box.size.width,
        origin.dy,
      ),
      items: [
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
    );
    if (selected != null) {
      await controller.setEnglish(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = AppStrings(controller.isEnglish);
        final en = controller.isEnglish;
        return Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _openMenu(context),
            borderRadius: BorderRadius.circular(hero ? 7 : (compact ? 5 : 6)),
            child: Tooltip(
              message: s.displayLanguage,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: hero ? 11 : (compact ? 7 : 8),
                  vertical: hero ? 5 : (compact ? 2 : 4),
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: light ? Colors.white54 : AppTheme.border),
                  borderRadius: BorderRadius.circular(hero ? 7 : (compact ? 5 : 6)),
                ),
                child: Text(
                  en ? 'EN' : 'TH',
                  style: TextStyle(
                    fontSize: hero ? 13 : (compact ? 10 : 11),
                    height: hero ? 1.15 : (compact ? 1.1 : 1.2),
                    fontWeight: FontWeight.w800,
                    color: light ? Colors.white : AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
