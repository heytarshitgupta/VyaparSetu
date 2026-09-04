import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buyer_section/core/auth/role_selection_screen.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/localization/language_provider.dart';
import 'package:buyer_section/core/services/preferences_service.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/core/theme/theme_provider.dart';
import 'package:buyer_section/core/widgets/app_top_bar_controls.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.instance.resetForTesting();
  });

  group('Appearance & ThemeProvider Unit Tests', () {
    test('Default appearance option is system', () {
      final themeProvider = ThemeProvider();
      expect(themeProvider.themeOption, AppThemeOption.system);
      expect(themeProvider.themeMode, ThemeMode.system);
    });

    test('Setting light and dark options updates themeMode accordingly', () {
      final themeProvider = ThemeProvider();

      themeProvider.setThemeOption(AppThemeOption.light);
      expect(themeProvider.themeOption, AppThemeOption.light);
      expect(themeProvider.themeMode, ThemeMode.light);

      themeProvider.setThemeOption(AppThemeOption.dark);
      expect(themeProvider.themeOption, AppThemeOption.dark);
      expect(themeProvider.themeMode, ThemeMode.dark);

      themeProvider.setThemeOption(AppThemeOption.system);
      expect(themeProvider.themeOption, AppThemeOption.system);
      expect(themeProvider.themeMode, ThemeMode.system);
    });

    test('Appearance and Language are strictly decoupled and independent', () {
      final themeProvider = ThemeProvider();
      final languageProvider = LanguageProvider();

      themeProvider.setThemeOption(AppThemeOption.dark);
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(languageProvider.appLanguage, AppLanguage.english);
      expect(languageProvider.voiceLanguage, VoiceLanguage.hindi);

      languageProvider.setAppLanguage(AppLanguage.punjabi);
      expect(languageProvider.appLanguage, AppLanguage.punjabi);
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(languageProvider.voiceLanguage, VoiceLanguage.hindi);
    });

    test('Corrupt or unsupported theme preference safely falls back to system', () {
      expect(AppThemeOption.fromString(null), AppThemeOption.system);
      expect(AppThemeOption.fromString('corrupted_value'), AppThemeOption.system);
      expect(AppThemeOption.fromString('unknown'), AppThemeOption.system);
      expect(AppThemeOption.fromString('light'), AppThemeOption.light);
      expect(AppThemeOption.fromString('dark'), AppThemeOption.dark);
      expect(AppThemeOption.fromString('system'), AppThemeOption.system);
    });
  });

  group('Preferences Persistence Tests', () {
    test('Theme preference persists across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesService.instance;

      await prefs.saveThemeMode('dark');
      final savedMode = await prefs.getSavedThemeMode();
      expect(savedMode, 'dark');

      final newThemeProvider = ThemeProvider();
      // Wait microtask for async load
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(newThemeProvider.themeOption, AppThemeOption.dark);
      expect(newThemeProvider.themeMode, ThemeMode.dark);
    });

    test('Language preference persists across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesService.instance;

      await prefs.saveLanguageCode('hi');
      final savedLang = await prefs.getSavedLanguageCode();
      expect(savedLang, 'hi');

      final newLangProvider = LanguageProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(newLangProvider.appLanguage, AppLanguage.hindi);
      expect(newLangProvider.currentLocale, const Locale('hi'));
    });

    test('Corrupt saved language safely falls back to English', () async {
      SharedPreferences.setMockInitialValues({'app_language_code': 'invalid_lang_code'});

      final newLangProvider = LanguageProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(newLangProvider.appLanguage, AppLanguage.english);
      expect(newLangProvider.currentLocale, const Locale('en'));
    });
  });

  group('AppTopBarControls Pre-login Widget Tests', () {
    testWidgets('Reusable pre-login control renders without authentication and switches theme', (WidgetTester tester) async {
      final themeProvider = ThemeProvider();
      final languageProvider = LanguageProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
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
                home: const Scaffold(
                  body: Center(
                    child: AppTopBarControls(),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify controls exist without authentication
      final langButton = find.byKey(const Key('app_top_bar_language_button'));
      final themeButton = find.byKey(const Key('app_top_bar_theme_button'));
      expect(langButton, findsOneWidget);
      expect(themeButton, findsOneWidget);

      // Open theme sheet
      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      // Options displayed with low-literacy wording
      expect(find.text('Choose appearance'), findsOneWidget);
      expect(find.byKey(const Key('app_top_bar_theme_light')), findsOneWidget);
      expect(find.byKey(const Key('app_top_bar_theme_dark')), findsOneWidget);
      expect(find.byKey(const Key('app_top_bar_theme_system')), findsOneWidget);

      // Select Dark mode
      await tester.tap(find.byKey(const Key('app_top_bar_theme_dark')));
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, ThemeMode.dark);

      // Open language sheet
      await tester.tap(langButton);
      await tester.pumpAndSettle();

      // Select Hindi
      await tester.tap(find.byKey(const Key('app_top_bar_lang_hi')));
      await tester.pumpAndSettle();

      expect(languageProvider.appLanguage, AppLanguage.hindi);
      expect(languageProvider.currentLocale, const Locale('hi'));
    });

    testWidgets('RoleSelectionScreen contains AppTopBarControls before login', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: const MaterialApp(
            home: RoleSelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppTopBarControls), findsOneWidget);
      expect(find.byKey(const Key('app_top_bar_language_button')), findsOneWidget);
      expect(find.byKey(const Key('app_top_bar_theme_button')), findsOneWidget);
    });
  });
}
