import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/localization/language_provider.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/core/theme/theme_provider.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_provider.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_screen.dart';

Widget _createLocalizedOnboardingApp({
  required LanguageProvider languageProvider,
  required ThemeProvider themeProvider,
  ProducerOnboardingProvider? onboardingProvider,
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
  group('Producer Onboarding V2 Localization Tests (Pass 3A)', () {
    testWidgets('Step 0 and Step 1 names and subtitles resolve correctly in en, hi, and pa',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final languageProvider = LanguageProvider();
      final themeProvider = ThemeProvider();
      final onboardingProvider = ProducerOnboardingProvider();

      await tester.pumpWidget(
        _createLocalizedOnboardingApp(
          languageProvider: languageProvider,
          themeProvider: themeProvider,
          onboardingProvider: onboardingProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: English
      expect(find.text('Your Business'), findsWidgets);
      expect(
        find.text('Tell us a little about what you make and where your business is based.'),
        findsOneWidget,
      );

      // Switch to Hindi
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(find.text('आपका व्यवसाय'), findsWidgets);
      expect(
        find.text('हमें थोड़ा बताएं कि आप क्या बनाते हैं और आपका व्यवसाय कहाँ स्थित है।'),
        findsOneWidget,
      );

      // Switch to Punjabi
      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(find.text('ਤੁਹਾਡਾ ਕਾਰੋਬਾਰ'), findsWidgets);
      expect(
        find.text('ਸਾਨੂੰ ਥੋੜ੍ਹਾ ਦੱਸੋ ਕਿ ਤੁਸੀਂ ਕੀ ਬਣਾਉਂਦੇ ਹੋ ਅਤੇ ਤੁਹਾਡਾ ਕਾਰੋਬਾਰ ਕਿੱਥੇ ਸਥਿਤ ਹੈ।'),
        findsOneWidget,
      );

      // Advance to Step 1 (About Your Business)
      onboardingProvider.goToStep(1);
      await tester.pumpAndSettle();

      // Step 1 in Punjabi
      expect(find.text('ਤੁਹਾਡੇ ਕਾਰੋਬਾਰ ਬਾਰੇ'), findsWidgets);
      expect(
        find.text('ਆਪਣੇ ਕਾਰੋਬਾਰ ਨੂੰ ਬਿਹਤਰ ਤਰੀਕੇ ਨਾਲ ਸਮਝਣ ਵਿੱਚ ਸਾਡੀ ਮਦਦ ਕਰੋ। ਤੁਸੀਂ ਇਸ ਪੜਾਅ ਨੂੰ ਛੱਡ ਸਕਦੇ ਹੋ।'),
        findsWidgets,
      );

      // Step 1 in Hindi
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(find.text('आपके व्यवसाय के बारे में'), findsWidgets);
      expect(
        find.text('अपने व्यवसाय को बेहतर ढंग से समझने में हमारी सहायता करें। आप इस चरण को छोड़ सकते हैं।'),
        findsWidgets,
      );

      // Step 1 in English
      languageProvider.setAppLanguage(AppLanguage.english);
      await tester.pumpAndSettle();
      expect(find.text('About Your Business'), findsWidgets);
      expect(
        find.text('Help us understand your business better. You can skip this step.'),
        findsWidgets,
      );
    });

    testWidgets('Step 0 visible labels change live when switching language',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final languageProvider = LanguageProvider();
      final themeProvider = ThemeProvider();
      final onboardingProvider = ProducerOnboardingProvider();

      await tester.pumpWidget(
        _createLocalizedOnboardingApp(
          languageProvider: languageProvider,
          themeProvider: themeProvider,
          onboardingProvider: onboardingProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: English labels
      expect(find.text('Producer Setup'), findsOneWidget);
      expect(find.text('Business / Brand Name'), findsOneWidget);
      expect(find.text('State / Union Territory *'), findsOneWidget);
      expect(find.text('District *'), findsOneWidget);
      expect(find.text('Area / Village / City *'), findsOneWidget);
      expect(find.text('Pincode *'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Switch to Hindi live
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();

      expect(find.text('उत्पादक पंजीकरण'), findsOneWidget);
      expect(find.text('व्यवसाय / ब्रांड का नाम'), findsOneWidget);
      expect(find.text('राज्य / केंद्र शासित प्रदेश *'), findsOneWidget);
      expect(find.text('जिला *'), findsOneWidget);
      expect(find.text('क्षेत्र / गाँव / शहर *'), findsOneWidget);
      expect(find.text('पिन कोड *'), findsOneWidget);
      expect(find.text('आगे बढ़ें'), findsOneWidget);

      // Switch to Punjabi live
      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();

      expect(find.text('ਉਤਪਾਦਕ ਰਜਿਸਟ੍ਰੇਸ਼ਨ'), findsOneWidget);
      expect(find.text('ਕਾਰੋਬਾਰ / ਬ੍ਰਾਂਡ ਦਾ ਨਾਮ'), findsOneWidget);
      expect(find.text('ਰਾਜ / ਕੇਂਦਰ ਸ਼ਾਸਿਤ ਪ੍ਰਦੇਸ਼ *'), findsOneWidget);
      expect(find.text('ਜ਼ਿਲ੍ਹਾ *'), findsOneWidget);
      expect(find.text('ਖੇਤਰ / ਪਿੰਡ / ਸ਼ਹਿਰ *'), findsOneWidget);
      expect(find.text('ਪਿੰਨ ਕੋਡ *'), findsOneWidget);
      expect(find.text('ਅੱਗੇ ਵਧੋ'), findsOneWidget);
    });

    testWidgets('Current step and entered form data remain intact across language switches',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final languageProvider = LanguageProvider();
      final themeProvider = ThemeProvider();
      final onboardingProvider = ProducerOnboardingProvider();

      await tester.pumpWidget(
        _createLocalizedOnboardingApp(
          languageProvider: languageProvider,
          themeProvider: themeProvider,
          onboardingProvider: onboardingProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Enter data in Step 0
      final businessField = find.byKey(const Key('producer_onboarding_business_name_field'));
      await tester.enterText(businessField, 'Singh Pottery Works');

      final cityField = find.byKey(const Key('producer_onboarding_city_field'));
      await tester.enterText(cityField, 'Khanna');

      final districtField = find.byKey(const Key('producer_onboarding_district_field'));
      await tester.enterText(districtField, 'Ludhiana');

      final pincodeField = find.byKey(const Key('producer_onboarding_pincode_field'));
      await tester.enterText(pincodeField, '141401');

      await tester.tap(find.byKey(const Key('category_card_handicrafts')));
      await tester.pumpAndSettle();

      expect(onboardingProvider.businessName, 'Singh Pottery Works');
      expect(onboardingProvider.craftCategory, 'handicrafts');
      expect(onboardingProvider.city, 'Khanna');
      expect(onboardingProvider.district, 'Ludhiana');
      expect(onboardingProvider.pincode, '141401');
      expect(onboardingProvider.currentStep, 0);

      // Switch EN -> HI -> PA -> EN
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 0);
      expect(find.text('Singh Pottery Works'), findsOneWidget);
      expect(find.text('Khanna'), findsOneWidget);
      expect(find.text('Ludhiana'), findsOneWidget);
      expect(find.text('141401'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 0);
      expect(find.text('Singh Pottery Works'), findsOneWidget);
      expect(find.text('Khanna'), findsOneWidget);
      expect(find.text('Ludhiana'), findsOneWidget);
      expect(find.text('141401'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.english);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 0);
      expect(find.text('Singh Pottery Works'), findsOneWidget);
      expect(find.text('Khanna'), findsOneWidget);
      expect(find.text('Ludhiana'), findsOneWidget);
      expect(find.text('141401'), findsOneWidget);
    });

    testWidgets('Entered form data and current step remain intact across theme switches',
        (WidgetTester tester) async {
      final languageProvider = LanguageProvider();
      final themeProvider = ThemeProvider();
      final onboardingProvider = ProducerOnboardingProvider();

      await tester.pumpWidget(
        _createLocalizedOnboardingApp(
          languageProvider: languageProvider,
          themeProvider: themeProvider,
          onboardingProvider: onboardingProvider,
        ),
      );
      await tester.pumpAndSettle();

      onboardingProvider.setBusinessName('Mithila Kala');
      onboardingProvider.setCraftCategory('handicrafts');
      await tester.pumpAndSettle();

      expect(onboardingProvider.currentStep, 0);
      expect(find.text('Mithila Kala'), findsOneWidget);

      // Toggle Light -> Dark -> System
      themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 0);
      expect(find.text('Mithila Kala'), findsOneWidget);

      themeProvider.setThemeMode(ThemeMode.system);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 0);
      expect(find.text('Mithila Kala'), findsOneWidget);

      themeProvider.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 0);
      expect(find.text('Mithila Kala'), findsOneWidget);
    });

    testWidgets('Responsive progress header layout renders without overflow at 320px width in all languages',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final languageProvider = LanguageProvider();
      final themeProvider = ThemeProvider();
      final onboardingProvider = ProducerOnboardingProvider();

      await tester.pumpWidget(
        _createLocalizedOnboardingApp(
          languageProvider: languageProvider,
          themeProvider: themeProvider,
          onboardingProvider: onboardingProvider,
        ),
      );
      await tester.pumpAndSettle();

      // English at 320px
      expect(tester.takeException(), isNull);
      expect(find.text('Your Business'), findsWidgets);

      // Hindi at 320px
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('आपका व्यवसाय'), findsWidgets);

      // Punjabi at 320px
      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ਤੁਹਾਡਾ ਕਾਰੋਬਾਰ'), findsWidgets);
    });
  });
}
