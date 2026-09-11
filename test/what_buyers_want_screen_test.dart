import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/producer_section/home/models/producer_home_models.dart';
import 'package:buyer_section/producer_section/home/models/producer_shell_profile.dart';
import 'package:buyer_section/producer_section/home/producer_main_screen.dart';
import 'package:buyer_section/producer_section/home/providers/producer_home_dashboard_provider.dart';
import 'package:buyer_section/producer_section/home/services/producer_home_service.dart';
import 'package:buyer_section/producer_section/home/tabs/what_buyers_want_screen.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';
import 'package:buyer_section/producer_section/products/providers/producer_products_provider.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_image_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

class FakeProducerHomeService implements IProducerHomeService {
  final ProducerOrdersSummary ordersSummaryToReturn;
  final List<ProducerBuyerNeedItem> buyerNeedsToReturn;
  final List<ProducerMarketSignalItem> marketSignalsToReturn;
  final bool shouldThrowOnSignals;
  int refreshCallCount = 0;

  FakeProducerHomeService({
    this.ordersSummaryToReturn = const ProducerOrdersSummary(
      completedSales: 45000,
      completedOrders: 6,
      pendingOrConfirmedOrders: 2,
      totalOrders: 8,
      cancelledOrders: 0,
    ),
    this.buyerNeedsToReturn = const [],
    this.marketSignalsToReturn = const [],
    this.shouldThrowOnSignals = false,
  });

  @override
  Future<ProducerOrdersSummary> fetchOrdersSummary() async => ordersSummaryToReturn;

  @override
  Future<List<ProducerBuyerNeedItem>> fetchActiveBuyerNeeds({
    List<String>? relevantCategories,
    String? state,
    String? district,
    int? limit,
  }) async =>
      buyerNeedsToReturn;

  @override
  Future<List<ProducerMarketSignalItem>> fetchMarketSignals({
    List<String>? relevantCategories,
    String? state,
    String? district,
    int? limit,
  }) async {
    refreshCallCount++;
    if (shouldThrowOnSignals) {
      throw const ProducerHomeOperationException('Network simulated failure');
    }
    return marketSignalsToReturn;
  }
}

class FakeProductService implements IProducerProductService {
  @override
  final IProducerProductImageService? imageService = null;

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async => [];

  @override
  Future<ProducerProduct> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteProduct(String productId) async {}

  @override
  Future<ProducerProduct> createDraft(ProducerProductDraft draft) async =>
      throw UnimplementedError();

  @override
  Future<ProducerProduct> updateDraft({
    required String productId,
    required ProducerProductDraft draft,
  }) async =>
      throw UnimplementedError();

  @override
  Future<ProducerProduct> updateProductImages({
    required String productId,
    required List<String> imagePaths,
  }) async =>
      throw UnimplementedError();
}

Widget _buildTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: themeMode,
    home: child,
  );
}

