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
  group('Producer Onboarding 5-Step Localization Tests (Step 5B.2)', () {
    testWidgets('All 5 step names and subtitles resolve correctly in en, hi, and pa',
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

      // Step 1: English
      expect(find.text('About You'), findsOneWidget);
      expect(find.text('Your name and contact info'), findsOneWidget);

      // Switch to Hindi
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(find.text('आपके बारे में'), findsOneWidget);
      expect(find.text('आपका नाम और संपर्क विवरण'), findsOneWidget);

      // Switch to Punjabi
      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(find.text('ਤੁਹਾਡੇ ਬਾਰੇ'), findsOneWidget);
      expect(find.text('ਤੁਹਾਡਾ ਨਾਮ ਅਤੇ ਸੰਪਰਕ ਵੇਰਵੇ'), findsOneWidget);

      // Step 2 in Punjabi -> Hindi -> English
      onboardingProvider.setFullName('Gurpreet Singh');
      onboardingProvider.nextStep();
      await tester.pumpAndSettle();
      expect(find.text('ਤੁਹਾਡਾ ਕੰਮ'), findsOneWidget);
      expect(find.text('ਤੁਸੀਂ ਕੀ ਬਣਾਉਂਦੇ ਅਤੇ ਵੇਚਦੇ ਹੋ'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(find.text('आपका काम'), findsOneWidget);
      expect(find.text('आप क्या बनाते और बेचते हैं'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.english);
      await tester.pumpAndSettle();
      expect(find.text('Your Work'), findsOneWidget);
      expect(find.text('What you make and sell'), findsOneWidget);

      // Step 3
      onboardingProvider.setBusinessName('Punjab Crafts');
      onboardingProvider.setCraftCategory('Handicrafts');
      onboardingProvider.nextStep();
      await tester.pumpAndSettle();
      expect(find.text('Your Address'), findsOneWidget);
      expect(find.text('Where your workshop is based'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(find.text('काम का पता'), findsOneWidget);
      expect(find.text('आपकी कार्यशाला या दुकान का पता'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(find.text('ਕੰਮ ਦਾ ਪਤਾ'), findsOneWidget);
      expect(find.text('ਤੁਹਾਡੀ ਵਰਕਸ਼ਾਪ ਜਾਂ ਦੁਕਾਨ ਦਾ ਪਤਾ'), findsOneWidget);

      // Step 4
      onboardingProvider.setStateValue('Punjab');
      onboardingProvider.setDistrict('Amritsar');
      onboardingProvider.setCity('Amritsar');
      onboardingProvider.setPincode('143001');
      onboardingProvider.setAddress('Golden Temple Road');
      onboardingProvider.nextStep();
      await tester.pumpAndSettle();
      expect(find.text('ਤਸਦੀਕ'), findsOneWidget);
      expect(find.text('ਪਛਾਣ ਅਤੇ ਕੰਮ ਦੇ ਵੇਰਵੇ'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(find.text('सत्यापन'), findsOneWidget);
      expect(find.text('पहचान और कार्य विवरण'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.english);
      await tester.pumpAndSettle();
      expect(find.text('Verification'), findsOneWidget);
      expect(find.text('Identity and business details'), findsOneWidget);

      // Step 5
      onboardingProvider.nextStep();
      await tester.pumpAndSettle();
      expect(find.text('Check & Submit'), findsOneWidget);
      expect(find.text('Confirm and start selling'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(find.text('जांचें और जमा करें'), findsOneWidget);
      expect(find.text('पुष्टि करें और बेचना शुरू करें'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(find.text('ਜਾਂਚੋ ਅਤੇ ਜਮ੍ਹਾਂ ਕਰੋ'), findsOneWidget);
      expect(find.text('ਪੁਸ਼ਟੀ ਕਰੋ ਅਤੇ ਵੇਚਣਾ ਸ਼ੁਰੂ ਕਰੋ'), findsOneWidget);
    });

    testWidgets('Step 1, 2, 3, 4, 5 visible labels change live when switching language',
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

      // Step 1: English labels
      expect(find.text('Producer Setup'), findsOneWidget);
      expect(find.text('Artisan Basic Details'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email Address (Login)'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Switch to Hindi live
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();

      expect(find.text('उत्पादक पंजीकरण'), findsOneWidget);
      expect(find.text('कारीगर का मूल विवरण'), findsOneWidget);
      expect(find.text('पूरा नाम *'), findsOneWidget);
      expect(find.text('ईमेल पता (लॉग इन)'), findsOneWidget);
      expect(find.text('आगे बढ़ें'), findsOneWidget);

      // Switch to Punjabi live
      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();

      expect(find.text('ਉਤਪਾਦਕ ਰਜਿਸਟ੍ਰੇਸ਼ਨ'), findsOneWidget);
      expect(find.text('ਕਾਰੀਗਰ ਦਾ ਮੂਲ ਵੇਰਵਾ'), findsOneWidget);
      expect(find.text('ਪੂਰਾ ਨਾਮ *'), findsOneWidget);
      expect(find.text('ਈਮੇਲ ਪਤਾ (ਲੌਗ ਇਨ)'), findsOneWidget);
      expect(find.text('ਅੱਗੇ ਵਧੋ'), findsOneWidget);

      // Move to Step 4 (Verification) to test PAN, Aadhaar, and GST localization
      onboardingProvider.setFullName('Test Producer');
      onboardingProvider.setBusinessName('Test Enterprise');
      onboardingProvider.setCraftCategory('Woodwork');
      onboardingProvider.setStateValue('Punjab');
      onboardingProvider.setDistrict('Ludhiana');
      onboardingProvider.setCity('Ludhiana');
      onboardingProvider.setPincode('141001');
      onboardingProvider.setAddress('Artisan Cluster');
      onboardingProvider.goToStep(3);
      await tester.pumpAndSettle();

      // Currently Punjabi on Step 4
      expect(find.text('ਪਛਾਣ ਅਤੇ ਤਸਦੀਕ'), findsOneWidget);
      expect(find.text('ਪੈਨ ਤਸਦੀਕ'), findsOneWidget);
      expect(find.text('ਆਧਾਰ ਤਸਦੀਕ'), findsWidgets);
      expect(find.text('ਜੀਐਸਟੀ ਰਜਿਸਟ੍ਰੇਸ਼ਨ'), findsOneWidget);
      expect(find.text('ਕੀ ਤੁਸੀਂ ਜੀਐਸਟੀ ਲਈ ਰਜਿਸਟਰਡ ਹੋ? *'), findsOneWidget);
      expect(find.text('ਹਾਂ'), findsOneWidget);
      expect(find.text('ਨਹੀਂ'), findsOneWidget);
      expect(find.text('ਪਿੱਛੇ ਜਾਓ'), findsOneWidget);

      // Switch Step 4 to Hindi live
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();

      expect(find.text('पहचान और सत्यापन'), findsOneWidget);
      expect(find.text('पैन सत्यापन'), findsOneWidget);
      expect(find.text('आधार सत्यापन'), findsWidgets);
      expect(find.text('जीएसटी पंजीकरण'), findsOneWidget);
      expect(find.text('क्या आप जीएसटी के लिए पंजीकृत हैं? *'), findsOneWidget);
      expect(find.text('हाँ'), findsOneWidget);
      expect(find.text('नहीं'), findsOneWidget);
      expect(find.text('पीछे जाएं'), findsOneWidget);

      // Switch Step 4 to English live
      languageProvider.setAppLanguage(AppLanguage.english);
      await tester.pumpAndSettle();

      expect(find.text('Identity & Compliance'), findsOneWidget);
      expect(find.text('PAN Verification'), findsOneWidget);
      expect(find.text('Aadhaar Verification'), findsWidgets);
      expect(find.text('GST Registration'), findsOneWidget);
      expect(find.text('Are you registered for GST? *'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Move to Step 5 (Review & Submit)
      onboardingProvider.goToStep(4);
      await tester.pumpAndSettle();

      expect(find.text('Review & Submit Onboarding'), findsOneWidget);
      expect(find.text('Profile Status'), findsOneWidget);
      expect(find.text('Ready for Submission'), findsOneWidget);
      expect(find.text('Submit Application'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(find.text('समीक्षा और सबमिट करें'), findsOneWidget);
      expect(find.text('प्रोफाइल स्थिति'), findsOneWidget);
      expect(find.text('जमा करने के लिए तैयार'), findsOneWidget);
      expect(find.text('आवेदन जमा करें'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(find.text('ਸਮੀਖਿਆ ਅਤੇ ਸਬਮਿਟ ਕਰੋ'), findsOneWidget);
      expect(find.text('ਪ੍ਰੋਫਾਈਲ ਸਥਿਤੀ'), findsOneWidget);
      expect(find.text('ਜਮ੍ਹਾਂ ਕਰਨ ਲਈ ਤਿਆਰ'), findsOneWidget);
      expect(find.text('ਅਰਜ਼ੀ ਜਮ੍ਹਾਂ ਕਰੋ'), findsOneWidget);
    });

    testWidgets('Current step and entered form data remain intact across language switches',
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

      // Enter data in Step 1
      final nameField = find.byKey(const Key('producer_onboarding_name_field'));
      await tester.enterText(nameField, 'Harpreet Singh');
      await tester.pumpAndSettle();

      expect(onboardingProvider.fullName, 'Harpreet Singh');
      expect(onboardingProvider.currentStep, 0);

      // Switch EN -> HI -> PA -> EN
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 0);
      expect(onboardingProvider.fullName, 'Harpreet Singh');
      expect(find.text('Harpreet Singh'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 0);
      expect(onboardingProvider.fullName, 'Harpreet Singh');
      expect(find.text('Harpreet Singh'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.english);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 0);
      expect(onboardingProvider.fullName, 'Harpreet Singh');
      expect(find.text('Harpreet Singh'), findsOneWidget);

      // Navigate to Step 2 and enter data
      onboardingProvider.nextStep();
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 1);

      final businessField = find.byKey(const Key('producer_onboarding_business_name_field'));
      await tester.enterText(businessField, 'Singh Pottery Works');
      await tester.pumpAndSettle();

      // Switch languages while on Step 2
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 1);
      expect(find.text('Singh Pottery Works'), findsOneWidget);

      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 1);
      expect(find.text('Singh Pottery Works'), findsOneWidget);

      // Navigate to Step 3 and enter location
      onboardingProvider.setCraftCategory('Handicrafts');
      onboardingProvider.nextStep();
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 2);

      final cityField = find.byKey(const Key('producer_onboarding_city_field'));
      await tester.enterText(cityField, 'Khanna');
      await tester.pumpAndSettle();

      languageProvider.setAppLanguage(AppLanguage.english);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 2);
      expect(find.text('Khanna'), findsOneWidget);
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

      // Move to step 2 with data
      onboardingProvider.setFullName('Anita Devi');
      onboardingProvider.setBusinessName('Mithila Kala');
      onboardingProvider.setCraftCategory('Handicrafts');
      onboardingProvider.goToStep(1);
      await tester.pumpAndSettle();

      expect(onboardingProvider.currentStep, 1);
      expect(find.text('Mithila Kala'), findsOneWidget);

      // Toggle Light -> Dark -> System
      themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 1);
      expect(find.text('Mithila Kala'), findsOneWidget);

      themeProvider.setThemeMode(ThemeMode.system);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 1);
      expect(find.text('Mithila Kala'), findsOneWidget);

      themeProvider.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(onboardingProvider.currentStep, 1);
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
      expect(find.text('Step 1 of 5'), findsOneWidget);

      // Hindi at 320px
      languageProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('कदम 1 / 5'), findsOneWidget);

      // Punjabi at 320px
      languageProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ਕਦਮ 1 / 5'), findsOneWidget);
    });
  });
}
