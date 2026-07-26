import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/config/env.dart';
import 'package:livingbkk/services/local_prefs_service.dart';
import 'package:livingbkk/theme/living_bkk_brand.dart';
import 'package:livingbkk/widgets/living_bkk_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Env.load();
    await LocalPrefsService.instance.init();
  });

  test('RealXtate brand constants', () {
    expect(LivingBkkBrand.name, 'RealXtate');
    expect(LivingBkkBrand.tagline(const Locale('th')), contains('ลงประกาศฟรี'));
    expect(LivingBkkBrand.tagline(const Locale('en')), contains('Free to post'));
    expect(LivingBkkBrand.purplePrimary, LivingBkkBrand.propNavy);
    expect(LivingBkkBrand.pink, LivingBkkBrand.piterOrange);
  });

  test('listing share URL uses WEB_BASE_URL when set', () {
    expect(
      Env.listingShareUrl('abc-123'),
      'https://realxtateth.com/listing/abc-123',
    );
  });

  testWidgets('RealXtate logo composes lockup and tagline', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('th'),
        home: Scaffold(
          body: Center(
            child: LivingBkkLogo(
              size: LivingBkkLogoSize.lg,
              showTagline: true,
              isEnglish: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LivingBkkLogo), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('ลงประกาศฟรี'), findsOneWidget);
  });
}
