import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/env.dart';
import 'firebase/firebase_bootstrap.dart';
import 'data/demo_listings_factory.dart';
import 'services/brand_service.dart';
import 'services/auth_service.dart';
import 'services/project_catalog.dart';
import 'services/search_display_catalog.dart';
import 'services/supabase_service.dart';
import 'services/demand_board_favorites_service.dart';
import 'services/favorites_service.dart';
import 'services/listing_activity_service.dart';
import 'services/platform_settings_service.dart';
import 'services/local_prefs_service.dart';
import 'state/locale_controller.dart';
import 'state/search_session_controller.dart';
import 'state/session_gate.dart';
import 'state/theme_controller.dart';
import 'state/user_role_controller.dart';
import 'utils/google_maps_web_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  if (kIsWeb && Env.hasMapsKey) {
    try {
      await ensureGoogleMapsWebSdk(Env.googleMapsApiKey);
    } catch (e) {
      debugPrint('Google Maps web SDK: $e');
    }
  }
  await FirebaseBootstrap.init();
  await SupabaseService.initialize();
  AuthService.instance.bindAuthListener();
  await ProjectCatalog.instance.load();
  await SearchDisplayCatalog.instance.load();
  await BrandService.instance.load();
  await LocalPrefsService.instance.init();
  await FavoritesService.instance.load();
  await DemandBoardFavoritesService.instance.load();
  await ListingActivityService.instance.load();
  await PlatformSettingsService.instance.load();
  final roleController = UserRoleController();
  final searchSession = SearchSessionController();
  final localeController = LocaleController();
  final themeController = ThemeController();
  final sessionGate = SessionGate();
  LocaleController.instance = localeController;
  SessionGate.instance = sessionGate;
  await localeController.load();
  await themeController.load();
  await sessionGate.load();
  DemoListingsFactory.invalidateCache();
  runApp(LivingBkkApp(
    roleController: roleController,
    searchSession: searchSession,
    localeController: localeController,
    themeController: themeController,
    sessionGate: sessionGate,
  ));
}