void main() {
  group('ProducerHomeService Market Signals BI Aggregation (Offline)', () {
    test('3. multiple requests aggregate by category and 4. request count correct', () async {
      final service = ProducerHomeService(
        buyerRequestsFetcher: () async => [
          {
            'category': 'handicrafts',
            'product_name': 'Brass Bell',
            'quantity': 10,
            'unit': 'piece',
            'target_price': 500,
            'urgency': 'normal',
            'state': 'Rajasthan',
            'district': 'Jaipur',
          },
          {
            'category': 'handicrafts',
            'product_name': 'Wooden Box',
            'quantity': 20,
            'unit': 'piece',
            'target_price': 800,
            'urgency': 'high',
            'state': 'Rajasthan',
            'district': 'Jodhpur',
          },
          {
            'category': 'candles',
            'product_name': 'Scented Candle',
            'quantity': 50,
            'unit': 'piece',
            'target_price': 150,
            'urgency': 'normal',
            'state': 'Delhi',
            'district': 'New Delhi',
          },
        ],
      );

      final signals = await service.fetchMarketSignals();
      expect(signals.length, 2);

      final handicraftSignal = signals.firstWhere((s) => s.category == 'handicraft');
      expect(handicraftSignal.activeRequestCount, 2);

      final candleSignal = signals.firstWhere((s) => s.category == 'candles');
      expect(candleSignal.activeRequestCount, 1);
    });

    test('5. same-unit quantity total correct', () async {
      final service = ProducerHomeService(
        buyerRequestsFetcher: () async => [
          {'category': 'pottery', 'quantity': 15, 'unit': 'piece'},
          {'category': 'pottery', 'quantity': 35, 'unit': 'piece'},
        ],
      );

      final signals = await service.fetchMarketSignals();
      final pottery = signals.firstWhere((s) => s.category == 'pottery');
      expect(pottery.totalRequestedQuantity, 50.0);
      expect(pottery.representativeUnit, 'piece');
    });

    test('6. mixed units do not produce misleading total', () async {
      final service = ProducerHomeService(
        buyerRequestsFetcher: () async => [
          {'category': 'honey', 'quantity': 50, 'unit': 'kg'},
          {'category': 'honey', 'quantity': 200, 'unit': 'bottle'},
        ],
      );

      final signals = await service.fetchMarketSignals();
      final honey = signals.firstWhere((s) => s.category == 'honey');
      expect(honey.totalRequestedQuantity, isNull);
      expect(honey.representativeUnit, isNull);
    });

    test('7. min target price, 8. max target price, 9. average target price correct', () async {
      final service = ProducerHomeService(
        buyerRequestsFetcher: () async => [
          {'category': 'spices', 'target_price': 200.0},
          {'category': 'spices', 'target_price': 500.0},
          {'category': 'spices', 'target_price': 350.0},
        ],
      );

      final signals = await service.fetchMarketSignals();
      final spices = signals.firstWhere((s) => s.category == 'spices');
      expect(spices.minTargetPrice, 200.0);
      expect(spices.maxTargetPrice, 500.0);
      expect(spices.averageTargetPrice, 350.0);
    });

    test('10. null target prices handled gracefully without crash', () async {
      final service = ProducerHomeService(
        buyerRequestsFetcher: () async => [
          {'category': 'textiles', 'target_price': null},
          {'category': 'textiles', 'target_price': null},
        ],
      );

      final signals = await service.fetchMarketSignals();
      final textiles = signals.firstWhere((s) => s.category == 'clothing');
      expect(textiles.minTargetPrice, isNull);
      expect(textiles.maxTargetPrice, isNull);
      expect(textiles.averageTargetPrice, isNull);
    });

    test('11. top state and 12. top district correct with producer relevance', () async {
      final service = ProducerHomeService(
        buyerRequestsFetcher: () async => [
          {'category': 'woodcraft', 'state': 'Punjab', 'district': 'Amritsar'},
          {'category': 'woodcraft', 'state': 'Delhi', 'district': 'Central Delhi'},
          {'category': 'woodcraft', 'state': 'Punjab', 'district': 'Amritsar'},
        ],
      );

      final signals = await service.fetchMarketSignals(state: 'Punjab', district: 'Amritsar');
      final woodcraft = signals.firstWhere((s) => s.category == 'woodcraft');
      expect(woodcraft.topState, 'Punjab');
      expect(woodcraft.topDistrict, 'Amritsar');
    });

    test('13. urgency count correct', () async {
      final service = ProducerHomeService(
        buyerRequestsFetcher: () async => [
          {'category': 'metalcraft', 'urgency': 'high'},
          {'category': 'metalcraft', 'urgency': 'high'},
          {'category': 'metalcraft', 'urgency': 'normal'},
        ],
      );

      final signals = await service.fetchMarketSignals();
      final metalcraft = signals.firstWhere((s) => s.category == 'metalcraft');
      expect(metalcraft.highUrgencyCount, 2);
    });

    test('14. existing category expansion works for craft categories', () async {
      final service = ProducerHomeService(
        buyerRequestsFetcher: () async => [
          {'category': 'apparel', 'quantity': 10, 'unit': 'piece'},
        ],
      );

      final signals = await service.fetchMarketSignals(
        relevantCategories: ['clothing_textiles'],
      );
      expect(signals.any((s) => s.category == 'clothing'), isTrue);
    });

    test('15. unseen category does not crash and gets deterministic metrics', () async {
      final service = ProducerHomeService(
        buyerRequestsFetcher: () async => [
          {
            'category': 'artisanal_soap',
            'product_name': 'Lavender Bar',
            'quantity': 40,
            'unit': 'bar',
            'target_price': 120,
            'urgency': 'high',
            'state': 'Goa',
            'district': 'North Goa',
          },
        ],
      );

      final signals = await service.fetchMarketSignals();
      final soap = signals.firstWhere((s) => s.category == 'artisanal soap');
      expect(soap.title, 'Artisanal Soap');
      expect(soap.activeRequestCount, 1);
      expect(soap.totalRequestedQuantity, 40.0);
      expect(soap.representativeUnit, 'bar');
      expect(soap.minTargetPrice, 120.0);
      expect(soap.highUrgencyCount, 1);
      expect(soap.topState, 'Goa');
      expect(soap.topDistrict, 'North Goa');
    });
  });

  group('WhatBuyersWantScreen UI & Provider Integration Tests', () {
    testWidgets('1. What Buyers Want uses live provider data', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final liveSignals = [
        const ProducerMarketSignalItem(
          category: 'handicraft',
          title: 'Handicraft',
          level: MarketDemandLevel.high,
          activeRequestCount: 5,
          totalRequestedQuantity: 250,
          representativeUnit: 'pieces',
          minTargetPrice: 400,
          maxTargetPrice: 850,
          averageTargetPrice: 625,
          topState: 'Rajasthan',
          topDistrict: 'Jaipur',
          highUrgencyCount: 2,
        ),
      ];

      final fakeService = FakeProducerHomeService(marketSignalsToReturn: liveSignals);
      final provider = ProducerHomeDashboardProvider(service: fakeService);
      await provider.loadDashboard();

      await tester.pumpWidget(
        _buildTestApp(
          child: WhatBuyersWantScreen(
            dashboardProvider: provider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check category and metrics rendered from provider data
      expect(find.text('Handicraft'), findsOneWidget);
      expect(find.text('5 requests'), findsOneWidget);
      expect(find.text('250 pieces'), findsOneWidget);
      expect(find.text('₹400 – ₹850'), findsOneWidget);
      expect(find.text('Jaipur, Rajasthan'), findsOneWidget);
      expect(find.text('2 urgent'), findsOneWidget);
      expect(find.text('High interest'), findsOneWidget);

      // Verify no numerical relevance score is rendered
      expect(find.textContaining('relevanceScore'), findsNothing);
      expect(find.textContaining('/100'), findsNothing);
    });

    testWidgets('2. hardcoded csvSeedSignals are not used in normal runtime', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeProducerHomeService(
        marketSignalsToReturn: [
          const ProducerMarketSignalItem(
            category: 'woodcraft',
            title: 'Woodcraft',
            level: MarketDemandLevel.growing,
            activeRequestCount: 2,
          ),
        ],
      );
      final provider = ProducerHomeDashboardProvider(service: fakeService);
      await provider.loadDashboard();

      await tester.pumpWidget(
        _buildTestApp(
          child: WhatBuyersWantScreen(
            dashboardProvider: provider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify old hardcoded CSV seed data is NOT rendered
      expect(find.text('Basmati (Rice)'), findsNothing);
      expect(find.text('Sample market insights'), findsNothing);
      expect(find.textContaining('CSV-backed'), findsNothing);
      expect(find.textContaining('products.csv'), findsNothing);
      expect(find.text('Woodcraft'), findsOneWidget);
    });

    testWidgets('16. empty state renders clean user message', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeProducerHomeService(marketSignalsToReturn: []);
      final provider = ProducerHomeDashboardProvider(service: fakeService);
      await provider.loadDashboard();

      await tester.pumpWidget(
        _buildTestApp(
          child: WhatBuyersWantScreen(
            dashboardProvider: provider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No active buyer demand found right now. Check again later.'),
        findsOneWidget,
      );
    });

    testWidgets('17. error state renders clean message and retry button', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeProducerHomeService(shouldThrowOnSignals: true);
      final provider = ProducerHomeDashboardProvider(service: fakeService);
      await provider.loadDashboard();

      await tester.pumpWidget(
        _buildTestApp(
          child: WhatBuyersWantScreen(
            dashboardProvider: provider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("We couldn't load market demand right now."), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Verify Supabase technical exception is not exposed
      expect(find.textContaining('ProducerHomeOperationException'), findsNothing);
      expect(find.textContaining('Network simulated failure'), findsNothing);
    });

    testWidgets('18. refresh invokes provider refresh', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeProducerHomeService(
        marketSignalsToReturn: [
          const ProducerMarketSignalItem(
            category: 'pottery',
            title: 'Pottery',
            level: MarketDemandLevel.steady,
            activeRequestCount: 1,
          ),
        ],
      );
      final provider = ProducerHomeDashboardProvider(service: fakeService);
      await provider.loadDashboard();
      expect(fakeService.refreshCallCount, 1);

      await tester.pumpWidget(
        _buildTestApp(
          child: WhatBuyersWantScreen(
            dashboardProvider: provider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap AppBar refresh button
      final refreshIcon = find.byIcon(Icons.refresh).first;
      await tester.tap(refreshIcon);
      await tester.pumpAndSettle();

      expect(fakeService.refreshCallCount, 2);
    });

    testWidgets('Mixed units display Multiple unit types instead of misleading number', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final signals = [
        const ProducerMarketSignalItem(
          category: 'honey',
          title: 'Honey',
          level: MarketDemandLevel.growing,
          activeRequestCount: 3,
          totalRequestedQuantity: null,
          representativeUnit: null,
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: WhatBuyersWantScreen(
            signals: signals,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Multiple unit types'), findsOneWidget);
    });

    testWidgets('19. EN localization renders correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('en'),
          child: const WhatBuyersWantScreen(
            signals: [
              ProducerMarketSignalItem(
                category: 'handicraft',
                title: 'Handicraft',
                level: MarketDemandLevel.high,
                activeRequestCount: 4,
                totalRequestedQuantity: 100,
                representativeUnit: 'pieces',
                minTargetPrice: 500,
                maxTargetPrice: 700,
                topState: 'Punjab',
                topDistrict: 'Amritsar',
                highUrgencyCount: 1,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('What Buyers Want'), findsOneWidget);
      expect(find.text('See real-time demand and buyer requests across regions.'), findsOneWidget);
      expect(find.text('Active buyer needs'), findsOneWidget);
      expect(find.text('Quantity wanted'), findsOneWidget);
      expect(find.text('Buyer price range'), findsOneWidget);
      expect(find.text('Where buyers are'), findsOneWidget);
      expect(find.text('High interest'), findsOneWidget);
      expect(find.text('1 urgent'), findsOneWidget);
    });

    testWidgets('20. HI localization renders Devanagari correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('hi'),
          child: const WhatBuyersWantScreen(
            signals: [
              ProducerMarketSignalItem(
                category: 'handicraft',
                title: 'Handicraft',
                level: MarketDemandLevel.high,
                activeRequestCount: 4,
                totalRequestedQuantity: 100,
                representativeUnit: 'pieces',
                minTargetPrice: 500,
                maxTargetPrice: 700,
                topState: 'Punjab',
                topDistrict: 'Amritsar',
                highUrgencyCount: 1,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('खरीदार क्या चाहते हैं'), findsOneWidget);
      expect(find.text('सक्रिय खरीदार ज़रूरतें'), findsOneWidget);
      expect(find.text('वांछित मात्रा'), findsOneWidget);
      expect(find.text('खरीदार मूल्य सीमा'), findsOneWidget);
      expect(find.text('खरीदार कहाँ से हैं'), findsOneWidget);
      expect(find.text('उच्च रुचि'), findsOneWidget);
      expect(find.text('1 अति आवश्यक'), findsOneWidget);
    });

    testWidgets('21. PA localization renders Gurmukhi correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('pa'),
          child: const WhatBuyersWantScreen(
            signals: [
              ProducerMarketSignalItem(
                category: 'handicraft',
                title: 'Handicraft',
                level: MarketDemandLevel.high,
                activeRequestCount: 4,
                totalRequestedQuantity: 100,
                representativeUnit: 'pieces',
                minTargetPrice: 500,
                maxTargetPrice: 700,
                topState: 'Punjab',
                topDistrict: 'Amritsar',
                highUrgencyCount: 1,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ਖਰੀਦਦਾਰ ਕੀ ਚਾਹੁੰਦੇ ਹਨ'), findsOneWidget);
      expect(find.text('ਸਰਗਰਮ ਖਰੀਦਦਾਰ ਲੋੜਾਂ'), findsOneWidget);
      expect(find.text('ਲੋੜੀਂਦੀ ਮਾਤਰਾ'), findsOneWidget);
      expect(find.text('ਖਰੀਦਦਾਰ ਕੀਮਤ ਸੀਮਾ'), findsOneWidget);
      expect(find.text('ਖਰੀਦਦਾਰ ਕਿੱਥੋਂ ਹਨ'), findsOneWidget);
      expect(find.text('ਉੱਚ ਦਿਲਚਸਪੀ'), findsOneWidget);
      expect(find.text('1 ਜ਼ਰੂਰੀ'), findsOneWidget);
    });

    testWidgets('Home navigation shortcut opens WhatBuyersWantScreen with live provider', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeProducerHomeService(
        marketSignalsToReturn: [
          const ProducerMarketSignalItem(
            category: 'handicrafts',
            title: 'Handicrafts',
            level: MarketDemandLevel.high,
            activeRequestCount: 4,
          ),
        ],
      );
      final fakeProdService = FakeProductService();
      final productsProvider = ProducerProductsProvider(service: fakeProdService);

      await tester.pumpWidget(
        _buildTestApp(
          child: ProducerMainScreen(
            homeService: fakeService,
            productsProvider: productsProvider,
            productService: fakeProdService,
            initialProfile: const ProducerShellProfile(
              businessName: 'Sharma Crafts',
              craftCategory: 'handicrafts',
              district: 'Amritsar',
              state: 'Punjab',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find "What Buyers Want" card on Home tab
      final shortcut = find.text('What Buyers Want');
      expect(shortcut, findsOneWidget);
      await tester.tap(shortcut);
      await tester.pumpAndSettle();

      // Verify WhatBuyersWantScreen is displayed
      expect(find.byType(WhatBuyersWantScreen), findsOneWidget);
      expect(find.text('Handicrafts'), findsOneWidget);
    });
  });
}
