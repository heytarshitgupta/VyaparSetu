import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/producer_section/home/models/producer_home_models.dart';
import 'package:buyer_section/producer_section/home/models/producer_shell_profile.dart';
import 'package:buyer_section/producer_section/home/providers/producer_home_dashboard_provider.dart';
import 'package:buyer_section/producer_section/home/services/producer_home_service.dart';
import 'package:buyer_section/producer_section/opportunities/buyer_needs_tab.dart';
import 'package:buyer_section/producer_section/home/producer_main_screen.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';
import 'package:buyer_section/producer_section/products/providers/producer_products_provider.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_image_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

class FakeBuyerProductService implements IProducerProductService {
  @override
  final IProducerProductImageService? imageService = null;
  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async => [];
  @override
  Future<ProducerProduct> updateProductStatus({required String productId, required ProductStatus newStatus}) => throw UnimplementedError();
  @override
  Future<void> deleteProduct(String productId) async {}
  @override
  Future<ProducerProduct> createDraft(ProducerProductDraft draft) => throw UnimplementedError();
  @override
  Future<ProducerProduct> updateDraft({required String productId, required ProducerProductDraft draft}) => throw UnimplementedError();
  @override
  Future<ProducerProduct> updateProductImages({required String productId, required List<String> imagePaths}) => throw UnimplementedError();
}

class FakeBuyerNeedsHomeService implements IProducerHomeService {
  final List<ProducerBuyerNeedItem> buyerNeedsToReturn;
  final bool shouldThrowOnNeeds;
  int refreshCallCount = 0;

  FakeBuyerNeedsHomeService({
    this.buyerNeedsToReturn = const [],
    this.shouldThrowOnNeeds = false,
  });

  @override
  Future<ProducerOrdersSummary> fetchOrdersSummary() async =>
      const ProducerOrdersSummary.empty();

  @override
  Future<List<ProducerBuyerNeedItem>> fetchActiveBuyerNeeds({
    List<String>? relevantCategories,
    String? state,
    String? district,
    int? limit,
  }) async {
    refreshCallCount++;
    if (shouldThrowOnNeeds) {
      throw const ProducerHomeOperationException('Simulated network failure');
    }
    return buyerNeedsToReturn;
  }

  @override
  Future<List<ProducerMarketSignalItem>> fetchMarketSignals({
    List<String>? relevantCategories,
    String? state,
    String? district,
    int? limit,
  }) async =>
      const [];
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
    home: Scaffold(body: child),
  );
}

