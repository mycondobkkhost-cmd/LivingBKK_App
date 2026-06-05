import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_strings.dart';
import 'router/app_router.dart';
import 'state/locale_controller.dart';
import 'state/search_session_controller.dart';
import 'state/session_gate.dart';
import 'state/theme_controller.dart';
import 'state/user_role_controller.dart';
import 'theme/app_theme.dart';
import 'utils/admin_desktop.dart';
import 'widgets/mobile_viewport_shell.dart';

class LivingBkkApp extends StatefulWidget {
  const LivingBkkApp({
    super.key,
    required this.roleController,
    required this.searchSession,
    required this.localeController,
    required this.sessionGate,
    required this.themeController,
  });

  final UserRoleController roleController;
  final SearchSessionController searchSession;
  final LocaleController localeController;
  final SessionGate sessionGate;
  final ThemeController themeController;

  @override
  State<LivingBkkApp> createState() => _LivingBkkAppState();
}

class _LivingBkkAppState extends State<LivingBkkApp> {
  late final GoRouter _router;
  String _location = '/';

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create(
      roleController: widget.roleController,
      searchSession: widget.searchSession,
      localeController: widget.localeController,
      sessionGate: widget.sessionGate,
      themeController: widget.themeController,
    );
    _location = _router.routeInformationProvider.value.uri.path;
    _router.routeInformationProvider.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    final next = _router.routeInformationProvider.value.uri.path;
    if (next == _location) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _location = next);
    });
  }

  @override
  void dispose() {
    _router.routeInformationProvider.removeListener(_onRouteChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.roleController,
        widget.localeController,
        widget.themeController,
      ]),
      builder: (context, _) {
        return MaterialApp.router(
          title: 'PROPPITER',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: widget.themeController.mode,
          locale: widget.localeController.locale,
          supportedLocales: const [
            Locale('th'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
          builder: (context, child) {
            return AppThemeBridge(
              child: AppStringsScope(
                localeController: widget.localeController,
                child: MobileViewportShell(
                  fullWidth: isAdminPath(_location),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
