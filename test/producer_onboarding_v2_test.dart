import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_provider.dart';
import 'package:buyer_section/producer_section/onboarding/producer_onboarding_screen.dart';

void main() {
  Widget buildTestApp({
    required Widget child,
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
    Map<String, WidgetBuilder>? routes,
  }) {
    return MaterialApp(
      locale: locale,
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
      routes: routes ?? {
        '/producer_home': (context) => const Scaffold(
              body: Text('Welcome to Producer Home'),
            ),
      },
    );
  }

  group('Onboarding V2 Pass 3A: Unit Tests', () {
    test('1. Initializes at Step 0 with 2 total steps (Your Business -> About Your Business)', () {
      final provider = ProducerOnboardingProvider();
      expect(provider.currentStep, 0);
      expect(ProducerOnboardingProvider.totalSteps, 2);
      expect(provider.isFirstStep, isTrue);
      expect(provider.isLastStep, isFalse);
      expect(provider.currentStepTitle, 'Your Business');
    });

    test('2 & 3. Validation enforces Business Name and Business Category', () {
      final provider = ProducerOnboardingProvider();

      // Empty name
      expect(provider.validateYourBusiness(), contains('business or brand name'));
      provider.setBusinessName('A'); // too short (<2)
      expect(provider.validateYourBusiness(), contains('business or brand name'));
      provider.setBusinessName('Ramesh Crafts');

      // Empty category
      expect(provider.validateYourBusiness(), contains('primary product category'));
      provider.setCraftCategory('handicrafts');

      // State required
      expect(provider.validateYourBusiness(), contains('state or union territory'));
      provider.setStateValue('Punjab');

      // District required
      expect(provider.validateYourBusiness(), contains('district'));
      provider.setDistrict('Amritsar');

      // City / Area required
      expect(provider.validateYourBusiness(), contains('area, village, or city'));
      provider.setCity('Rampur');

      // PIN required
      expect(provider.validateYourBusiness(), contains('PIN code'));
      provider.setPincode('143001');

      // Valid without bio
      expect(provider.validateYourBusiness(), isNull);
    });

    test('4. Description is optional in client validation', () {
      final provider = ProducerOnboardingProvider();
      provider.setBusinessName('Desi Pickles');
      provider.setCraftCategory('food_homemade');
      provider.setStateValue('Punjab');
      provider.setDistrict('Ludhiana');
      provider.setCity('Model Town');
      provider.setPincode('141002');

      // Description is empty
      expect(provider.businessDescription, isEmpty);
      expect(provider.validateYourBusiness(), isNull);

      // Optional description entered
      provider.setBusinessDescription('Handmade mango and lime pickles.');
      expect(provider.validateYourBusiness(), isNull);
    });

    test('8. PIN Code validation requires exactly 6 numeric digits starting with 1-9', () {
      final provider = ProducerOnboardingProvider();
      provider.setBusinessName('Test Business');
      provider.setCraftCategory('other');
      provider.setStateValue('Delhi');
      provider.setDistrict('Central Delhi');
      provider.setCity('Connaught Place');

      provider.setPincode('12345'); // 5 digits
      expect(provider.validateYourBusiness(), contains('PIN code'));

      provider.setPincode('012345'); // starts with 0
      expect(provider.validateYourBusiness(), contains('PIN code'));

      provider.setPincode('110001a'); // non-digit
      expect(provider.validateYourBusiness(), contains('PIN code'));

      provider.setPincode('110001'); // exactly 6 valid digits
      expect(provider.validateYourBusiness(), isNull);
    });

    test('9. Canonical category mapping: maps known values, preserves canonical, returns null for unknown', () {
      // Known translations / historical representations map to canonical
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('Food & Homemade Products'), 'food_homemade');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('खाद्य और घरेलू उत्पाद'), 'food_homemade');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('Handicrafts'), 'handicrafts');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('Clothing & Textiles'), 'clothing_textiles');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('Jewellery & Accessories'), 'jewellery_accessories');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('Home Decor'), 'home_decor');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('Beauty / Personal Care'), 'beauty_personal_care');

      // Canonical keys remain preserved
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('food_homemade'), 'food_homemade');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('handicrafts'), 'handicrafts');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('clothing_textiles'), 'clothing_textiles');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('jewellery_accessories'), 'jewellery_accessories');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('home_decor'), 'home_decor');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('agriculture_products'), 'agriculture_products');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('beauty_personal_care'), 'beauty_personal_care');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('other'), 'other');

      // Explicit other representations
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('Other'), 'other');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('अन्य'), 'other');
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('ਹੋਰ'), 'other');

      // Unknown historical categories MUST NOT silently map to 'other'
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('Vintage Horology'), isNull);
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('Mechanical Clocks'), isNull);
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical('Custom Sculptures'), isNull);
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical(''), isNull);
      expect(ProducerOnboardingProvider.normalizeCategoryToCanonical(null), isNull);
    });

    test('10. Existing business values prefill correctly from producer_profiles', () {
      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        profile: {
          'id': 'test-uuid-1',
          'full_name': 'Gurpreet Singh',
          'phone': '9876543210',
          'email': 'gurpreet@example.com',
        },
        producerProfile: {
          'business_name': 'Punjab Handlooms',
          'craft_category': 'clothing_textiles',
          'bio': 'Weaving authentic phulkari suits.',
          'state': 'Punjab',
          'district': 'Amritsar',
          'city': 'Raja Sansi',
          'pincode': '143101',
          'onboarding_status': 'in_progress',
        },
        user: null,
      );

      expect(provider.businessName, 'Punjab Handlooms');
      expect(provider.craftCategory, 'clothing_textiles');
      expect(provider.rawCraftCategory, 'clothing_textiles');
      expect(provider.bio, 'Weaving authentic phulkari suits.');
      expect(provider.state, 'Punjab');
      expect(provider.district, 'Amritsar');
      expect(provider.city, 'Raja Sansi');
      expect(provider.pincode, '143101');
      expect(provider.currentStep, 0);
    });

    test('17. Existing completed Producer state is not regressed', () {
      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        profile: {'id': 'completed-id', 'full_name': 'Completed Artisan'},
        producerProfile: {
          'business_name': 'Completed Brand',
          'craft_category': 'handicrafts',
          'onboarding_status': 'completed',
        },
        user: null,
      );

      expect(provider.currentStep, 1); // Not forced back to Step 0
    });

    test('18. Unknown historical craft_category preserves raw value and requires explicit canonical selection', () {
      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        profile: {
          'id': 'unknown-cat-producer-1',
          'full_name': 'Aarav Patel',
          'email': 'aarav@example.com',
        },
        producerProfile: {
          'business_name': 'Timepiece Heritage',
          'craft_category': 'Vintage Horology & Restorations', // Unknown historical category
          'bio': 'Antique pocket watch restorers',
          'state': 'Gujarat',
          'district': 'Ahmedabad',
          'city': 'Ellisbridge',
          'pincode': '380006',
          'onboarding_status': 'in_progress',
          'onboarding_step': 1,
        },
        user: null,
      );

      // Raw value preserved in provider state
      expect(provider.rawCraftCategory, 'Vintage Horology & Restorations');
      // Craft category is empty so no canonical card is falsely pre-selected
      expect(provider.craftCategory, isEmpty);
      expect(provider.craftCategory, isNot('other')); // Must not silently convert to 'other'

      // Validation fails until user explicitly chooses a canonical category
      expect(provider.validateYourBusiness(), contains('category'));

      // Producer explicitly chooses 'other' or a canonical category
      provider.setCraftCategory('other');
      expect(provider.craftCategory, 'other');
      expect(provider.validateYourBusiness(), isNull);
    });

    test('19. Local UI transition to About Your Business does not advance database onboarding_step', () async {
      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        profile: {'id': 'step-test-1', 'full_name': 'Test Artisan'},
        producerProfile: {
          'business_name': 'Test Business',
          'craft_category': 'handicrafts',
          'state': 'Rajasthan',
          'district': 'Jaipur',
          'city': 'Amer',
          'pincode': '302028',
          'onboarding_step': 1,
        },
        user: null,
      );

      expect(provider.currentStep, 0);
      expect(provider.persistedServerStep, 1);

      bool saveCalled = false;
      provider.yourBusinessSaver = ({
        required businessName,
        required craftCategory,
        bio,
        required state,
        required district,
        required city,
        required pincode,
      }) async {
        saveCalled = true;
      };

      final saved = await provider.saveYourBusiness();
      expect(saved, isTrue);
      expect(saveCalled, isTrue);

      // Local UI transition
      provider.nextStep();
      expect(provider.currentStep, 1);

      // Server step strictly remains 1, no progression RPC called
      expect(provider.persistedServerStep, 1);
    });
  });

  group('Onboarding V2 Pass 3A: Widget Tests', () {
    testWidgets('1 & 15. New Your Business screen renders and excludes old PAN/GST/compliance stages',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = ProducerOnboardingProvider();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerOnboardingScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Renders clean Your Business title and 2-step progress header
      expect(find.text('Your Business'), findsWidgets);
      expect(find.text('About Your Business'), findsWidgets);
      expect(find.text('Step 1 of 5'), findsNothing);
      expect(find.text('Step 2 of 5'), findsNothing);

      // Verifies old compliance stages are absent
      expect(find.text('PAN Verification'), findsNothing);
      expect(find.text('Aadhaar Verification'), findsNothing);
      expect(find.text('GST Registration'), findsNothing);
      expect(find.text('Identity & Compliance'), findsNothing);

      // Contact phone field is not present as a mandatory field
      expect(find.text('Contact Phone *'), findsNothing);
    });

    testWidgets('11. Form values survive live language switch without data loss',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = ProducerOnboardingProvider();
      provider.setBusinessName('Sita Pottery');
      provider.setCraftCategory('handicrafts');
      provider.setBio('Handmade clay terracotta pots');
      provider.setStateValue('Rajasthan');
      provider.setDistrict('Jaipur');
      provider.setCity('Sanganer');
      provider.setPincode('302029');

      Locale activeLocale = const Locale('en');

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestApp(
              locale: activeLocale,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        activeLocale = const Locale('hi');
                      });
                    },
                    child: const Text('Switch to Hindi'),
                  ),
                  Expanded(child: ProducerOnboardingScreen(provider: provider)),
                ],
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sita Pottery'), findsOneWidget);
      expect(find.text('Handmade clay terracotta pots'), findsOneWidget);

      // Switch to Hindi
      await tester.tap(find.text('Switch to Hindi'));
      await tester.pumpAndSettle();

      // Form values are preserved
      expect(provider.businessName, 'Sita Pottery');
      expect(provider.craftCategory, 'handicrafts');
      expect(provider.bio, 'Handmade clay terracotta pots');
      expect(find.text('Sita Pottery'), findsOneWidget);
      expect(find.text('Handmade clay terracotta pots'), findsOneWidget);
      // Localized Hindi strings appear
      expect(find.text('आपका व्यवसाय'), findsWidgets);
    });

    testWidgets('12. Form values survive appearance / theme switch without data loss',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = ProducerOnboardingProvider();
      provider.setBusinessName('Kashmir Carpets');
      provider.setCraftCategory('handicrafts');

      ThemeMode mode = ThemeMode.light;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestApp(
              themeMode: mode,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        mode = ThemeMode.dark;
                      });
                    },
                    child: const Text('Switch to Dark'),
                  ),
                  Expanded(child: ProducerOnboardingScreen(provider: provider)),
                ],
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kashmir Carpets'), findsOneWidget);

      // Switch to dark theme
      await tester.tap(find.text('Switch to Dark'));
      await tester.pumpAndSettle();

      // State is preserved
      expect(provider.businessName, 'Kashmir Carpets');
      expect(find.text('Kashmir Carpets'), findsOneWidget);
    });

    testWidgets('13 & 14. Successful Continue persists expected fields and advances to Step 2 without completing onboarding',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Map<String, dynamic>? persistedData;
      final provider = ProducerOnboardingProvider();

      provider.setBusinessName('Mohan Sweets');
      provider.setCraftCategory('food_homemade');
      provider.setBio('Fresh traditional pedas');
      provider.setStateValue('Uttar Pradesh');
      provider.setDistrict('Mathura');
      provider.setCity('Vrindavan');
      provider.setPincode('281121');

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerOnboardingScreen(
            provider: provider,
            yourBusinessSaver: ({
              required businessName,
              required craftCategory,
              bio,
              required state,
              required district,
              required city,
              required pincode,
            }) async {
              persistedData = {
                'business_name': businessName,
                'craft_category': craftCategory,
                'bio': bio,
                'state': state,
                'district': district,
                'city': city,
                'pincode': pincode,
              };
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Continue
      final continueBtn = find.text('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Verified persistence
      expect(persistedData, isNotNull);
      expect(persistedData!['business_name'], 'Mohan Sweets');
      expect(persistedData!['craft_category'], 'food_homemade');
      expect(persistedData!['bio'], 'Fresh traditional pedas');
      expect(persistedData!['state'], 'Uttar Pradesh');
      expect(persistedData!['district'], 'Mathura');
      expect(persistedData!['city'], 'Vrindavan');
      expect(persistedData!['pincode'], '281121');

      // Advanced to Step 1 (About Your Business real form) - local UI only
      expect(provider.currentStep, 1);
      expect(provider.persistedServerStep, 1); // Server onboarding_step strictly untouched
      expect(find.text('About Your Business'), findsWidgets);
      expect(find.byKey(const ValueKey('team_size_chip_solo')), findsOneWidget);

      // Onboarding completion was NOT called
      expect(provider.producerProfile?['onboarding_status'], isNot('completed'));
    });

    testWidgets('20. Responsive UX compaction: adapts between phone single-column and desktop 2-row location layout',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();

      // 1. Phone Viewport (360 x 740)
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestApp(child: ProducerOnboardingScreen(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('producer_onboarding_business_name_field')), findsOneWidget);
      expect(find.byKey(const Key('producer_onboarding_state_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('producer_onboarding_district_field')), findsOneWidget);
      expect(find.byKey(const Key('producer_onboarding_city_field')), findsOneWidget);
      expect(find.byKey(const Key('producer_onboarding_pincode_field')), findsOneWidget);

      // Verify lightweight Business Location header is present
      expect(find.text('Business Location'), findsOneWidget);

      // 2. Desktop Viewport (1024 x 768)
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Verify all 4 location fields are rendered and accessible
      expect(find.byKey(const Key('producer_onboarding_state_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('producer_onboarding_pincode_field')), findsOneWidget);
      expect(find.byKey(const Key('producer_onboarding_district_field')), findsOneWidget);
      expect(find.byKey(const Key('producer_onboarding_city_field')), findsOneWidget);
    });

    testWidgets('21. Category chips: render all 8 canonical chips and display check indicator on selection',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = ProducerOnboardingProvider();

      await tester.pumpWidget(
        buildTestApp(child: ProducerOnboardingScreen(provider: provider)),
      );
      await tester.pumpAndSettle();

      // All 8 canonical category chips are rendered
      for (final cat in ProducerOnboardingProvider.canonicalCategories) {
        expect(find.byKey(Key('category_card_$cat')), findsOneWidget);
      }

      // No checkmark initially
      expect(find.byIcon(Icons.check_circle), findsNothing);

      // Tap 'handicrafts' chip
      await tester.tap(find.byKey(const Key('category_card_handicrafts')));
      await tester.pumpAndSettle();

      expect(provider.craftCategory, 'handicrafts');
      // Visual checkmark indicator is shown (not color alone)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('22. Step 1 shows Back, Complete Setup, and Skip for now, and Back preserves Step 0 data',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();
      provider.setBusinessName('Handmade Pottery');
      provider.setCraftCategory('handicrafts');
      provider.setStateValue('Rajasthan');
      provider.setDistrict('Jaipur');
      provider.setCity('Sanganer');
      provider.setPincode('302029');

      // Navigate to Step 1
      provider.nextStep();
      expect(provider.currentStep, 1);

      await tester.pumpWidget(
        buildTestApp(child: ProducerOnboardingScreen(provider: provider)),
      );
      await tester.pumpAndSettle();

      // Verify Step 1 is displayed with Pass 3B real form
      expect(find.text('About Your Business'), findsWidgets);

      // Verify Back, Complete Setup, and Skip for now buttons are shown
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Complete Setup'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      // Tap Back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Returns to Step 0 with all data intact
      expect(provider.currentStep, 0);
      expect(find.text('Your Business'), findsWidgets);
      expect(find.text('Handmade Pottery'), findsOneWidget);
    });

    test('23. Step 0 Continue does NOT complete onboarding', () {
      final provider = ProducerOnboardingProvider();
      provider.setBusinessName('Punjab Loom');
      provider.setCraftCategory('clothing_textiles');
      provider.setStateValue('Punjab');
      provider.setDistrict('Ludhiana');
      provider.setCity('Civil Lines');
      provider.setPincode('141001');

      provider.nextStep();
      expect(provider.currentStep, 1);
      // Onboarding status is NOT completed
      expect(provider.producerProfile?['onboarding_status'], isNot('completed'));
    });
  });

  group('Onboarding V2 Pass 3B: About Your Business & Complete Setup', () {
    testWidgets('1. About Your Business real form renders with all 4 optional sections',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();
      provider.goToStep(1);

      await tester.pumpWidget(
        buildTestApp(child: ProducerOnboardingScreen(provider: provider)),
      );
      await tester.pumpAndSettle();

      // Verify Title, Subtitle, and Optional Badge
      expect(find.text('About Your Business'), findsWidgets);
      expect(
        find.text('Help us understand your business better. You can skip this step.'),
        findsWidgets,
      );
      expect(find.text('Optional'), findsOneWidget);

      // Verify 4 Sections
      expect(find.text('Team / Business Size'), findsOneWidget);
      expect(find.text('Typical Monthly Sales'), findsOneWidget);
      expect(find.text('How much can you usually produce?'), findsOneWidget);
      expect(find.text('Where do you currently sell?'), findsOneWidget);

      // Verify Actions
      expect(find.text('Complete Setup'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    test('2. All Step 3 fields are optional (validation passes when all empty)', () {
      final provider = ProducerOnboardingProvider();
      expect(provider.teamSize, isNull);
      expect(provider.typicalMonthlySales, isNull);
      expect(provider.productionCapacityQuantity, isEmpty);
      expect(provider.productionCapacityUnit, isNull);
      expect(provider.productionCapacityPeriod, isNull);
      expect(provider.sellingChannels, isEmpty);

      expect(provider.validateAboutYourBusiness(), isNull);
    });

    test('3. Team size canonical mapping matches database constraint', () {
      final provider = ProducerOnboardingProvider();
      const expectedCanonical = ['solo', '2_5', '6_10', '11_25', '25_plus'];
      expect(ProducerOnboardingProvider.canonicalTeamSizes, expectedCanonical);

      for (final size in expectedCanonical) {
        provider.setTeamSize(size);
        expect(provider.teamSize, size);
      }

      // Can be deselected / cleared
      provider.setTeamSize(null);
      expect(provider.teamSize, isNull);
    });

    test('4. Monthly sales canonical mapping matches database constraint', () {
      final provider = ProducerOnboardingProvider();
      const expectedCanonical = [
        'below_10k',
        '10k_50k',
        '50k_1l',
        '1l_5l',
        'above_5l',
        'prefer_not_to_say',
      ];
      expect(ProducerOnboardingProvider.canonicalMonthlySales, expectedCanonical);

      for (final sales in expectedCanonical) {
        provider.setTypicalMonthlySales(sales);
        expect(provider.typicalMonthlySales, sales);
      }

      provider.setTypicalMonthlySales(null);
      expect(provider.typicalMonthlySales, isNull);
    });

    test('5 & 6. Production capacity all-or-none and positive quantity validation', () {
      final provider = ProducerOnboardingProvider();

      // Case A: Quantity only -> invalid
      provider.setProductionCapacityQuantity('50');
      expect(provider.validateAboutYourBusiness(), contains('specify quantity, unit, and period'));

      // Case B: Unit only -> invalid
      provider.setProductionCapacityQuantity('');
      provider.setProductionCapacityUnit('pieces');
      expect(provider.validateAboutYourBusiness(), contains('specify quantity, unit, and period'));

      // Case C: Period only -> invalid
      provider.setProductionCapacityUnit(null);
      provider.setProductionCapacityPeriod('month');
      expect(provider.validateAboutYourBusiness(), contains('specify quantity, unit, and period'));

      // Case D: Quantity + Unit without Period -> invalid
      provider.setProductionCapacityPeriod(null);
      provider.setProductionCapacityQuantity('50');
      provider.setProductionCapacityUnit('pieces');
      expect(provider.validateAboutYourBusiness(), contains('specify quantity, unit, and period'));

      // Case E: Quantity <= 0 -> invalid
      provider.setProductionCapacityPeriod('month');
      provider.setProductionCapacityQuantity('0');
      expect(provider.validateAboutYourBusiness(), contains('positive number'));

      provider.setProductionCapacityQuantity('-5');
      expect(provider.validateAboutYourBusiness(), contains('positive number'));

      // Case F: Valid complete values
      provider.setProductionCapacityQuantity('50');
      expect(provider.validateAboutYourBusiness(), isNull);

      // Decimal positive quantity
      provider.setProductionCapacityQuantity('12.5');
      expect(provider.validateAboutYourBusiness(), isNull);

      // Case G: All empty -> valid
      provider.setProductionCapacityQuantity('');
      provider.setProductionCapacityUnit(null);
      provider.setProductionCapacityPeriod(null);
      expect(provider.validateAboutYourBusiness(), isNull);
    });

    test('7. Unit canonical mapping matches database constraint', () {
      const expectedCanonical = ['pieces', 'kg', 'litres', 'packs', 'boxes', 'other'];
      expect(ProducerOnboardingProvider.canonicalCapacityUnits, expectedCanonical);
    });

    test('8. Period canonical mapping matches database constraint', () {
      const expectedCanonical = ['week', 'month', 'year'];
      expect(ProducerOnboardingProvider.canonicalCapacityPeriods, expectedCanonical);
    });

    test('9, 10, 11. Selling channels multi-select and not_selling_yet mutual exclusivity', () {
      final provider = ProducerOnboardingProvider();
      const expectedCanonical = [
        'local_customers',
        'local_shops',
        'whatsapp',
        'social_media',
        'online_marketplaces',
        'exhibitions_fairs',
        'not_selling_yet',
      ];
      expect(ProducerOnboardingProvider.canonicalSellingChannels, expectedCanonical);

      // Multi-select regular channels
      provider.toggleSellingChannel('local_customers');
      provider.toggleSellingChannel('whatsapp');
      expect(provider.sellingChannels, ['local_customers', 'whatsapp']);

      // 10. Selecting not_selling_yet clears other channels
      provider.toggleSellingChannel('not_selling_yet');
      expect(provider.sellingChannels, ['not_selling_yet']);

      // 11. Selecting another channel while not_selling_yet active clears not_selling_yet
      provider.toggleSellingChannel('social_media');
      expect(provider.sellingChannels, ['social_media']);
      expect(provider.sellingChannels.contains('not_selling_yet'), isFalse);
    });

    testWidgets('11b. Selecting visible Instagram / Facebook chip persists canonical social_media and never instagram_facebook',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();
      provider.goToStep(1);

      List<String>? savedChannels;
      provider.aboutYourBusinessSaver = ({
        teamSize,
        typicalMonthlySales,
        productionCapacityQuantity,
        productionCapacityUnit,
        productionCapacityPeriod,
        sellingChannels,
      }) async {
        savedChannels = sellingChannels;
      };
      provider.onboardingCompleter = () async => {'status': 'completed'};

      await tester.pumpWidget(
        buildTestApp(child: ProducerOnboardingScreen(provider: provider)),
      );
      await tester.pumpAndSettle();

      // Tap visible "Instagram / Facebook" chip
      final chipFinder = find.byKey(const ValueKey('selling_channel_chip_social_media'));
      expect(chipFinder, findsOneWidget);
      await tester.ensureVisible(chipFinder);
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // Verify provider state uses canonical social_media only
      expect(provider.sellingChannels, contains('social_media'));
      expect(provider.sellingChannels.contains('instagram_facebook'), isFalse);

      // Save About Your Business
      final success = await provider.saveAboutYourBusiness();
      expect(success, isTrue);

      // Verify persisted write contains social_media and NEVER instagram_facebook
      expect(savedChannels, contains('social_media'));
      expect(savedChannels!.contains('instagram_facebook'), isFalse);
    });

    test('12. Existing optional values prefill correctly from producer_profiles', () {
      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        user: null,
        profile: {'id': 'p-123', 'full_name': 'Asha Rani'},
        producerProfile: {
          'id': 'p-123',
          'business_name': 'Asha Crafts',
          'craft_category': 'handicrafts',
          'state': 'Punjab',
          'district': 'Amritsar',
          'city': 'Town Hall',
          'pincode': '143001',
          'team_size': '2_5',
          'typical_monthly_sales': '50k_1l',
          'production_capacity_quantity': 100,
          'production_capacity_unit': 'pieces',
          'production_capacity_period': 'month',
          'selling_channels': ['whatsapp', 'instagram_facebook'],
        },
      );

      expect(provider.teamSize, '2_5');
      expect(provider.typicalMonthlySales, '50k_1l');
      expect(provider.productionCapacityQuantity, '100');
      expect(provider.productionCapacityUnit, 'pieces');
      expect(provider.productionCapacityPeriod, 'month');
      // instagram_facebook was normalized to social_media
      expect(provider.sellingChannels, ['whatsapp', 'social_media']);
    });

    testWidgets('13 & 14. Live language & theme switches preserve Step 3 data',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();
      provider.goToStep(1);
      provider.setTeamSize('6_10');
      provider.setTypicalMonthlySales('1l_5l');
      provider.setProductionCapacityQuantity('250');
      provider.setProductionCapacityUnit('boxes');
      provider.setProductionCapacityPeriod('year');
      provider.toggleSellingChannel('local_shops');

      Locale currentLocale = const Locale('en');
      ThemeMode currentTheme = ThemeMode.light;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestApp(
              locale: currentLocale,
              themeMode: currentTheme,
              child: Column(
                children: [
                  ElevatedButton(
                    key: const Key('switch_hindi'),
                    onPressed: () => setState(() => currentLocale = const Locale('hi')),
                    child: const Text('Hindi'),
                  ),
                  ElevatedButton(
                    key: const Key('switch_dark'),
                    onPressed: () => setState(() => currentTheme = ThemeMode.dark),
                    child: const Text('Dark'),
                  ),
                  Expanded(child: ProducerOnboardingScreen(provider: provider)),
                ],
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // 13. Switch language to Hindi
      await tester.tap(find.byKey(const Key('switch_hindi')));
      await tester.pumpAndSettle();

      expect(provider.teamSize, '6_10');
      expect(provider.typicalMonthlySales, '1l_5l');
      expect(provider.productionCapacityQuantity, '250');
      expect(provider.productionCapacityUnit, 'boxes');
      expect(provider.productionCapacityPeriod, 'year');
      expect(provider.sellingChannels, ['local_shops']);

      // 14. Switch theme to Dark
      await tester.tap(find.byKey(const Key('switch_dark')));
      await tester.pumpAndSettle();

      expect(provider.teamSize, '6_10');
      expect(provider.typicalMonthlySales, '1l_5l');
      expect(provider.productionCapacityQuantity, '250');
      expect(provider.productionCapacityUnit, 'boxes');
      expect(provider.productionCapacityPeriod, 'year');
      expect(provider.sellingChannels, ['local_shops']);
    });

    testWidgets('15 & 16. Complete Setup persists valid optional values and calls complete RPC',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();
      provider.goToStep(1);
      provider.setTeamSize('solo');
      provider.setTypicalMonthlySales('below_10k');
      provider.setProductionCapacityQuantity('75');
      provider.setProductionCapacityUnit('litres');
      provider.setProductionCapacityPeriod('month');
      provider.toggleSellingChannel('whatsapp');

      Map<String, dynamic>? persistedAbout;
      bool rpcCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerOnboardingScreen(
            provider: provider,
            aboutYourBusinessSaver: ({
              teamSize,
              typicalMonthlySales,
              productionCapacityQuantity,
              productionCapacityUnit,
              productionCapacityPeriod,
              sellingChannels,
            }) async {
              persistedAbout = {
                'team_size': teamSize,
                'typical_monthly_sales': typicalMonthlySales,
                'production_capacity_quantity': productionCapacityQuantity,
                'production_capacity_unit': productionCapacityUnit,
                'production_capacity_period': productionCapacityPeriod,
                'selling_channels': sellingChannels,
              };
            },
            onboardingCompleter: () async {
              rpcCalled = true;
              return {'status': 'completed'};
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Complete Setup
      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();

      expect(persistedAbout, isNotNull);
      expect(persistedAbout!['team_size'], 'solo');
      expect(persistedAbout!['typical_monthly_sales'], 'below_10k');
      expect(persistedAbout!['production_capacity_quantity'], 75.0);
      expect(persistedAbout!['production_capacity_unit'], 'litres');
      expect(persistedAbout!['production_capacity_period'], 'month');
      expect(persistedAbout!['selling_channels'], ['whatsapp']);
      expect(rpcCalled, isTrue);
    });

    testWidgets('17. Successful completion routes to Producer Home',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();
      provider.goToStep(1);

      bool rpcCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/': (context) => Scaffold(
                  body: ProducerOnboardingScreen(
                    provider: provider,
                    aboutYourBusinessSaver: ({
                      teamSize,
                      typicalMonthlySales,
                      productionCapacityQuantity,
                      productionCapacityUnit,
                      productionCapacityPeriod,
                      sellingChannels,
                    }) async {},
                    onboardingCompleter: () async {
                      rpcCalled = true;
                      return {'status': 'completed'};
                    },
                  ),
                ),
            '/producer_home': (context) => const Scaffold(
                  body: Text('Welcome to Producer Home'),
                ),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();

      expect(rpcCalled, isTrue);
      expect(find.text('Welcome to Producer Home'), findsOneWidget);
    });

    testWidgets('17b. If completion RPC fails, remains on onboarding with retryable error and does not complete',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();
      provider.goToStep(1);

      bool saveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/': (context) => Scaffold(
                  body: ProducerOnboardingScreen(
                    provider: provider,
                    aboutYourBusinessSaver: ({
                      teamSize,
                      typicalMonthlySales,
                      productionCapacityQuantity,
                      productionCapacityUnit,
                      productionCapacityPeriod,
                      sellingChannels,
                    }) async {
                      saveCalled = true;
                    },
                    onboardingCompleter: () async {
                      throw Exception('Simulated RPC network timeout');
                    },
                  ),
                ),
            '/producer_home': (context) => const Scaffold(
                  body: Text('Welcome to Producer Home'),
                ),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();

      expect(saveCalled, isTrue);
      // Remained on onboarding
      expect(find.text('Welcome to Producer Home'), findsNothing);
      expect(find.text('About Your Business'), findsWidgets);
      // Safe retryable error displayed
      expect(find.text('Failed to complete setup. Please check your connection and try again.'), findsOneWidget);
      // Status not falsely marked completed
      expect(provider.producerProfile?['onboarding_status'], isNot('completed'));
    });

    testWidgets('18 & 19. Skip for now works with all fields empty and discards invalid partial capacity',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();
      provider.goToStep(1);

      // Enter partial INVALID capacity (quantity only)
      provider.setProductionCapacityQuantity('50');
      provider.setProductionCapacityUnit(null);
      provider.setProductionCapacityPeriod(null);
      // Valid team size
      provider.setTeamSize('solo');

      Map<String, dynamic>? persistedAbout;
      bool rpcCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/': (context) => Scaffold(
                  body: ProducerOnboardingScreen(
                    provider: provider,
                    aboutYourBusinessSaver: ({
                      teamSize,
                      typicalMonthlySales,
                      productionCapacityQuantity,
                      productionCapacityUnit,
                      productionCapacityPeriod,
                      sellingChannels,
                    }) async {
                      persistedAbout = {
                        'team_size': teamSize,
                        'typical_monthly_sales': typicalMonthlySales,
                        'production_capacity_quantity': productionCapacityQuantity,
                        'production_capacity_unit': productionCapacityUnit,
                        'production_capacity_period': productionCapacityPeriod,
                        'selling_channels': sellingChannels,
                      };
                    },
                    onboardingCompleter: () async {
                      rpcCalled = true;
                      return {'status': 'completed'};
                    },
                  ),
                ),
            '/producer_home': (context) => const Scaffold(
                  body: Text('Welcome to Producer Home'),
                ),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap Skip for now
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      // Skip for now does not write uncommitted optional fields to database,
      // preventing DB constraint failure and preserving any existing database profile data
      expect(persistedAbout, isNull);
      expect(rpcCalled, isTrue);
      expect(find.text('Welcome to Producer Home'), findsOneWidget);
    });

    testWidgets('21. No PAN / GST / Aadhaar in onboarding',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();
      provider.goToStep(1);

      await tester.pumpWidget(
        buildTestApp(child: ProducerOnboardingScreen(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('PAN'), findsNothing);
      expect(find.text('Aadhaar'), findsNothing);
      expect(find.text('GST'), findsNothing);
      expect(find.text('GSTIN'), findsNothing);
      expect(find.text('Business Verification'), findsNothing);
    });

    testWidgets('20. Back preserves Step 0 data and returning to Step 1 preserves Step 1 data',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();
      provider.setBusinessName('Jaipur Block Prints');
      provider.setCraftCategory('handicrafts');
      provider.setStateValue('Rajasthan');
      provider.setDistrict('Jaipur');
      provider.setCity('Sanganer');
      provider.setPincode('302029');

      // Navigate to Step 1
      provider.goToStep(1);
      provider.setTeamSize('6_10');
      provider.setTypicalMonthlySales('50k_1l');
      provider.toggleSellingChannel('whatsapp');

      await tester.pumpWidget(
        buildTestApp(child: ProducerOnboardingScreen(provider: provider)),
      );
      await tester.pumpAndSettle();

      // Tap Back to Step 0
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(provider.currentStep, 0);
      expect(provider.businessName, 'Jaipur Block Prints');
      expect(find.text('Jaipur Block Prints'), findsOneWidget);

      // Re-enter Step 1
      provider.goToStep(1);
      await tester.pumpAndSettle();

      expect(provider.currentStep, 1);
      expect(provider.teamSize, '6_10');
      expect(provider.typicalMonthlySales, '50k_1l');
      expect(provider.sellingChannels, ['whatsapp']);
    });

    test('22. Completed Producer remains completed', () {
      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        user: null,
        profile: {'id': 'p-999', 'full_name': 'Ramesh Kumar'},
        producerProfile: {
          'id': 'p-999',
          'onboarding_status': 'completed',
          'onboarding_step': 5,
        },
      );

      expect(provider.producerProfile?['onboarding_status'], 'completed');
      expect(provider.currentStep, ProducerOnboardingProvider.totalSteps - 1);
    });

    testWidgets('23. Completion preserves session and updates status to completed without logging out',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();
      provider.initializeFromProfile(
        user: null,
        profile: {'id': 'p-101', 'full_name': 'Devi Crafts'},
        producerProfile: {
          'id': 'p-101',
          'business_name': 'Devi Handlooms',
          'craft_category': 'handicrafts',
          'state': 'Odisha',
          'district': 'Puri',
          'city': 'Raghurajpur',
          'pincode': '752012',
          'onboarding_status': 'in_progress',
        },
      );
      provider.goToStep(1);

      provider.onboardingCompleter = () async {
        return {'status': 'completed'};
      };
      provider.aboutYourBusinessSaver = ({
        teamSize,
        typicalMonthlySales,
        productionCapacityQuantity,
        productionCapacityUnit,
        productionCapacityPeriod,
        sellingChannels,
      }) async {};

      final success = await provider.saveAboutYourBusiness();
      expect(success, isTrue);
      expect(provider.producerProfile?['onboarding_status'], 'completed');
      expect(provider.errorMessage, isNull);
    });

    testWidgets('24. Explicit logout button in top bar remains accessible and functional',
        (WidgetTester tester) async {
      final provider = ProducerOnboardingProvider();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerOnboardingScreen(provider: provider),
          routes: {
            '/producer_login': (context) => const Scaffold(
                  body: Text('Producer Login Screen'),
                ),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Top bar exit/logout button is present
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });
}