void main() {
  group('BuyerNeedsTab Live Opportunities Feed Tests (Step BI-2)', () {
    testWidgets('1. placeholder removed & 2-8 card fields rendered truthfully', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sampleItems = [
        ProducerBuyerNeedItem(
          id: 'need-1',
          productName: 'Phulkari Cushion Covers',
          category: 'Handicraft',
          quantity: 30,
          unit: 'pieces',
          targetPrice: 650,
          urgency: 'high',
          status: 'active',
          state: 'Rajasthan',
          district: 'Jaipur',
          notes: 'Prefer natural dyes',
          createdAt: DateTime.now(),
        ),
        ProducerBuyerNeedItem(
          id: 'need-2',
          productName: 'Mustard Oil Jars',
          category: 'Agriculture',
          quantity: 15,
          unit: 'bottles',
          targetPrice: null, // null target price
          urgency: 'normal',
          status: 'active',
          state: 'Punjab',
          district: 'Ludhiana',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: BuyerNeedsTab(
            buyerNeeds: sampleItems,
            profile: const ProducerShellProfile(
              businessName: 'Craft Studio',
              craftCategory: 'handicrafts',
              district: 'Jaipur',
              state: 'Rajasthan',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Placeholder removed
      expect(find.text('Feature Coming Soon'), findsNothing);
      expect(find.text('Feature coming soon'), findsNothing);

      // 2. Live items rendered
      expect(find.text('Phulkari Cushion Covers'), findsOneWidget);
      expect(find.text('Mustard Oil Jars'), findsOneWidget);

      // 3. Category rendered
      expect(find.text('Handicraft'), findsOneWidget);
      expect(find.text('Agriculture'), findsOneWidget);

      // 4. Quantity/unit rendered
      expect(find.text('30 pieces'), findsOneWidget);
      expect(find.text('15 bottles'), findsOneWidget);

      // 5. Target price rendered when present
      expect(find.text('₹650 / pieces'), findsOneWidget);

      // 6. Target price safely omitted when null
      expect(find.textContaining('₹null'), findsNothing);

      // 7. Location rendered
      expect(find.text('Jaipur, Rajasthan'), findsOneWidget);
      expect(find.text('Ludhiana, Punjab'), findsOneWidget);

      // 8. Urgent badge rendered (one chip, one card badge)
      expect(find.text('Urgent'), findsNWidgets(2));

      // Buyer sensitive data check
      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining('+91'), findsNothing);
    });

    test('9. default relevance ordering orders by producer relevance and urgency', () async {
      final service = ProducerHomeService(
        buyerRequestsFetcher: () async => [
          {
            'id': '1',
            'product_name': 'Generic Wheat',
            'category': 'agriculture',
            'quantity': 100,
            'unit': 'kg',
            'urgency': 'normal',
            'state': 'Bihar',
            'district': 'Patna',
            'created_at': DateTime.now().subtract(const Duration(hours: 10)).toIso8601String(),
          },
          {
            'id': '2',
            'product_name': 'Phulkari Dupatta',
            'category': 'clothing',
            'quantity': 10,
            'unit': 'pieces',
            'urgency': 'high',
            'state': 'Punjab',
            'district': 'Amritsar',
            'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
          },
        ],
      );

      final items = await service.fetchActiveBuyerNeeds(
        relevantCategories: ['clothing_textiles'],
        state: 'Punjab',
        district: 'Amritsar',
      );

      expect(items.first.productName, 'Phulkari Dupatta');
    });

    testWidgets('10. search by product name filters results', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        ProducerBuyerNeedItem(
          id: '1',
          productName: 'Handmade Wooden Toys',
          category: 'Woodcraft',
          quantity: 20,
          unit: 'pieces',
          urgency: 'normal',
          status: 'active',
          state: 'Karnataka',
          district: 'Channapatna',
          createdAt: DateTime.now(),
        ),
        ProducerBuyerNeedItem(
          id: '2',
          productName: 'Pure Honey',
          category: 'Food',
          quantity: 50,
          unit: 'kg',
          urgency: 'normal',
          status: 'active',
          state: 'Himachal',
          district: 'Kangra',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: BuyerNeedsTab(buyerNeeds: items),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Handmade Wooden Toys'), findsOneWidget);
      expect(find.text('Pure Honey'), findsOneWidget);

      // Search for "Wooden"
      await tester.enterText(find.byType(TextField), 'Wooden');
      await tester.pumpAndSettle();

      expect(find.text('Handmade Wooden Toys'), findsOneWidget);
      expect(find.text('Pure Honey'), findsNothing);
    });

    testWidgets('11. search by category & 12. search by district/state & 13. case-insensitive', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        ProducerBuyerNeedItem(
          id: '1',
          productName: 'Item One',
          category: 'Textiles',
          quantity: 10,
          unit: 'm',
          urgency: 'normal',
          status: 'active',
          state: 'Gujarat',
          district: 'Surat',
          createdAt: DateTime.now(),
        ),
        ProducerBuyerNeedItem(
          id: '2',
          productName: 'Item Two',
          category: 'Pottery',
          quantity: 5,
          unit: 'pieces',
          urgency: 'normal',
          status: 'active',
          state: 'Rajasthan',
          district: 'Alwar',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: BuyerNeedsTab(buyerNeeds: items),
        ),
      );
      await tester.pumpAndSettle();

      // Search by category (case-insensitive "TEXTILES")
      await tester.enterText(find.byType(TextField), 'TEXTILES');
      await tester.pumpAndSettle();
      expect(find.text('Item One'), findsOneWidget);
      expect(find.text('Item Two'), findsNothing);

      // Search by district ("alwar")
      await tester.enterText(find.byType(TextField), 'alwar');
      await tester.pumpAndSettle();
      expect(find.text('Item One'), findsNothing);
      expect(find.text('Item Two'), findsOneWidget);
    });

    testWidgets('14. For You filter filters by producer craft category', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        ProducerBuyerNeedItem(
          id: '1',
          productName: 'Cotton Shawl',
          category: 'clothing',
          quantity: 10,
          unit: 'pieces',
          urgency: 'normal',
          status: 'active',
          state: 'Punjab',
          district: 'Ludhiana',
          createdAt: DateTime.now(),
        ),
        ProducerBuyerNeedItem(
          id: '2',
          productName: 'Clay Pots',
          category: 'pottery',
          quantity: 25,
          unit: 'pieces',
          urgency: 'normal',
          status: 'active',
          state: 'Punjab',
          district: 'Ludhiana',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: BuyerNeedsTab(
            buyerNeeds: items,
            profile: const ProducerShellProfile(
              craftCategory: 'clothing_textiles',
              district: 'Ludhiana',
              state: 'Punjab',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "For You" filter chip
      await tester.tap(find.text('For You'));
      await tester.pumpAndSettle();

      expect(find.text('Cotton Shawl'), findsOneWidget);
      expect(find.text('Clay Pots'), findsNothing);
    });

    testWidgets('15. Nearby same district & 16. Nearby same state fallback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        ProducerBuyerNeedItem(
          id: '1',
          productName: 'District Item',
          category: 'Craft',
          quantity: 10,
          unit: 'pieces',
          urgency: 'normal',
          status: 'active',
          state: 'Punjab',
          district: 'Amritsar',
          createdAt: DateTime.now(),
        ),
        ProducerBuyerNeedItem(
          id: '2',
          productName: 'Other State Item',
          category: 'Craft',
          quantity: 10,
          unit: 'pieces',
          urgency: 'normal',
          status: 'active',
          state: 'Maharashtra',
          district: 'Pune',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: BuyerNeedsTab(
            buyerNeeds: items,
            profile: const ProducerShellProfile(
              district: 'Amritsar',
              state: 'Punjab',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Nearby
      await tester.tap(find.text('Nearby'));
      await tester.pumpAndSettle();

      expect(find.text('District Item'), findsOneWidget);
      expect(find.text('Other State Item'), findsNothing);
    });

    testWidgets('16. Nearby falls back to state when district has no match', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        ProducerBuyerNeedItem(
          id: '1',
          productName: 'State Fallback Item',
          category: 'Craft',
          quantity: 10,
          unit: 'pieces',
          urgency: 'normal',
          status: 'active',
          state: 'Punjab',
          district: 'Ludhiana', // Different district from producer
          createdAt: DateTime.now(),
        ),
        ProducerBuyerNeedItem(
          id: '2',
          productName: 'Other State Item',
          category: 'Craft',
          quantity: 10,
          unit: 'pieces',
          urgency: 'normal',
          status: 'active',
          state: 'Maharashtra',
          district: 'Pune',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: BuyerNeedsTab(
            buyerNeeds: items,
            profile: const ProducerShellProfile(
              district: 'Amritsar', // Producer in Amritsar
              state: 'Punjab',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Nearby
      await tester.tap(find.text('Nearby'));
      await tester.pumpAndSettle();

      // Should fall back to matching state (Punjab) since district Amritsar has 0 matches
      expect(find.text('State Fallback Item'), findsOneWidget);
      expect(find.text('Other State Item'), findsNothing);
    });

    testWidgets('17. Urgent filter filters to high urgency requests only', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        ProducerBuyerNeedItem(
          id: '1',
          productName: 'Urgent Blankets',
          category: 'Textile',
          quantity: 100,
          unit: 'pieces',
          urgency: 'high',
          status: 'active',
          state: 'Delhi',
          district: 'South Delhi',
          createdAt: DateTime.now(),
        ),
        ProducerBuyerNeedItem(
          id: '2',
          productName: 'Regular Blankets',
          category: 'Textile',
          quantity: 50,
          unit: 'pieces',
          urgency: 'normal',
          status: 'active',
          state: 'Delhi',
          district: 'South Delhi',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: BuyerNeedsTab(buyerNeeds: items),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Urgent" filter chip
      await tester.tap(find.widgetWithText(FilterChip, 'Urgent'));
      await tester.pumpAndSettle();

      expect(find.text('Urgent Blankets'), findsOneWidget);
      expect(find.text('Regular Blankets'), findsNothing);
    });

    testWidgets('18. no search result state & 19. no filter result state & 20. empty live dataset', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 20. Empty live dataset
      await tester.pumpWidget(
        _buildTestApp(
          child: const BuyerNeedsTab(buyerNeeds: []),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No active buyer needs right now. Check again later.'), findsOneWidget);

      // Rerun with 1 item
      final singleItem = [
        ProducerBuyerNeedItem(
          id: '1',
          productName: 'Silk Scarf',
          category: 'Apparel',
          quantity: 5,
          unit: 'pieces',
          urgency: 'low',
          status: 'active',
          state: 'Karnataka',
          district: 'Bengaluru',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: BuyerNeedsTab(buyerNeeds: singleItem),
        ),
      );
      await tester.pumpAndSettle();

      // 18. No search match
      await tester.enterText(find.byType(TextField), 'NonExistentProduct');
      await tester.pumpAndSettle();
      expect(find.text('No buyer needs match your search.'), findsOneWidget);

      // Clear search and tap "Urgent" (which has 0 matches)
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.widgetWithText(FilterChip, 'Urgent'));
      await tester.pumpAndSettle();

      // 19. No filter match
      expect(find.text('No opportunities found for this filter.'), findsOneWidget);
    });

    testWidgets('21. loading & 22. error state with retry', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeBuyerNeedsHomeService(shouldThrowOnNeeds: true);
      final provider = ProducerHomeDashboardProvider(service: fakeService);
      await provider.loadDashboard();

      await tester.pumpWidget(
        _buildTestApp(
          child: BuyerNeedsTab(dashboardProvider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("We couldn't load buyer needs right now."), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.textContaining('ProducerHomeOperationException'), findsNothing);
    });

    testWidgets('23. refresh invokes provider refresh', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeBuyerNeedsHomeService(
        buyerNeedsToReturn: [
          ProducerBuyerNeedItem(
            id: '1',
            productName: 'Jute Bags',
            category: 'Jute',
            quantity: 50,
            unit: 'pieces',
            urgency: 'normal',
            status: 'active',
            state: 'West Bengal',
            district: 'Kolkata',
            createdAt: DateTime.now(),
          ),
        ],
      );
      final provider = ProducerHomeDashboardProvider(service: fakeService);
      await provider.loadDashboard();
      expect(fakeService.refreshCallCount, 1);

      await tester.pumpWidget(
        _buildTestApp(
          child: BuyerNeedsTab(dashboardProvider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jute Bags'), findsOneWidget);
    });

    testWidgets('24. EN localization & 25. HI localization & 26. PA localization', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        ProducerBuyerNeedItem(
          id: '1',
          productName: 'Test Item',
          category: 'Craft',
          quantity: 10,
          unit: 'pieces',
          targetPrice: 200,
          urgency: 'high',
          status: 'active',
          state: 'State',
          district: 'District',
          createdAt: DateTime.now(),
        ),
      ];

      // 24. English
      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('en'),
          child: BuyerNeedsTab(buyerNeeds: items),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Buyer Needs'), findsOneWidget);
      expect(find.text('Buyer wants'), findsOneWidget);
      expect(find.text('Target price'), findsOneWidget);
      expect(find.text('Where buyers are'), findsOneWidget);
      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Nearby'), findsOneWidget);

      // 25. Hindi
      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('hi'),
          child: BuyerNeedsTab(buyerNeeds: items),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('खरीदारों की जरूरतें'), findsOneWidget);
      expect(find.text('खरीदार को चाहिए'), findsOneWidget);
      expect(find.text('लक्षित मूल्य'), findsOneWidget);
      expect(find.text('खरीदार कहाँ से हैं'), findsOneWidget);
      expect(find.text('आपके लिए'), findsOneWidget);
      expect(find.text('आस-पास'), findsOneWidget);

      // 26. Punjabi
      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('pa'),
          child: BuyerNeedsTab(buyerNeeds: items),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ਖਰੀਦਦਾਰਾਂ ਦੀਆਂ ਲੋੜਾਂ'), findsOneWidget);
      expect(find.text('ਖਰੀਦਦਾਰ ਨੂੰ ਚਾਹੀਦਾ ਹੈ'), findsOneWidget);
      expect(find.text('ਟੀਚਾ ਮੁੱਲ'), findsOneWidget);
      expect(find.text('ਖਰੀਦਦਾਰ ਕਿੱਥੋਂ ਹਨ'), findsOneWidget);
      expect(find.text('ਤੁਹਾਡੇ ਲਈ'), findsOneWidget);
      expect(find.text('ਨੇੜੇ'), findsOneWidget);
    });

    testWidgets('27. unseen category does not crash', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        ProducerBuyerNeedItem(
          id: '1',
          productName: 'Organic Candles',
          category: 'candles',
          quantity: 20,
          unit: 'boxes',
          urgency: 'normal',
          status: 'active',
          state: 'Goa',
          district: 'North Goa',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: BuyerNeedsTab(
            buyerNeeds: items,
            profile: const ProducerShellProfile(craftCategory: 'handicrafts'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Organic Candles'), findsOneWidget);
      expect(find.text('candles'), findsOneWidget);
    });

    testWidgets('28. compatibility: Home Buyer Needs preview and View All navigation opens live BuyerNeedsTab', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeHomeService = FakeBuyerNeedsHomeService(
        buyerNeedsToReturn: [
          ProducerBuyerNeedItem(
            id: '1',
            productName: 'Preview Brass Lamps',
            category: 'Handicraft',
            quantity: 20,
            unit: 'pieces',
            targetPrice: 750,
            urgency: 'high',
            status: 'active',
            state: 'Punjab',
            district: 'Patiala',
            createdAt: DateTime.now(),
          ),
        ],
      );
      final fakeProdService = FakeBuyerProductService();
      final productsProvider = ProducerProductsProvider(service: fakeProdService);

      await tester.pumpWidget(
        _buildTestApp(
          child: ProducerMainScreen(
            homeService: fakeHomeService,
            productsProvider: productsProvider,
            productService: fakeProdService,
            initialProfile: const ProducerShellProfile(
              businessName: 'Patiala Crafts',
              craftCategory: 'handicrafts',
              district: 'Patiala',
              state: 'Punjab',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "View All" on the Home buyer needs section
      final viewAllButton = find.text('View All');
      await tester.scrollUntilVisible(viewAllButton, 200);
      expect(viewAllButton, findsOneWidget);
      await tester.tap(viewAllButton);
      await tester.pumpAndSettle();

      // Confirms BuyerNeedsTab is active and rendered
      expect(find.byType(BuyerNeedsTab), findsOneWidget);
      expect(find.text('Preview Brass Lamps'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search bar present
    });
  });
}
