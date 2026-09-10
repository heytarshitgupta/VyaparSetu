import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/localization/language_provider.dart';
import 'package:buyer_section/core/services/pricing_api_service.dart';
import 'package:buyer_section/core/theme/theme_provider.dart';
import 'package:buyer_section/producer_section/products/providers/add_product_provider.dart';
import 'package:buyer_section/producer_section/products/screens/add_product_screen.dart';

Widget createTestWidget({
  required Widget child,
  Locale locale = const Locale('en'),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Producer "Set a Good Price" Tests', () {
    testWidgets('A. "Set a Good Price" action is visible near price field', (tester) async {
      final provider = AddProductProvider();
      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('set_good_price_button'));
      expect(button, findsOneWidget);
      expect(find.text('Set a Good Price'), findsOneWidget);
    });

    testWidgets('B. Missing category/description blocks request safely with guidance', (tester) async {
      final provider = AddProductProvider();
      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Set a Good Price without entering category or description
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Add a product category and description first so we can suggest a price.'),
        findsOneWidget,
      );
    });

    testWidgets('B2. Safe reporting when no legitimate pricing profile ID is mapped', (tester) async {
      final provider = AddProductProvider();
      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Enter category and description
      provider.setCategory('food');
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Fresh handmade organic sweets',
      );
      await tester.pumpAndSettle();

      // Tap Set a Good Price with default unmapped profile ID
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Personalized price guidance is not available for this product yet.'),
        findsOneWidget,
      );
    });

    testWidgets('C & E. Valid response displays break-even floor, market ceiling, and suggested price', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');

      var fetcherCalled = false;
      Future<PricingApiResponse?> mockFetcher({
        required String productId,
        required String category,
        required String description,
      }) async {
        fetcherCalled = true;
        return PricingApiResponse(
          recommendedPrice: 150.0,
          breakEvenFloor: 100.0,
          marketCeiling: 200.0,
          aiGuidance: 'High demand in local markets; recommended markup is optimal.',
          pricingTier: 'B2C Retail Tier',
        );
      }

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingProfileId: 'PROD000010',
            pricingFetcher: mockFetcher,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Organic jaggery block',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();

      expect(fetcherCalled, isTrue);
      expect(find.text('Price Guidance'), findsOneWidget);
      expect(find.text('Cost to make'), findsOneWidget);
      expect(find.text('₹100'), findsOneWidget);
      expect(find.text('Similar market price'), findsOneWidget);
      expect(find.text('₹200'), findsOneWidget);
      expect(find.text('Suggested price'), findsOneWidget);
      expect(find.text('₹150'), findsOneWidget);
      expect(find.text('High demand in local markets; recommended markup is optimal.'), findsOneWidget);
      expect(
        find.text('Prototype guidance based on sample market data. Final price is your choice.'),
        findsOneWidget,
      );
    });

    testWidgets('D & H. API failure shows friendly fallback and no raw exception', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');

      Future<PricingApiResponse?> failingFetcher({
        required String productId,
        required String category,
        required String description,
      }) async {
        throw Exception('Network connection refused to port 8001');
      }

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingProfileId: 'PROD000010',
            pricingFetcher: failingFetcher,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Organic jaggery block',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();

      // Shows friendly fallback
      expect(
        find.text('Price guidance is temporarily unavailable. You can enter your price manually.'),
        findsOneWidget,
      );
      // No raw exception exposed
      expect(find.textContaining('Network connection refused'), findsNothing);
    });

    testWidgets('F & G. "Use This Price" fills price field and preserves other form data', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');

      Future<PricingApiResponse?> mockFetcher({
        required String productId,
        required String category,
        required String description,
      }) async {
        return PricingApiResponse(
          recommendedPrice: 180.0,
          breakEvenFloor: 120.0,
          marketCeiling: 220.0,
          aiGuidance: 'Balanced recommendation for local festivals.',
          pricingTier: 'B2C Retail Tier',
        );
      }

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingProfileId: 'PROD000010',
            pricingFetcher: mockFetcher,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter name & description
      await tester.enterText(
        find.byKey(const Key('add_product_name_field')),
        'Desi Gur Premium',
      );
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Pure desi organic jaggery',
      );
      await tester.pumpAndSettle();

      // Tap Set a Good Price
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('use_this_price_button')), findsOneWidget);

      // Tap "Use This Price"
      await tester.tap(find.byKey(const Key('use_this_price_button')));
      await tester.pumpAndSettle();

      // Bottom sheet closed
      expect(find.byKey(const Key('use_this_price_button')), findsNothing);

      // Price field populated with 180
      final priceFormField = tester.widget<TextFormField>(
        find.byKey(const Key('add_product_price_field')),
      );
      expect(priceFormField.controller?.text, '180');
      expect(provider.draft.pricePaise, 18000);

      // Other fields preserved
      final nameFormField = tester.widget<TextFormField>(
        find.byKey(const Key('add_product_name_field')),
      );
      expect(nameFormField.controller?.text, 'Desi Gur Premium');

      final descFormField = tester.widget<TextFormField>(
        find.byKey(const Key('add_product_description_field')),
      );
      expect(descFormField.controller?.text, 'Pure desi organic jaggery');
      expect(provider.draft.category, 'food');
    });

    testWidgets('I. Localized button labels in Hindi and Punjabi', (tester) async {
      // Test Hindi
      final providerHi = AddProductProvider();
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('hi'),
          child: AddProductScreen(provider: providerHi),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('अच्छी कीमत तय करें'), findsOneWidget);

      // Test Punjabi
      final providerPa = AddProductProvider();
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('pa'),
          child: AddProductScreen(provider: providerPa),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ਵਧੀਆ ਕੀਮਤ ਤੈਅ ਕਰੋ'), findsOneWidget);
    });
  });
}
