import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/locale_controller.dart';
import '../state/search_session_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// ตัวกรองโคนายหน้า — แทนปุ่มสลับบทบาท (แสดงเฉพาะทรัพย์รับโค)
class CoBrokerSearchChip extends StatelessWidget {
  const CoBrokerSearchChip({
    super.key,
    required this.searchSession,
    required this.localeController,
    this.onPurpleHeader = false,
    this.compact = false,
    this.mini = false,
  });

  final SearchSessionController searchSession;
  final LocaleController localeController;
  final bool onPurpleHeader;
  final bool compact;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([searchSession, localeController]),
      builder: (context, _) {
        final s = AppStrings(localeController.isEnglish);
        final p = context.palette;
        final active = searchSession.coBrokerMode;
        final onPurple = onPurpleHeader;

        final fg = active
            ? Colors.white
            : (onPurple ? Colors.white : p.primary);
        final bg = active
            ? null
            : (onPurple ? Colors.white.withOpacity(0.16) : p.surface);
        final borderColor = active
            ? Colors.transparent
            : (onPurple
                ? Colors.white38
                : p.primary.withOpacity(0.4));

        return Material(
          color: bg,
          elevation: active ? 0 : (onPurple ? 0 : 1),
          shadowColor: p.cardShadow,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: InkWell(
            onTap: searchSession.toggleCoBrokerMode,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: Ink(
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(
                        colors: [p.primary, p.accent.withOpacity(0.88)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: mini ? 8 : (compact ? 10 : 12),
                vertical: mini ? 4 : (compact ? 5 : 7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    size: mini ? 14 : (compact ? 16 : 15),
                    color: fg,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      active ? s.coBrokerSearchChipOn : s.coBrokerSearchChip,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: mini ? 11 : (compact ? 12 : 11),
                        fontWeight: FontWeight.w800,
                        color: fg,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// สวิตช์ Co-Agent แบบ iOS — เทาเมื่อปิด · เขียวเมื่อเปิด (หัวหน้าแบบ Shopee)
class CoAgentToggleSwitch extends StatelessWidget {
  const CoAgentToggleSwitch({
    super.key,
    required this.searchSession,
    required this.localeController,
  });

  final SearchSessionController searchSession;
  final LocaleController localeController;

  static const Color _onGreen = Color(0xFF34C759);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([searchSession, localeController]),
      builder: (context, _) {
        final active = searchSession.coBrokerMode;
        return Semantics(
          label: AppStrings(localeController.isEnglish).coBrokerSearchChip,
          toggled: active,
          child: Transform.scale(
            scale: 0.82,
            child: Switch.adaptive(
              value: active,
              onChanged: (_) => searchSession.toggleCoBrokerMode(),
              activeColor: _onGreen,
              activeTrackColor: _onGreen.withOpacity(0.45),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.28),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        );
      },
    );
  }
}

/// แถบคำอธิบายเมื่อเปิดโหมดโคนายหน้า
class CoBrokerSearchHint extends StatelessWidget {
  const CoBrokerSearchHint({
    super.key,
    required this.searchSession,
    required this.localeController,
  });

  final SearchSessionController searchSession;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([searchSession, localeController]),
      builder: (context, _) {
        if (!searchSession.coBrokerMode) return const SizedBox.shrink();
        final s = AppStrings(localeController.isEnglish);
        final p = context.palette;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            s.coBrokerSearchHint,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: p.primary,
            ),
          ),
        );
      },
    );
  }
}
