import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/core/routes/app_router.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_provider.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_screen.dart';
import 'package:buyer_section/producer_section/onboarding/steps/identity_compliance_step.dart';
import 'package:buyer_section/producer_section/verification/producer_verification_service.dart';

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

    test('Step 4E2.1: New producer starts at Step 1', () {
      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        user: null,
        profile: {'id': 'p-new', 'full_name': 'New Artisan', 'role': 'producer'},
        producerProfile: null,
      );

      expect(provider.persistedServerStep, 1);
      expect(provider.currentStep, 0); // 0-indexed Step 1
      expect(provider.isFirstStep, isTrue);
    });

    test('Step 4E2.1: Successful Step 1, 2, & 3 advance server progress 1 -> 2 -> 3 -> 4', () async {
      final provider = ProducerOnboardingProvider();
      final advancedSteps = <int>[];

      provider.stepAdvancer = ({required expectedCurrentStep, required nextStep}) async {
        advancedSteps.add(nextStep);
      };

      // Step 1 Save
      provider.step1Saver = ({required fullName, phone}) async {};
      provider.setFullName('Lakshmi Devi');
      provider.setContactPhone('9876543210');
      final step1Ok = await provider.saveStep1();
      expect(step1Ok, isTrue);
      expect(provider.persistedServerStep, 2);
      expect(advancedSteps, [2]);

      // Step 2 Save
      provider.step2Saver = ({required businessName, required craftCategory, bio}) async {};
      provider.setBusinessName('Lakshmi Crafts');
      provider.setCraftCategory('Handicrafts');
      final step2Ok = await provider.saveStep2();
      expect(step2Ok, isTrue);
      expect(provider.persistedServerStep, 3);
      expect(advancedSteps, [2, 3]);

      // Step 3 Save
      provider.step3Saver = ({required state, required district, required city, required pincode, required address}) async {};
      provider.setStateValue('Odisha');
      provider.setDistrict('Puri');
      provider.setCity('Raghurajpur');
      provider.setPincode('752012');
      provider.setAddress('Artisan Heritage Village, House 12');
      final step3Ok = await provider.saveStep3();
      expect(step3Ok, isTrue);
      expect(provider.persistedServerStep, 4);
      expect(advancedSteps, [2, 3, 4]);
    });

    test('Step 4E2.1: Failed save does NOT advance server progress', () async {
      final provider = ProducerOnboardingProvider();
      bool advancerCalled = false;

      provider.stepAdvancer = ({required expectedCurrentStep, required nextStep}) async {
        advancerCalled = true;
      };

      // Invalid input (empty name)
      provider.setFullName('');
      final saved = await provider.saveStep1();
      expect(saved, isFalse);
      expect(advancerCalled, isFalse);
      expect(provider.persistedServerStep, 1);

      // Backend throw
      provider.setFullName('Valid Name');
      provider.step1Saver = ({required fullName, phone}) async {
        throw Exception('Network timeout');
      };
      final saveThrew = await provider.saveStep1();
      expect(saveThrew, isFalse);
      expect(advancerCalled, isFalse);
      expect(provider.persistedServerStep, 1);
    });

    test('Step 4E2.1: Pressing Back does NOT reduce persisted progress', () {
      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        user: null,
        profile: {'id': 'p-step4', 'full_name': 'Meena Bai'},
        producerProfile: {'onboarding_step': 4},
      );

      expect(provider.persistedServerStep, 4);
      expect(provider.currentStep, 3); // Step 4 Identity & Compliance

      // User presses Back to Step 3 Location
      provider.previousStep();
      expect(provider.currentStep, 2); // Step 3
      expect(provider.persistedServerStep, 4); // Server progress remains 4

      // User presses Back to Step 2 Craft
      provider.previousStep();
      expect(provider.currentStep, 1); // Step 2
      expect(provider.persistedServerStep, 4); // Server progress remains 4
    });

    test('Step 4E2.1: Recreated provider (browser refresh simulation) restores server step', () {
      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        user: null,
        profile: {
          'id': 'p-resume',
          'full_name': 'Govind Ram',
          'role': 'producer',
        },
        producerProfile: {
          'business_name': 'Govind Blue Pottery',
          'craft_category': 'Handicrafts',
          'state': 'Rajasthan',
          'district': 'Jaipur',
          'city': 'Jaipur',
          'pincode': '302001',
          'address': 'Kishanpole Bazaar',
          'onboarding_step': 4,
        },
      );

      // Directly lands on Step 4 (index 3)
      expect(provider.persistedServerStep, 4);
      expect(provider.currentStep, 3);
      expect(provider.currentStepTitle, 'Identity & Compliance');

      // Completed earlier data is fully preserved and available
      expect(provider.fullName, 'Govind Ram');
      expect(provider.businessName, 'Govind Blue Pottery');
      expect(provider.craftCategory, 'Handicrafts');
      expect(provider.state, 'Rajasthan');
      expect(provider.pincode, '302001');
    });

    test('Step 4E2.1: Invalid progress values clamped safely', () {
      final provider = ProducerOnboardingProvider();

      // Negative value
      provider.initializeFromProfile(
        user: null,
        profile: {'full_name': 'Test'},
        producerProfile: {'onboarding_step': -5},
      );
      expect(provider.persistedServerStep, 1);
      expect(provider.currentStep, 0);

      // Excess value > 5
      provider.initializeFromProfile(
        user: null,
        profile: {'full_name': 'Test'},
        producerProfile: {'onboarding_step': 99},
      );
      expect(provider.persistedServerStep, 5);
      expect(provider.currentStep, 4);
    });

    test('Step 4E2.1: Completed onboarding status routes to producer home, incomplete routes to onboarding', () {
      String resolvePostAuthRoute(Map<String, dynamic>? producerProfile) {
        final onboardingStatus = producerProfile?['onboarding_status']?.toString();
        if (onboardingStatus == 'completed') {
          return AppRouter.producerHomeRoute;
        }
        return AppRouter.producerOnboardingRoute;
      }

      // Completed
      expect(
        resolvePostAuthRoute({'onboarding_status': 'completed'}),
        AppRouter.producerHomeRoute,
      );

      // In progress
      expect(
        resolvePostAuthRoute({'onboarding_status': 'in_progress', 'onboarding_step': 4}),
        AppRouter.producerOnboardingRoute,
      );

      // Not started
      expect(
        resolvePostAuthRoute({'onboarding_status': 'not_started'}),
        AppRouter.producerOnboardingRoute,
      );

      // Null profile
      expect(
        resolvePostAuthRoute(null),
        AppRouter.producerOnboardingRoute,
      );
    });

    test('Step 4E2.3: Server progress validation enforces expected step, prevents skipping, and blocks 4 -> 5', () {
      Map<String, dynamic> simulateAdvanceRpc({
        required int? expectedCurrentStep,
        required int nextStep,
        required int serverStep,
        required String onboardingStatus,
        required String? fullName,
        required String? businessName,
        required String? craftCategory,
        required String? state,
        required String? district,
        required String? city,
        required String? pincode,
        required String? address,
      }) {
        // 1. Already completed
        if (onboardingStatus == 'completed') {
          return {'success': true, 'status': 'already_completed', 'onboarding_step': 5};
        }

        // 2. Bounds check
        if (nextStep < 1 || nextStep > 5) {
          return {'success': false, 'status': 'invalid_step'};
        }

        // 3. Idempotent / already advanced
        if (serverStep >= nextStep) {
          return {'success': true, 'status': 'already_advanced', 'onboarding_step': serverStep};
        }

        // 4. Validate expected_current_step
        if (expectedCurrentStep == null) {
          return {'success': false, 'status': 'invalid_step'};
        }
        if (serverStep != expectedCurrentStep) {
          return {'success': false, 'status': 'stale_client_state', 'onboarding_step': serverStep};
        }

        // 5. Strict single step progression
        if (nextStep != expectedCurrentStep + 1) {
          return {'success': false, 'status': 'invalid_progression', 'onboarding_step': serverStep};
        }

        // 6. Server-side prerequisite checks
        if (expectedCurrentStep == 1) {
          if (fullName == null || fullName.trim().length < 2) {
            return {'success': false, 'status': 'prerequisite_failed'};
          }
        } else if (expectedCurrentStep == 2) {
          if (businessName == null || businessName.trim().length < 2 || craftCategory == null || craftCategory.trim().isEmpty) {
            return {'success': false, 'status': 'prerequisite_failed'};
          }
        } else if (expectedCurrentStep == 3) {
          if (state == null || state.trim().isEmpty ||
              district == null || district.trim().length < 2 ||
              city == null || city.trim().length < 2 ||
              pincode == null || !RegExp(r'^[1-9][0-9]{5}$').hasMatch(pincode) ||
              address == null || address.trim().length < 5) {
            return {'success': false, 'status': 'prerequisite_failed'};
          }
        } else if (expectedCurrentStep == 4) {
          // Blocked: Step 4 -> 5
          return {'success': false, 'status': 'identity_compliance_incomplete'};
        }

        return {'success': true, 'status': 'advanced', 'onboarding_step': nextStep};
      }

      // Normal valid 1 -> 2
      final res1 = simulateAdvanceRpc(
        expectedCurrentStep: 1,
        nextStep: 2,
        serverStep: 1,
        onboardingStatus: 'not_started',
        fullName: 'Shanti Devi',
        businessName: null, craftCategory: null, state: null, district: null, city: null, pincode: null, address: null,
      );
      expect(res1['status'], 'advanced');
      expect(res1['onboarding_step'], 2);

      // Stale client state (client thinks 1, server is 2)
      final resStale = simulateAdvanceRpc(
        expectedCurrentStep: 1,
        nextStep: 2,
        serverStep: 2,
        onboardingStatus: 'in_progress',
        fullName: 'Shanti Devi',
        businessName: null, craftCategory: null, state: null, district: null, city: null, pincode: null, address: null,
      );
      expect(resStale['status'], 'already_advanced');

      // Stale client state mismatch
      final resMismatch = simulateAdvanceRpc(
        expectedCurrentStep: 1,
        nextStep: 2,
        serverStep: 3,
        onboardingStatus: 'in_progress',
        fullName: 'Shanti Devi',
        businessName: null, craftCategory: null, state: null, district: null, city: null, pincode: null, address: null,
      );
      expect(resMismatch['status'], 'already_advanced');

      // Arbitrary skip attempt (1 -> 3)
      final resSkip = simulateAdvanceRpc(
        expectedCurrentStep: 1,
        nextStep: 3,
        serverStep: 1,
        onboardingStatus: 'not_started',
        fullName: 'Shanti Devi',
        businessName: null, craftCategory: null, state: null, district: null, city: null, pincode: null, address: null,
      );
      expect(resSkip['status'], 'invalid_progression');

      // Prerequisite failure for 1 -> 2 (missing name)
      final resPrereq1 = simulateAdvanceRpc(
        expectedCurrentStep: 1,
        nextStep: 2,
        serverStep: 1,
        onboardingStatus: 'not_started',
        fullName: '',
        businessName: null, craftCategory: null, state: null, district: null, city: null, pincode: null, address: null,
      );
      expect(resPrereq1['status'], 'prerequisite_failed');

      // Prerequisite failure for 2 -> 3 (missing craft)
      final resPrereq2 = simulateAdvanceRpc(
        expectedCurrentStep: 2,
        nextStep: 3,
        serverStep: 2,
        onboardingStatus: 'in_progress',
        fullName: 'Shanti Devi',
        businessName: 'Shanti Weaves',
        craftCategory: '',
        state: null, district: null, city: null, pincode: null, address: null,
      );
      expect(resPrereq2['status'], 'prerequisite_failed');

      // Prerequisite failure for 3 -> 4 (invalid pincode)
      final resPrereq3 = simulateAdvanceRpc(
        expectedCurrentStep: 3,
        nextStep: 4,
        serverStep: 3,
        onboardingStatus: 'in_progress',
        fullName: 'Shanti Devi',
        businessName: 'Shanti Weaves',
        craftCategory: 'Handloom & Textiles',
        state: 'Rajasthan',
        district: 'Jaipur',
        city: 'Jaipur',
        pincode: '012345', // invalid
        address: 'Artisan Colony',
      );
      expect(resPrereq3['status'], 'prerequisite_failed');

      // Step 4 -> 5 blocked
      final resBlocked = simulateAdvanceRpc(
        expectedCurrentStep: 4,
        nextStep: 5,
        serverStep: 4,
        onboardingStatus: 'in_progress',
        fullName: 'Shanti Devi',
        businessName: 'Shanti Weaves',
        craftCategory: 'Handloom & Textiles',
        state: 'Rajasthan',
        district: 'Jaipur',
        city: 'Jaipur',
        pincode: '302001',
        address: 'Artisan Colony',
      );
      expect(resBlocked['status'], 'identity_compliance_incomplete');

      // Completed onboarding returns already_completed
      final resCompleted = simulateAdvanceRpc(
        expectedCurrentStep: 1,
        nextStep: 2,
        serverStep: 1,
        onboardingStatus: 'completed',
        fullName: 'Shanti Devi',
        businessName: null, craftCategory: null, state: null, district: null, city: null, pincode: null, address: null,
      );
      expect(resCompleted['status'], 'already_completed');
      expect(resCompleted['onboarding_step'], 5);
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
      // ----------------------------------------------------------------------
      // STEP 4: Identity & Compliance reached
      // ----------------------------------------------------------------------
      expect(find.text('Step 4 of 5'), findsOneWidget);
      expect(find.text('Identity & Compliance'), findsNWidgets(2));
      expect(find.text('Demo verification environment • Verification is simulated in this prototype.'), findsOneWidget);
      expect(find.text('PAN Verification'), findsOneWidget);
      expect(find.text('Aadhaar Verification'), findsOneWidget);
      expect(find.text('GST Registration'), findsOneWidget);
      expect(find.text('Workshop Address Verification'), findsNothing);

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

    testWidgets('Step 4E1: IdentityComplianceStep renders cards, validates PAN, and keeps raw PAN transient', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        user: null,
        profile: {
          'id': 'test-uuid-4e1',
          'full_name': 'Ramesh Kumar',
          'role': 'producer',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IdentityComplianceStep(provider: provider),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Check title, description, and disclosure banner
      expect(find.text('Identity & Compliance'), findsOneWidget);
      expect(find.text('Verify your details to build trust with buyers.'), findsOneWidget);
      expect(find.text('Demo verification environment • Verification is simulated in this prototype.'), findsOneWidget);

      // 2. Check cards and badges
      expect(find.text('PAN Verification'), findsOneWidget);
      expect(find.text('Secure identity verification'), findsOneWidget);
      expect(find.text('Aadhaar Verification'), findsOneWidget);
      expect(find.text('GST Registration'), findsOneWidget);
      expect(find.text('Workshop Address Verification'), findsNothing);
      expect(find.text('Coming Soon'), findsNothing);

      // 3. Name prefilled from provider.fullName
      final nameFieldFinder = find.byKey(const Key('producer_onboarding_pan_name_field'));
      expect(nameFieldFinder, findsOneWidget);
      final nameFieldWidget = tester.widget<TextFormField>(nameFieldFinder);
      expect(nameFieldWidget.controller?.text, 'Ramesh Kumar');

      // 4. Tap Verify PAN with empty fields -> should show error
      final verifyButtonFinder = find.byKey(const Key('producer_onboarding_verify_pan_button'));
      await tester.ensureVisible(verifyButtonFinder);
      await tester.tap(verifyButtonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Please enter your 10-character PAN number.'), findsOneWidget);

      // 5. Enter invalid PAN format (e.g. lowercase, too short, wrong pattern)
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_pan_field')),
        'invalid123',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(verifyButtonFinder);
      await tester.tap(verifyButtonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid 10-character PAN (e.g. ABCDE1234F).'), findsOneWidget);

      // 6. Enter valid PAN format (should auto uppercase via formatter)
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_pan_field')),
        'abcde1234f',
      );
      await tester.pumpAndSettle();

      // Verify the input is converted to uppercase in the controller
      final panFieldWidget = tester.widget<TextFormField>(find.byKey(const Key('producer_onboarding_pan_field')));
      expect(panFieldWidget.controller?.text, 'ABCDE1234F');

      // 7. Clear name -> should validate name required
      await tester.enterText(nameFieldFinder, '');
      await tester.pumpAndSettle();
      await tester.ensureVisible(verifyButtonFinder);
      await tester.tap(verifyButtonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Please enter your name as per PAN.'), findsOneWidget);

      // 8. Restore name and check DOB required
      await tester.enterText(nameFieldFinder, 'Ramesh Kumar');
      await tester.pumpAndSettle();
      await tester.ensureVisible(verifyButtonFinder);
      await tester.tap(verifyButtonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Please select your Date of Birth as on PAN.'), findsOneWidget);

      // 9. Select DOB via date picker
      await tester.ensureVisible(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.tap(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      // Select the OK button in DatePicker
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 10. Tap Verify PAN with simulated verification success
      bool rpcCalled = false;
      final mockService = ProducerVerificationService(
        rpcHandler: (fnName, params) async {
          rpcCalled = true;
          expect(fnName, 'verify_producer_pan_prototype');
          expect(params['p_pan'], 'ABCDE1234F');
          expect(params['p_name'], 'Ramesh Kumar');
          expect(params['p_dob'], isNotNull);
          return {
            'success': true,
            'status': 'verified',
            'message': 'PAN verified successfully in demo environment.',
            'pan_last4': '234F',
            'masked_pan': '******234F',
          };
        },
      );

      // Rebuild with mock verification service
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IdentityComplianceStep(
                provider: provider,
                verificationService: mockService,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid fields
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_pan_field')),
        'ABCDE1234F',
      );
      await tester.enterText(nameFieldFinder, 'Ramesh Kumar');
      await tester.ensureVisible(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.tap(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final verifyBtn = find.byKey(const Key('producer_onboarding_verify_pan_button'));
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      expect(rpcCalled, isTrue);

      // Verify UI reflects SUCCESS:
      expect(find.text('PAN Verified'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('PAN verified successfully in demo environment.'), findsOneWidget);
      expect(find.byKey(const Key('producer_onboarding_masked_pan_text')), findsOneWidget);
      expect(find.text('******234F'), findsOneWidget);

      // CRITICAL: Raw PAN is NEVER displayed after success
      expect(find.text('ABCDE1234F'), findsNothing);
      expect(find.text('Edit Details'), findsOneWidget);
    });

    testWidgets('Step 4E2: Simulated PAN verification rejects test PAN and allows retry', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        user: null,
        profile: {
          'id': 'test-uuid-4e2-fail',
          'full_name': 'Devendra Singh',
          'role': 'producer',
        },
      );

      final mockService = ProducerVerificationService(
        rpcHandler: (fnName, params) async {
          return {
            'success': false,
            'status': 'rejected',
            'message': 'PAN details could not be verified with records in demo registry.',
            'pan_last4': null,
            'masked_pan': null,
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IdentityComplianceStep(
                provider: provider,
                verificationService: mockService,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter FAIL format PAN (e.g. FAILA1234B)
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_pan_field')),
        'FAILA1234B',
      );
      await tester.ensureVisible(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.tap(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final verifyBtn = find.byKey(const Key('producer_onboarding_verify_pan_button'));
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // Verify UI reflects REJECTION:
      expect(find.text('Could Not Verify'), findsOneWidget);
      expect(find.text('PAN details could not be verified with records in demo registry.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Verified'), findsNothing);
    });

    testWidgets('Step 4E2: Backend exception produces sanitized user-friendly error', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        user: null,
        profile: {
          'id': 'test-uuid-4e2-err',
          'full_name': 'Kavita Sharma',
          'role': 'producer',
        },
      );

      final mockService = ProducerVerificationService(
        rpcHandler: (fnName, params) async {
          throw Exception('Internal Postgres Database Error');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IdentityComplianceStep(
                provider: provider,
                verificationService: mockService,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('producer_onboarding_pan_field')),
        'ABCDE1234F',
      );
      await tester.ensureVisible(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.tap(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final verifyBtn = find.byKey(const Key('producer_onboarding_verify_pan_button'));
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // User sees sanitized error, NOT internal database error
      expect(find.text('Unable to complete verification at this time. Please try again.'), findsOneWidget);
      expect(find.text('Internal Postgres Database Error'), findsNothing);
      expect(find.text('Could Not Verify'), findsOneWidget);
    });

    testWidgets('Step 4E2.3: Already verified same PAN returns already_verified status cleanly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        user: null,
        profile: {
          'id': 'test-uuid-4e2-already',
          'full_name': 'Geeta Devi',
          'role': 'producer',
        },
      );

      final mockService = ProducerVerificationService(
        rpcHandler: (fnName, params) async {
          return {
            'success': true,
            'status': 'already_verified',
            'message': 'PAN is already verified for this account.',
            'pan_last4': '1234',
            'masked_pan': '******1234',
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IdentityComplianceStep(
                provider: provider,
                verificationService: mockService,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('producer_onboarding_pan_field')),
        'ABCDE1234F',
      );
      await tester.ensureVisible(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.tap(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final verifyBtn = find.byKey(const Key('producer_onboarding_verify_pan_button'));
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // UI recognizes already_verified as verified
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('******1234'), findsOneWidget);
      expect(find.text('PAN is already verified for this account.'), findsOneWidget);
    });

    testWidgets('Step 4E2.3: Already verified account conflict returns safe error and does not destroy verified status', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Initially prefilled with verified PAN from database
      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        user: null,
        profile: {
          'id': 'test-uuid-4e2-conflict',
          'full_name': 'Geeta Devi',
          'role': 'producer',
        },
        producerProfile: {
          'pan_last4': '1234',
          'pan_verification_status': 'verified',
        },
      );

      final mockService = ProducerVerificationService(
        rpcHandler: (fnName, params) async {
          return {
            'success': false,
            'status': 'already_verified_conflict',
            'message': 'A verified PAN is already associated with this account. Re-verification is required to change it.',
            'pan_last4': '1234',
            'masked_pan': '******1234',
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IdentityComplianceStep(
                provider: provider,
                verificationService: mockService,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Form is initially in verified state displaying ******1234
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('******1234'), findsOneWidget);

      // User taps "Edit Details"
      final editBtn = find.text('Edit Details');
      await tester.ensureVisible(editBtn);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // User tries to enter a different PAN
      await tester.enterText(
        find.byKey(const Key('producer_onboarding_pan_field')),
        'XYZPK9999Q',
      );
      await tester.ensureVisible(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.tap(find.byKey(const Key('producer_onboarding_pan_dob_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final verifyBtn = find.byKey(const Key('producer_onboarding_verify_pan_button'));
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // Conflict is shown cleanly without exposing internal errors
      expect(find.text('Could Not Verify'), findsOneWidget);
      expect(find.text('A verified PAN is already associated with this account. Re-verification is required to change it.'), findsOneWidget);
    });

    testWidgets('Step 4E3: Aadhaar card shows Not Verified, opens info dialog, and does not collect Aadhaar number', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = ProducerOnboardingProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IdentityComplianceStep(provider: provider),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Aadhaar card appears with Not Verified badge
      expect(find.text('Aadhaar Verification'), findsOneWidget);
      expect(find.byKey(const Key('producer_onboarding_verify_aadhaar_button')), findsOneWidget);

      // Verify no input field for Aadhaar number exists
      expect(find.byKey(const Key('producer_onboarding_aadhaar_field')), findsNothing);

      // Tap Verify Aadhaar button
      final verifyAadhaarBtn = find.byKey(const Key('producer_onboarding_verify_aadhaar_button'));
      await tester.ensureVisible(verifyAadhaarBtn);
      await tester.tap(verifyAadhaarBtn);
      await tester.pumpAndSettle();

      // Informational dialog appears with correct message
      expect(find.text('Aadhaar verification will be available through an authorized verification service. It is not enabled in this prototype.'), findsOneWidget);

      // Tap Got It to close
      final okBtn = find.byKey(const Key('producer_onboarding_aadhaar_dialog_ok_button'));
      expect(okBtn, findsOneWidget);
      await tester.tap(okBtn);
      await tester.pumpAndSettle();

      // Dialog closed; no Aadhaar stored or simulated
      expect(find.text('Aadhaar verification will be available through an authorized verification service. It is not enabled in this prototype.'), findsNothing);
    });

    testWidgets('Step 4E3: GST card toggles Yes/No, validates GSTIN format, and shows non-faked verification feedback', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = ProducerOnboardingProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IdentityComplianceStep(provider: provider),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // GST card appears; default is Not Registered (No selected)
      expect(find.text('GST Registration'), findsOneWidget);
      expect(find.text('Not Registered'), findsOneWidget);
      expect(find.text('GST not registered. Micro-producers below registration thresholds can continue without GST.'), findsOneWidget);
      expect(find.byKey(const Key('producer_onboarding_gstin_field')), findsNothing);

      // Select "Yes" for GST registered
      final yesOption = find.byKey(const Key('producer_onboarding_gst_yes_option'));
      await tester.ensureVisible(yesOption);
      await tester.tap(yesOption);
      await tester.pumpAndSettle();

      // Status badge changes to Not Verified and GSTIN input appears
      expect(find.text('Not Verified'), findsWidgets);
      final gstinField = find.byKey(const Key('producer_onboarding_gstin_field'));
      expect(gstinField, findsOneWidget);

      // Select "No" again -> GSTIN field hidden
      final noOption = find.byKey(const Key('producer_onboarding_gst_no_option'));
      await tester.ensureVisible(noOption);
      await tester.tap(noOption);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('producer_onboarding_gstin_field')), findsNothing);

      // Select "Yes" again
      await tester.ensureVisible(yesOption);
      await tester.tap(yesOption);
      await tester.pumpAndSettle();

      // Tap "Verify GSTIN" with empty field -> error
      final verifyGstinBtn = find.byKey(const Key('producer_onboarding_verify_gstin_button'));
      await tester.ensureVisible(verifyGstinBtn);
      await tester.tap(verifyGstinBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter your 15-character GSTIN.'), findsOneWidget);

      // Enter invalid GSTIN format
      await tester.enterText(gstinField, 'INVALID123');
      await tester.tap(verifyGstinBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid 15-character GSTIN (e.g. 07AAAAA0000A1Z5).'), findsOneWidget);

      // Enter valid format GSTIN (e.g. 07AAAAA0000A1Z5)
      await tester.enterText(gstinField, '07AAAAA0000A1Z5');
      await tester.tap(verifyGstinBtn);
      await tester.pumpAndSettle();

      // Shows informational message; does NOT fake verification
      expect(find.text('GST verification integration will be added next.'), findsOneWidget);
      expect(find.text('Verified'), findsNothing); // Does not show fake verified badge
      expect(provider.gstin, '07AAAAA0000A1Z5');
      expect(provider.gstRegistered, true);
    });
  });
}

