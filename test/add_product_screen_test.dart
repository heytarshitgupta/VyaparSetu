import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/localization/language_provider.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/core/theme/theme_provider.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';
import 'package:buyer_section/producer_section/products/providers/add_product_provider.dart';
import 'package:buyer_section/producer_section/products/screens/add_product_screen.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

class FakeAddProductService implements IProducerProductService {
  final Map<String, ProducerProduct> database = {};
  int createCalls = 0;
  int updateDraftCalls = 0;
  int updateStatusCalls = 0;
  bool shouldFailPersistence = false;

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async =>
      database.values.toList();

  @override
  Future<ProducerProduct> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  }) async {
    updateStatusCalls++;
    final existing = database[productId]!;
    final updated = existing.copyWith(status: newStatus);
    database[productId] = updated;
    return updated;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    database.remove(productId);
  }

  @override
  Future<ProducerProduct> createDraft(ProducerProductDraft draft) async {
    createCalls++;
    if (shouldFailPersistence) {
      throw const ProductOperationException('Simulated database create failure');
    }
    final id = 'prod-$createCalls';
    final product = ProducerProduct(
      id: id,
      producerId: 'test-producer',
      name: draft.name,
      description: draft.description,
      category: draft.category,
      pricePaise: draft.pricePaise,
      unit: draft.unit,
      images: draft.images,
      status: ProductStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    database[id] = product;
    return product;
  }

  @override
  Future<ProducerProduct> updateDraft({
    required String productId,
    required ProducerProductDraft draft,
  }) async {
    updateDraftCalls++;
    if (shouldFailPersistence) {
      throw const ProductOperationException('Simulated database update failure');
    }
    final existing = database[productId]!;
    final updated = existing.copyWith(
      name: draft.name,
      description: draft.description,
      category: draft.category,
      pricePaise: draft.pricePaise,
      unit: draft.unit,
      updatedAt: DateTime.now(),
    );
    database[productId] = updated;
    return updated;
  }

  @override
  Future<ProducerProduct> updateProductImages({
    required String productId,
    required List<String> imagePaths,
  }) async => database[productId]!;
}

