import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/localization/language_provider.dart';
import 'package:buyer_section/core/services/preferences_service.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/core/theme/theme_provider.dart';
import 'package:buyer_section/producer_section/home/models/producer_shell_profile.dart';
import 'package:buyer_section/producer_section/home/producer_main_screen.dart';
import 'package:buyer_section/producer_section/home/tabs/producer_home_tab.dart';
import 'package:buyer_section/producer_section/opportunities/buyer_needs_tab.dart';
import 'package:buyer_section/producer_section/products/screens/add_product_screen.dart';
import 'package:buyer_section/producer_section/products/producer_products_tab.dart';
import 'package:buyer_section/producer_section/profile/producer_profile_tab.dart';

Widget createTestApp({
  required Widget child,
  Size screenSize = const Size(390, 844),
  LanguageProvider? languageProvider,
  ThemeProvider? themeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(
        create: (_) => languageProvider ?? LanguageProvider(),
      ),
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => themeProvider ?? ThemeProvider(),
      ),
    ],
    child: Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, langProv, thProv, _) {
        return MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            textScaler: TextScaler.noScaling,
          ),
          child: MaterialApp(
            locale: langProv.currentLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: thProv.themeMode,
            home: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: child,
            ),
          ),
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

  const testProfile = ProducerShellProfile(
    fullName: 'Ramesh Kumar',
    email: 'ramesh@example.com',
    businessName: 'Kumar Handloom Crafts',
    craftCategory: 'Handicrafts',
  );

  group('Producer App Shell Responsive Layout Tests (Step 6A & 6A.2)', () {
    testWidgets('Phone width (< 640px) renders Material 3 NavigationBar and no rail/sidebar',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const ProducerMainScreen(initialProfile: testProfile),
          screenSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // NavigationBar must be present
      expect(find.byType(NavigationBar), findsOneWidget);
      // NavigationRail must NOT be present
      expect(find.byType(NavigationRail), findsNothing);
      // Exactly 4 navigation destinations
      expect(find.byType(NavigationDestination), findsNWidgets(4));

      expect(find.text('Home'), findsWidgets);
      expect(find.text('My Products'), findsWidgets);
      expect(find.text('Buyer Needs'), findsWidgets);
      expect(find.text('My Profile'), findsWidgets);
    });

    testWidgets('Tablet width (640px - 1024px) renders NavigationRail with visible Add Product label',
        (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const ProducerMainScreen(initialProfile: testProfile),
          screenSize: const Size(768, 1024),
        ),
      );
      await tester.pumpAndSettle();

      // NavigationRail must be present with exactly 4 destinations
      final railFinder = find.byType(NavigationRail);
      expect(railFinder, findsOneWidget);
      final rail = tester.widget<NavigationRail>(railFinder);
      expect(rail.destinations.length, 4);

      // Bottom NavigationBar must NOT be present
      expect(find.byType(NavigationBar), findsNothing);

      // Tablet rail includes visible Add Product action label
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Add Product'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Desktop width (> 1024px) renders expanded left sidebar with Add Product button',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const ProducerMainScreen(initialProfile: testProfile),
          screenSize: const Size(1280, 900),
        ),
      );
      await tester.pumpAndSettle();

      // Neither NavigationBar nor NavigationRail should exist on desktop
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);

      // Desktop sidebar header and Add Product action button must be present
      expect(find.text('VyaparSetu'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add Product'), findsOneWidget);

      // 4 destinations are available in the sidebar
      expect(find.text('Home'), findsWidgets);
      expect(find.text('My Products'), findsWidgets);
      expect(find.text('Buyer Needs'), findsWidgets);
      expect(find.text('My Profile'), findsWidgets);
    });
  });

  group('Single-Fetch Profile Architecture & Non-Duplication Tests (Step 6A.2)', () {
    testWidgets('Profile is loaded once at shell level and shared with Home and Profile tabs',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int fetchCount = 0;
      Future<ProducerShellProfile?> testLoader() async {
        fetchCount++;
        return testProfile;
      }

      await tester.pumpWidget(
        createTestApp(
          child: ProducerMainScreen(profileLoader: testLoader),
          screenSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Loaded once at startup
      expect(fetchCount, 1);

      // 2. Home displays loaded producer identity
      expect(find.text('Welcome, Ramesh Kumar'), findsOneWidget);
      expect(find.text('Kumar Handloom Crafts'), findsOneWidget);
      expect(find.text('Handicrafts'), findsOneWidget);

      // 3. Switch to My Profile tab
      await tester.tap(find.text('My Profile').first);
      await tester.pumpAndSettle();

      // 4. Profile tab displays the same loaded data without refetching
      expect(fetchCount, 1);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Kumar Handloom Crafts'), findsOneWidget);
      expect(find.text('ramesh@example.com'), findsOneWidget);

      // 5. Switch back to Home -> no refetch
      await tester.tap(find.text('Home').first);
      await tester.pumpAndSettle();
      expect(fetchCount, 1);
    });

    testWidgets('Locale and Theme changes do NOT trigger duplicate profile fetches',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int fetchCount = 0;
      Future<ProducerShellProfile?> testLoader() async {
        fetchCount++;
        return testProfile;
      }

      final langProv = LanguageProvider();
      final themeProv = ThemeProvider();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerMainScreen(profileLoader: testLoader),
          screenSize: const Size(390, 844),
          languageProvider: langProv,
          themeProvider: themeProv,
        ),
      );
      await tester.pumpAndSettle();

      expect(fetchCount, 1);

      // Switch language to Hindi -> no refetch
      langProv.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(fetchCount, 1);
      expect(find.text('नमस्ते, Ramesh Kumar'), findsOneWidget);

      // Switch theme to Dark -> no refetch
      themeProv.setThemeOption(AppThemeOption.dark);
      await tester.pumpAndSettle();
      expect(fetchCount, 1);

      // Switch language to Punjabi -> no refetch
      langProv.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();
      expect(fetchCount, 1);
      expect(find.text('ਜੀ ਆਇਆਂ ਨੂੰ, Ramesh Kumar'), findsOneWidget);
    });

    testWidgets('Profile load failure uses safe localized fallback UI without raw backend errors',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Future<ProducerShellProfile?> failingLoader() async {
        throw Exception('FATAL_POSTGRES_CONNECTION_REFUSED_LEAK_TEST');
      }

      await tester.pumpWidget(
        createTestApp(
          child: ProducerMainScreen(profileLoader: failingLoader),
          screenSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // Uses safe localized default name fallback
      expect(find.text('Welcome, Producer'), findsOneWidget);

      // Raw backend error text must NEVER be shown to user
      expect(find.textContaining('FATAL_POSTGRES_CONNECTION_REFUSED'), findsNothing);
      expect(find.textContaining('Exception:'), findsNothing);
    });
  });

  group('Navigation State & Tab Switching Tests', () {
    testWidgets('Tapping destinations updates active tab and preserves IndexedStack children',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const ProducerMainScreen(initialProfile: testProfile),
          screenSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);
      final indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.children.length, 4);
      expect(indexedStack.index, 0);

      // Switch to My Products tab
      await tester.tap(find.text('My Products').first);
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(indexedStackFinder).index, 1);
      expect(find.byType(ProducerProductsTab), findsOneWidget);

      // Switch to Buyer Needs tab
      await tester.tap(find.text('Buyer Needs').first);
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(indexedStackFinder).index, 2);
      expect(find.byType(BuyerNeedsTab), findsOneWidget);

      // Switch to My Profile tab
      await tester.tap(find.text('My Profile').first);
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(indexedStackFinder).index, 3);
      expect(find.byType(ProducerProfileTab), findsOneWidget);
    });
  });

  group('Producer Home Visual Hierarchy & Shortcuts Tests', () {
    testWidgets('Renders truthful Home information with updated Buyer Needs wording',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: ProducerHomeTab(
            profile: testProfile,
            onAddProduct: () {},
            onNavigateToTab: (_) {},
            onOpenWhatBuyersWant: () {},
          ),
          screenSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // Identity Area
      expect(find.text('Welcome, Ramesh Kumar'), findsOneWidget);
      expect(find.text('Kumar Handloom Crafts'), findsOneWidget);
      expect(find.text('Handicrafts'), findsOneWidget);

      // Dominant Add Product Action
      expect(find.text('Add Product'), findsWidgets);
      expect(find.text('Show buyers what you make'), findsOneWidget);

      // Shortcuts
      expect(find.text('See the products you have added'), findsOneWidget);
      expect(find.text('See what buyers are looking for'), findsOneWidget);
      expect(find.text('What Buyers Want'), findsOneWidget);
      expect(find.text('See what products people want'), findsOneWidget);

      // Truthful empty status cards with corrected non-matching wording
      expect(find.text('No products added yet'), findsOneWidget);
      expect(find.text('Buyer needs will appear here'), findsOneWidget);
      expect(find.text('Buyer requests will be listed here when available'), findsOneWidget);
    });

    testWidgets('Home shortcuts invoke appropriate callbacks', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool addProductCalled = false;
      int? navigatedTab;
      bool whatBuyersWantCalled = false;

      await tester.pumpWidget(
        createTestApp(
          child: ProducerHomeTab(
            profile: testProfile,
            onAddProduct: () => addProductCalled = true,
            onNavigateToTab: (tab) => navigatedTab = tab,
            onOpenWhatBuyersWant: () => whatBuyersWantCalled = true,
          ),
          screenSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // Tap dominant Add Product card via subtitle
      await tester.tap(find.text('Show buyers what you make'));
      await tester.pumpAndSettle();
      expect(addProductCalled, isTrue);

      // Tap My Products shortcut
      await tester.tap(find.text('See the products you have added'));
      await tester.pumpAndSettle();
      expect(navigatedTab, 1);

      // Tap Buyer Needs shortcut
      await tester.tap(find.text('See what buyers are looking for'));
      await tester.pumpAndSettle();
      expect(navigatedTab, 2);

      // Tap What Buyers Want shortcut
      await tester.tap(find.text('What Buyers Want'));
      await tester.pumpAndSettle();
      expect(whatBuyersWantCalled, isTrue);
    });

    testWidgets('Tapping Add Product in shell opens AddProductScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const ProducerMainScreen(initialProfile: testProfile),
          screenSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show buyers what you make'));
      await tester.pumpAndSettle();

      expect(find.byType(AddProductScreen), findsOneWidget);
    });
  });

  group('Localization Across English, Hindi, and Punjabi', () {
    testWidgets('Hindi (Devanagari) displays correct Home labels', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final langProv = LanguageProvider();
      langProv.setAppLanguage(AppLanguage.hindi);

      await tester.pumpWidget(
        createTestApp(
          child: const ProducerMainScreen(initialProfile: testProfile),
          screenSize: const Size(390, 844),
          languageProvider: langProv,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('होम'), findsWidgets);
      expect(find.text('मेरे उत्पाद'), findsWidgets);
      expect(find.text('खरीदारों की जरूरतें'), findsWidgets);
      expect(find.text('मेरी प्रोफाइल'), findsWidgets);
      expect(find.text('उत्पाद जोड़ें'), findsWidgets);
      expect(find.text('खरीदारों को दिखाएं कि आप क्या बनाते हैं'), findsOneWidget);
    });

    testWidgets('Punjabi (Gurmukhi) displays correct Home labels', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final langProv = LanguageProvider();
      langProv.setAppLanguage(AppLanguage.punjabi);

      await tester.pumpWidget(
        createTestApp(
          child: const ProducerMainScreen(initialProfile: testProfile),
          screenSize: const Size(390, 844),
          languageProvider: langProv,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ਹੋਮ'), findsWidgets);
      expect(find.text('ਮੇਰੇ ਉਤਪਾਦ'), findsWidgets);
      expect(find.text('ਖਰੀਦਦਾਰਾਂ ਦੀਆਂ ਲੋੜਾਂ'), findsWidgets);
      expect(find.text('ਮੇਰੀ ਪ੍ਰੋਫਾਈਲ'), findsWidgets);
      expect(find.text('ਉਤਪਾਦ ਸ਼ਾਮਲ ਕਰੋ'), findsWidgets);
      expect(find.text('ਖਰੀਦਦਾਰਾਂ ਨੂੰ ਦਿਖਾਓ ਕਿ ਤੁਸੀਂ ਕੀ ਬਣਾਉਂਦੇ ਹੋ'), findsOneWidget);
    });
  });

  group('Appearance & Responsiveness Boundary Tests', () {
    testWidgets('320px narrow mobile viewport renders without RenderFlex overflow in all languages',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      for (final lang in [AppLanguage.english, AppLanguage.hindi, AppLanguage.punjabi]) {
        final langProv = LanguageProvider();
        langProv.setAppLanguage(lang);

        await tester.pumpWidget(
          createTestApp(
            child: const ProducerMainScreen(initialProfile: testProfile),
            screenSize: const Size(320, 568),
            languageProvider: langProv,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Theme and language switches preserve active tab index', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final langProv = LanguageProvider();
      final themeProv = ThemeProvider();

      await tester.pumpWidget(
        createTestApp(
          child: const ProducerMainScreen(initialProfile: testProfile),
          screenSize: const Size(390, 844),
          languageProvider: langProv,
          themeProvider: themeProv,
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Buyer Needs tab (index 2)
      await tester.tap(find.text('Buyer Needs').first);
      await tester.pumpAndSettle();

      final stackFinder = find.byType(IndexedStack);
      expect(tester.widget<IndexedStack>(stackFinder).index, 2);

      // Switch to Dark mode
      themeProv.setThemeOption(AppThemeOption.dark);
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(stackFinder).index, 2);

      // Switch to Hindi
      langProv.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(stackFinder).index, 2);
    });

    testWidgets('Step 6A.3 Responsive resolutions (320x700, 390x844, 768x1024, 1200x800, 1440x900) render cleanly',
        (tester) async {
      const resolutions = [
        Size(320, 700),
        Size(390, 844),
        Size(768, 1024),
        Size(1200, 800),
        Size(1440, 900),
      ];

      for (final res in resolutions) {
        tester.view.physicalSize = res;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          createTestApp(
            child: const ProducerMainScreen(initialProfile: testProfile),
            screenSize: res,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at resolution $res');
        expect(find.text('Add Product'), findsWidgets, reason: 'Add Product missing at $res');
      }

      tester.view.resetPhysicalSize();
    });

    testWidgets('Step 6A.3 Increased text scale factor (1.3x) renders without exception',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(1.3),
              ),
              child: const ProducerMainScreen(initialProfile: testProfile),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Add Product'), findsWidgets);
    });
  });
}
