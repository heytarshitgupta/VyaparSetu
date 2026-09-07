import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/producer_section/home/producer_main_screen.dart';
import 'package:buyer_section/producer_section/home/tabs/what_buyers_want_screen.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/producer_market_intelligence.dart';
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';
import 'package:buyer_section/producer_section/products/providers/producer_products_provider.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_image_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

class FakeProductService implements IProducerProductService {
  @override
  final IProducerProductImageService? imageService = null;

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async => [];

  @override
  Future<ProducerProduct> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProduct(String productId) async {}

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
  group('What Buyers Want / Market Intelligence Tests (Step BI-2)', () {
    test('MarketDemandLevel thresholds calculate deterministically', () {
      expect(MarketDemandLevel.fromScore(96.4), MarketDemandLevel.high);
      expect(MarketDemandLevel.fromScore(75.0), MarketDemandLevel.high);
      expect(MarketDemandLevel.fromScore(74.9), MarketDemandLevel.medium);
      expect(MarketDemandLevel.fromScore(50.0), MarketDemandLevel.medium);
      expect(MarketDemandLevel.fromScore(49.9), MarketDemandLevel.low);
      expect(MarketDemandLevel.fromScore(0.0), MarketDemandLevel.low);
    });

    testWidgets('Home shortcut opens real WhatBuyersWantScreen without "Feature coming soon"', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeProductService();
      final provider = ProducerProductsProvider(service: fakeService);

      await tester.pumpWidget(
        _buildTestApp(
          child: ProducerMainScreen(
            productsProvider: provider,
            productService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap "What Buyers Want" shortcut card
      final shortcutCard = find.text('What Buyers Want');
      expect(shortcutCard, findsOneWidget);
      await tester.tap(shortcutCard);
      await tester.pumpAndSettle();

      // Verify WhatBuyersWantScreen is open
      expect(find.byType(WhatBuyersWantScreen), findsOneWidget);

      // Verify old "Feature coming soon" is NOT present
      expect(find.text('Feature coming soon'), findsNothing);

      // Verify sample market insights note is present
      expect(find.text('Sample market insights'), findsOneWidget);
    });

    testWidgets('Signal cards render product details truthfully', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WhatBuyersWantScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Sample product from Rajat seed
      expect(find.text('Basmati (Rice)'), findsOneWidget);
      expect(find.text('Agriculture'), findsWidgets);

      // Demand score and high demand label
      expect(find.textContaining('High demand • 96/100'), findsOneWidget);

      // District & Top City location text
      expect(find.textContaining('District: Tarn Taran'), findsOneWidget);
      expect(find.textContaining('Top buying city: Amritsar'), findsOneWidget);

      // Activity metrics
      expect(find.textContaining('2840 units'), findsOneWidget);
      expect(find.textContaining('₹1280'), findsOneWidget);

      // Truthfulness check: Technical CSV terms removed from user-facing UI
      expect(find.text('CSV-backed'), findsNothing);
      expect(find.textContaining('products.csv'), findsNothing);

      // Visual hierarchy check: "What Buyers Want" appears once in AppBar, section heading is "Sample market insights"
      expect(find.text('What Buyers Want'), findsOneWidget);
      expect(find.text('Sample market insights'), findsOneWidget);
    });

    testWidgets('Empty signal list displays safe localized empty state', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const WhatBuyersWantScreen(
            signals: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No market insights available yet.'), findsOneWidget);
      expect(find.text('Basmati (Rice)'), findsNothing);
    });

    testWidgets('Demand levels (High, Medium, Low) render correctly', (tester) async {
      const sampleSignals = [
        ProducerMarketSignal(
          productId: 'P1',
          productName: 'High Item',
          category: 'Agriculture',
          district: 'District 1',
          marketDemandScore: 85.0,
          monthlyUnits: 500,
          avgOrderValue: 200.0,
          topState: 'State',
          topCity: 'City 1',
        ),
        ProducerMarketSignal(
          productId: 'P2',
          productName: 'Medium Item',
          category: 'Textile',
          district: 'District 2',
          marketDemandScore: 60.0,
          monthlyUnits: 250,
          avgOrderValue: 150.0,
          topState: 'State',
          topCity: 'City 2',
        ),
        ProducerMarketSignal(
          productId: 'P3',
          productName: 'Low Item',
          category: 'Manufacturing',
          district: 'District 3',
          marketDemandScore: 35.0,
          monthlyUnits: 50,
          avgOrderValue: 100.0,
          topState: 'State',
          topCity: 'City 3',
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: const WhatBuyersWantScreen(
            signals: sampleSignals,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('High demand • 85/100'), findsOneWidget);
      expect(find.textContaining('Medium demand • 60/100'), findsOneWidget);
      expect(find.textContaining('Low demand • 35/100'), findsOneWidget);
    });

    testWidgets('Dark mode renders cleanly without crash or overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WhatBuyersWantScreen(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WhatBuyersWantScreen), findsOneWidget);
      expect(find.text('Basmati (Rice)'), findsOneWidget);
    });

    testWidgets('Hindi localization renders naturally in Devanagari', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WhatBuyersWantScreen(),
          locale: const Locale('hi'),
        ),
      );
      await tester.pumpAndSettle();

      // Hindi title & badge (title only appears once in AppBar)
      expect(find.text('खरीदार क्या चाहते हैं'), findsOneWidget);
      expect(find.text('नमूना बाज़ार रुझान'), findsOneWidget);

      // Hindi demand label
      expect(find.textContaining('अधिक मांग'), findsWidgets);

      // Hindi category mapping
      expect(find.text('कृषि'), findsWidgets);
    });

    testWidgets('Punjabi localization renders naturally in Gurmukhi', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WhatBuyersWantScreen(),
          locale: const Locale('pa'),
        ),
      );
      await tester.pumpAndSettle();

      // Punjabi title & badge (title only appears once in AppBar)
      expect(find.text('ਖਰੀਦਦਾਰ ਕੀ ਚਾਹੁੰਦੇ ਹਨ'), findsOneWidget);
      expect(find.text('ਨਮੂਨਾ ਮੰਡੀ ਰੁਝਾਨ'), findsOneWidget);

      // Punjabi demand label
      expect(find.textContaining('ਵੱਧ ਮੰਗ'), findsWidgets);

      // Punjabi category mapping
      expect(find.text('ਖੇਤੀਬਾੜੀ'), findsWidgets);
    });

    testWidgets('Responsiveness: 320px narrow phone renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WhatBuyersWantScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Basmati (Rice)'), findsOneWidget);
    });

    testWidgets('Responsiveness: 768px tablet renders cleanly', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WhatBuyersWantScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Basmati (Rice)'), findsOneWidget);
    });

    testWidgets('Responsiveness: 1440px desktop renders cleanly', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const WhatBuyersWantScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Basmati (Rice)'), findsOneWidget);
    });
  });
}