Widget createTestWidget({
  required Widget child,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: child,
    ),
  );
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('AddProductScreen - Step 1 ("What do you make?") Tests', () {
    late FakeAddProductService service;
    late AddProductProvider provider;

    setUp(() {
      service = FakeAddProductService();
      provider = AddProductProvider(productService: service);
    });

    testWidgets('starts at Step 1 with empty initial values and step indicators', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('What do you make?'), findsWidgets);
      expect(find.text('Product name'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Unit'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('cannot continue with empty product name; shows validation error', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Continue'));

      expect(find.text('Please enter a product name first'), findsOneWidget);
      expect(provider.currentStep, 1);
    });

    testWidgets('entering valid name, selecting category and unit navigates to Step 2', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextField).first, 'Handcrafted Terracotta Pot');
      // Select Handicraft category
      await tapVisible(tester, find.text('Handicraft'));

      expect(provider.draft.category, 'handicraft');

      // Tap Continue
      await tapVisible(tester, find.text('Continue'));

      // Should now be on Step 2
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('Price & Details'), findsWidgets);
      expect(provider.currentStep, 2);
    });

    testWidgets('selecting Other category allows entering custom category description', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Other'));

      expect(find.text('Describe category'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Describe category'), 'Metal Sculptures');
      expect(provider.draft.category, 'Metal Sculptures');
    });
  });

  group('AddProductScreen - Step 2 ("Price & Details") Tests', () {
    late FakeAddProductService service;
    late AddProductProvider provider;

    setUp(() {
      service = FakeAddProductService();
      provider = AddProductProvider(productService: service);
    });

    testWidgets('Price converts to paise and Back button preserves Step 1 values', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Complete Step 1
      await tester.enterText(find.byType(TextField).first, 'Bamboo Basket');
      await tapVisible(tester, find.text('Continue'));

      expect(find.text('Step 2 of 3'), findsOneWidget);

      // Enter Price
      final priceField = find.widgetWithText(TextField, '250');
      await tester.enterText(priceField, '450.50');
      expect(provider.draft.pricePaise, 45050);

      // Enter Description
      final descField = find.widgetWithText(TextField, 'What is it made from? What makes it special?');
      await tester.enterText(descField, 'Woven from natural bamboo strips');
      expect(provider.draft.description, 'Woven from natural bamboo strips');

      // Tap Back
      await tapVisible(tester, find.text('Back'));

      // Back in Step 1, verify values preserved
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Bamboo Basket'), findsOneWidget);
    });

    testWidgets('invalid price input shows format error', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Ceramic Mug');
      await tapVisible(tester, find.text('Continue'));

      // Enter 0 (invalid price)
      final priceField = find.widgetWithText(TextField, '250');
      await tester.enterText(priceField, '0');
      await tester.pumpAndSettle();

      expect(find.text('Price must be greater than zero: "0"'), findsOneWidget);
    });

    testWidgets('Continue on Step 2 automatically persists draft before advancing to Step 3', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1
      await tester.enterText(find.byType(TextField).first, 'Pure Honey');
      await tapVisible(tester, find.text('Continue'));

      // Step 2
      final priceField = find.widgetWithText(TextField, '250');
      await tester.enterText(priceField, '350');
      await tester.pumpAndSettle();

      expect(service.createCalls, 0);

      // Tap Continue to Step 3
      await tapVisible(tester, find.text('Continue'));

      // Verified: createDraft was invoked and provider holds persisted ID
      expect(service.createCalls, 1);
      expect(provider.isPersisted, isTrue);
      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(find.text('Add Photos & Save'), findsWidgets);
    });

    testWidgets('database persistence failure halts navigation at Step 2 with error', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      service.shouldFailPersistence = true;

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Pure Honey');
      await tapVisible(tester, find.text('Continue'));

      await tapVisible(tester, find.text('Continue'));

      // Must remain at Step 2
      expect(provider.currentStep, 2);
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('Simulated database create failure'), findsOneWidget);
    });
  });

  group('AddProductScreen - Step 3 ("Add Photos & Save") Tests', () {
    late FakeAddProductService service;
    late AddProductProvider provider;

    setUp(() {
      service = FakeAddProductService();
      provider = AddProductProvider(productService: service);
    });

    testWidgets('Add Photo tile displays truthful coming-next feedback without uploading', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Advance to Step 3
      await tester.enterText(find.byType(TextField).first, 'Silk Shawl');
      await tapVisible(tester, find.text('Clothing'));
      await tapVisible(tester, find.text('Continue'));

      final priceField = find.widgetWithText(TextField, '250');
      await tester.enterText(priceField, '1200');
      await tapVisible(tester, find.text('Continue'));

      expect(find.text('Step 3 of 3'), findsOneWidget);

      // Tap Add Photo tile
      await tapVisible(tester, find.byIcon(Icons.add_a_photo_outlined));

      expect(find.text('Photo selection will be added next'), findsWidgets);
    });

    testWidgets('Mark Ready is disabled when requirements incomplete, enabled when complete', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 without category
      await tester.enterText(find.byType(TextField).first, 'Wood Toy');
      await tapVisible(tester, find.text('Continue'));

      // Step 2 without price
      await tapVisible(tester, find.text('Continue'));

      // Step 3
      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(provider.canMarkActive, isFalse);

      // Guidance message is displayed
      expect(find.text('Add name, category, and price to mark ready'), findsOneWidget);

      // Back to Step 1 to set category
      await tapVisible(tester, find.text('Back'));
      await tapVisible(tester, find.text('Back'));
      await tapVisible(tester, find.text('Handicraft'));

      // Step 2 set price
      await tapVisible(tester, find.text('Continue'));
      final priceField = find.widgetWithText(TextField, '250');
      await tester.enterText(priceField, '250');

      // Step 3
      await tapVisible(tester, find.text('Continue'));

      // Now canMarkActive is true, guidance is gone
      expect(provider.canMarkActive, isTrue);
      expect(find.text('Add name, category, and price to mark ready'), findsNothing);
    });

    testWidgets('Save Draft saves draft and pops route with true', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool? poppedResult;

      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                poppedResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddProductScreen(provider: provider),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Open'));

      // Navigate to Step 3
      await tester.enterText(find.byType(TextField).first, 'Pickle Jar');
      await tapVisible(tester, find.text('Continue'));
      await tapVisible(tester, find.text('Continue'));

      // Tap Save Draft
      await tapVisible(tester, find.text('Save Draft'));

      expect(poppedResult, isTrue);
    });

    testWidgets('Mark Ready marks active and pops route with true', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool? poppedResult;

      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                poppedResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddProductScreen(provider: provider),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Open'));

      // Step 1
      await tester.enterText(find.byType(TextField).first, 'Leather Journal');
      await tapVisible(tester, find.text('Handicraft'));
      await tapVisible(tester, find.text('Continue'));

      // Step 2
      final priceField = find.widgetWithText(TextField, '250');
      await tester.enterText(priceField, '400');
      await tapVisible(tester, find.text('Continue'));

      // Step 3: Tap Mark Ready
      await tapVisible(tester, find.text('Mark Ready'));

      expect(service.updateStatusCalls, 1);
      expect(poppedResult, isTrue);
    });
  });

  group('AddProductScreen - Responsiveness & Theme Tests', () {
    late FakeAddProductService service;
    late AddProductProvider provider;

    setUp(() {
      service = FakeAddProductService();
      provider = AddProductProvider(productService: service);
    });

    testWidgets('renders cleanly on phone (320px width) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet (768px width)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);
    });

    testWidgets('renders cleanly on desktop (1440px width)', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);
    });

    testWidgets('renders properly in Dark Theme', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);
    });
  });

  group('AddProductScreen - Localization (Hindi & Punjabi) Tests', () {
    late FakeAddProductService service;
    late AddProductProvider provider;

    setUp(() {
      service = FakeAddProductService();
      provider = AddProductProvider(productService: service);
    });

    testWidgets('renders Devanagari labels in Hindi', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('hi'),
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('आप क्या बनाते हैं?'), findsWidgets);
      expect(find.text('उत्पाद का नाम'), findsOneWidget);
      expect(find.text('श्रेणी'), findsOneWidget);
      expect(find.text('खाद्य सामग्री'), findsOneWidget);
    });

    testWidgets('renders Gurmukhi labels in Punjabi', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('pa'),
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ਤੁਸੀਂ ਕੀ ਬਣਾਉਂਦੇ ਹੋ?'), findsWidgets);
      expect(find.text('ਉਤਪਾਦ ਦਾ ਨਾਮ'), findsOneWidget);
      expect(find.text('ਸ਼੍ਰੇਣੀ'), findsOneWidget);
      expect(find.text('ਦਸਤਕਾਰੀ'), findsOneWidget);
    });
  });
}
