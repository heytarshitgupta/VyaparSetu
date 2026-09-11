import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/producer_section/home/models/producer_home_models.dart';
import 'package:buyer_section/producer_section/home/models/producer_shell_profile.dart';
import 'package:buyer_section/producer_section/home/providers/producer_home_dashboard_provider.dart';
import 'package:buyer_section/producer_section/home/services/producer_home_service.dart';
import 'package:buyer_section/producer_section/home/tabs/producer_home_tab.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';
import 'package:buyer_section/producer_section/products/providers/producer_products_provider.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_image_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

class FakeProducerHomeService implements IProducerHomeService {
  final ProducerOrdersSummary ordersSummaryToReturn;
  final List<ProducerBuyerNeedItem> buyerNeedsToReturn;
  final List<ProducerMarketSignalItem> marketSignalsToReturn;

  FakeProducerHomeService({
    this.ordersSummaryToReturn = const ProducerOrdersSummary(
      completedSales: 45000,
      completedOrders: 6,
      pendingOrConfirmedOrders: 2,
      totalOrders: 8,
      cancelledOrders: 0,
    ),
    List<ProducerBuyerNeedItem>? buyerNeeds,
    this.marketSignalsToReturn = const [
      ProducerMarketSignalItem(
        title: 'High Demand for Mustard Oil',
        category: 'Agri Produce',
        level: MarketDemandLevel.high,
        activeRequestCount: 12,
        completedOrderCount: 4,
        subtitle: '12 active buyer requirements',
      ),
    ],
  }) : buyerNeedsToReturn = buyerNeeds ?? [
          ProducerBuyerNeedItem(
            id: 'need-1',
            productName: 'Raw Wildflower Honey',
            category: 'Honey',
            quantity: 50,
            unit: 'kg',
            targetPrice: 420,
            district: 'Ludhiana',
            state: 'Punjab',
            urgency: 'high',
            status: 'active',
            createdAt: DateTime.now(),
          ),
        ];

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
  }) async =>
      marketSignalsToReturn;
}

class FakeHomeProductService implements IProducerProductService {
  final List<ProducerProduct> products;

  FakeHomeProductService({this.products = const []});

  @override
  IProducerProductImageService? get imageService => null;

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async => products;

  @override
  Future<ProducerProduct> createDraft(ProducerProductDraft draft) async {
    throw UnimplementedError();
  }

