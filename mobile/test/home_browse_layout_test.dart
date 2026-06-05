import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/config/env.dart';
import 'package:livingbkk/models/search_filters.dart';
import 'package:livingbkk/services/local_prefs_service.dart';
import 'package:livingbkk/state/locale_controller.dart';
import 'package:livingbkk/state/search_session_controller.dart';
import 'package:livingbkk/state/user_role_controller.dart';
import 'package:livingbkk/widgets/home/home_browse_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Env.load();
    await LocalPrefsService.instance.init();
  });

  testWidgets('HomeBrowseLayout renders inside scroll view', (tester) async {
    final roleController = UserRoleController();
    final searchSession = SearchSessionController();
    final localeController = LocaleController();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('th'),
        home: Scaffold(
          body: HomeBrowseLayout(
            roleController: roleController,
            searchSession: searchSession,
            localeController: localeController,
            filters: const SearchFilters(),
            listings: const [],
            sections: const [],
            isAgentPerspective: false,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(HomeBrowseLayout), findsOneWidget);
  });
}
