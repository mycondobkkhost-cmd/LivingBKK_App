import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/theme_controller.dart';
import '../theme/profile_shell_theme.dart';

/// เลือกธีม — ไม่มีกรอบ เรียบกับพื้นแถวเมนู
class ThemeModeSwitchButton extends StatelessWidget {
  const ThemeModeSwitchButton({super.key, required this.controller});

  final ThemeController controller;

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final s = AppStrings.of(context);
    final origin = box.localToGlobal(Offset.zero);
    final selected = await showMenu<ThemeMode>(
      context: context,
      color: ProfileShellTheme.surface(context),
      position: RelativeRect.fromLTRB(
        origin.dx - 120,
        origin.dy + box.size.height + 4,
        origin.dx + box.size.width,
        origin.dy,
      ),
      items: [
        _menuItem(
          context,
          s.themeLight,
          ThemeMode.light,
          controller.mode,
        ),
        _menuItem(
          context,
          s.themeDark,
          ThemeMode.dark,
          controller.mode,
        ),
        _menuItem(
          context,
          s.themeSystem,
          ThemeMode.system,
          controller.mode,
        ),
      ],
    );
    if (selected != null) {
      await controller.setMode(selected);
    }
  }

  PopupMenuItem<ThemeMode> _menuItem(
    BuildContext context,
    String label,
    ThemeMode value,
    ThemeMode current,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (value == current)
            Icon(
              Icons.check,
              size: 18,
              color: ProfileShellTheme.accent(context),
            )
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = AppStrings.of(context);
        final label = controller.label(s.isEnglish);
        final secondary = ProfileShellTheme.textSecondary(context);

        return Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _openMenu(context),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: secondary,
                    ),
                  ),
                  Icon(Icons.expand_more, size: 20, color: secondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
