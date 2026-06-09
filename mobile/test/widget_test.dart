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
    expect(LivingBkkBrand.tagline(const Locale('th')), contains('โพสต์ฟรี'));
    expect(LivingBkkBrand.tagline(const Locale('en')), contains('Post for free'));
    expect(LivingBkkBrand.purplePrimary, const Color(0xFF583AD6));
    expect(LivingBkkBrand.pink, const Color(0xFFDB3D76));
  });

  test('listing share URL uses WEB_BASE_URL when set', () {
    expect(
      Env.listingShareUrl('abc-123'),
      'https://quiet-kangaroo-ab6073.netlify.app/listing/abc-123',
    );
  });

  testWidgets('RealXtate logo composes mark and wordmark', (WidgetTester tester) async {
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
    expect(find.textContaining('RealXtate'), findsOneWidget);
    expect(find.textContaining('โพสต์ฟรี'), findsOneWidget);
  });
}
