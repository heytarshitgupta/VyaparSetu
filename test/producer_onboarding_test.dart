import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_provider.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_screen.dart';

void main() {
  group('ProducerOnboardingProvider Unit Tests', () {
    test('Initializes at step 0 with 5 total steps', () {
      final provider = ProducerOnboardingProvider();
      expect(provider.currentStep, 0);
      expect(provider.isFirstStep, isTrue);
      expect(provider.isLastStep, isFalse);
      expect(provider.progressPercentage, 0.2);
      expect(provider.currentStepTitle, 'Basic Details');
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
    testWidgets('Renders onboarding shell and navigates between steps',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProducerOnboardingScreen(),
        ),
      );

      // Verify Step 1
      expect(find.text('Producer Setup'), findsOneWidget);
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Basic Details'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Back'), findsNothing); // First step has no Back button

      // Advance to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 5'), findsOneWidget);
      expect(find.text('Craft & Business'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Go back to Step 1
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Basic Details'), findsOneWidget);

      // Advance to Step 5
      await tester.tap(find.text('Continue')); // Step 2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue')); // Step 3
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue')); // Step 4
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue')); // Step 5
      await tester.pumpAndSettle();

      expect(find.text('Step 5 of 5'), findsOneWidget);
      expect(find.text('Review & Submit'), findsOneWidget);
      expect(find.text('Submit Application'), findsOneWidget);
    });
  });
}
