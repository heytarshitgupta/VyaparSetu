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
import 'package:buyer_section/producer_section/auth/services/producer_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          onGenerateRoute: AppRouter.generateRoute,
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
      expect(find.text('Sign in with OTP'), findsOneWidget);
      expect(find.text('Sign in with Phone OTP'), findsNothing);
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
      expect(find.text('ओटीपी से लॉग इन करें'), findsOneWidget);
      expect(find.text('फोन ओटीपी से लॉग इन करें'), findsNothing);
      expect(find.text('खाता बनाएं'), findsOneWidget);

      // Switch to Punjabi
      langProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();

      expect(find.text('ਲੌਗ ਇਨ ਕਰੋ'), findsWidgets);
      expect(find.text('ਈਮੇਲ ਪਤਾ'), findsOneWidget);
      expect(find.text('ਪਾਸਵਰਡ'), findsOneWidget);
      expect(find.text('ਪਾਸਵਰਡ ਭੁੱਲ ਗਏ?'), findsOneWidget);
      expect(find.text('ਓਟੀਪੀ ਨਾਲ ਲੌਗ ਇਨ ਕਰੋ'), findsOneWidget);
      expect(find.text('ਫ਼ੋਨ ਓਟੀਪੀ ਨਾਲ ਲੌਗ ਇਨ ਕਰੋ'), findsNothing);
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

      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Sign up with Phone OTP'), findsNothing);

      // Trigger empty validation
      final submitButton = find.widgetWithText(ElevatedButton, 'Continue');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please create a password'), findsOneWidget);

      // Enter user text
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(3));

      await tester.enterText(textFields.at(0), 'Ramesh Kumar');
      await tester.enterText(textFields.at(1), 'ramesh@example.com');
      await tester.enterText(textFields.at(2), 'mypassword');
      await tester.pump();

      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('mypassword'), findsOneWidget);

      // Live switch to Hindi
      langProvider.setAppLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();

      expect(find.text('पूरा नाम'), findsOneWidget);
      expect(find.text('ईमेल पता'), findsOneWidget);
      expect(find.text('अपना खाता बनाएं'), findsOneWidget);
      expect(find.text('आगे बढ़ें'), findsOneWidget);
      // Values preserved
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('mypassword'), findsOneWidget);

      // Live switch to Dark theme
      themeProvider.setThemeOption(AppThemeOption.dark);
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('mypassword'), findsOneWidget);

      // Live switch to Punjabi
      langProvider.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpAndSettle();

      expect(find.text('ਪੂਰਾ ਨਾਮ'), findsOneWidget);
      expect(find.text('ਈਮੇਲ ਪਤਾ'), findsOneWidget);
      expect(find.text('ਆਪਣਾ ਖਾਤਾ ਬਣਾਓ'), findsOneWidget);
      expect(find.text('ਅੱਗੇ ਵਧੋ'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('ramesh@example.com'), findsOneWidget);
      expect(find.text('mypassword'), findsOneWidget);
    });

    testWidgets('Step 1 Email OTP flow: Transitions to OTP screen, handles Change Email, and verifies OTP', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final langProvider = LanguageProvider();
      final themeProvider = ThemeProvider();

      bool signUpCalled = false;
      bool verifyOtpCalled = false;
      bool registrationCalled = false;

      final testScreen = ProducerSignupScreen(
        signUpHandler: ({required email, required password, data}) async {
          signUpCalled = true;
          return AuthResponse(
            user: User(
              id: 'test-user-id',
              appMetadata: {},
              userMetadata: data ?? {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        },
        verifyOtpHandler: ({required email, required otp}) async {
          verifyOtpCalled = true;
          return AuthResponse(
            session: Session(
              accessToken: 'test-token',
              tokenType: 'bearer',
              user: User(
                id: 'test-user-id',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
              ),
            ),
            user: User(
              id: 'test-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        },
        profileRegistrationHandler: ({required fullName}) async {
          registrationCalled = true;
          return 'test-user-id';
        },
        accessValidationHandler: ({fallbackFullName}) async {
          return const ProducerAuthValidationResult(
            status: ProducerAuthStatus.success,
            message: 'Success',
            producerProfile: {'onboarding_status': 'not_started'},
          );
        },
      );

      await tester.pumpWidget(
        _createTestHarness(
          child: testScreen,
          languageProvider: langProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Enter details
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Ramesh Kumar');
      await tester.enterText(textFields.at(1), 'ramesh@example.com');
      await tester.enterText(textFields.at(2), 'mypassword');
      await tester.pump();

      // 2. Submit initial form to send OTP
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(signUpCalled, isTrue);

      // 3. Confirm transition to OTP verification view
      expect(find.text('Verify Your Email'), findsWidgets);
      expect(find.textContaining('ra***@example.com'), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
      expect(find.text('Change Email'), findsOneWidget);
      expect(find.textContaining('Resend Code in'), findsOneWidget);

      // 4. Test "Change Email" returns to details without losing name or password
      final changeEmailButton = find.text('Change Email');
      await tester.tap(changeEmailButton);
      await tester.pumpAndSettle();

      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('mypassword'), findsOneWidget);

      // 5. Submit again to return to OTP
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Verify Your Email'), findsWidgets);

      // 6. Enter OTP and verify
      // The hidden text field inside ProducerOtpInputField captures input
      final otpTextField = find.byType(TextField);
      await tester.enterText(otpTextField, '123456');
      await tester.pump();

      final verifyButton = find.widgetWithText(ElevatedButton, 'Verify & Continue');
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();

      expect(verifyOtpCalled, isTrue);
      expect(registrationCalled, isTrue);
    });

    testWidgets('Normal Email/Password Login: authenticates and validates producer access', (WidgetTester tester) async {
      bool signInCalled = false;
      bool accessValidationCalled = false;

      final testScreen = ProducerLoginScreen(
        signInHandler: ({required email, required password}) async {
          signInCalled = true;
          return AuthResponse(
            session: Session(
              accessToken: 'test-token',
              tokenType: 'bearer',
              user: User(
                id: 'test-user-id',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
              ),
            ),
            user: User(
              id: 'test-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        },
        accessValidationHandler: ({fallbackFullName}) async {
          accessValidationCalled = true;
          return const ProducerAuthValidationResult(
            status: ProducerAuthStatus.success,
            message: 'Success',
            producerProfile: {'onboarding_status': 'not_started'},
          );
        },
      );

      await tester.pumpWidget(
        _createTestHarness(
          child: testScreen,
          languageProvider: LanguageProvider(),
          themeProvider: ThemeProvider(),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'ramesh@example.com');
      await tester.enterText(textFields.at(1), 'mypassword');
      await tester.pump();

      final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(signInCalled, isTrue);
      expect(accessValidationCalled, isTrue);
    });

    testWidgets('ProducerLoginScreen rejects non-producer accounts safely', (WidgetTester tester) async {
      final testScreen = ProducerLoginScreen(
        signInHandler: ({required email, required password}) async {
          return AuthResponse(
            session: Session(
              accessToken: 'test-token',
              tokenType: 'bearer',
              user: User(
                id: 'buyer-user-id',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
              ),
            ),
            user: User(
              id: 'buyer-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        },
        accessValidationHandler: ({fallbackFullName}) async {
          return const ProducerAuthValidationResult(
            status: ProducerAuthStatus.buyerRejected,
            message: 'This account is registered as a Buyer. Access to the Producer portal is restricted.',
          );
        },
      );

      await tester.pumpWidget(
        _createTestHarness(
          child: testScreen,
          languageProvider: LanguageProvider(),
          themeProvider: ThemeProvider(),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'buyer@example.com');
      await tester.enterText(textFields.at(1), 'buyerpassword');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('This account is registered as a Buyer. Access to the Producer portal is restricted.'), findsOneWidget);
    });

    testWidgets('Sign in with Email OTP: transitions to OTP view, enforces 60s cooldown, verifies OTP and validates Producer', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool otpSent = false;
      bool otpVerified = false;
      bool accessValidationCalled = false;

      final testScreen = ProducerLoginScreen(
        signInWithOtpHandler: ({required email}) async {
          otpSent = true;
        },
        verifyLoginOtpHandler: ({required email, required otp}) async {
          otpVerified = true;
          return AuthResponse(
            session: Session(
              accessToken: 'test-token',
              tokenType: 'bearer',
              user: User(
                id: 'test-user-id',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
              ),
            ),
            user: User(
              id: 'test-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        },
        accessValidationHandler: ({fallbackFullName}) async {
          accessValidationCalled = true;
          return const ProducerAuthValidationResult(
            status: ProducerAuthStatus.success,
            message: 'Success',
            producerProfile: {'onboarding_status': 'completed'},
          );
        },
      );

      await tester.pumpWidget(
        _createTestHarness(
          child: testScreen,
          languageProvider: LanguageProvider(),
          themeProvider: ThemeProvider(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter email and tap "Sign in with OTP"
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'producer@example.com');
      await tester.pump();

      final otpLoginBtn = find.widgetWithText(OutlinedButton, 'Sign in with OTP');
      await tester.ensureVisible(otpLoginBtn);
      await tester.tap(otpLoginBtn);
      await tester.pumpAndSettle();

      expect(otpSent, isTrue);
      expect(find.text('Check Your Email'), findsWidgets);
      expect(find.textContaining('pr***@example.com'), findsOneWidget);
      expect(find.textContaining('Resend Code in'), findsOneWidget);

      // Enter 6-digit OTP
      final otpInput = find.byType(TextField);
      await tester.enterText(otpInput, '654321');
      await tester.pump();

      final verifyBtn = find.widgetWithText(ElevatedButton, 'Verify & Sign In');
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      expect(otpVerified, isTrue);
      expect(accessValidationCalled, isTrue);
    });

    testWidgets('Forgot Password: sends recovery code with enumeration protection, verifies recovery OTP, and updates password', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool recoverySent = false;
      bool recoveryVerified = false;
      bool passwordUpdated = false;

      final testScreen = ProducerLoginScreen(
        sendRecoveryOtpHandler: ({required email}) async {
          recoverySent = true;
        },
        verifyRecoveryOtpHandler: ({required email, required otp}) async {
          recoveryVerified = true;
          return AuthResponse(
            session: Session(
              accessToken: 'recovery-token',
              tokenType: 'bearer',
              user: User(
                id: 'test-user-id',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
              ),
            ),
            user: User(
              id: 'test-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        },
        updatePasswordHandler: ({required newPassword}) async {
          passwordUpdated = true;
          return UserResponse.fromJson(<String, dynamic>{
            'id': 'test-user-id',
            'app_metadata': <String, dynamic>{},
            'user_metadata': <String, dynamic>{},
            'aud': 'authenticated',
            'created_at': DateTime.now().toIso8601String(),
          });
        },
      );

      await tester.pumpWidget(
        _createTestHarness(
          child: testScreen,
          languageProvider: LanguageProvider(),
          themeProvider: ThemeProvider(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tap Forgot Password?
      final forgotPasswordBtn = find.text('Forgot Password?');
      await tester.ensureVisible(forgotPasswordBtn);
      await tester.tap(forgotPasswordBtn);
      await tester.pumpAndSettle();

      expect(find.text('Reset Your Password'), findsOneWidget);
      expect(find.text('Send Recovery Code'), findsOneWidget);

      // 2. Enter email and submit recovery request
      await tester.enterText(find.byType(TextField), 'forgot@example.com');
      await tester.pump();

      final sendRecoveryBtn = find.widgetWithText(ElevatedButton, 'Send Recovery Code');
      await tester.ensureVisible(sendRecoveryBtn);
      await tester.tap(sendRecoveryBtn);
      await tester.pumpAndSettle();

      expect(recoverySent, isTrue);
      // Enumeration safe message
      expect(find.text("If an account exists for this email, we've sent a verification code."), findsOneWidget);
      expect(find.text('Verify Your Email'), findsWidgets);
      expect(find.textContaining('fo***@example.com'), findsOneWidget);

      // 3. Enter 6-digit recovery OTP
      await tester.enterText(find.byType(TextField), '112233');
      await tester.pump();

      final verifyCodeBtn = find.widgetWithText(ElevatedButton, 'Verify Code');
      await tester.ensureVisible(verifyCodeBtn);
      await tester.tap(verifyCodeBtn);
      await tester.pumpAndSettle();

      expect(recoveryVerified, isTrue);
      expect(find.text('Create New Password'), findsOneWidget);

      // 4. Test password mismatch rejection
      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(0), 'newpassword123');
      await tester.enterText(passwordFields.at(1), 'mismatchpassword');
      await tester.pump();

      final updatePasswordBtn = find.widgetWithText(ElevatedButton, 'Update Password');
      await tester.ensureVisible(updatePasswordBtn);
      await tester.tap(updatePasswordBtn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(passwordUpdated, isFalse);

      // 5. Enter matching password and submit
      await tester.enterText(passwordFields.at(1), 'newpassword123');
      await tester.pump();

      await tester.ensureVisible(updatePasswordBtn);
      await tester.tap(updatePasswordBtn);
      await tester.pumpAndSettle();

      expect(passwordUpdated, isTrue);
      expect(find.text('Your password has been updated.'), findsOneWidget);
    });
  });
}
