import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buyer_section/core/auth/role_selection_screen.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/localization/language_provider.dart';
import 'package:buyer_section/core/routes/app_router.dart';
import 'package:buyer_section/core/services/preferences_service.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/core/theme/theme_provider.dart';
import 'package:buyer_section/producer_section/auth/producer_login_screen.dart';
import 'package:buyer_section/producer_section/auth/producer_signup_screen.dart';

Widget _createTestHarness({
  required Widget child,
  required LanguageProvider languageProvider,
  required ThemeProvider themeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    ],
    child: Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, theme, lang, _) {
        return MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme.themeMode,
          locale: lang.currentLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: child,
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.instance.resetForTesting();
  });

  group('RoleSelectionScreen Localization & Navigation', () {
    testWidgets('RoleSelectionScreen renders in English, Hindi, and Punjabi', (WidgetTester tester) async {
      final langProvider = LanguageProvider();
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        _createTestHarness(
          child: const RoleSelectionScreen(),
          languageProvider: langProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pumpAndSettle();

      // English
      expect(find.text('VyaparSetu'), findsOneWidget);
      expect(find.text('I Want to Buy Products'), findsOneWidget);
      expect(find.text('I Make & Sell Products'), findsOneWidget);
      expect(find.text('Choose how you want to continue:'), findsOneWidget);

      // Switch to Hindi
      langProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();

      expect(find.text('व्यापार सेतु'), findsOneWidget);
      expect(find.text('मुझे उत्पाद खरीदने हैं'), findsOneWidget);
      expect(find.text('मैं सामान बनाता और बेचता हूँ'), findsOneWidget);
      expect(find.text('चुनें कि आप ऐप का उपयोग कैसे करना चाहते हैं:'), findsOneWidget);

      // Switch to Punjabi
      langProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();

      expect(find.text('ਵਪਾਰ ਸੇਤੂ'), findsOneWidget);
      expect(find.text('ਮੈਂ ਉਤਪਾਦ ਖਰੀਦਣਾ ਚਾਹੁੰਦਾ ਹਾਂ'), findsOneWidget);
      expect(find.text('ਮੈਂ ਸਾਮਾਨ ਬਣਾਉਂਦਾ ਅਤੇ ਵੇਚਦਾ ਹਾਂ'), findsOneWidget);
      expect(find.text('ਚੁਣੋ ਕਿ ਤੁਸੀਂ ਐਪ ਦੀ ਵਰਤੋਂ ਕਿਵੇਂ ਕਰਨਾ ਚਾਹੁੰਦੇ ਹੋ:'), findsOneWidget);
    });

    testWidgets('RoleSelectionScreen navigates to Producer Login when Producer card tapped', (WidgetTester tester) async {
      final langProvider = LanguageProvider();
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LanguageProvider>.value(value: langProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ],
          child: Consumer2<ThemeProvider, LanguageProvider>(
            builder: (context, theme, lang, _) {
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: theme.themeMode,
                locale: lang.currentLocale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                initialRoute: AppRouter.initialRoute,
                onGenerateRoute: AppRouter.generateRoute,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('I Make & Sell Products'), findsOneWidget);

      await tester.tap(find.text('I Make & Sell Products'));
      await tester.pumpAndSettle();

      expect(find.byType(ProducerLoginScreen), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
    });
  });

  group('ProducerLoginScreen Localization & Form State Preservation', () {
    testWidgets('ProducerLoginScreen renders and localizes fields and validation', (WidgetTester tester) async {
      final langProvider = LanguageProvider();
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        _createTestHarness(
          child: const ProducerLoginScreen(),
          languageProvider: langProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign in with Phone OTP'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // Trigger empty validation
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Switch to Hindi
      langProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();

      expect(find.text('लॉग इन करें'), findsWidgets);
      expect(find.text('ईमेल पता'), findsOneWidget);
      expect(find.text('पासवर्ड'), findsOneWidget);
      expect(find.text('पासवर्ड भूल गए?'), findsOneWidget);
      expect(find.text('फोन ओटीपी से लॉग इन करें'), findsOneWidget);
      expect(find.text('खाता बनाएं'), findsOneWidget);

      // Switch to Punjabi
      langProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();

      expect(find.text('ਲੌਗ ਇਨ ਕਰੋ'), findsWidgets);
      expect(find.text('ਈਮੇਲ ਪਤਾ'), findsOneWidget);
      expect(find.text('ਪਾਸਵਰਡ'), findsOneWidget);
      expect(find.text('ਪਾਸਵਰਡ ਭੁੱਲ ਗਏ?'), findsOneWidget);
      expect(find.text('ਫ਼ੋਨ ਓਟੀਪੀ ਨਾਲ ਲੌਗ ਇਨ ਕਰੋ'), findsOneWidget);
      expect(find.text('ਖਾਤਾ ਬਣਾਓ'), findsOneWidget);
    });

    testWidgets('Step 8A/8B: ProducerLoginScreen preserves entered text across live language & appearance switches', (WidgetTester tester) async {
      final langProvider = LanguageProvider();
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        _createTestHarness(
          child: const ProducerLoginScreen(),
          languageProvider: langProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Enter user text
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.first, 'ramesh@example.com');
      await tester.enterText(textFields.last, 'secret123');
      await tester.pump();

      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('secret123'), findsOneWidget);

      // 1. Live Language Switch: English -> Hindi
      langProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();

      // Check labels changed to Hindi
      expect(find.text('ईमेल पता'), findsOneWidget);
      expect(find.text('पासवर्ड'), findsOneWidget);
      // Verify entered text was preserved
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('secret123'), findsOneWidget);

      // 2. Live Language Switch: Hindi -> Punjabi
      langProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();

      expect(find.text('ਈਮੇਲ ਪਤਾ'), findsOneWidget);
      expect(find.text('ਪਾਸਵਰਡ'), findsOneWidget);
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('secret123'), findsOneWidget);

      // 3. Live Appearance Switch: Light -> Dark
      themeProvider.setThemeOption(AppThemeOption.dark);
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('secret123'), findsOneWidget);

      // 4. Repeated switches back to English and Light
      langProvider.setAppLanguage(AppLanguage.english);
      themeProvider.setThemeOption(AppThemeOption.light);
      await tester.pumpAndSettle();

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('secret123'), findsOneWidget);
    });
  });

  group('ProducerSignupScreen Localization & Form State Preservation', () {
    testWidgets('ProducerSignupScreen renders, validates, and preserves state across live switches', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final langProvider = LanguageProvider();
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        _createTestHarness(
          child: const ProducerSignupScreen(),
          languageProvider: langProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Sign up with Phone OTP'), findsOneWidget);

      // Trigger empty validation
      final submitButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please create a password'), findsOneWidget);

      // Enter user text
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(4));

      await tester.enterText(textFields.at(0), 'Ramesh Kumar');
      await tester.enterText(textFields.at(1), 'ramesh@example.com');
      await tester.enterText(textFields.at(2), 'mypassword');
      await tester.enterText(textFields.at(3), 'mypassword');
      await tester.pump();

      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('mypassword'), findsNWidgets(2));

      // Live switch to Hindi
      langProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();

      expect(find.text('पूरा नाम'), findsOneWidget);
      expect(find.text('ईमेल पता'), findsOneWidget);
      expect(find.text('खाता बनाएं'), findsWidgets);
      // Values preserved
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('mypassword'), findsNWidgets(2));

      // Live switch to Dark theme
      themeProvider.setThemeOption(AppThemeOption.dark);
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('mypassword'), findsNWidgets(2));

      // Live switch to Punjabi
      langProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();

      expect(find.text('ਪੂਰਾ ਨਾਮ'), findsOneWidget);
      expect(find.text('ਈਮੇਲ ਪਤਾ'), findsOneWidget);
      expect(find.text('ਖਾਤਾ ਬਣਾਓ'), findsWidgets);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('mypassword'), findsNWidgets(2));
    });
  });
}
