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
import 'package:buyer_section/producer_section/profile/producer_profile_tab.dart';
import 'package:buyer_section/producer_section/verification/models/business_verification_status.dart';
import 'package:buyer_section/producer_section/verification/producer_verification_service.dart';
import 'package:buyer_section/producer_section/verification/screens/business_verification_overview_screen.dart';
import 'package:buyer_section/producer_section/verification/services/business_verification_session.dart';

Widget buildTestApp({
  required Widget child,
  Size screenSize = const Size(390, 844),
  LanguageProvider? languageProvider,
  ThemeProvider? themeProvider,
}) {
  final langProv = languageProvider ?? LanguageProvider();
  final thProv = themeProvider ?? ThemeProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>.value(value: langProv),
      ChangeNotifierProvider<ThemeProvider>.value(value: thProv),
    ],
    child: Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, lang, th, _) {
        return MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            textScaler: TextScaler.noScaling,
          ),
          child: MaterialApp(
            locale: lang.currentLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: th.themeMode,
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
    BusinessVerificationSession.instance.reset();
  });

  const unverifiedProfile = ProducerShellProfile(
    fullName: 'Sunita Devi',
    email: 'sunita@example.com',
    businessName: 'Devi Pottery',
    craftCategory: 'Pottery',
    panVerificationStatus: 'unverified',
    gstRegistered: false,
    gstVerificationStatus: 'not_applicable',
  );

  const panVerifiedNonGstProfile = ProducerShellProfile(
    fullName: 'Sunita Devi',
    email: 'sunita@example.com',
    businessName: 'Devi Pottery',
    craftCategory: 'Pottery',
    panVerificationStatus: 'verified',
    panLast4: '5678',
    gstRegistered: false,
    gstVerificationStatus: 'not_applicable',
  );

  const gstRegisteredUnverifiedProfile = ProducerShellProfile(
    fullName: 'Sunita Devi',
    email: 'sunita@example.com',
    businessName: 'Devi Pottery',
    craftCategory: 'Pottery',
    panVerificationStatus: 'verified',
    panLast4: '5678',
    gstRegistered: true,
    gstin: '07AAAAA0000A1Z5',
    gstVerificationStatus: 'unverified',
  );

  const fullyVerifiedGstProfile = ProducerShellProfile(
    fullName: 'Sunita Devi',
    email: 'sunita@example.com',
    businessName: 'Devi Pottery',
    craftCategory: 'Pottery',
    panVerificationStatus: 'verified',
    panLast4: '5678',
    gstRegistered: true,
    gstin: '07AAAAA0000A1Z5',
    gstVerificationStatus: 'verified',
  );

  group('Status Semantics & Model Unit Tests', () {
    test('1. Email unverified + PAN unverified -> incomplete and banner shown', () {
      final status = BusinessVerificationStatus.fromProfile(
        profile: unverifiedProfile,
        overrideEmailVerified: false,
      );
      expect(status.isEmailVerified, isFalse);
      expect(status.isPanVerified, isFalse);
      expect(status.isCoreComplete, isFalse);
      expect(status.shouldShowHomeBanner, isTrue);
      expect(status.totalApplicableSteps, 2);
      expect(status.completedStepsCount, 0);
      expect(status.remainingStepsCount, 2);
    });

    test('2. Email verified + PAN unverified -> incomplete and banner shown', () {
      final status = BusinessVerificationStatus.fromProfile(
        profile: unverifiedProfile,
        overrideEmailVerified: true,
      );
      expect(status.isEmailVerified, isTrue);
      expect(status.isPanVerified, isFalse);
      expect(status.isCoreComplete, isFalse);
      expect(status.shouldShowHomeBanner, isTrue);
      expect(status.totalApplicableSteps, 2);
      expect(status.completedStepsCount, 1);
      expect(status.remainingStepsCount, 1);
    });

    test('3 & 4. Email verified + PAN verified + GST not registered -> complete and banner hidden', () {
      final status = BusinessVerificationStatus.fromProfile(
        profile: panVerifiedNonGstProfile,
        overrideEmailVerified: true,
      );
      expect(status.isEmailVerified, isTrue);
      expect(status.isPanVerified, isTrue);
      expect(status.isCoreComplete, isTrue);
      expect(status.gstRegistered, isFalse);
      expect(status.isOverallComplete, isTrue);
      // Critical check: Non-GST producer is NOT marked permanently incomplete!
      expect(status.shouldShowHomeBanner, isFalse);
      expect(status.totalApplicableSteps, 2);
      expect(status.completedStepsCount, 2);
      expect(status.remainingStepsCount, 0);
    });

    test('5. GST registered + unverified -> incomplete state and banner shown', () {
      final status = BusinessVerificationStatus.fromProfile(
        profile: gstRegisteredUnverifiedProfile,
        overrideEmailVerified: true,
      );
      expect(status.isEmailVerified, isTrue);
      expect(status.isPanVerified, isTrue);
      expect(status.isCoreComplete, isTrue);
      expect(status.gstRegistered, isTrue);
      expect(status.isGstVerified, isFalse);
      expect(status.isOverallComplete, isFalse);
      expect(status.shouldShowHomeBanner, isTrue);
      expect(status.totalApplicableSteps, 3);
      expect(status.completedStepsCount, 2);
      expect(status.remainingStepsCount, 1);
      expect(status.gstStatus, GstComponentStatus.pending);
    });

    test('6. GST registered + verified -> all 3 complete and banner hidden', () {
      final status = BusinessVerificationStatus.fromProfile(
        profile: fullyVerifiedGstProfile,
        overrideEmailVerified: true,
      );
      expect(status.isEmailVerified, isTrue);
      expect(status.isPanVerified, isTrue);
      expect(status.isGstVerified, isTrue);
      expect(status.isOverallComplete, isTrue);
      expect(status.shouldShowHomeBanner, isFalse);
      expect(status.totalApplicableSteps, 3);
      expect(status.completedStepsCount, 3);
      expect(status.remainingStepsCount, 0);
      expect(status.gstStatus, GstComponentStatus.verified);
    });
  });

  group('Session-Only Home Banner Tests', () {
    testWidgets('7. Incomplete verification shows banner on ProducerHomeTab', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: ProducerHomeTab(
            profile: unverifiedProfile,
            onAddProduct: () {},
            onNavigateToTab: (_) {},
            onOpenWhatBuyersWant: () {},
            overrideEmailVerified: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('business_verification_banner')), findsOneWidget);
      expect(find.text('Reach more buyers across India'), findsOneWidget);
      expect(find.text('Verify your business to build trust and unlock eligible wider-market features.'), findsOneWidget);
      expect(find.byKey(const ValueKey('verify_my_business_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_banner_close')), findsOneWidget);

      // Verify layout ordering: Identity card -> Verification banner -> Add Product card
      final identityTop = tester.getTopLeft(find.text('Welcome, Sunita Devi')).dy;
      final bannerTop = tester.getTopLeft(find.byKey(const ValueKey('business_verification_banner'))).dy;
      final addProductTop = tester.getTopLeft(find.text('Add Product')).dy;
      expect(identityTop < bannerTop, isTrue, reason: 'Identity card must appear above verification banner');
      expect(bannerTop < addProductTop, isTrue, reason: 'Verification banner must appear above Add Product card');
    });

    testWidgets('8. Core verified non-GST producer hides banner on ProducerHomeTab', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: ProducerHomeTab(
            profile: panVerifiedNonGstProfile,
            onAddProduct: () {},
            onNavigateToTab: (_) {},
            onOpenWhatBuyersWant: () {},
            overrideEmailVerified: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('business_verification_banner')), findsNothing);
    });

    testWidgets('9. Tapping X dismisses banner for session and reset restores it', (tester) async {
      bool bannerDismissed = false;

      await tester.pumpWidget(
        buildTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return ProducerHomeTab(
                profile: unverifiedProfile,
                onAddProduct: () {},
                onNavigateToTab: (_) {},
                onOpenWhatBuyersWant: () {},
                overrideEmailVerified: false,
                isBannerDismissed: BusinessVerificationSession.instance.isHomeBannerDismissed,
                onDismissVerificationBanner: () {
                  setState(() {
                    BusinessVerificationSession.instance.dismissHomeBanner();
                    bannerDismissed = true;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('business_verification_banner')), findsOneWidget);

      // Tap close 'X'
      await tester.tap(find.byKey(const ValueKey('verification_banner_close')));
      await tester.pumpAndSettle();

      expect(bannerDismissed, isTrue);
      expect(BusinessVerificationSession.instance.isHomeBannerDismissed, isTrue);
      expect(find.byKey(const ValueKey('business_verification_banner')), findsNothing);

      // Resetting session restores banner
      BusinessVerificationSession.instance.reset();
      expect(BusinessVerificationSession.instance.isHomeBannerDismissed, isFalse);
    });
  });

  group('My Profile Entry Point & Permanent Access Tests', () {
    testWidgets('10. My Profile contains permanent Business Verification entry point', (tester) async {
      bool navCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProfileTab(
            profile: panVerifiedNonGstProfile,
            onNavigateToVerification: () => navCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final entryFinder = find.byKey(const ValueKey('business_verification_entry'));
      expect(entryFinder, findsOneWidget);
      expect(find.text('Business Verification'), findsOneWidget);
      expect(find.text('Verify your business details and build buyer trust.'), findsOneWidget);

      await tester.ensureVisible(entryFinder);
      await tester.pumpAndSettle();
      await tester.tap(entryFinder);
      await tester.pumpAndSettle();
      expect(navCalled, isTrue);
    });
  });

  group('Business Verification Overview Screen Tests', () {
    testWidgets('11. Overview screen renders all 3 component cards and progress summary', (tester) async {
      final status = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: false,
        gstRegistered: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Progress Summary: Non-GST producer has 2 applicable steps. 1 of 2 completed -> 1 step remaining
      expect(find.text('1 step remaining'), findsOneWidget);
      expect(find.text('1 of 2 completed'), findsOneWidget);

      // Email Card
      expect(find.byKey(const ValueKey('verification_card_email')), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('sunita@example.com'), findsOneWidget);
      expect(find.text('Verified'), findsWidgets);

      // PAN Card
      expect(find.byKey(const ValueKey('verification_card_pan')), findsOneWidget);
      expect(find.text('Business Identity'), findsOneWidget);
      expect(find.text('Not provided'), findsWidgets);
      expect(find.byKey(const ValueKey('verify_pan_button')), findsOneWidget);

      // GST Card
      expect(find.byKey(const ValueKey('verification_card_gst')), findsOneWidget);
      expect(find.text('GST Registration'), findsOneWidget);
      expect(find.text('Optional • Not provided'), findsOneWidget);
      expect(find.byKey(const ValueKey('verify_gst_button')), findsOneWidget);

      // Truthful copy assertions: no legal tax-threshold claims, no authoritative claims
      expect(find.textContaining('40 Lakh'), findsNothing);
      expect(find.textContaining('turnover'), findsNothing);
      expect(find.textContaining('Government verified'), findsNothing);

      // Zero Aadhaar UI
      expect(find.textContaining('Aadhaar'), findsNothing);
    });

    testWidgets('12. PAN verified card displays masked PAN', (tester) async {
      final status = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: true,
        panLast4: '5678',
        gstRegistered: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Business details recorded'), findsOneWidget);
      expect(find.text('2 of 2 completed'), findsOneWidget);
      expect(find.textContaining('•••• 5678'), findsOneWidget);
      expect(find.byKey(const ValueKey('verify_pan_button')), findsNothing);
      expect(find.text('Details Added'), findsWidgets);
    });

    testWidgets('13. PAN verification: validates format, calls RPC, masks last4, does not fabricate name/DOB, and updates UI', (tester) async {
      String? calledRpc;
      Map<String, dynamic>? calledParams;

      final testService = ProducerVerificationService(
        rpcHandler: (fnName, params) async {
          calledRpc = fnName;
          calledParams = params;
          return {
            'success': true,
            'status': 'verified',
            'message': 'PAN details recorded successfully.',
            'pan_last4': '1234',
            'masked_pan': '••••••••34',
          };
        },
      );

      final status = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: false,
        gstRegistered: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
            verificationService: testService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Verify PAN
      final panBtnFinder = find.byKey(const ValueKey('verify_pan_button'));
      await tester.ensureVisible(panBtnFinder);
      await tester.tap(panBtnFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('pan_verification_sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('pan_input_field')), findsOneWidget);

      // Malformed PAN blocked client-side
      await tester.enterText(find.byKey(const ValueKey('pan_input_field')), 'ABC');
      await tester.tap(find.byKey(const ValueKey('submit_pan_verification_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Please enter a valid 10-character PAN'), findsOneWidget);
      expect(calledRpc, isNull);

      // Enter valid PAN
      await tester.enterText(find.byKey(const ValueKey('pan_input_field')), 'abcde1234f');
      await tester.tap(find.byKey(const ValueKey('submit_pan_verification_button')));
      await tester.pumpAndSettle();

      expect(calledRpc, equals('verify_producer_pan_prototype'));
      expect(calledParams!['p_pan'], equals('ABCDE1234F'));
      // Verify NO fabricated identity data was passed
      expect(calledParams!.containsKey('p_name'), isFalse);
      expect(calledParams!.containsKey('p_dob'), isFalse);
      expect(calledParams!.length, equals(1));

      // Sheet is closed
      expect(find.byKey(const ValueKey('pan_verification_sheet')), findsNothing);

      // UI is updated immediately with truthful semantics
      expect(find.textContaining('•••• 1234'), findsOneWidget);
      expect(find.byKey(const ValueKey('verify_pan_button')), findsNothing);
      expect(find.text('Business details recorded'), findsOneWidget);
      expect(find.text('Government verified'), findsNothing);
    });

    testWidgets('14. PAN duplicate error shows safe localized message without leaking other accounts', (tester) async {
      final testService = ProducerVerificationService(
        rpcHandler: (fnName, params) async {
          return {
            'success': false,
            'status': 'duplicate_pan',
            'message': 'This PAN is already registered with another account.',
          };
        },
      );

      final status = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: false,
        gstRegistered: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
            verificationService: testService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final panBtnFinder = find.byKey(const ValueKey('verify_pan_button'));
      await tester.ensureVisible(panBtnFinder);
      await tester.tap(panBtnFinder);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('pan_input_field')), 'ABCDE1234F');
      await tester.tap(find.byKey(const ValueKey('submit_pan_verification_button')));
      await tester.pumpAndSettle();

      // Sheet stays open, safe error displayed
      expect(find.byKey(const ValueKey('pan_verification_sheet')), findsOneWidget);
      expect(find.text('A PAN is already associated with this account.'), findsOneWidget);
      expect(find.textContaining('another account'), findsNothing);
      expect(find.textContaining('other user'), findsNothing);
    });

    testWidgets('15. GST verification: validates format, calls RPC, updates denominator to 3', (tester) async {
      String? calledRpc;
      Map<String, dynamic>? calledParams;

      final testService = ProducerVerificationService(
        rpcHandler: (fnName, params) async {
          calledRpc = fnName;
          calledParams = params;
          return {
            'success': true,
            'status': 'verified',
            'message': 'GSTIN details recorded successfully.',
            'masked_gstin': '07••••••••••1Z5',
            'market_access_scope': 'national',
          };
        },
      );

      final status = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: true,
        panLast4: '5678',
        gstRegistered: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
            verificationService: testService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gstBtnFinder = find.byKey(const ValueKey('verify_gst_button'));
      await tester.ensureVisible(gstBtnFinder);
      await tester.tap(gstBtnFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('gstin_verification_sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('gstin_input_field')), findsOneWidget);

      // Malformed GSTIN blocked
      await tester.enterText(find.byKey(const ValueKey('gstin_input_field')), '07ABC');
      await tester.tap(find.byKey(const ValueKey('submit_gst_verification_button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Please enter a valid 15-character GSTIN'), findsOneWidget);

      // Invalid state code (00) blocked
      await tester.enterText(find.byKey(const ValueKey('gstin_input_field')), '00AAAAA0000A1Z5');
      await tester.tap(find.byKey(const ValueKey('submit_gst_verification_button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Invalid state code in GSTIN'), findsOneWidget);
      expect(calledRpc, isNull);

      // Valid GSTIN submitted
      await tester.enterText(find.byKey(const ValueKey('gstin_input_field')), '07aaaaa0000a1z5');
      await tester.tap(find.byKey(const ValueKey('submit_gst_verification_button')));
      await tester.pumpAndSettle();

      expect(calledRpc, equals('verify_producer_gst_prototype'));
      expect(calledParams!['p_gstin'], equals('07AAAAA0000A1Z5'));

      // Sheet is closed
      expect(find.byKey(const ValueKey('gstin_verification_sheet')), findsNothing);

      // GST card updated to Details Added, denominator updated to 3 (3 of 3 completed)
      expect(find.text('3 of 3 completed'), findsOneWidget);
      expect(find.text('Business details recorded'), findsOneWidget);
      expect(find.byKey(const ValueKey('verify_gst_button')), findsNothing);
      expect(find.text('Government verified'), findsNothing);
    });

    testWidgets('16. GST duplicate error shows safe localized message without leaking other accounts', (tester) async {
      final testService = ProducerVerificationService(
        rpcHandler: (fnName, params) async {
          return {
            'success': false,
            'status': 'duplicate_gstin',
            'message': 'This GSTIN is already registered.',
          };
        },
      );

      final status = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: true,
        panLast4: '5678',
        gstRegistered: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
            verificationService: testService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gstBtnFinder = find.byKey(const ValueKey('verify_gst_button'));
      await tester.ensureVisible(gstBtnFinder);
      await tester.tap(gstBtnFinder);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('gstin_input_field')), '07AAAAA0000A1Z5');
      await tester.tap(find.byKey(const ValueKey('submit_gst_verification_button')));
      await tester.pumpAndSettle();

      // Sheet stays open, safe error displayed
      expect(find.byKey(const ValueKey('gstin_verification_sheet')), findsOneWidget);
      expect(find.text('A GSTIN is already associated with this account.'), findsOneWidget);
      expect(find.textContaining('another account'), findsNothing);
    });

    testWidgets('17. Hindi (Devanagari) localization renders correctly', (tester) async {
      final langProv = LanguageProvider();
      langProv.setAppLanguage(AppLanguage.hindi);

      final status = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: true,
        panLast4: '5678',
        gstRegistered: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          languageProvider: langProv,
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('व्यवसाय सत्यापन'), findsOneWidget);
      expect(find.text('व्यवसाय विवरण दर्ज'), findsOneWidget);
      expect(find.text('2 में से 2 पूर्ण'), findsOneWidget);
      expect(find.text('ईमेल'), findsOneWidget);
      expect(find.text('व्यवसाय पहचान'), findsOneWidget);
      expect(find.text('जीएसटी पंजीकरण'), findsOneWidget);
    });

    testWidgets('18. Punjabi (Gurmukhi) localization renders correctly', (tester) async {
      final langProv = LanguageProvider();
      langProv.setAppLanguage(AppLanguage.punjabi);

      final status = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: false,
        gstRegistered: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          languageProvider: langProv,
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ਕਾਰੋਬਾਰ ਤਸਦੀਕ'), findsOneWidget);
      expect(find.text('1 ਕਦਮ ਬਾਕੀ'), findsOneWidget);
      expect(find.text('2 ਵਿੱਚੋਂ 1 ਪੂਰੇ'), findsOneWidget);
      expect(find.text('ਕਾਰੋਬਾਰੀ ਪਛਾਣ'), findsOneWidget);
      expect(find.text('ਪੈਨ ਸ਼ਾਮਲ ਕਰੋ'), findsOneWidget);
    });

    testWidgets('19. 320px narrow mobile viewport renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final status = BusinessVerificationStatus(
        isEmailVerified: false,
        isPanVerified: false,
        gstRegistered: true,
        gstVerificationStatus: 'unverified',
      );

      await tester.pumpWidget(
        buildTestApp(
          screenSize: const Size(320, 700),
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('verification_overview_header')), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_card_email')), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_card_pan')), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_card_gst')), findsOneWidget);
    });

    testWidgets('20. Dark theme renders cleanly', (tester) async {
      final themeProv = ThemeProvider();
      themeProv.setThemeOption(AppThemeOption.dark);

      final status = BusinessVerificationStatus(
        isEmailVerified: true,
        isPanVerified: true,
        gstRegistered: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          themeProvider: themeProv,
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Business Verification'), findsOneWidget);
    });

    testWidgets('21. Navigation from ProducerMainScreen to verification and back preserves session and tabs', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const ProducerMainScreen(initialProfile: panVerifiedNonGstProfile),
        ),
      );
      await tester.pumpAndSettle();

      // Go to profile tab
      await tester.tap(find.text('My Profile').first);
      await tester.pumpAndSettle();
      expect(find.byType(ProducerProfileTab), findsOneWidget);

      // Tap Business Verification entry
      final entryFinder = find.byKey(const ValueKey('business_verification_entry'));
      await tester.ensureVisible(entryFinder);
      await tester.pumpAndSettle();
      await tester.tap(entryFinder);
      await tester.pumpAndSettle();
      expect(find.byType(BusinessVerificationOverviewScreen), findsOneWidget);

      // Tap back button in AppBar
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Should return to ProducerProfileTab in ProducerMainScreen without logout
      expect(find.byType(ProducerProfileTab), findsOneWidget);
      expect(find.byType(ProducerMainScreen), findsOneWidget);
    });

    testWidgets('22. Fully verified profile does not show any verification action buttons', (tester) async {
      final status = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: true,
        panLast4: '5678',
        gstRegistered: true,
        gstVerificationStatus: 'verified',
        gstin: '07AAAAA0000A1Z5',
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('verify_pan_button')), findsNothing);
      expect(find.byKey(const ValueKey('verify_gst_button')), findsNothing);
      expect(find.text('Business details recorded'), findsOneWidget);
      expect(find.text('3 of 3 completed'), findsOneWidget);
    });

    testWidgets('23. Sensitive input bottom sheet cleans up upon cancellation/dismiss', (tester) async {
      final status = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: false,
        gstRegistered: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BusinessVerificationOverviewScreen(
            statusOverride: status,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open PAN sheet
      await tester.tap(find.byKey(const ValueKey('verify_pan_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pan_verification_sheet')), findsOneWidget);

      // Enter text into controller
      await tester.enterText(find.byKey(const ValueKey('pan_input_field')), 'ABCDE1234F');
      await tester.pumpAndSettle();

      // Close bottom sheet via tapping outside/barrier
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Sheet is dismissed
      expect(find.byKey(const ValueKey('pan_verification_sheet')), findsNothing);

      // Re-opening the sheet presents a fresh controller rather than stale retained data
      await tester.tap(find.byKey(const ValueKey('verify_pan_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pan_verification_sheet')), findsOneWidget);
      final textField = tester.widget<TextField>(find.byKey(const ValueKey('pan_input_field')));
      expect(textField.controller?.text ?? '', isEmpty);
    });

    testWidgets('24. Non-GST copy contains truthful platform framing without legal tax claims', (tester) async {
      final nonGstStatus = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: true,
        panLast4: '5678',
        gstRegistered: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BusinessVerificationOverviewScreen(
            statusOverride: nonGstStatus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check truthful non-GST text
      expect(
        find.text('GST details are optional here. You can add them later if applicable to your business.'),
        findsOneWidget,
      );

      // No government verification or tax threshold claims
      expect(find.textContaining('tax threshold'), findsNothing);
      expect(find.textContaining('exempt'), findsNothing);
      expect(find.textContaining('legally approved'), findsNothing);

      // Now test GST registered profile frames wider market as platform capability
      final gstStatus = BusinessVerificationStatus(
        isEmailVerified: true,
        email: 'sunita@example.com',
        isPanVerified: true,
        panLast4: '5678',
        gstRegistered: true,
        gstVerificationStatus: 'unverified',
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BusinessVerificationOverviewScreen(
            statusOverride: gstStatus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Record your GST registration to access eligible wider-market features on VyaparSetu.'),
        findsOneWidget,
      );
      expect(find.textContaining('tax threshold'), findsNothing);
      expect(find.textContaining('legally approved'), findsNothing);
    });
  });
}