  @override
  Future<ProducerProduct> updateDraft({
    required String productId,
    required ProducerProductDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ProducerProduct> updateProductImages({
    required String productId,
    required List<String> imagePaths,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ProducerProduct> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProduct(String productId) async {}
}

Widget createDashboardTestWidget({
  required Widget child,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testProfile = ProducerShellProfile(
    fullName: 'Ramesh Kumar',
    email: 'ramesh@example.com',
    businessName: 'Kumar Handloom Crafts',
    craftCategory: 'Handicrafts',
  );

  group('Producer Home Data Models Tests', () {
    test('ProducerBuyerNeedItem parses row data correctly', () {
      final row = {
        'id': 'req-123',
        'product_name': 'Desi Khand Bulk',
        'category': 'Sweeteners',
        'quantity': 100.5,
        'unit': 'kg',
        'target_price': 65.0,
        'district': 'Amritsar',
        'state': 'Punjab',
        'urgency': 'high',
        'status': 'active',
      };

      final item = ProducerBuyerNeedItem.fromJson(row);
      expect(item.id, equals('req-123'));
      expect(item.productName, equals('Desi Khand Bulk'));
      expect(item.category, equals('Sweeteners'));
      expect(item.quantity, equals(100.5));
      expect(item.unit, equals('kg'));
      expect(item.targetPrice, equals(65.0));
      expect(item.district, equals('Amritsar'));
      expect(item.state, equals('Punjab'));
      expect(item.urgency, equals('high'));
    });

    test('ProducerOrdersSummary aggregates orders correctly', () {
      final rows = [
        {'status': 'delivered', 'total_amount': 1500.0},
        {'status': 'completed', 'total_amount': 2500.0},
        {'status': 'pending', 'total_amount': 1000.0},
        {'status': 'confirmed', 'total_amount': 3000.0},
        {'status': 'cancelled', 'total_amount': 800.0},
      ];

      final summary = ProducerOrdersSummary.fromOrdersList(rows);
      expect(summary.completedSales, equals(2500.0));
      expect(summary.completedOrders, equals(1));
      expect(summary.pendingOrConfirmedOrders, equals(2));
      expect(summary.totalOrders, equals(5));
      expect(summary.cancelledOrders, equals(1));
    });
  });

  group('Producer Home Dashboard Provider Tests', () {
    test('loadDashboard populates orders, buyer needs, and signals', () async {
      final fakeService = FakeProducerHomeService();
      final provider = ProducerHomeDashboardProvider(service: fakeService);

      expect(provider.isLoadingOrders, isFalse);
      expect(provider.ordersSummary, isNull);

      await provider.loadDashboard();

      expect(provider.isLoadingOrders, isFalse);
      expect(provider.ordersSummary, isNotNull);
      expect(provider.ordersSummary!.completedSales, equals(45000));
      expect(provider.ordersSummary!.completedOrders, equals(6));
      expect(provider.buyerNeeds.length, equals(1));
      expect(provider.marketSignals.length, equals(1));
    });
  });

  group('ProducerHomeTab Widget Integration Tests', () {
    testWidgets('Renders empty products card when producer has zero products', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final productsProvider = ProducerProductsProvider(
        service: FakeHomeProductService(products: []),
      );
      await productsProvider.loadProducts();

      final dashboardProvider = ProducerHomeDashboardProvider(
        service: FakeProducerHomeService(),
      );
      await dashboardProvider.loadDashboard();

      await tester.pumpWidget(
        createDashboardTestWidget(
          child: ProducerHomeTab(
            profile: testProfile,
            productsProvider: productsProvider,
            dashboardProvider: dashboardProvider,
            onNavigateToTab: (_) {},
            onAddProduct: () {},
            onOpenWhatBuyersWant: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No products added yet'), findsOneWidget);
      expect(find.text('Add your first product so buyers can discover your craft'), findsOneWidget);
    });

    testWidgets('Renders live products preview when producer has active products', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleProduct = ProducerProduct(
        id: 'prod-1',
        producerId: 'test-id',
        name: 'Organic Honey 500g',
        category: 'Honey',
        pricePaise: 35000,
        unit: 'jar',
        images: const [],
        status: ProductStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final productsProvider = ProducerProductsProvider(
        service: FakeHomeProductService(products: [sampleProduct]),
      );
      await productsProvider.loadProducts();

      final dashboardProvider = ProducerHomeDashboardProvider(
        service: FakeProducerHomeService(),
      );
      await dashboardProvider.loadDashboard();

      await tester.pumpWidget(
        createDashboardTestWidget(
          child: ProducerHomeTab(
            profile: testProfile,
            productsProvider: productsProvider,
            dashboardProvider: dashboardProvider,
            onNavigateToTab: (_) {},
            onAddProduct: () {},
            onOpenWhatBuyersWant: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Products'), findsOneWidget);
      expect(find.text('Organic Honey 500g'), findsOneWidget);
      expect(find.text('₹350.00 / jar'), findsOneWidget);
    });

    testWidgets('Renders live order summary KPIs, buyer needs, and market signals', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final productsProvider = ProducerProductsProvider(
        service: FakeHomeProductService(products: []),
      );
      await productsProvider.loadProducts();

      final dashboardProvider = ProducerHomeDashboardProvider(
        service: FakeProducerHomeService(),
      );
      await dashboardProvider.loadDashboard();

      await tester.pumpWidget(
        createDashboardTestWidget(
          child: ProducerHomeTab(
            profile: testProfile,
            productsProvider: productsProvider,
            dashboardProvider: dashboardProvider,
            onNavigateToTab: (_) {},
            onAddProduct: () {},
            onOpenWhatBuyersWant: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Order KPIs
      expect(find.text('₹45,000'), findsOneWidget);
      expect(find.text('Completed Sales'), findsOneWidget);
      expect(find.text('Completed Orders'), findsOneWidget);
      expect(find.text('Pending / Confirmed'), findsOneWidget);

      // Check Active Buyer Needs
      expect(find.text('Raw Wildflower Honey'), findsOneWidget);

      // Check Market Demand Signals
      expect(find.text('High Demand for Mustard Oil'), findsOneWidget);
      expect(find.text('12 active buyer requirements'), findsOneWidget);
    });

    testWidgets('Action callbacks trigger properly when tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool addProductCalled = false;
      int? navigatedTabIndex;

      final productsProvider = ProducerProductsProvider(
        service: FakeHomeProductService(products: []),
      );
      await productsProvider.loadProducts();

      final dashboardProvider = ProducerHomeDashboardProvider(
        service: FakeProducerHomeService(),
      );
      await dashboardProvider.loadDashboard();

      await tester.pumpWidget(
        createDashboardTestWidget(
          child: ProducerHomeTab(
            profile: testProfile,
            productsProvider: productsProvider,
            dashboardProvider: dashboardProvider,
            onNavigateToTab: (index) => navigatedTabIndex = index,
            onAddProduct: () => addProductCalled = true,
            onOpenWhatBuyersWant: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Primary Add Product button
      await tester.tap(find.text('Add Product'));
      await tester.pumpAndSettle();
      expect(addProductCalled, isTrue);

      // Tap View All on Buyer Needs
      final viewAllFinders = find.text('View All');
      expect(viewAllFinders, findsWidgets);
      await tester.tap(viewAllFinders.first);
      await tester.pumpAndSettle();
      expect(navigatedTabIndex, isNotNull);
    });
  });
}
