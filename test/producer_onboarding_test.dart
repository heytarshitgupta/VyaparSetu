import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_provider.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_screen.dart';

void main() {
  group('ProducerOnboardingProvider Step 1, 2, & 3 Unit Tests', () {
    test('Initializes at step 0 with 5 total steps', () {
      final provider = ProducerOnboardingProvider();
      expect(provider.currentStep, 0);
      expect(provider.isFirstStep, isTrue);
      expect(provider.isLastStep, isFalse);
      expect(provider.progressPercentage, 0.2);
      expect(provider.currentStepTitle, 'Basic Details');
    });

    test('Prefill logic correctly prioritizes profile, producerProfile, and auth data', () {
      final provider = ProducerOnboardingProvider();

      provider.initializeFromProfile(
        profile: {
          'full_name': 'Ramesh Artisan',
          'email': 'ramesh@example.com',
          'phone': '9876543210',
        },
        producerProfile: {
          'business_name': 'Ramesh Handlooms',
          'craft_category': 'Handloom & Textiles',
          'bio': 'Weaving natural cotton stoles for 10 years.',
          'state': 'Rajasthan',
          'district': 'Jaipur',
          'city': 'Sanganer',
          'pincode': '302029',
          'address': 'Plot 42, Artisan Colony, Sanganer',
        },
        user: null,
      );

      // Step 1
      expect(provider.fullName, 'Ramesh Artisan');
      expect(provider.displayEmail, 'ramesh@example.com');
      expect(provider.contactPhone, '9876543210');
      expect(provider.isAuthPhone, isFalse);

      // Step 2
      expect(provider.businessName, 'Ramesh Handlooms');
      expect(provider.craftCategory, 'Handloom & Textiles');
      expect(provider.customCategory, '');
      expect(provider.businessDescription, 'Weaving natural cotton stoles for 10 years.');

      // Step 3
      expect(provider.state, 'Rajasthan');
      expect(provider.district, 'Jaipur');
      expect(provider.city, 'Sanganer');
      expect(provider.pincode, '302029');
      expect(provider.address, 'Plot 42, Artisan Colony, Sanganer');
    });

    test('Step 3 validation enforces state, district, city, pincode, and address rules', () {
      final provider = ProducerOnboardingProvider();

      // 1. Missing State
      expect(provider.validateStep3(), contains('state or union territory'));
      provider.setStateValue('Rajasthan');

      // 2. Missing District
      expect(provider.validateStep3(), contains('enter your district'));
      provider.setDistrict('J'); // too short
      expect(provider.validateStep3(), contains('between 2 and 100 characters'));
      provider.setDistrict('Jaipur');

      // 3. Missing City
      expect(provider.validateStep3(), contains('city, town, or village'));
      provider.setCity('S'); // too short
      expect(provider.validateStep3(), contains('between 2 and 100 characters'));
      provider.setCity('Sanganer');

      // 4. Pincode validation (matches ^[1-9][0-9]{5}$)
      expect(provider.validateStep3(), contains('6-digit postal PIN code'));

      provider.setPincode('012345'); // starts with 0
      expect(provider.validateStep3(), contains('cannot start with 0'));

      provider.setPincode('12345'); // 5 digits
      expect(provider.validateStep3(), contains('cannot start with 0'));

      provider.setPincode('302029'); // valid 6 digits

      // 5. Address validation
      expect(provider.validateStep3(), contains('workshop or business address'));

      provider.setAddress('Home'); // < 5 chars
      expect(provider.validateStep3(), contains('between 5 and 300 characters'));

      provider.setAddress('A' * 301); // > 300 chars
      expect(provider.validateStep3(), contains('between 5 and 300 characters'));

      provider.setAddress('Plot 42, Artisan Colony, Main Road');
      expect(provider.validateStep3(), isNull);
    });

    test('saveStep3 succeeds with custom updater and handles failures gracefully', () async {
      final provider = ProducerOnboardingProvider();
      provider.setStateValue('Rajasthan');
      provider.setDistrict('Jaipur');
      provider.setCity('Sanganer');
      provider.setPincode('302029');
      provider.setAddress('Plot 42, Artisan Colony, Main Road');

      // Success case
      String? savedState;
      String? savedPincode;
      provider.step3Saver = ({
        required state,
        required district,
        required city,
        required pincode,
        required address,
      }) async {
        savedState = state;
        savedPincode = pincode;
      };

      final success = await provider.saveStep3();
      expect(success, isTrue);
      expect(savedState, 'Rajasthan');
      expect(savedPincode, '302029');
      expect(provider.errorMessage, isNull);

      // Failure case
      provider.step3Saver = ({
        required state,
        required district,
        required city,
        required pincode,
        required address,
      }) async {
        throw Exception('Database offline');
      };

      final failed = await provider.saveStep3();
      expect(failed, isFalse);
      expect(provider.errorMessage, contains('Failed to save location details'));
    });
  });

  group('ProducerOnboardingScreen Widget Tests', () {
    testWidgets('Step 1, Step 2, and Step 3 full interaction, validation, and multi-step back navigation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? savedName;
      String? savedBusiness;
      String? savedCategory;
      String? savedState;
      String? savedDistrict;
      String? savedCity;
      String? savedPincode;
      String? savedAddress;

      await tester.pumpWidget(
        MaterialApp(
          home: ProducerOnboardingScreen(
            step1Saver: ({required fullName, phone}) async {
              savedName = fullName;
            },
            step2Saver: ({required businessName, required craftCategory, bio}) async {
              savedBusiness = businessName;
              savedCategory = craftCategory;
            },
            step3Saver: ({
              required state,
              required district,
              required city,
              required pincode,
              required address,
            }) async {
              savedState = state;
              savedDistrict = district;
              savedCity = city;
              savedPincode = pincode;
              savedAddress = address;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ----------------------------------------------------------------------
      // STEP 1: Basic Details
      // ----------------------------------------------------------------------
      expect(find.text('Step 1 of 5'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_name_field')),
        'Sunita Devi',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(savedName, 'Sunita Devi');
      expect(find.text('Step 2 of 5'), findsOneWidget);

      // ----------------------------------------------------------------------
      // STEP 2: Craft & Business
      // ----------------------------------------------------------------------
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_business_name_field')),
        'Sunita Handloom Works',
      );
      await tester.tap(find.byKey(const Key('category_chip_Handloom_&_Textiles')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(savedBusiness, 'Sunita Handloom Works');
      expect(savedCategory, 'Handloom & Textiles');

      // ----------------------------------------------------------------------
      // STEP 3: Location Details
      // ----------------------------------------------------------------------
      expect(find.text('Step 3 of 5'), findsOneWidget);
      expect(find.text('Location Details'), findsOneWidget);
      expect(find.text('State / Union Territory *'), findsOneWidget);
      expect(find.text('District *'), findsOneWidget);
      expect(find.text('City / Village *'), findsOneWidget);
      expect(find.text('Pincode *'), findsOneWidget);
      expect(find.text('Workshop / Business Address *'), findsOneWidget);

      // Attempt Continue with empty fields -> should block
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 5'), findsOneWidget);
      expect(find.text('Please select your state or union territory.'), findsOneWidget);

      // Select State
      await tester.tap(find.byKey(const Key('producer_onboarding_state_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rajasthan').last);
      await tester.pumpAndSettle();

      // Enter District & City
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_district_field')),
        'Jaipur',
      );
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_city_field')),
        'Sanganer',
      );

      // Enter invalid pincode starting with 0
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_pincode_field')),
        '012345',
      );
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_address_field')),
        'Plot 42, Artisan Colony',
      );
      await tester.pumpAndSettle();

      // Tap Continue -> Should fail on pincode starting with 0
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid 6-digit Indian PIN code (cannot start with 0).'), findsOneWidget);

      // Fix pincode
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_pincode_field')),
        '302029',
      );
      await tester.pumpAndSettle();

      // Tap Continue -> Should save Step 3 and advance to Step 4
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(savedState, 'Rajasthan');
      expect(savedDistrict, 'Jaipur');
      expect(savedCity, 'Sanganer');
      expect(savedPincode, '302029');
      expect(savedAddress, 'Plot 42, Artisan Colony');

      // ----------------------------------------------------------------------
      // STEP 4: Identity & Compliance placeholder reached
      // ----------------------------------------------------------------------
      expect(find.text('Step 4 of 5'), findsOneWidget);
      expect(find.text('Identity & Compliance'), findsOneWidget);

      // ----------------------------------------------------------------------
      // BACK NAVIGATION: Verify all values preserved across steps
      // ----------------------------------------------------------------------
      // Step 4 -> Step 3
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 5'), findsOneWidget);
      expect(find.text('Rajasthan'), findsOneWidget);
      expect(find.text('Jaipur'), findsOneWidget);
      expect(find.text('Sanganer'), findsOneWidget);
      expect(find.text('302029'), findsOneWidget);
      expect(find.text('Plot 42, Artisan Colony'), findsOneWidget);

      // Step 3 -> Step 2
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 5'), findsOneWidget);
      expect(find.text('Sunita Handloom Works'), findsOneWidget);

      // Step 2 -> Step 1
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Sunita Devi'), findsOneWidget);
    });
  });
}
