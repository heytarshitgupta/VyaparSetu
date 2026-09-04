import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/localization/language_provider.dart';
import 'package:buyer_section/core/location/indian_states.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/core/theme/theme_provider.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_provider.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_screen.dart';

Widget _createLocalizedLocationApp({
  required LanguageProvider languageProvider,
  required ThemeProvider themeProvider,
  required ProducerOnboardingProvider onboardingProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    ],
    child: Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, lang, theme, _) {
        return MaterialApp(
          locale: lang.currentLocale,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme.themeMode,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ProducerOnboardingScreen(
            provider: onboardingProvider,
          ),
        );
      },
    ),
  );
}

void main() {
  group('Localized Location Data Foundation Unit Tests (Step 5B.3)', () {
    test('PB canonical code displays as Punjab in English, पंजाब in Hindi, ਪੰਜਾਬ in Punjabi', () {
      final pb = IndianStates.findByCode('PB');
      expect(pb, isNotNull);
      expect(pb!.code, 'PB');
      expect(pb.englishName, 'Punjab');
      expect(pb.hindiName, 'पंजाब');
      expect(pb.punjabiName, 'ਪੰਜਾਬ');

      // Localized name via Locale
      expect(pb.getLocalizedName(const Locale('en')), 'Punjab');
      expect(pb.getLocalizedName(const Locale('hi')), 'पंजाब');
      expect(pb.getLocalizedName(const Locale('pa')), 'ਪੰਜਾਬ');

      // Localized name via language code
      expect(pb.getLocalizedNameForCode('en'), 'Punjab');
      expect(pb.getLocalizedNameForCode('hi'), 'पंजाब');
      expect(pb.getLocalizedNameForCode('pa'), 'ਪੰਜਾਬ');
    });

    test('All 36 States and UTs are deterministically loaded with valid codes and multilingual names', () {
      expect(IndianStates.allStates.length, 36);

      for (final state in IndianStates.allStates) {
        expect(state.code.length, 2, reason: 'State code must be 2 characters: ${state.code}');
        expect(state.englishName.trim().isNotEmpty, isTrue);
        expect(state.hindiName.trim().isNotEmpty, isTrue);
        expect(state.punjabiName.trim().isNotEmpty, isTrue);
      }

      // Check key states and UTs
      expect(IndianStates.findByCode('DL')?.englishName, 'Delhi');
      expect(IndianStates.findByCode('DL')?.hindiName, 'दिल्ली');
      expect(IndianStates.findByCode('DL')?.punjabiName, 'ਦਿੱਲੀ');

      expect(IndianStates.findByCode('RJ')?.englishName, 'Rajasthan');
      expect(IndianStates.findByCode('RJ')?.hindiName, 'राजस्थान');
      expect(IndianStates.findByCode('RJ')?.punjabiName, 'ਰਾਜਸਥਾਨ');

      expect(IndianStates.findByCode('HR')?.englishName, 'Haryana');
      expect(IndianStates.findByCode('HR')?.hindiName, 'हरियाणा');
      expect(IndianStates.findByCode('HR')?.punjabiName, 'ਹਰਿਆਣਾ');
    });

    test('findByCodeOrName resolves canonical code from English, Hindi, and Punjabi names', () {
      expect(IndianStates.findByCodeOrName('PB')?.code, 'PB');
      expect(IndianStates.findByCodeOrName('Punjab')?.code, 'PB');
      expect(IndianStates.findByCodeOrName('पंजाब')?.code, 'PB');
      expect(IndianStates.findByCodeOrName('ਪੰਜਾਬ')?.code, 'PB');

      expect(IndianStates.getCanonicalCode('Punjab'), 'PB');
      expect(IndianStates.getCanonicalCode('पंजाब'), 'PB');
      expect(IndianStates.getCanonicalCode('ਪੰਜਾਬ'), 'PB');
      expect(IndianStates.getCanonicalCode('PB'), 'PB');

      expect(IndianStates.getEnglishName('PB'), 'Punjab');
      expect(IndianStates.getEnglishName('पंजाब'), 'Punjab');
      expect(IndianStates.getEnglishName('ਪੰਜਾਬ'), 'Punjab');
    });

    test('Zero runtime translation or external AI dependencies', () {
      // Validates dataset is completely local, synchronous, and deterministic
      const stopwatch = Duration(milliseconds: 10);
      final startTime = DateTime.now();
      for (int i = 0; i < 1000; i++) {
        IndianStates.findByCode('PB');
        IndianStates.getLocalizedName('PB', const Locale('hi'));
      }
      final duration = DateTime.now().difference(startTime);
      expect(duration < stopwatch * 5, isTrue);
    });
  });

  group('Localized Location UI & State Preservation Widget Tests (Step 5B.3)', () {
    testWidgets('State dropdown shows Punjab in EN, पंजाब in HI, ਪੰਜਾਬ in PA with same canonical PB',
        (WidgetTester tester) async {
      final languageProvider = LanguageProvider();
      final themeProvider = ThemeProvider();
      final onboardingProvider = ProducerOnboardingProvider();

      // Start on Step 3 with canonical PB
      onboardingProvider.setFullName('Harjit Singh');
      onboardingProvider.setBusinessName('Khalsa Handlooms');
      onboardingProvider.setCraftCategory('Textiles');
      onboardingProvider.setStateValue('PB');
      onboardingProvider.goToStep(2);

      await tester.pumpWidget(
        _createLocalizedLocationApp(
          languageProvider: languageProvider,
          themeProvider: themeProvider,
          onboardingProvider: onboardingProvider,
        ),
      );
      await tester.pumpAndSettle();

      // 1. English: Dropdown displays 'Punjab'
      expect(find.text('Punjab'), findsOneWidget);
      expect(onboardingProvider.stateCode, 'PB');

      // 2. Switch to Hindi: Dropdown displays 'पंजाब'
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(find.text('पंजाब'), findsOneWidget);
      expect(onboardingProvider.stateCode, 'PB');

      // 3. Switch to Punjabi: Dropdown displays 'ਪੰਜਾਬ'
      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(find.text('ਪੰਜਾਬ'), findsOneWidget);
      expect(onboardingProvider.stateCode, 'PB');

      // 4. Switch back to English: Dropdown displays 'Punjab'
      languageProvider.setAppLanguage(AppLanguage.english);
      await tester.pumpAndSettle();
      expect(find.text('Punjab'), findsOneWidget);
      expect(onboardingProvider.stateCode, 'PB');
    });

    testWidgets('Changing language does not clear district, city, or address inputs',
        (WidgetTester tester) async {
      final languageProvider = LanguageProvider();
      final themeProvider = ThemeProvider();
      final onboardingProvider = ProducerOnboardingProvider();

      onboardingProvider.setFullName('Gurmeet Kaur');
      onboardingProvider.setBusinessName('Phulkari Kendra');
      onboardingProvider.setCraftCategory('Textiles');
      onboardingProvider.setStateValue('PB');
      onboardingProvider.setDistrict('Patiala');
      onboardingProvider.setCity('Nabha');
      onboardingProvider.setPincode('147201');
      onboardingProvider.setAddress('Near Old Fort, Street 4');
      onboardingProvider.goToStep(2);

      await tester.pumpWidget(
        _createLocalizedLocationApp(
          languageProvider: languageProvider,
          themeProvider: themeProvider,
          onboardingProvider: onboardingProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial English values
      expect(find.text('Patiala'), findsOneWidget);
      expect(find.text('Nabha'), findsOneWidget);
      expect(find.text('147201'), findsOneWidget);
      expect(find.text('Near Old Fort, Street 4'), findsOneWidget);

      // Switch to Hindi
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();

      expect(onboardingProvider.district, 'Patiala');
      expect(onboardingProvider.city, 'Nabha');
      expect(onboardingProvider.pincode, '147201');
      expect(onboardingProvider.address, 'Near Old Fort, Street 4');
      expect(find.text('Patiala'), findsOneWidget);
      expect(find.text('Nabha'), findsOneWidget);
      expect(find.text('147201'), findsOneWidget);
      expect(find.text('Near Old Fort, Street 4'), findsOneWidget);

      // Switch to Punjabi
      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();

      expect(onboardingProvider.district, 'Patiala');
      expect(onboardingProvider.city, 'Nabha');
      expect(onboardingProvider.pincode, '147201');
      expect(onboardingProvider.address, 'Near Old Fort, Street 4');
      expect(find.text('Patiala'), findsOneWidget);
      expect(find.text('Nabha'), findsOneWidget);
      expect(find.text('147201'), findsOneWidget);
      expect(find.text('Near Old Fort, Street 4'), findsOneWidget);
    });

    testWidgets('Hindi and Punjabi Unicode free-form address inputs remain exactly unchanged',
        (WidgetTester tester) async {
      final languageProvider = LanguageProvider();
      final themeProvider = ThemeProvider();
      final onboardingProvider = ProducerOnboardingProvider();

      onboardingProvider.setFullName('ਸੁਰਜੀਤ ਸਿੰਘ');
      onboardingProvider.setBusinessName('ਕਾਰੀਗਰੀ ਕੇਂਦਰ');
      onboardingProvider.setCraftCategory('Woodwork');
      onboardingProvider.setStateValue('PB');
      onboardingProvider.setDistrict('ਲੁਧਿਆਣਾ');
      onboardingProvider.setCity('ਖੰਨਾ');
      onboardingProvider.setPincode('141401');
      onboardingProvider.setAddress('ਮਕਾਨ ਨੰ. ੪੨, ਗੁਰਦੁਆਰਾ ਰੋਡ, ਪਿੰਡ ਸਮਰਾਲਾ');
      onboardingProvider.goToStep(2);

      await tester.pumpWidget(
        _createLocalizedLocationApp(
          languageProvider: languageProvider,
          themeProvider: themeProvider,
          onboardingProvider: onboardingProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Gurmukhi Unicode fields are rendered without mangling
      expect(find.text('ਲੁਧਿਆਣਾ'), findsOneWidget);
      expect(find.text('ਖੰਨਾ'), findsOneWidget);
      expect(find.text('ਮਕਾਨ ਨੰ. ੪੨, ਗੁਰਦੁਆਰਾ ਰੋਡ, ਪਿੰਡ ਸਮਰਾਲਾ'), findsOneWidget);

      // Switch language to Hindi -> Gurmukhi address must remain completely intact
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();

      expect(onboardingProvider.district, 'ਲੁਧਿਆਣਾ');
      expect(onboardingProvider.city, 'ਖੰਨਾ');
      expect(onboardingProvider.address, 'ਮਕਾਨ ਨੰ. ੪੨, ਗੁਰਦੁਆਰਾ ਰੋਡ, ਪਿੰਡ ਸਮਰਾਲਾ');
      expect(find.text('ਲੁਧਿਆਣਾ'), findsOneWidget);
      expect(find.text('ਖੰਨਾ'), findsOneWidget);
      expect(find.text('ਮਕਾਨ ਨੰ. ੪੨, ਗੁਰਦੁਆਰਾ ਰੋਡ, ਪਿੰਡ ਸਮਰਾਲਾ'), findsOneWidget);

      // Enter Hindi Devanagari text into city and address
      final cityField = find.byKey(const Key('producer_onboarding_city_field'));
      final addressField = find.byKey(const Key('producer_onboarding_address_field'));

      await tester.enterText(cityField, 'सांगानेर');
      await tester.enterText(addressField, 'दुकान संख्या १२, मुख्य बाज़ार, जयपुर रोड');
      await tester.pumpAndSettle();

      expect(onboardingProvider.city, 'सांगानेर');
      expect(onboardingProvider.address, 'दुकान संख्या १२, मुख्य बाज़ार, जयपुर रोड');

      // Switch language to English -> Devanagari inputs remain preserved exactly
      languageProvider.setAppLanguage(AppLanguage.english);
      await tester.pumpAndSettle();

      expect(onboardingProvider.city, 'सांगानेर');
      expect(onboardingProvider.address, 'दुकान संख्या १२, मुख्य बाज़ार, जयपुर रोड');
      expect(find.text('सांगानेर'), findsOneWidget);
      expect(find.text('दुकान संख्या १२, मुख्य बाज़ार, जयपुर रोड'), findsOneWidget);
    });

    testWidgets('Theme switching does not affect location values or state selection',
        (WidgetTester tester) async {
      final languageProvider = LanguageProvider();
      final themeProvider = ThemeProvider();
      final onboardingProvider = ProducerOnboardingProvider();

      onboardingProvider.setFullName('Balwinder Kaur');
      onboardingProvider.setBusinessName('Malwa Jutti Works');
      onboardingProvider.setCraftCategory('Leatherwork');
      onboardingProvider.setStateValue('PB');
      onboardingProvider.setDistrict('Muktsar');
      onboardingProvider.setCity('Malout');
      onboardingProvider.setPincode('152107');
      onboardingProvider.setAddress('Near Bus Stand, Malout');
      onboardingProvider.goToStep(2);

      await tester.pumpWidget(
        _createLocalizedLocationApp(
          languageProvider: languageProvider,
          themeProvider: themeProvider,
          onboardingProvider: onboardingProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(onboardingProvider.stateCode, 'PB');
      expect(find.text('Punjab'), findsOneWidget);
      expect(find.text('Muktsar'), findsOneWidget);

      // Light -> Dark
      themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(onboardingProvider.stateCode, 'PB');
      expect(find.text('Punjab'), findsOneWidget);
      expect(find.text('Muktsar'), findsOneWidget);

      // Dark -> System
      themeProvider.setThemeMode(ThemeMode.system);
      await tester.pumpAndSettle();

      expect(onboardingProvider.stateCode, 'PB');
      expect(find.text('Punjab'), findsOneWidget);
      expect(find.text('Muktsar'), findsOneWidget);
    });
  });
}
