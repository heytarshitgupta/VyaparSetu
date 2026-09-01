import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_provider.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_screen.dart';

void main() {
  group('ProducerOnboardingProvider Step 1 Unit Tests', () {
    test('Initializes at step 0 with 5 total steps', () {
      final provider = ProducerOnboardingProvider();
      expect(provider.currentStep, 0);
      expect(provider.isFirstStep, isTrue);
      expect(provider.isLastStep, isFalse);
      expect(provider.progressPercentage, 0.2);
      expect(provider.currentStepTitle, 'Basic Details');
    });

    test('Prefill logic correctly prioritizes profile and auth data', () {
      final provider = ProducerOnboardingProvider();

      // Profile contains full_name, email, and contact phone (no auth phone)
      provider.initializeFromProfile(
        profile: {
          'full_name': 'Ramesh Artisan',
          'email': 'ramesh@example.com',
          'phone': '9876543210',
        },
        user: null,
      );

      expect(provider.fullName, 'Ramesh Artisan');
      expect(provider.displayEmail, 'ramesh@example.com');
      expect(provider.contactPhone, '9876543210');
      expect(provider.isAuthPhone, isFalse);
    });

    test('Validation enforces full_name length and 10-digit mobile', () {
      final provider = ProducerOnboardingProvider();

      // Empty name
      provider.setFullName('');
      expect(provider.validateStep1(), contains('full name'));

      // 1-char name
      provider.setFullName('A');
      expect(provider.validateStep1(), contains('at least 2 characters'));

      // Valid name, invalid contact phone
      provider.setFullName('Ramesh Kumar');
      provider.setContactPhone('12345'); // not 10 digits
      expect(provider.validateStep1(), contains('10-digit Indian mobile'));

      // Valid name, valid contact phone (starting with 6-9)
      provider.setContactPhone('9876543210');
      expect(provider.validateStep1(), isNull);
    });

    test('saveStep1 succeeds with custom updater and fails with error handler', () async {
      final provider = ProducerOnboardingProvider();
      provider.setFullName('Ramesh Kumar');
      provider.setContactPhone('9876543210');

      // 1. Success case
      provider.step1Saver = ({required fullName, phone}) async {};
      final success = await provider.saveStep1();
      expect(success, isTrue);
      expect(provider.errorMessage, isNull);

      // 2. Failure case
      provider.step1Saver = ({required fullName, phone}) async {
        throw Exception('Network disconnected');
      };
      final failed = await provider.saveStep1();
      expect(failed, isFalse);
      expect(provider.errorMessage, contains('Failed to save basic details'));
    });

    test('nextStep and previousStep work properly with bounds', () {
      final provider = ProducerOnboardingProvider();

      // Step 0 -> 1
      provider.nextStep();
      expect(provider.currentStep, 1);
      expect(provider.isFirstStep, isFalse);
      expect(provider.currentStepTitle, 'Craft & Business');

      // Step 1 -> 4 (Last Step)
      provider.goToStep(4);
      expect(provider.currentStep, 4);
      expect(provider.isLastStep, isTrue);
      expect(provider.currentStepTitle, 'Review & Submit');

      // Next at last step should not overflow
      provider.nextStep();
      expect(provider.currentStep, 4);

      // Step 4 -> 3
      provider.previousStep();
      expect(provider.currentStep, 3);
      expect(provider.isLastStep, isFalse);
      expect(provider.currentStepTitle, 'Identity & Compliance');

      // Step 3 -> 0
      provider.previousStep();
      provider.previousStep();
      provider.previousStep();
      expect(provider.currentStep, 0);

      // Previous at first step should not underflow
      provider.previousStep();
      expect(provider.currentStep, 0);
    });
  });

  group('ProducerOnboardingScreen Widget Tests', () {
    testWidgets('Renders Basic Details form, blocks invalid name, and persists across navigation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? savedName;
      String? savedPhone;

      await tester.pumpWidget(
        MaterialApp(
          home: ProducerOnboardingScreen(
            step1Saver: ({required fullName, phone}) async {
              savedName = fullName;
              savedPhone = phone;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Step 1 elements
      expect(find.text('Producer Setup'), findsOneWidget);
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Basic Details'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email Address (Login)'), findsOneWidget);
      expect(find.text('Read Only'), findsOneWidget);
      expect(find.text('Contact Phone Number'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // 1. Try to continue with empty name -> should block and show error
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 5'), findsOneWidget); // Did not advance
      expect(find.text('Please enter your full name.'), findsOneWidget);

      // 2. Enter valid Name and Contact Phone
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_name_field')),
        'Sunita Devi',
      );
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_phone_field')),
        '9876543210',
      );
      await tester.pumpAndSettle();

      // Tap Continue -> Should save and advance to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(savedName, 'Sunita Devi');
      expect(savedPhone, '9876543210');
      expect(find.text('Step 2 of 5'), findsOneWidget);
      expect(find.text('Craft & Business'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // 3. Navigate Back to Step 1
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Verify values survived back navigation
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Sunita Devi'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
    });
  });
}
