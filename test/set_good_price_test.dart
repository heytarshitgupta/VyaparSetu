/// VyaparSetu — Set a Good Price Widget Tests — V2
///
/// Tests the full V2 pricing integration:
/// - No product_id required
/// - Optional cost inputs
/// - V2 response fields (suggested_price, range, cost_floor, bulk_price, reason)
/// - Use This Price form state preservation
/// - API failure safe messaging
/// - Localization (EN/HI/PA)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/services/pricing_api_service.dart';
import 'package:buyer_section/producer_section/products/providers/add_product_provider.dart';
import 'package:buyer_section/producer_section/products/screens/add_product_screen.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Widget createTestWidget({
  required Widget child,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

PricingApiResponse _fakeResponse({
  double suggestedPrice = 418.0,
  double suggestedPriceLow = 250.0,
  double suggestedPriceHigh = 800.0,
  double? estimatedUnitCost,
  double? costFloor,
  double? bulkPrice = 355.0,
  String confidence = 'medium',
  String reason = 'Similar handmade products sell between ₹250 and ₹800.',
}) =>
    PricingApiResponse(
      suggestedPrice: suggestedPrice,
      suggestedPriceLow: suggestedPriceLow,
      suggestedPriceHigh: suggestedPriceHigh,
      estimatedUnitCost: estimatedUnitCost,
      costFloor: costFloor,
      bulkPrice: bulkPrice,
      confidence: confidence,
      reason: reason,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Set a Good Price — V2', () {
    // ── Case 1: Button always visible ───────────────────────────────────────
    testWidgets('1. Set a Good Price button is present', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: AddProductScreen(provider: AddProductProvider())),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('set_good_price_button')), findsOneWidget);
      expect(find.text('Set a Good Price'), findsOneWidget);
    });

    // ── Case 2: Missing category/description blocks request ─────────────────
    testWidgets('2. Missing category/description shows guidance', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: AddProductScreen(provider: AddProductProvider())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Add a product category and description'),
        findsOneWidget,
      );
    });

    // ── Case 3: V2 request WITHOUT product_id succeeds ──────────────────────
    testWidgets('3. V2 request without product_id succeeds', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');
      bool fetcherCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (req) async {
              fetcherCalled = true;
              expect(req.productId, isNull);
              expect(req.productName, isNotEmpty);
              expect(req.category, 'food');
              return _fakeResponse();
            },
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
      // Cost input sheet appeared; tap Get Price Suggestion without costs
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(fetcherCalled, isTrue);
    });

    // ── Case 4: V2 request WITH optional product_id ─────────────────────────
    testWidgets('4. V2 request with optional product_id passes it through', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');
      String? receivedProductId;

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingProfileId: 'PROD000010',
            pricingFetcher: (req) async {
              receivedProductId = req.productId;
              return _fakeResponse();
            },
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
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(receivedProductId, 'PROD000010');
    });

    // ── Case 5: Request with no cost fields ─────────────────────────────────
    testWidgets('5. Request with no cost fields sends null costs', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('handicraft');

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (req) async {
              expect(req.rawMaterialCost, isNull);
              expect(req.packagingCost, isNull);
              expect(req.laborCost, isNull);
              expect(req.otherCost, isNull);
              expect(req.productionQuantity, isNull);
              expect(req.desiredMarginPercent, isNull);
              return _fakeResponse();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Wooden tray',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();
    });

    // ── Case 6: Request with all cost fields ────────────────────────────────
    testWidgets('6. Request with all cost fields passes them to fetcher', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('handicraft');
      PricingRequestV2? capturedReq;

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (req) async {
              capturedReq = req;
              return _fakeResponse(
                estimatedUnitCost: 190,
                costFloor: 237.5,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Handmade candle',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();

      // Enter all cost fields
      await tester.enterText(find.byKey(const Key('pricing_raw_material_field')), '220');
      await tester.enterText(find.byKey(const Key('pricing_packaging_field')), '40');
      await tester.enterText(find.byKey(const Key('pricing_labour_field')), '100');
      await tester.enterText(find.byKey(const Key('pricing_other_cost_field')), '20');
      await tester.enterText(find.byKey(const Key('pricing_quantity_field')), '2');
      await tester.enterText(find.byKey(const Key('pricing_margin_field')), '25');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(capturedReq, isNotNull);
      expect(capturedReq!.rawMaterialCost, 220.0);
      expect(capturedReq!.packagingCost, 40.0);
      expect(capturedReq!.laborCost, 100.0);
      expect(capturedReq!.otherCost, 20.0);
      expect(capturedReq!.productionQuantity, 2.0);
      expect(capturedReq!.desiredMarginPercent, 25.0);
    });

    // ── Case 7: Response numeric parsing ────────────────────────────────────
    testWidgets('7. PricingApiResponse.fromJson parses int and double values safely', (_) async {
      final json = {
        'suggested_price': 418,       // int
        'suggested_price_low': 250.0, // double
        'suggested_price_high': 800,
        'market_typical_price': null,
        'estimated_unit_cost': null,
        'cost_floor': null,
        'bulk_price': 355.27,
        'confidence': 'medium',
        'reason': 'Test reason',
        'signals_used': ['text_similar_benchmark', 'ml_prediction'],
      };
      final r = PricingApiResponse.fromJson(json);
      expect(r.suggestedPrice, 418.0);
      expect(r.suggestedPriceLow, 250.0);
      expect(r.bulkPrice, closeTo(355.27, 0.01));
      expect(r.estimatedUnitCost, isNull);
      expect(r.costFloor, isNull);
      expect(r.signalsUsed, contains('ml_prediction'));
    });

    // ── Case 8: Suggested price renders prominently ─────────────────────────
    testWidgets('8. Suggested price is displayed', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (_) async => _fakeResponse(suggestedPrice: 418),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Jaggery block',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('₹418'), findsOneWidget);
    });

    // ── Case 9: Market range renders ────────────────────────────────────────
    testWidgets('9. Market range is displayed', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (_) async => _fakeResponse(
              suggestedPriceLow: 250,
              suggestedPriceHigh: 800,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Jaggery block',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Similar items sell for'), findsOneWidget);
      expect(find.textContaining('₹250'), findsWidgets);
      expect(find.textContaining('₹800'), findsWidgets);
    });

    // ── Case 10: Cost-to-make shown when present ────────────────────────────
    testWidgets('10. Cost to make shown when estimatedUnitCost is provided', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('handicraft');

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (_) async => _fakeResponse(
              estimatedUnitCost: 190,
              costFloor: 237,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Soy candle',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Cost to make'), findsOneWidget);
      expect(find.text('₹190'), findsOneWidget);
      expect(find.text('Minimum sustainable price'), findsOneWidget);
      expect(find.text('₹237'), findsOneWidget);
    });

    // ── Case 11: Cost section hidden when absent ─────────────────────────────
    testWidgets('11. Cost to make hidden when estimatedUnitCost is null', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (_) async => _fakeResponse(
              estimatedUnitCost: null,
              costFloor: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Jaggery block',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Cost to make'), findsNothing);
      expect(find.text('Minimum sustainable price'), findsNothing);
    });

    // ── Case 12: Reason text renders ────────────────────────────────────────
    testWidgets('12. Reason text is displayed', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');
      const testReason = 'Based on market comparables, ₹418 is balanced.';

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (_) async => _fakeResponse(reason: testReason),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Jaggery block',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Why this price?'), findsOneWidget);
      expect(find.text(testReason), findsOneWidget);
    });

    // ── Case 13: Loading state shown ────────────────────────────────────────
    testWidgets('13. Loading state shown during API call', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');

      // Use a completer to control when the fetcher resolves
      // so we can observe the loading state synchronously.
      final completer = Completer<PricingApiResponse?>();

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (_) => completer.future,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Jaggery block',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      // pump one frame to trigger the async call but not await it
      await tester.pump();

      // While fetching, the Set a Good Price button shows a loading spinner
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Resolve the completer so the test can clean up
      completer.complete(null);
      await tester.pumpAndSettle();
    });

    // ── Case 14: API failure shows safe message ──────────────────────────────
    testWidgets('14. API failure shows friendly message, not raw error', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (_) async {
              throw Exception('Connection refused to port 8001');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Jaggery block',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Price guidance is temporarily unavailable'),
        findsOneWidget,
      );
      expect(find.textContaining('port 8001'), findsNothing);
    });

    // ── Case 15: Add Product can open pricing before save ───────────────────
    testWidgets('15. Can open pricing before product is saved', (tester) async {
      final provider = AddProductProvider();
      // Deliberately not calling markReady() — product is unsaved
      provider.setCategory('clothing');

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (_) async => _fakeResponse(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Phulkari dupatta',
      );
      await tester.pumpAndSettle();

      // Tap pricing button — should NOT require product to be saved
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pricing_get_suggestion_button')), findsOneWidget);
    });

    // ── Case 16: Add Product values passed as prefill to request ────────────
    testWidgets('16. Add Product form values prefill the pricing request', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('clothing');
      PricingRequestV2? capturedReq;

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (req) async {
              capturedReq = req;
              return _fakeResponse();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('add_product_name_field')),
        'Phulkari Dupatta',
      );
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Hand embroidered traditional Punjabi dupatta',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(capturedReq?.category, 'clothing');
      expect(capturedReq?.description, contains('embroidered'));
    });

    // ── Case 17: Use This Price updates price field ──────────────────────────
    testWidgets('17. Use This Price fills price field and preserves other fields', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (_) async => _fakeResponse(suggestedPrice: 418),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('add_product_name_field')),
        'Desi Jaggery',
      );
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Pure organic jaggery',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('use_this_price_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('use_this_price_button')));
      await tester.pumpAndSettle();

      // Sheet closed
      expect(find.byKey(const Key('use_this_price_button')), findsNothing);

      // Price populated
      final priceField = tester.widget<TextFormField>(
        find.byKey(const Key('add_product_price_field')),
      );
      expect(priceField.controller?.text, '418');
      expect(provider.draft.pricePaise, 41800);

      // Other fields preserved
      final nameField = tester.widget<TextFormField>(
        find.byKey(const Key('add_product_name_field')),
      );
      expect(nameField.controller?.text, 'Desi Jaggery');

      final descField = tester.widget<TextFormField>(
        find.byKey(const Key('add_product_description_field')),
      );
      expect(descField.controller?.text, 'Pure organic jaggery');
      expect(provider.draft.category, 'food');
    });

    // ── Case 18: Blank optional costs accepted ───────────────────────────────
    testWidgets('18. Blank optional costs are accepted (not validated as errors)', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');
      bool fetcherCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (req) async {
              fetcherCalled = true;
              expect(req.rawMaterialCost, isNull);
              return _fakeResponse();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Organic honey',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();
      // Leave all cost fields blank
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(fetcherCalled, isTrue);
    });

    // ── Case 19: Invalid negative cost handled ───────────────────────────────
    testWidgets('19. Negative cost shows validation error', (tester) async {
      final provider = AddProductProvider();
      provider.setCategory('food');

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            pricingFetcher: (_) async => _fakeResponse(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('add_product_description_field')),
        'Organic honey',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set_good_price_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('pricing_raw_material_field')),
        '-50',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pricing_get_suggestion_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('cannot be negative'), findsOneWidget);
    });

    // ── Localization ─────────────────────────────────────────────────────────
    testWidgets('20. Hindi and Punjabi button labels render correctly', (tester) async {
      // Hindi
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('hi'),
          child: AddProductScreen(provider: AddProductProvider()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('अच्छी कीमत तय करें'), findsOneWidget);

      // Punjabi
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('pa'),
          child: AddProductScreen(provider: AddProductProvider()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ਵਧੀਆ ਕੀਮਤ ਤੈਅ ਕਰੋ'), findsOneWidget);
    });
  });
}
