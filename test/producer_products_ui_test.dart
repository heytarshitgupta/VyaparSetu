import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/localization/language_provider.dart';
import 'package:buyer_section/core/services/preferences_service.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/core/theme/theme_provider.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/producer_products_tab.dart';
import 'package:buyer_section/producer_section/products/providers/producer_products_provider.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

class FakeProducerProductService implements IProducerProductService {
  List<ProducerProduct> productsToReturn;
  bool shouldThrowAuthError = false;
  bool shouldThrowOperationError = false;
  int fetchCallCount = 0;

  FakeProducerProductService({
    List<ProducerProduct>? initialProducts,
  }) : productsToReturn = initialProducts != null ? List.from(initialProducts) : [];

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async {
    fetchCallCount++;
    if (shouldThrowAuthError) {
      throw const ProductAuthException('Not authenticated');
    }
    if (shouldThrowOperationError) {
      throw const ProductOperationException('Simulated database error');
    }
    if (statusFilter != null) {
      return productsToReturn.where((p) => p.status == statusFilter).toList();
    }
    return List.from(productsToReturn);
  }

  @override
  Future<ProducerProduct> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  }) async {
    if (shouldThrowAuthError) {
      throw const ProductAuthException('Not authenticated');
    }
    if (shouldThrowOperationError) {
      throw const ProductOperationException('Constraint violation');
    }
    final index = productsToReturn.indexWhere((p) => p.id == productId);
    if (index == -1) {
      throw const ProductOperationException('Product not found');
    }
    final updated = productsToReturn[index].copyWith(status: newStatus);
    productsToReturn[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    if (shouldThrowAuthError) {
      throw const ProductAuthException('Not authenticated');
    }
    if (shouldThrowOperationError) {
      throw const ProductOperationException('Delete failed');
    }
    productsToReturn.removeWhere((p) => p.id == productId);
  }
}

