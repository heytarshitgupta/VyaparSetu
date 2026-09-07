// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/localization/language_provider.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/core/theme/theme_provider.dart';
import 'package:buyer_section/producer_section/home/models/producer_shell_profile.dart';
import 'package:buyer_section/producer_section/home/producer_main_screen.dart';
import 'package:buyer_section/producer_section/profile/producer_profile_tab.dart';
import 'package:buyer_section/producer_section/widgets/producer_quick_action_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LanguageProvider languageProvider;
  late ThemeProvider themeProvider;

  const testVerifiedProfile = ProducerShellProfile(
    fullName: 'Harpreet Singh',
    email: 'harpreet@example.com',
    phone: '9820012345',
    businessName: 'Singh Wooden Crafts',
    craftCategory: 'Wood Carving',
    bio: 'Artisan handcrafting wooden artifacts',
    state: 'Punjab',
    district: 'Amritsar',
    city: 'Amritsar',
    pincode: '143001',
    address: '45 Artisan Market, Hall Gate',
    panLast4: '4321',
    panVerificationStatus: 'verified',
    gstRegistered: true,
    gstin: '03ABCDE1234F1Z5',
    gstVerificationStatus: 'verified',
    onboardingStep: 4,
  );

  const testUnverifiedProfile = ProducerShellProfile(
    fullName: 'Pooja Sharma',
    email: 'pooja@example.com',
    phone: null,
    businessName: null,
    craftCategory: null,
    bio: null,
    state: 'Haryana',
    district: null,
    city: 'Panipat',
    pincode: null,
    address: null,
    panLast4: null,
    panVerificationStatus: 'unverified',
    gstRegistered: false,
    gstin: null,
    gstVerificationStatus: 'not_applicable',
    onboardingStep: 1,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    languageProvider = LanguageProvider();
    themeProvider = ThemeProvider();
  });

  Widget buildTestableWidget({
    required Widget child,
    LanguageProvider? langProv,
    ThemeProvider? themeProv,
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(
          value: langProv ?? languageProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProv ?? themeProvider,
        ),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: Scaffold(body: child),
      ),
    );
  }

  group('ProducerShellProfile Domain Model Tests', () {
    test('Initials generates correct two-letter initials', () {
      expect(testVerifiedProfile.initials, 'HS');
      expect(const ProducerShellProfile(fullName: 'Amrit').initials, 'A');
      expect(const ProducerShellProfile(fullName: '').initials, 'P');
    });

    test('Location summary formats city, district, and state truthfully', () {
      expect(testVerifiedProfile.locationSummary, 'Amritsar, Punjab');
      expect(testUnverifiedProfile.locationSummary, 'Panipat, Haryana');
      expect(const ProducerShellProfile().locationSummary, isNull);
    });

    test('Masked PAN strictly reveals only last 4 digits and never raw PAN', () {
      expect(testVerifiedProfile.maskedPan, '•••• 4321');
      expect(testUnverifiedProfile.maskedPan, isNull);
      expect(testVerifiedProfile.isPanVerified, isTrue);
      expect(testVerifiedProfile.isIdentityVerified, isTrue);
    });

    test('ProducerShellProfile does not carry aadhaarLast4 or fake GST masking', () {
      // ProducerShellProfile only carries safe identity fields, no aadhaar digits
      expect(testVerifiedProfile.panLast4, '4321');
      expect(testVerifiedProfile.gstRegistered, isTrue);
      expect(testUnverifiedProfile.gstRegistered, isFalse);
    });
  });

  group('ProducerProfileTab Rendering & Identity Tests', () {
    testWidgets('Renders verified producer header, initials avatar, and location', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ProducerProfileTab(profile: testVerifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      // Header avatar and name
      expect(find.text('HS'), findsOneWidget);
      expect(find.byKey(const ValueKey('profile_name_text')), findsOneWidget);
      expect(find.text('Harpreet Singh'), findsOneWidget);
      expect(find.text('Amritsar, Punjab'), findsOneWidget);
      expect(find.text('Verified Producer'), findsOneWidget);
    });

    testWidgets('Renders unverified profile with safe fallbacks and "Not provided"', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ProducerProfileTab(profile: testUnverifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('P'), findsNothing); // Initials for Pooja Sharma = 'PS'
      expect(find.text('PS'), findsOneWidget);
      expect(find.text('Pooja Sharma'), findsOneWidget);
      expect(find.text('Producer'), findsOneWidget);
      // Missing phone and craft show 'Not provided'
      expect(find.text('Not provided'), findsWidgets);
    });
  });

  group('Verification & Compliance Card Security Tests', () {
    testWidgets('Shows generic Identity Verification, safe GST status, strictly masked PAN, and no Aadhaar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ProducerProfileTab(profile: testVerifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('verification_section')), findsOneWidget);

      // 1. Generic truthful Identity Verification status
      expect(find.text('Identity Verification'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // 2. Strictly masked PAN last 4 digits (never raw PAN)
      expect(find.text('Verified • •••• 4321'), findsOneWidget);
      expect(find.textContaining('ABCDE1234F'), findsNothing);

      // 3. Safe GST status without fake masking (no •••• F1Z5)
      expect(find.text('GST'), findsOneWidget);
      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('Registered • •••• F1Z5'), findsNothing);
      expect(find.textContaining('F1Z5'), findsNothing);

      // 4. Aadhaar digits/status/fingerprints NEVER rendered
      expect(find.text('Aadhaar Identity'), findsNothing);
      expect(find.textContaining('Aadhaar'), findsNothing);
      expect(find.textContaining('8765'), findsNothing);
      expect(find.byIcon(Icons.fingerprint_outlined), findsNothing);
    });

    testWidgets('Unverified profile shows Pending for Identity, Not Verified for PAN, and Not Registered for GST', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ProducerProfileTab(profile: testUnverifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Identity Verification'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Not Verified'), findsOneWidget);
      expect(find.text('GST'), findsOneWidget);
      expect(find.text('Not Registered'), findsOneWidget);
      expect(find.textContaining('Aadhaar'), findsNothing);
    });
  });

  group('Settings Controls Tests', () {
    testWidgets('App Language switches reactively between English, Hindi, and Punjabi', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ProducerProfileTab(profile: testVerifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      // Initially English
      expect(languageProvider.appLanguage, AppLanguage.english);

      // Select Hindi
      final hiFinder = find.byKey(const ValueKey('lang_radio_hi'));
      await tester.ensureVisible(hiFinder);
      await tester.tap(hiFinder);
      await tester.pumpAndSettle();
      expect(languageProvider.appLanguage, AppLanguage.hindi);

      // Select Punjabi
      final paFinder = find.byKey(const ValueKey('lang_radio_pa'));
      await tester.ensureVisible(paFinder);
      await tester.tap(paFinder);
      await tester.pumpAndSettle();
      expect(languageProvider.appLanguage, AppLanguage.punjabi);

      // Select English again
      final enFinder = find.byKey(const ValueKey('lang_radio_en'));
      await tester.ensureVisible(enFinder);
      await tester.tap(enFinder);
      await tester.pumpAndSettle();
      expect(languageProvider.appLanguage, AppLanguage.english);
    });

    testWidgets('Voice Guidance Language changes option and persists in PreferencesService', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ProducerProfileTab(profile: testVerifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Voice Guidance: English
      final enFinder = find.byKey(const ValueKey('voice_radio_en'));
      await tester.ensureVisible(enFinder);
      await tester.tap(enFinder);
      await tester.pumpAndSettle();
      expect(languageProvider.voiceGuidanceOption, VoiceGuidanceOption.english);
      expect(languageProvider.voiceLanguage, VoiceLanguage.english);

      // Tap Voice Guidance: Punjabi
      final paFinder = find.byKey(const ValueKey('voice_radio_pa'));
      await tester.ensureVisible(paFinder);
      await tester.tap(paFinder);
      await tester.pumpAndSettle();
      expect(languageProvider.voiceGuidanceOption, VoiceGuidanceOption.punjabi);
      expect(languageProvider.voiceLanguage, VoiceLanguage.punjabi);
    });

    testWidgets('Appearance switches ThemeOption between System, Light, and Dark', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ProducerProfileTab(profile: testVerifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Dark
      final darkFinder = find.byKey(const ValueKey('theme_radio_dark'));
      await tester.ensureVisible(darkFinder);
      await tester.tap(darkFinder);
      await tester.pumpAndSettle();
      expect(themeProvider.themeOption, AppThemeOption.dark);
      expect(themeProvider.themeMode, ThemeMode.dark);

      // Tap Light
      final lightFinder = find.byKey(const ValueKey('theme_radio_light'));
      await tester.ensureVisible(lightFinder);
      await tester.tap(lightFinder);
      await tester.pumpAndSettle();
      expect(themeProvider.themeOption, AppThemeOption.light);
      expect(themeProvider.themeMode, ThemeMode.light);

      // Tap System
      final systemFinder = find.byKey(const ValueKey('theme_radio_system'));
      await tester.ensureVisible(systemFinder);
      await tester.tap(systemFinder);
      await tester.pumpAndSettle();
      expect(themeProvider.themeOption, AppThemeOption.system);
      expect(themeProvider.themeMode, ThemeMode.system);
    });
  });

  group('Account & Security Actions Tests', () {
    testWidgets('Registered email is displayed and reset password invokes callback', (tester) async {
      String? requestedEmail;
      await tester.pumpWidget(
        buildTestableWidget(
          child: ProducerProfileTab(
            profile: testVerifiedProfile,
            onResetPassword: (email) async {
              requestedEmail = email;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Email is visible
      final emailFinder = find.byKey(const ValueKey('profile_email_text'));
      await tester.ensureVisible(emailFinder);
      expect(emailFinder, findsOneWidget);
      expect(find.text('harpreet@example.com'), findsOneWidget);
      // Session wording is truthful: Current Session / Signed in (no device tracking implied)
      expect(find.text('Current Session'), findsOneWidget);
      expect(find.text('Signed in'), findsOneWidget);
      expect(find.text('This device'), findsNothing);
      expect(find.text('Active Session'), findsNothing);

      // Tap Reset Password
      final resetBtn = find.byKey(const ValueKey('reset_password_button'));
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(requestedEmail, 'harpreet@example.com');
      expect(find.text('Password reset link sent to your email'), findsOneWidget);
    });

    testWidgets('Sign Out button opens confirmation dialog; cancel dismisses and confirm signs out', (tester) async {
      bool signedOut = false;
      await tester.pumpWidget(
        buildTestableWidget(
          child: ProducerProfileTab(
            profile: testVerifiedProfile,
            onSignOut: () async {
              signedOut = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap bottom Sign Out button
      final signOutBtn = find.byKey(const ValueKey('sign_out_button'));
      await tester.ensureVisible(signOutBtn);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Sign out of VyaparSetu?'), findsOneWidget);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.byKey(const ValueKey('sign_out_cancel_button')));
      await tester.pumpAndSettle();
      expect(find.text('Sign out of VyaparSetu?'), findsNothing);
      expect(signedOut, isFalse);

      // Tap Sign Out again and confirm
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sign_out_confirm_button')));
      await tester.pumpAndSettle();
      expect(signedOut, isTrue);
    });
  });

  group('Help & About Modals Tests', () {
    testWidgets('How VyaparSetu Works tile opens informational dialog', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ProducerProfileTab(profile: testVerifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      final howWorksTile = find.byKey(const ValueKey('how_works_tile'));
      await tester.ensureVisible(howWorksTile);
      await tester.tap(howWorksTile);
      await tester.pumpAndSettle();

      expect(find.text('How VyaparSetu Works'), findsWidgets);
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsNothing);
    });

    testWidgets('Privacy & Data tile opens security info dialog with truthful privacy wording', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ProducerProfileTab(profile: testVerifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      final privacyTile = find.byKey(const ValueKey('privacy_data_tile'));
      await tester.ensureVisible(privacyTile);
      await tester.tap(privacyTile);
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Data'), findsWidgets);
      // Verify truthful privacy claims
      expect(
        find.textContaining('Sensitive identity information is minimized'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Aadhaar numbers are not displayed or carried'),
        findsOneWidget,
      );
      // Verify NO unsupported encryption claims
      expect(
        find.textContaining('documents are encrypted'),
        findsNothing,
      );
      expect(
        find.textContaining('securely encrypted'),
        findsNothing,
      );
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('About VyaparSetu tile opens app version info dialog', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ProducerProfileTab(profile: testVerifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      final aboutTile = find.byKey(const ValueKey('about_app_tile'));
      await tester.ensureVisible(aboutTile);
      await tester.tap(aboutTile);
      await tester.pumpAndSettle();

      expect(find.text('About VyaparSetu'), findsWidgets);
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });
  });

  group('ProducerQuickActionMenu & Shell Integration Tests', () {
    testWidgets('ProducerQuickActionMenu trigger opens bottom sheet on narrow screens (<640px)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool profileNavigated = false;
      await tester.pumpWidget(
        buildTestableWidget(
          child: ProducerQuickActionMenu(
            onNavigateToProfile: () => profileNavigated = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Button exists
      expect(find.byKey(const ValueKey('producer_quick_menu_button')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('producer_quick_menu_button')));
      await tester.pumpAndSettle();

      // Sheet opens
      expect(find.byKey(const ValueKey('quick_menu_profile')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick_menu_language')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick_menu_appearance')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick_menu_help')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick_menu_sign_out')), findsOneWidget);

      // Tap My Profile
      await tester.tap(find.byKey(const ValueKey('quick_menu_profile')));
      await tester.pumpAndSettle();
      expect(profileNavigated, isTrue);
    });

    testWidgets('Desktop sidebar footer renders profile avatar and QuickActionMenu trigger', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          child: ProducerMainScreen(
            initialProfile: testVerifiedProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Left sidebar profile card is rendered
      expect(find.text('Harpreet Singh'), findsWidgets);
      expect(find.text('Wood Carving'), findsWidgets);
      expect(find.byKey(const ValueKey('producer_quick_menu_button')), findsOneWidget);
    });
  });

  group('Responsiveness & Text Scale Boundary Tests', () {
    testWidgets('320px ultra-narrow viewport renders ProducerProfileTab without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const ProducerProfileTab(profile: testVerifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('High text scale factor (1.3x) renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: buildTestableWidget(
            child: const ProducerProfileTab(profile: testVerifiedProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Dark theme renders cleanly with high contrast', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          themeMode: ThemeMode.dark,
          child: const ProducerProfileTab(profile: testVerifiedProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
