import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'services/app_lifecycle_analytics.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/in_app_notification_hub.dart';
import 'l10n/app_strings.dart';
import 'router/app_router.dart';
import 'widgets/app_splash_overlay.dart';
import 'widgets/in_app_notification_banner.dart';
import 'state/locale_controller.dart';
import 'state/search_session_controller.dart';
import 'state/session_gate.dart';
import 'state/theme_controller.dart';
import 'state/user_role_controller.dart';
import 'theme/app_theme.dart';
import 'utils/admin_desktop.dart';
import 'widgets/mobile_route_shell.dart';
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

class _LivingBkkAppState extends State<LivingBkkApp> with WidgetsBindingObserver {
  late final GoRouter _router;
  String _location = '/';
  Uri _uri = Uri(path: '/');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = AppRouter.create(
      roleController: widget.roleController,
      searchSession: widget.searchSession,
      localeController: widget.localeController,
      sessionGate: widget.sessionGate,
      themeController: widget.themeController,
    );
    _uri = _router.routeInformationProvider.value.uri;
    _location = _uri.path;
    _router.routeInformationProvider.addListener(_onRouteChanged);
    widget.sessionGate.addListener(_syncCustomerChatInbox);
    AuthService.instance.addListener(_syncCustomerChatInbox);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCustomerChatInbox());
  }

  void _syncCustomerChatInbox() {
    if (!widget.sessionGate.loaded || !AuthService.instance.isSignedIn) return;
    if (widget.roleController.isPlatformAdmin) return;
    ChatService.instance.ensureCustomerInboxRealtime();
  }

  void _onRouteChanged() {
    final nextUri = _router.routeInformationProvider.value.uri;
    if (nextUri.path == _location && nextUri.query == _uri.query) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _uri = nextUri;
        _location = nextUri.path;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.sessionGate.removeListener(_syncCustomerChatInbox);
    AuthService.instance.removeListener(_syncCustomerChatInbox);
    _router.routeInformationProvider.removeListener(_onRouteChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AppLifecycleAnalytics.instance.onAppPaused();
    }
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
            final hub = InAppNotificationHub.instance;
            return AppThemeBridge(
              child: AppStringsScope(
                localeController: widget.localeController,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppSplashOverlay(
                      child: MobileViewportShell(
                        fullWidth: adminShellFullWidth(
                          _location,
                          query: _uri.queryParameters,
                        ),
                        child: MobileRouteShell(
                          path: _location,
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: InAppNotificationBanner(
                        hub: hub,
                        onTap: () {
                          hub.dismissBanner();
                          hub.clearUnread();
                          if (isAdminPath(_location)) {
                            _router.go('/admin/console');
                          } else {
                            hub.requestOpenContactTab();
                            _router.go('/');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