Widget createTestApp({
  required Widget child,
  Size screenSize = const Size(390, 844),
  LanguageProvider? languageProvider,
  ThemeProvider? themeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(
        create: (_) => languageProvider ?? LanguageProvider(),
      ),
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => themeProvider ?? ThemeProvider(),
      ),
    ],
    child: Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, langProv, thProv, _) {
        return MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            textScaler: TextScaler.noScaling,
          ),
          child: MaterialApp(
            locale: langProv.currentLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: thProv.themeMode,
            home: Scaffold(
              body: SizedBox(
                width: screenSize.width,
                height: screenSize.height,
                child: child,
              ),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTimestamp = DateTime.parse('2026-09-04T12:00:00.000Z');

  late List<ProducerProduct> sampleProducts;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.instance.resetForTesting();

    sampleProducts = [
      ProducerProduct(
        id: 'p-1',
        producerId: 'u-1',
        name: 'Handcrafted Blue Pottery Vase',
        category: 'Pottery',
        pricePaise: 125000,
        unit: 'piece',
        status: ProductStatus.active,
        createdAt: testTimestamp,
        updatedAt: testTimestamp,
      ),
      ProducerProduct(
        id: 'p-2',
        producerId: 'u-1',
        name: 'Unfinished Wooden Carving',
        category: 'Woodcraft',
        pricePaise: null,
        unit: 'piece',
        status: ProductStatus.draft,
        createdAt: testTimestamp,
        updatedAt: testTimestamp,
      ),
      ProducerProduct(
        id: 'p-3',
        producerId: 'u-1',
        name: 'Pure Pashmina Shawl',
        category: 'Textiles',
        pricePaise: 1050,
        unit: 'piece',
        status: ProductStatus.hidden,
        createdAt: testTimestamp,
        updatedAt: testTimestamp,
      ),
    ];
  });

  group('ProducerProductsTab UI & State Tests', () {
    testWidgets('1. Loading state renders calm progress indicator without error', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);

      // Provider not loaded yet
      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(
            provider: provider,
          ),
        ),
      );

      // Loading state should show progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('2. True zero-products empty state renders with prominent Add Product', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: []);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      bool addProductTapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(
            provider: provider,
            onAddProduct: () => addProductTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No products added yet'), findsOneWidget);
      expect(find.text('Add your first product so buyers can discover your craft'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add Product'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Add Product'));
      expect(addProductTapped, isTrue);
    });

    testWidgets('3. Products render properly from fake provider', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Handcrafted Blue Pottery Vase'), findsOneWidget);
      expect(find.text('Unfinished Wooden Carving'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Pure Pashmina Shawl'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Pure Pashmina Shawl'), findsOneWidget);
    });

    testWidgets('4, 5, 6. Active, Draft, and Hidden status badges render with icon and label', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Active status
      expect(find.text('Active'), findsWidgets);
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);

      // Draft status
      expect(find.text('Draft'), findsWidgets);
      expect(find.byIcon(Icons.edit_note_outlined), findsWidgets);

      // Hidden status
      await tester.scrollUntilVisible(
        find.text('Hidden'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Hidden'), findsWidgets);
      expect(find.byIcon(Icons.visibility_off_outlined), findsWidgets);
    });

    testWidgets('7. Null price displays "Price not set"', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: [sampleProducts[1]]);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Price not set'), findsOneWidget);
    });

    testWidgets('8. Formats INR integer paise correctly', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: [sampleProducts[0], sampleProducts[2]]);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // 125000 paise -> ₹1,250.00
      expect(find.text('₹1,250.00'), findsOneWidget);
      // 1050 paise -> ₹10.50
      expect(find.text('₹10.50'), findsOneWidget);
    });

    testWidgets('9, 10, 11, 12, 13. Filters work locally without refetching from service', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeService.fetchCallCount, 1);

      // Filter Active
      await tester.tap(find.widgetWithText(FilterChip, 'Active'));
      await tester.pumpAndSettle();
      expect(find.text('Handcrafted Blue Pottery Vase'), findsOneWidget);
      expect(find.text('Unfinished Wooden Carving'), findsNothing);
      expect(find.text('Pure Pashmina Shawl'), findsNothing);

      // Filter Draft
      await tester.tap(find.widgetWithText(FilterChip, 'Draft'));
      await tester.pumpAndSettle();
      expect(find.text('Handcrafted Blue Pottery Vase'), findsNothing);
      expect(find.text('Unfinished Wooden Carving'), findsOneWidget);

      // Filter Hidden
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Hidden'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Hidden'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Pure Pashmina Shawl'), findsOneWidget);

      // Filter All
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'All'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Handcrafted Blue Pottery Vase'), findsOneWidget);
      expect(find.text('Unfinished Wooden Carving'), findsOneWidget);

      // Verify no refetch happened during filter toggling
      expect(fakeService.fetchCallCount, 1);
    });

    testWidgets('14. Filtered-empty state differs from true empty state and offers Show All', (tester) async {
      // Only 1 active product
      final fakeService = FakeProducerProductService(initialProducts: [sampleProducts[0]]);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Draft filter (which has 0 items)
      await tester.tap(find.widgetWithText(FilterChip, 'Draft'));
      await tester.pumpAndSettle();

      expect(find.text('No draft products'), findsOneWidget);
      expect(find.text('Products that still need details will appear here'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Show All Products'), findsOneWidget);

      // Switch to Hidden filter (which has 0 items)
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Hidden'));
      await tester.tap(find.widgetWithText(FilterChip, 'Hidden'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('No hidden products'), findsOneWidget);
      expect(find.text('Products you temporarily hide will appear here'), findsOneWidget);
      expect(find.textContaining('buyers'), findsNothing);

      // Tap Show All Products returns to all products
      await tester.tap(find.widgetWithText(OutlinedButton, 'Show All Products'));
      await tester.pumpAndSettle();
      expect(find.text('Handcrafted Blue Pottery Vase'), findsOneWidget);
    });

    testWidgets('15. Load error state displays retry button and refetches', (tester) async {
      final fakeService = FakeProducerProductService();
      fakeService.shouldThrowOperationError = true;
      final provider = ProducerProductsProvider(service: fakeService);

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("We couldn't load your products"), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

      // Fix service and tap retry
      fakeService.shouldThrowOperationError = false;
      fakeService.productsToReturn = sampleProducts;

      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Handcrafted Blue Pottery Vase'), findsOneWidget);
    });

    testWidgets('16. Add Product button invokes callback', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      bool callbackInvoked = false;

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(
            provider: provider,
            onAddProduct: () => callbackInvoked = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add Product'));
      expect(callbackInvoked, isTrue);
    });

    testWidgets('17, 18. Hide action on active product succeeds and handles failure', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: [sampleProducts[0]]);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Hide
      await tester.tap(find.widgetWithText(OutlinedButton, 'Hide'));
      await tester.pumpAndSettle();

      expect(find.text('Product hidden'), findsOneWidget);
      expect(find.text('Product hidden from buyers'), findsNothing);
      expect(find.textContaining('buyer'), findsNothing);
      expect(provider.allProducts.first.status, ProductStatus.hidden);

      // Now set service to fail and tap Show
      fakeService.shouldThrowOperationError = true;
      await tester.tap(find.widgetWithText(FilledButton, 'Show'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to update product. Please try again.'), findsOneWidget);
    });

    testWidgets('19, 20. Show action on hidden product succeeds', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: [sampleProducts[2]]);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Show
      await tester.tap(find.widgetWithText(FilledButton, 'Show'));
      await tester.pumpAndSettle();

      expect(find.text('Product marked active'), findsOneWidget);
      expect(find.text('Product is now active'), findsNothing);
      expect(find.textContaining('buyer'), findsNothing);
      expect(provider.allProducts.first.status, ProductStatus.active);
    });

    testWidgets('21, 22, 23. Delete confirmation dialog cancels or proceeds', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: [sampleProducts[0]]);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Tap delete icon button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirm dialog appeared
      expect(find.text('Delete Product?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this product? This action cannot be undone.'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Product still exists
      expect(provider.allProducts.length, 1);
      expect(find.text('Handcrafted Blue Pottery Vase'), findsOneWidget);

      // Tap delete again and confirm
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Deleted successfully
      expect(find.text('Product deleted'), findsOneWidget);
      expect(provider.allProducts.isEmpty, isTrue);
    });

    testWidgets('24. No raw backend error is shown to user', (tester) async {
      final fakeService = FakeProducerProductService();
      fakeService.shouldThrowOperationError = true;
      final provider = ProducerProductsProvider(service: fakeService);

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Postgres'), findsNothing);
      expect(find.textContaining('Simulated database error'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('25, 26, 27, 28. Responsive viewports render cleanly without overflow', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      const resolutions = [
        Size(320, 700),
        Size(390, 844),
        Size(768, 1024),
        Size(1200, 800),
      ];

      for (final res in resolutions) {
        await tester.pumpWidget(
          createTestApp(
            screenSize: res,
            child: ProducerProductsTab(provider: provider),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow at resolution $res');
        expect(find.text('Handcrafted Blue Pottery Vase'), findsOneWidget);
      }
    });

    testWidgets('29, 30, 31. Multi-language rendering in en, hi, pa', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      final langProv = LanguageProvider();

      // English
      langProv.setAppLanguage(AppLanguage.english);
      await tester.pumpWidget(
        createTestApp(
          languageProvider: langProv,
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Products'), findsOneWidget);

      // Hindi
      langProv.setAppLanguage(AppLanguage.hindi);
      await tester.pumpWidget(
        createTestApp(
          languageProvider: langProv,
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('मेरे उत्पाद'), findsOneWidget);
      expect(find.text('सभी'), findsOneWidget);

      // Punjabi
      langProv.setAppLanguage(AppLanguage.punjabi);
      await tester.pumpWidget(
        createTestApp(
          languageProvider: langProv,
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ਮੇਰੇ ਉਤਪਾਦ'), findsOneWidget);
      expect(find.text('ਸਾਰੇ'), findsOneWidget);
    });

    testWidgets('32, 33. Light and Dark themes render without error', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      final thProv = ThemeProvider();

      // Light theme
      thProv.setThemeMode(ThemeMode.light);
      await tester.pumpWidget(
        createTestApp(
          themeProvider: thProv,
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Dark theme
      thProv.setThemeMode(ThemeMode.dark);
      await tester.pumpWidget(
        createTestApp(
          themeProvider: thProv,
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('34. Missing image renders local material inventory placeholder', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: [sampleProducts[0]]);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inventory_2_outlined), findsWidgets);
      // Verify no network image in widget tree
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('35. My Products UI does not render misleading buyer visibility claims', (tester) async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      await tester.pumpWidget(
        createTestApp(
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Misleading phrases that should never appear describing current product status
      expect(find.textContaining('hidden from buyers'), findsNothing);
      expect(find.textContaining('show to buyers'), findsNothing);
      expect(find.textContaining('visible to buyers'), findsNothing);
      expect(find.textContaining('shown to buyers'), findsNothing);
      expect(find.textContaining('buyers can now see'), findsNothing);
      expect(find.textContaining('published to marketplace'), findsNothing);

      // Verify each filter does not display misleading phrases
      for (final filter in ['Active', 'Draft', 'Hidden', 'All']) {
        await tester.ensureVisible(find.widgetWithText(FilterChip, filter));
        await tester.tap(find.widgetWithText(FilterChip, filter), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.textContaining('hidden from buyers'), findsNothing);
        expect(find.textContaining('show to buyers'), findsNothing);
        expect(find.textContaining('visible to buyers'), findsNothing);
        expect(find.textContaining('shown to buyers'), findsNothing);
      }
    });
  });
}
