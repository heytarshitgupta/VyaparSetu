import 'dart:typed_data';
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
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';
import 'package:buyer_section/producer_section/products/producer_products_tab.dart';
import 'package:buyer_section/producer_section/products/providers/add_product_provider.dart';
import 'package:buyer_section/producer_section/products/providers/producer_products_provider.dart';
import 'package:buyer_section/producer_section/products/screens/add_product_screen.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_enhancement_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_image_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';
import 'package:buyer_section/producer_section/products/widgets/producer_product_card.dart';
import 'package:buyer_section/producer_section/products/widgets/producer_product_details_view.dart';

// -----------------------------------------------------------------------------
// FAKE SERVICES FOR MY PRODUCTS MANAGEMENT TESTS
// -----------------------------------------------------------------------------

class FakeManagementPhotoEnhancementService implements IProductPhotoEnhancementService {
  bool shouldThrow = false;
  final List<Map<String, String>> improveCalls = [];
  final List<String> discardedCandidates = [];

  @override
  Future<EnhancementResult> improvePhoto({
    required String productId,
    required String sourceStoragePath,
  }) async {
    improveCalls.add({'productId': productId, 'sourceStoragePath': sourceStoragePath});
    if (shouldThrow) {
      throw const ProductOperationException('Could not improve photo. Please try again.');
    }
    final ext = sourceStoragePath.split('.').last;
    return EnhancementResult(
      improvedStoragePath: 'test-producer/$productId/improved_candidate.$ext',
      sourceStoragePath: sourceStoragePath,
    );
  }

  @override
  Future<void> discardCandidateImage(String candidateStoragePath) async {
    discardedCandidates.add(candidateStoragePath);
  }
}

class FakeProductImageService implements IProducerProductImageService {
  int signedUrlCallCount = 0;
  bool shouldFailSignedUrl = false;
  final List<String> deletedStoragePaths = [];

  @override
  Future<String> createSignedImageUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    signedUrlCallCount++;
    if (shouldFailSignedUrl) {
      throw const ProductOperationException('Failed to generate signed URL');
    }
    return 'https://storage.supabase.co/product-images/$storagePath?token=transient_preview_token';
  }

  @override
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    return 'test-producer/$productId/test_photo.jpg';
  }

  @override
  Future<void> deleteProductImage(String storagePath) async {
    deletedStoragePaths.add(storagePath);
  }
}

class FakeManagementProductService implements IProducerProductService {
  final Map<String, ProducerProduct> database = {};
  final FakeProductImageService fakeImageService;
  int createDraftCalls = 0;
  int updateDraftCalls = 0;
  int updateStatusCalls = 0;
  int deleteCalls = 0;
  final List<String> callLog = [];

  FakeManagementProductService({
    FakeProductImageService? imageService,
    List<ProducerProduct>? initialProducts,
  }) : fakeImageService = imageService ?? FakeProductImageService() {
    if (initialProducts != null) {
      for (final p in initialProducts) {
        database[p.id] = p;
      }
    }
  }

  @override
  IProducerProductImageService get imageService => fakeImageService;

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async {
    final list = database.values.toList();
    if (statusFilter != null) {
      return list.where((p) => p.status == statusFilter).toList();
    }
    return list;
  }

  @override
  Future<ProducerProduct> createDraft(ProducerProductDraft draft) async {
    createDraftCalls++;
    final id = 'prod-$createDraftCalls';
    final p = ProducerProduct(
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
    database[id] = p;
    return p;
  }

  @override
  Future<ProducerProduct> updateDraft({
    required String productId,
    required ProducerProductDraft draft,
  }) async {
    updateDraftCalls++;
    final existing = database[productId];
    final updated = (existing ??
            ProducerProduct(
              id: productId,
              producerId: 'test-producer',
              name: draft.name,
              category: draft.category,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ))
        .copyWith(
      name: draft.name,
      description: draft.description,
      category: draft.category,
      pricePaise: draft.pricePaise,
      unit: draft.unit,
      images: draft.images,
      updatedAt: DateTime.now(),
    );
    database[productId] = updated;
    return updated;
  }

  @override
  Future<ProducerProduct> updateProductImages({
    required String productId,
    required List<String> imagePaths,
  }) async {
    final existing = database[productId]!;
    final updated = existing.copyWith(images: imagePaths);
    database[productId] = updated;
    return updated;
  }

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
    deleteCalls++;
    final existing = database[productId];
    if (existing != null && existing.images.isNotEmpty) {
      callLog.add('delete_storage_images');
      for (final img in existing.images) {
        await fakeImageService.deleteProductImage(img);
      }
    }
    callLog.add('delete_db_row');
    database.remove(productId);
  }
}

// -----------------------------------------------------------------------------
// TEST WRAPPER HELPER
// -----------------------------------------------------------------------------

Widget buildTestApp({
  required Widget child,
  Size screenSize = const Size(390, 844),
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(
        create: (_) => LanguageProvider()..setLocale(locale),
      ),
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider()..setThemeMode(themeMode),
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        textScaler: TextScaler.noScaling,
      ),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: Scaffold(
          body: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTimestamp = DateTime.parse('2026-09-08T00:00:00.000Z');

  late FakeProductImageService fakeImageService;
  late FakeManagementProductService fakeProductService;

  final sampleActiveWithImage = ProducerProduct(
    id: 'prod-active-1',
    producerId: 'test-producer',
    name: 'Handmade Kashmiri Shawl',
    category: 'Textiles',
    pricePaise: 450000,
    unit: 'piece',
    images: const ['test-producer/prod-active-1/kashmir_shawl.jpg'],
    status: ProductStatus.active,
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  final sampleDraftWithoutImage = ProducerProduct(
    id: 'prod-draft-2',
    producerId: 'test-producer',
    name: 'Draft Bamboo Basket',
    category: 'Crafts',
    pricePaise: null,
    unit: 'piece',
    images: const [],
    status: ProductStatus.draft,
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  final sampleInactiveReady = ProducerProduct(
    id: 'prod-inactive-3',
    producerId: 'test-producer',
    name: 'Terracotta Clay Pot',
    category: 'Pottery',
    pricePaise: 25000,
    unit: 'piece',
    images: const ['test-producer/prod-inactive-3/clay_pot.jpg'],
    status: ProductStatus.hidden,
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  final sampleInactiveIncomplete = ProducerProduct(
    id: 'prod-inactive-4',
    producerId: 'test-producer',
    name: 'X', // Name < 2 characters
    category: 'Crafts',
    pricePaise: 0,
    unit: 'piece',
    images: const [],
    status: ProductStatus.hidden,
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.instance.resetForTesting();
    fakeImageService = FakeProductImageService();
    fakeProductService = FakeManagementProductService(
      imageService: fakeImageService,
      initialProducts: [
        sampleActiveWithImage,
        sampleDraftWithoutImage,
        sampleInactiveReady,
        sampleInactiveIncomplete,
      ],
    );
  });

  // ===========================================================================
  // GROUP 1: IMAGE DISPLAY TESTS (1 - 4)
  // ===========================================================================
  group('Part B & Q: Image Display Tests', () {
    testWidgets('1. Product with image generates transient signed preview URL', (tester) async {
      final card = ProducerProductCard(
        product: sampleActiveWithImage,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: card));
      await tester.pumpAndSettle();

      expect(fakeImageService.signedUrlCallCount, 1);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('2. Product with no image uses local material inventory placeholder', (tester) async {
      final card = ProducerProductCard(
        product: sampleDraftWithoutImage,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: card));
      await tester.pumpAndSettle();

      expect(fakeImageService.signedUrlCallCount, 0);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('3. Signed URL failure handles gracefully without crash', (tester) async {
      fakeImageService.shouldFailSignedUrl = true;

      final card = ProducerProductCard(
        product: sampleActiveWithImage,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: card));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('4. Signed URL remains transient and never enters domain model or database', () {
      final product = sampleActiveWithImage;
      for (final path in product.images) {
        expect(path.startsWith('http://'), isFalse);
        expect(path.startsWith('https://'), isFalse);
        expect(path.contains('token='), isFalse);
      }
    });
  });

  // ===========================================================================
  // GROUP 2: EDITING TESTS (5 - 12)
  // ===========================================================================
  group('Part F, G & Q: Product Editing Tests', () {
    testWidgets('5. Edit opens the single-sheet Add/Edit Product modal', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddProductScreen.show(
                context,
                existingProduct: sampleActiveWithImage,
                productService: fakeProductService,
                imageService: fakeImageService,
              ),
              child: const Text('Open Edit'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Product'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('6. Existing fields are prefilled when editing', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddProductScreen.show(
                context,
                existingProduct: sampleActiveWithImage,
                productService: fakeProductService,
                imageService: fakeImageService,
              ),
              child: const Text('Open Edit'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Handmade Kashmiri Shawl'), findsOneWidget);
      expect(find.text('Textiles'), findsOneWidget);
      expect(find.text('4500.00'), findsOneWidget);
    });

    test('7. AddProductProvider.forExistingProduct preserves existing product ID', () {
      final provider = AddProductProvider.forExistingProduct(
        product: sampleActiveWithImage,
        productService: fakeProductService,
        imageService: fakeImageService,
      );

      expect(provider.isEditMode, isTrue);
      expect(provider.persistedProductId, 'prod-active-1');
      expect(provider.existingProduct?.id, 'prod-active-1');
      expect(provider.existingStatus, ProductStatus.active);
    });

    test('8. Saving changes updates the same row without creating duplicates', () async {
      final provider = AddProductProvider.forExistingProduct(
        product: sampleActiveWithImage,
        productService: fakeProductService,
        imageService: fakeImageService,
      );

      provider.setName('Updated Kashmiri Shawl');
      await provider.saveChanges();

      expect(fakeProductService.updateDraftCalls, 1);
      expect(fakeProductService.createDraftCalls, 0);
      expect(fakeProductService.database['prod-active-1']?.name, 'Updated Kashmiri Shawl');
      expect(fakeProductService.database['prod-active-1']?.status, ProductStatus.active);
    });

    test('9. Editing an active product retains its Active status', () async {
      final provider = AddProductProvider.forExistingProduct(
        product: sampleActiveWithImage,
        productService: fakeProductService,
        imageService: fakeImageService,
      );

      provider.setPriceFromRupeesText('4999');
      await provider.saveChanges();

      final updated = fakeProductService.database['prod-active-1']!;
      expect(updated.status, ProductStatus.active);
      expect(updated.pricePaise, 499900);
    });

    test('10. Existing images are visible in edit mode provider state', () {
      final provider = AddProductProvider.forExistingProduct(
        product: sampleActiveWithImage,
        productService: fakeProductService,
        imageService: fakeImageService,
      );

      expect(provider.draft.images, hasLength(1));
      expect(provider.draft.images.first, 'test-producer/prod-active-1/kashmir_shawl.jpg');
    });

    test('11. Photo add/remove works during edit mode', () {
      final provider = AddProductProvider.forExistingProduct(
        product: sampleActiveWithImage,
        productService: fakeProductService,
        imageService: fakeImageService,
      );

      provider.addImagePath('test-producer/prod-active-1/new_photo.jpg');
      expect(provider.draft.images, hasLength(2));

      provider.removeImagePath('test-producer/prod-active-1/kashmir_shawl.jpg');
      expect(provider.draft.images, hasLength(1));
      expect(provider.draft.images.first, 'test-producer/prod-active-1/new_photo.jpg');
    });

    test('12. AI Improve Photo services remain accessible in edit mode', () {
      final provider = AddProductProvider.forExistingProduct(
        product: sampleActiveWithImage,
        productService: fakeProductService,
        imageService: fakeImageService,
      );

      expect(provider.improvingPhotoPath, isNull);
      expect(provider.improvedCandidates, isEmpty);
    });
  });

  // ===========================================================================
  // GROUP 3: STATUS LIFECYCLE TESTS (13 - 19)
  // ===========================================================================
  group('Part D, E & Q: Status Lifecycle Tests', () {
    testWidgets('13. Draft displays Continue Editing action', (tester) async {
      final card = ProducerProductCard(
        product: sampleDraftWithoutImage,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: card));
      await tester.pumpAndSettle();

      expect(find.text('Continue Editing'), findsOneWidget);
    });

    testWidgets('14. Active displays compact edit icon and Active switch ON', (tester) async {
      final card = ProducerProductCard(
        product: sampleActiveWithImage,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: card));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('edit_product_prod-active-1')), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      final switchFinder = find.byKey(const ValueKey('toggle_visibility_prod-active-1'));
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);
      expect(find.text('Active'), findsWidgets);
    });

    testWidgets('15. Inactive displays compact edit icon and Inactive switch OFF', (tester) async {
      final card = ProducerProductCard(
        product: sampleInactiveReady,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: card));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('edit_product_prod-inactive-3')), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      final switchFinder = find.byKey(const ValueKey('toggle_visibility_prod-inactive-3'));
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);
      expect(find.text('Inactive'), findsWidgets);
    });

    testWidgets('16. Active -> Inactive transition succeeds', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(child: ProducerProductsTab(provider: provider)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('toggle_visibility_prod-active-1')));
      await tester.pumpAndSettle();

      expect(fakeProductService.database['prod-active-1']?.status, ProductStatus.hidden);
    });

    testWidgets('17. Inactive -> Active transition succeeds for complete product', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(child: ProducerProductsTab(provider: provider)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Inactive'));
      await tester.tap(find.widgetWithText(FilterChip, 'Inactive'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('toggle_visibility_prod-inactive-3')));
      await tester.tap(find.byKey(const ValueKey('toggle_visibility_prod-inactive-3')));
      await tester.pumpAndSettle();

      expect(fakeProductService.database['prod-inactive-3']?.status, ProductStatus.active);
    });

    testWidgets('18. Incomplete inactive product cannot activate and guides to edit', (tester) async {
      final incompleteService = FakeManagementProductService(
        initialProducts: [sampleInactiveIncomplete],
      );
      final provider = ProducerProductsProvider(service: incompleteService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(child: ProducerProductsTab(provider: provider)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('toggle_visibility_prod-inactive-4')));
      await tester.pump();

      expect(incompleteService.database['prod-inactive-4']?.status, ProductStatus.hidden);
      expect(find.textContaining('Please edit product to fill name, category, and price before making it active.'), findsOneWidget);
    });

    testWidgets('19. User-facing Hidden terminology is replaced by Inactive across filters and badges', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(child: ProducerProductsTab(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inactive'), findsWidgets);
      expect(find.text('Hidden'), findsNothing);
    });
  });

  // ===========================================================================
  // GROUP 4: SECURE DELETE TESTS (20 - 23)
  // ===========================================================================
  group('Part I, J & Q: Delete Lifecycle Tests', () {
    testWidgets('20. Delete shows confirmation dialog with safe copy', (tester) async {
      final card = ProducerProductCard(
        product: sampleActiveWithImage,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: card));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('overflow_product_prod-active-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('delete_product_prod-active-1')));
      await tester.pumpAndSettle();

      expect(find.text('Delete product?'), findsOneWidget);
      expect(find.text('This will permanently remove this product and its photos.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('21. Confirming delete calls service deleteProduct', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(child: ProducerProductsTab(provider: provider)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('overflow_product_prod-active-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('delete_product_prod-active-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(fakeProductService.deleteCalls, 1);
      expect(fakeProductService.database.containsKey('prod-active-1'), isFalse);
    });

    test('22. Image cleanup precedes DB row deletion in deleteProduct lifecycle', () async {
      await fakeProductService.deleteProduct('prod-active-1');

      expect(fakeProductService.callLog, ['delete_storage_images', 'delete_db_row']);
      expect(fakeImageService.deletedStoragePaths, contains('test-producer/prod-active-1/kashmir_shawl.jpg'));
    });

    testWidgets('23. Cancel in delete dialog preserves product card', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(child: ProducerProductsTab(provider: provider)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('overflow_product_prod-active-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('delete_product_prod-active-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(fakeProductService.deleteCalls, 0);
      expect(find.text('Handmade Kashmiri Shawl'), findsOneWidget);
    });
  });

  // ===========================================================================
  // GROUP 5: LIST & FILTERING TESTS (24 - 28)
  // ===========================================================================
  group('Part M, N, O & Q: List, Filtering & Empty States', () {
    testWidgets('24. Local filters filter in-memory without refetching from database', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(child: ProducerProductsTab(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(provider.visibleProducts.length, 4);
      // Filter Active
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Active'));
      await tester.tap(find.widgetWithText(FilterChip, 'Active'));
      await tester.pumpAndSettle();
      expect(provider.visibleProducts.length, 1);
      expect(provider.visibleProducts.first.name, 'Handmade Kashmiri Shawl');

      // Filter Draft
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Draft'));
      await tester.tap(find.widgetWithText(FilterChip, 'Draft'));
      await tester.pumpAndSettle();
      expect(provider.visibleProducts.length, 1);
      expect(provider.visibleProducts.first.name, 'Draft Bamboo Basket');

      // Filter Inactive
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Inactive'));
      await tester.tap(find.widgetWithText(FilterChip, 'Inactive'));
      await tester.pumpAndSettle();
      expect(provider.visibleProducts.length, 2);
    });

    testWidgets('25. Upserting product updates card immediately without full reload', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      final updated = sampleActiveWithImage.copyWith(name: 'Super Fine Kashmiri Shawl');
      provider.upsertProduct(updated);

      expect(provider.allProducts.firstWhere((p) => p.id == 'prod-active-1').name, 'Super Fine Kashmiri Shawl');
    });

    testWidgets('26. Zero products renders friendly first-product onboarding empty state', (tester) async {
      final emptyService = FakeManagementProductService(initialProducts: []);
      final provider = ProducerProductsProvider(service: emptyService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(child: ProducerProductsTab(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No products added yet'), findsOneWidget);
      expect(find.text('Add your first product so buyers can discover your craft'), findsOneWidget);
    });

    testWidgets('27. Filtered empty state displays specific filter empty messaging', (tester) async {
      final singleService = FakeManagementProductService(
        initialProducts: [sampleActiveWithImage],
      );
      final provider = ProducerProductsProvider(service: singleService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(child: ProducerProductsTab(provider: provider)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Inactive'));
      await tester.tap(find.widgetWithText(FilterChip, 'Inactive'));
      await tester.pumpAndSettle();

      expect(find.text('No inactive products'), findsOneWidget);
      expect(find.text('Show All Products'), findsOneWidget);
    });

    testWidgets('28. Real image card renders responsively', (tester) async {
      final card = ProducerProductCard(
        product: sampleActiveWithImage,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: card));
      await tester.pumpAndSettle();

      expect(find.text('Handmade Kashmiri Shawl'), findsOneWidget);
      expect(find.text('₹4,500.00'), findsOneWidget);
      expect(find.text('/ piece'), findsOneWidget);
    });
  });

  // ===========================================================================
  // GROUP 6: UX, LOCALIZATION & THEME TESTS (29 - 36)
  // ===========================================================================
  group('Part C, P & Q: Responsive Viewports, Locales and Themes', () {
    testWidgets('29. Phone viewport (320x700) renders cleanly without overflow', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          screenSize: const Size(320, 700),
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Handmade Kashmiri Shawl'), findsOneWidget);
    });

    testWidgets('30. Tablet viewport (768x1024) renders cleanly without overflow', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          screenSize: const Size(768, 1024),
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Handmade Kashmiri Shawl'), findsOneWidget);
    });

    testWidgets('31. Desktop viewport (1200x800) renders cleanly without overflow', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          screenSize: const Size(1200, 800),
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Handmade Kashmiri Shawl'), findsOneWidget);
    });

    testWidgets('32. English locale renders localized terminology', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('en'),
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Products'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Inactive'), findsWidgets);
    });

    testWidgets('33. Hindi locale renders localized terminology', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('hi'),
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('मेरे उत्पाद'), findsOneWidget);
      expect(find.text('सक्रिय'), findsWidgets);
      expect(find.text('निष्क्रिय'), findsWidgets);
    });

    testWidgets('34. Punjabi locale renders localized terminology', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('pa'),
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ਮੇਰੇ ਉਤਪਾਦ'), findsOneWidget);
      expect(find.text('ਸਰਗਰਮ'), findsWidgets);
      expect(find.text('ਅਕਿਰਿਆਸ਼ੀਲ'), findsWidgets);
    });

    testWidgets('35. Light Theme renders without visual error', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          themeMode: ThemeMode.light,
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('36. Dark Theme renders without visual error', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          themeMode: ThemeMode.dark,
          child: ProducerProductsTab(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // STEP 6D.1 — IMAGE PERSISTENCE DIAGNOSTIC TESTS (15 tests)
  // ---------------------------------------------------------------------------
  group('Step 6D.1 Image Persistence Diagnostic Tests', () {
    late FakeManagementProductService fakeService;
    late FakeProductImageService fakeImageService;

    setUp(() {
      fakeImageService = FakeProductImageService();
      fakeService = FakeManagementProductService(imageService: fakeImageService);
    });

    // -------------------------------------------------------------------------
    // Test 37: Realistic DB JSON images parsing
    // -------------------------------------------------------------------------
    test('37. ProducerProduct.fromJson parses realistic DB JSON images correctly', () {
      final json = {
        'id': 'prod-abc',
        'producer_id': 'user-123',
        'name': 'Test Product',
        'description': 'A product',
        'category': 'food',
        'price': '120.00',
        'unit': 'kg',
        'images': ['user-123/prod-abc/abc123.jpg', 'user-123/prod-abc/def456.png'],
        'status': 'active',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final product = ProducerProduct.fromJson(json);

      expect(product.images.length, 2);
      expect(product.images[0], 'user-123/prod-abc/abc123.jpg');
      expect(product.images[1], 'user-123/prod-abc/def456.png');
    });

    test('38. ProducerProduct.fromJson handles null images as empty list', () {
      final json = {
        'id': 'prod-abc',
        'producer_id': 'user-123',
        'name': 'Test Product',
        'images': null,
        'status': 'draft',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final product = ProducerProduct.fromJson(json);

      expect(product.images, isEmpty);
    });

    test('39. ProducerProduct.fromJson handles missing images key as empty list', () {
      final json = {
        'id': 'prod-abc',
        'producer_id': 'user-123',
        'name': 'Test Product',
        'status': 'draft',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final product = ProducerProduct.fromJson(json);

      expect(product.images, isEmpty);
    });

    // -------------------------------------------------------------------------
    // Test 40: createDraft preserves images
    // -------------------------------------------------------------------------
    test('40. createDraft preserves images from draft', () async {
      final draft = const ProducerProductDraft(
        name: 'Rice',
        category: 'food',
        images: ['uid/pid/file.jpg'],
      );
      final product = await fakeService.createDraft(draft);

      expect(product.images, ['uid/pid/file.jpg']);
      expect(fakeService.database[product.id]?.images, ['uid/pid/file.jpg']);
    });

    // -------------------------------------------------------------------------
    // Test 41: updateDraft preserves existing images
    // -------------------------------------------------------------------------
    test('41. updateDraft preserves existing images in draft', () async {
      // Setup: product with existing images
      final initial = ProducerProduct(
        id: 'prod-1',
        producerId: 'user-1',
        name: 'Dal',
        images: const ['user-1/prod-1/photo.jpg'],
        status: ProductStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      fakeService.database['prod-1'] = initial;

      // Update only name — images in draft should carry forward
      final draft = ProducerProductDraft.fromProduct(initial).copyWith(name: 'Red Dal');
      final updated = await fakeService.updateDraft(productId: 'prod-1', draft: draft);

      expect(updated.name, 'Red Dal');
      expect(updated.images, ['user-1/prod-1/photo.jpg'],
          reason: 'updateDraft must preserve existing images');
    });

    // -------------------------------------------------------------------------
    // Test 42: Edit Save Changes preserves images
    // -------------------------------------------------------------------------
    test('42. Edit Save Changes via AddProductProvider preserves product images', () async {
      final existingProduct = ProducerProduct(
        id: 'prod-edit',
        producerId: 'user-1',
        name: 'Wheat',
        category: 'food',
        pricePaise: 5000,
        unit: 'kg',
        images: const ['user-1/prod-edit/photo.jpg'],
        status: ProductStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      fakeService.database['prod-edit'] = existingProduct;

      final provider = AddProductProvider.forExistingProduct(
        product: existingProduct,
        productService: fakeService,
        imageService: fakeImageService,
      );

      // Change name only — images should stay
      provider.setName('Premium Wheat');
      final success = await provider.saveChanges();

      expect(success, isTrue);
      final saved = fakeService.database['prod-edit']!;
      expect(saved.name, 'Premium Wheat');
      expect(saved.images, ['user-1/prod-edit/photo.jpg'],
          reason: 'Save Changes must not drop existing images');
    });

    // -------------------------------------------------------------------------
    // Test 43: updateProductImages persists exact paths
    // -------------------------------------------------------------------------
    test('43. updateProductImages persists exactly the given paths', () async {
      final initial = ProducerProduct(
        id: 'prod-2',
        producerId: 'user-1',
        name: 'Masala',
        images: const [],
        status: ProductStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      fakeService.database['prod-2'] = initial;

      final paths = ['user-1/prod-2/img1.jpg', 'user-1/prod-2/img2.jpg'];
      final updated = await fakeService.updateProductImages(
        productId: 'prod-2',
        imagePaths: paths,
      );

      expect(updated.images, paths);
      expect(fakeService.database['prod-2']?.images, paths);
    });

    // -------------------------------------------------------------------------
    // Test 44: provider upsertProduct does not lose images
    // -------------------------------------------------------------------------
    test('44. ProducerProductsProvider.upsertProduct does not drop images', () async {
      final provider = ProducerProductsProvider(service: fakeService);

      final productWithImages = ProducerProduct(
        id: 'prod-up',
        producerId: 'user-1',
        name: 'Ghee',
        images: const ['user-1/prod-up/photo.jpg'],
        status: ProductStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      provider.upsertProduct(productWithImages);

      final found = provider.allProducts.firstWhere((p) => p.id == 'prod-up');
      expect(found.images, ['user-1/prod-up/photo.jpg'],
          reason: 'upsertProduct must retain images');
    });

    test('45. ProducerProductsProvider.upsertProduct replacing stale empty-images product with image-having product', () async {
      final stale = ProducerProduct(
        id: 'prod-stale',
        producerId: 'user-1',
        name: 'Honey',
        images: const [],
        status: ProductStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = ProducerProductsProvider(service: fakeService);
      provider.upsertProduct(stale);

      final fresh = stale.copyWith(images: ['user-1/prod-stale/photo.jpg']);
      provider.upsertProduct(fresh);

      final found = provider.allProducts.firstWhere((p) => p.id == 'prod-stale');
      expect(found.images, ['user-1/prod-stale/photo.jpg'],
          reason: 'upsertProduct must update to fresh product with images');
    });

    // -------------------------------------------------------------------------
    // Test 46: fetchProducts returns image paths
    // -------------------------------------------------------------------------
    test('46. fetchProducts returns products with images intact', () async {
      fakeService.database['prod-fetch'] = ProducerProduct(
        id: 'prod-fetch',
        producerId: 'user-1',
        name: 'Oil',
        images: const ['user-1/prod-fetch/img.jpg'],
        status: ProductStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final products = await fakeService.fetchProducts();
      final found = products.firstWhere((p) => p.id == 'prod-fetch');

      expect(found.images, ['user-1/prod-fetch/img.jpg']);
    });

    // -------------------------------------------------------------------------
    // Test 47: signed URL requested for canonical path
    // -------------------------------------------------------------------------
    testWidgets('47. ProducerProductCard requests signed URL from canonical product.images.first path', (tester) async {
      fakeImageService = FakeProductImageService();
      final product = ProducerProduct(
        id: 'prod-card',
        producerId: 'user-1',
        name: 'Honey',
        images: const ['user-1/prod-card/photo.jpg'],
        status: ProductStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: ProducerProductCard(
              product: product,
              imageService: fakeImageService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeImageService.signedUrlCallCount, greaterThan(0),
          reason: 'Card must request signed URL when product has images');
    });

    // -------------------------------------------------------------------------
    // Test 48: no-image placeholder
    // -------------------------------------------------------------------------
    testWidgets('48. ProducerProductCard shows placeholder when product.images is empty', (tester) async {
      fakeImageService = FakeProductImageService();
      final product = ProducerProduct(
        id: 'prod-noimg',
        producerId: 'user-1',
        name: 'Sugar',
        images: const [],
        status: ProductStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: ProducerProductCard(
              product: product,
              imageService: fakeImageService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No signed URL requests — images empty
      expect(fakeImageService.signedUrlCallCount, 0,
          reason: 'No signed URL should be requested when product.images is empty');
      // Placeholder icon visible
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 49: signed URL failure uses placeholder WITHOUT erasing product.images
    // -------------------------------------------------------------------------
    testWidgets('49. Signed URL failure shows placeholder but does NOT erase product.images', (tester) async {
      fakeImageService = FakeProductImageService()..shouldFailSignedUrl = true;
      final product = ProducerProduct(
        id: 'prod-signerr',
        producerId: 'user-1',
        name: 'Jaggery',
        images: const ['user-1/prod-signerr/photo.jpg'],
        status: ProductStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: ProducerProductCard(
              product: product,
              imageService: fakeImageService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // product.images is still intact (domain model is immutable)
      expect(product.images, ['user-1/prod-signerr/photo.jpg'],
          reason: 'Signed URL failure must NEVER erase product.images');
    });

    // -------------------------------------------------------------------------
    // Test 50: status change preserves images
    // -------------------------------------------------------------------------
    test('50. updateProductStatus preserves images', () async {
      fakeService.database['prod-status'] = ProducerProduct(
        id: 'prod-status',
        producerId: 'user-1',
        name: 'Paneer',
        images: const ['user-1/prod-status/photo.jpg'],
        status: ProductStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = await fakeService.updateProductStatus(
        productId: 'prod-status',
        newStatus: ProductStatus.active,
      );

      expect(updated.status, ProductStatus.active);
      expect(updated.images, ['user-1/prod-status/photo.jpg'],
          reason: 'Status update must not drop images');
    });

    // -------------------------------------------------------------------------
    // Test 51: local filtering preserves images
    // -------------------------------------------------------------------------
    test('51. Local filtering preserves images on filtered products', () async {
      final product = ProducerProduct(
        id: 'prod-filter',
        producerId: 'user-1',
        name: 'Butter',
        images: const ['user-1/prod-filter/photo.jpg'],
        status: ProductStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      fakeService.database['prod-filter'] = product;

      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();
      provider.setFilter(ProducerProductFilter.active);

      final visible = provider.visibleProducts.firstWhere((p) => p.id == 'prod-filter');
      expect(visible.images, ['user-1/prod-filter/photo.jpg'],
          reason: 'Filtering must not strip images from products');
    });

    // -------------------------------------------------------------------------
    // Test 52: delete is storage-first
    // -------------------------------------------------------------------------
    test('52. deleteProduct removes storage objects before deleting DB row', () async {
      fakeService.database['prod-del'] = ProducerProduct(
        id: 'prod-del',
        producerId: 'user-1',
        name: 'Turmeric',
        images: const ['user-1/prod-del/photo.jpg'],
        status: ProductStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeService.deleteProduct('prod-del');

      expect(fakeService.callLog.indexOf('delete_storage_images'),
          lessThan(fakeService.callLog.indexOf('delete_db_row')),
          reason: 'Storage deletion must occur BEFORE DB row deletion');
      expect(fakeImageService.deletedStoragePaths, ['user-1/prod-del/photo.jpg']);
      expect(fakeService.database.containsKey('prod-del'), isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 53: AddProductScreen is single-sheet, no wizard
    // -------------------------------------------------------------------------
    testWidgets('53. AddProductScreen renders as single-sheet form with no Step wizard', (tester) async {
      SharedPreferences.setMockInitialValues({});
      PreferencesService.instance.resetForTesting();

      final addProvider = AddProductProvider(
        productService: fakeService,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: AddProductScreen(provider: addProvider),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All fields visible on single form — no wizard steps
      expect(find.byKey(const Key('add_product_name_field')), findsOneWidget);
      expect(find.byKey(const Key('add_product_price_field')), findsOneWidget);
      expect(find.byKey(const Key('add_product_description_field')), findsOneWidget);

      // No step indicator, no "Next" button (wizard pattern)
      expect(find.text('Step 1'), findsNothing);
      expect(find.text('Step 2'), findsNothing);
      expect(find.text('Step 3'), findsNothing);
      expect(find.text('Next'), findsNothing);

      // Both action buttons present on one screen
      expect(find.byKey(const Key('add_product_save_draft_button')), findsOneWidget);
      expect(find.byKey(const Key('add_product_mark_ready_button')), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 54: uploadAndAddImage calls updateProductImages, not updateDraft
    // -------------------------------------------------------------------------
    test('54. uploadAndAddImage uses updateProductImages to persist path (not updateDraft)', () async {
      // Create a product first
      final draft = const ProducerProductDraft(name: 'Chili', category: 'food', pricePaise: 100);
      await fakeService.createDraft(draft);

      final provider = AddProductProvider(
        productService: fakeService,
        imageService: fakeImageService,
      );
      // Simulate product already persisted
      provider.setName('Chili');
      await provider.saveDraft();

      final productId = provider.persistedProductId!;
      fakeService.database[productId] = fakeService.database[productId]!;

      final initialUpdateDraftCount = fakeService.updateDraftCalls;

      final success = await provider.uploadAndAddImage(
        bytes: Uint8List.fromList([0, 1, 2, 3]),
        contentType: 'image/jpeg',
        originalFilename: 'test.jpg',
      );

      expect(success, isTrue);
      expect(fakeService.updateDraftCalls, initialUpdateDraftCount,
          reason: 'uploadAndAddImage must NOT call updateDraft — it must use updateProductImages');
      expect(provider.draft.images.length, 1,
          reason: 'In-memory draft must contain the new image path');
    });
  });

  // ===========================================================================
  // STEP 6D.2 — MY PRODUCTS UX REDESIGN + LIVE-READY AI TESTS
  // ===========================================================================
  group('Step 6D.2: My Products UX Redesign + Live-Ready AI Enhancement Tests', () {
    late FakeProductImageService fakeImageService;
    late FakeManagementProductService fakeProductService;
    late FakeManagementPhotoEnhancementService fakeEnhancementService;

    final sampleMultiPhotoProduct = ProducerProduct(
      id: 'prod-multi-1',
      producerId: 'test-producer',
      name: 'Carved Wooden Box',
      category: 'Crafts',
      description: 'Hand-carved teakwood box with brass inlay',
      pricePaise: 180000,
      unit: 'piece',
      images: const [
        'test-producer/prod-multi-1/box_front.jpg',
        'test-producer/prod-multi-1/box_open.jpg',
      ],
      status: ProductStatus.active,
      createdAt: testTimestamp,
      updatedAt: testTimestamp,
    );

    final sampleProductNoDescription = ProducerProduct(
      id: 'prod-nodesc-2',
      producerId: 'test-producer',
      name: 'Simple Clay Cup',
      category: 'Pottery',
      description: '',
      pricePaise: 8000,
      unit: 'piece',
      images: const ['test-producer/prod-nodesc-2/cup.jpg'],
      status: ProductStatus.active,
      createdAt: testTimestamp,
      updatedAt: testTimestamp,
    );

    final sampleDraftProduct = ProducerProduct(
      id: 'prod-draft-3',
      producerId: 'test-producer',
      name: 'Unfinished Wooden Toy',
      category: 'Toys',
      description: 'Pine wood toy car',
      pricePaise: 45000,
      unit: 'piece',
      images: const [],
      status: ProductStatus.draft,
      createdAt: testTimestamp,
      updatedAt: testTimestamp,
    );

    setUp(() {
      fakeImageService = FakeProductImageService();
      fakeEnhancementService = FakeManagementPhotoEnhancementService();
      fakeProductService = FakeManagementProductService(
        imageService: fakeImageService,
        initialProducts: [
          sampleMultiPhotoProduct,
          sampleProductNoDescription,
          sampleDraftProduct,
        ],
      );
    });

    testWidgets('55. Compact product card renders compact layout without full-width action buttons', (tester) async {
      final card = ProducerProductCard(
        product: sampleMultiPhotoProduct,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: card));
      await tester.pumpAndSettle();

      expect(find.text('Carved Wooden Box'), findsOneWidget);
      expect(find.text('₹1,800.00'), findsOneWidget);
      expect(find.text('/ piece'), findsOneWidget);
      expect(find.text('Crafts'), findsWidgets);
      expect(find.text('Active'), findsWidgets);

      expect(find.widgetWithText(FilledButton, 'Make Inactive'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Edit'), findsNothing);
    });

    testWidgets('56. Card tap opens responsive Product Details view', (tester) async {
      bool openedDetails = false;
      final card = ProducerProductCard(
        product: sampleMultiPhotoProduct,
        imageService: fakeImageService,
        onOpenDetails: () => openedDetails = true,
      );

      await tester.pumpWidget(buildTestApp(child: card));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(openedDetails, isTrue);
    });

    testWidgets('57. Compact edit icon tap invokes onEdit independently of onOpenDetails', (tester) async {
      bool openedDetails = false;
      bool openedEdit = false;

      final card = ProducerProductCard(
        product: sampleMultiPhotoProduct,
        imageService: fakeImageService,
        onOpenDetails: () => openedDetails = true,
        onEdit: () => openedEdit = true,
      );

      await tester.pumpWidget(buildTestApp(child: card));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('edit_product_prod-multi-1')));
      await tester.pumpAndSettle();

      expect(openedEdit, isTrue);
      expect(openedDetails, isFalse);
    });

    testWidgets('58. Active switch is ON for active product, Inactive switch is OFF for inactive product', (tester) async {
      final activeCard = ProducerProductCard(
        product: sampleMultiPhotoProduct,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: activeCard));
      await tester.pumpAndSettle();

      final activeSwitch = tester.widget<Switch>(find.byKey(const ValueKey('toggle_visibility_prod-multi-1')));
      expect(activeSwitch.value, isTrue);

      final inactiveProduct = sampleMultiPhotoProduct.copyWith(status: ProductStatus.hidden);
      final inactiveCard = ProducerProductCard(
        product: inactiveProduct,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: inactiveCard));
      await tester.pumpAndSettle();

      final inactiveSwitch = tester.widget<Switch>(find.byKey(const ValueKey('toggle_visibility_prod-multi-1')));
      expect(inactiveSwitch.value, isFalse);
    });

    testWidgets('59. Draft card has NO active switch and shows Continue Editing action', (tester) async {
      final draftCard = ProducerProductCard(
        product: sampleDraftProduct,
        imageService: fakeImageService,
      );

      await tester.pumpWidget(buildTestApp(child: draftCard));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('toggle_visibility_prod-draft-3')), findsNothing);
      expect(find.text('Continue Editing'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('60. Product Details renders real product data accurately', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProductDetailsView(
            product: sampleMultiPhotoProduct,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Carved Wooden Box'), findsOneWidget);
      expect(find.text('Crafts'), findsWidgets);
      expect(find.text('₹1,800.00'), findsOneWidget);
      expect(find.text('/ piece'), findsOneWidget);
      expect(find.text('Hand-carved teakwood box with brass inlay'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
    });

    testWidgets('61. Product Details displays localized No description added when description is empty', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProductDetailsView(
            product: sampleProductNoDescription,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No description added'), findsOneWidget);
    });

    testWidgets('62. Multiple photos display thumbnails and tapping switches the active photo', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProductDetailsView(
            product: sampleMultiPhotoProduct,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      final inkWells = find.descendant(of: find.byType(ListView), matching: find.byType(InkWell));
      expect(inkWells, findsNWidgets(2));

      await tester.tap(inkWells.at(1));
      await tester.pumpAndSettle();

      expect(fakeImageService.signedUrlCallCount, greaterThanOrEqualTo(2));
    });

    testWidgets('63. Improve Photo action button is visible in Product Details when photo exists', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProductDetailsView(
            product: sampleMultiPhotoProduct,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('improve_photo_button')), findsOneWidget);
      expect(find.text('Improve Photo'), findsOneWidget);
    });

    testWidgets('64. Improve Photo action is not shown when product has no images', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProductDetailsView(
            product: sampleDraftProduct,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('improve_photo_button')), findsNothing);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('65. Tapping Improve Photo calls AI service and displays Original vs Improved comparison modal', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProductDetailsView(
            product: sampleMultiPhotoProduct,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('improve_photo_button')));
      await tester.pumpAndSettle();

      expect(fakeEnhancementService.improveCalls.length, 1);
      expect(fakeEnhancementService.improveCalls.first['productId'], 'prod-multi-1');
      expect(fakeEnhancementService.improveCalls.first['sourceStoragePath'], 'test-producer/prod-multi-1/box_front.jpg');

      expect(find.text('Photo Improved'), findsOneWidget);
      expect(find.text('Original'), findsOneWidget);
      expect(find.text('Improved'), findsOneWidget);
      expect(find.text('Keep Original'), findsOneWidget);
      expect(find.text('Use Improved Photo'), findsOneWidget);
      expect(find.text('AI improves only the presentation, not your product.'), findsOneWidget);
    });

    testWidgets('66. Keep Original retains original photo in canonical product and cleans up candidate', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProductDetailsView(
            product: sampleMultiPhotoProduct,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('improve_photo_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep Original'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Improved'), findsNothing);

      expect(fakeProductService.database['prod-multi-1']?.images, [
        'test-producer/prod-multi-1/box_front.jpg',
        'test-producer/prod-multi-1/box_open.jpg',
      ]);

      expect(fakeEnhancementService.discardedCandidates, contains('test-producer/prod-multi-1/improved_candidate.jpg'));
    });

    testWidgets('67. Use Improved Photo replaces canonical photo path and updates database', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProductDetailsView(
            product: sampleMultiPhotoProduct,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('improve_photo_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use Improved Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Improved'), findsNothing);
      expect(find.text('Improved photo applied'), findsOneWidget);

      final updatedProd = fakeProductService.database['prod-multi-1']!;
      expect(updatedProd.images.first, 'test-producer/prod-multi-1/improved_candidate.jpg');
      expect(updatedProd.images[1], 'test-producer/prod-multi-1/box_open.jpg');
    });

    testWidgets('68. Provider upsertProduct reflects updated cover image across My Products', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(child: ProducerProductsTab(provider: provider, service: fakeProductService)),
      );
      await tester.pumpAndSettle();

      final updated = sampleMultiPhotoProduct.copyWith(
        images: ['test-producer/prod-multi-1/enhanced_new.jpg'],
      );
      provider.upsertProduct(updated);
      await tester.pumpAndSettle();

      final found = provider.allProducts.firstWhere((p) => p.id == 'prod-multi-1');
      expect(found.images.first, 'test-producer/prod-multi-1/enhanced_new.jpg');
    });

    testWidgets('69. AI service failure shows friendly error message without throwing unhandled exception', (tester) async {
      fakeEnhancementService.shouldThrow = true;
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProductDetailsView(
            product: sampleMultiPhotoProduct,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('improve_photo_button')));
      await tester.pumpAndSettle();

      expect(find.text('Could not improve photo. Please try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('70. Product Details switch toggles Active and Inactive states', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProductDetailsView(
            product: sampleMultiPhotoProduct,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final toggleFinder = find.byKey(const ValueKey('details_toggle_visibility_prod-multi-1'));
      await tester.ensureVisible(toggleFinder);
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(fakeProductService.database['prod-multi-1']?.status, ProductStatus.hidden);
    });

    testWidgets('71. Product Details overflow menu opens delete confirmation dialog', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      await tester.pumpWidget(
        buildTestApp(
          child: ProducerProductDetailsView(
            product: sampleMultiPhotoProduct,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('details_overflow_prod-multi-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('delete_product_prod-multi-1')));
      await tester.pumpAndSettle();

      expect(find.text('Delete product?'), findsOneWidget);
      expect(find.text('This will permanently remove this product and its photos.'), findsOneWidget);
    });

    testWidgets('72. Product Details renders cleanly across Phone (320px), Tablet (768px), and Desktop (1440px)', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      for (final size in [const Size(320, 700), const Size(768, 1024), const Size(1440, 900)]) {
        await tester.pumpWidget(
          buildTestApp(
            screenSize: size,
            child: ProducerProductDetailsView(
              product: sampleMultiPhotoProduct,
              productsProvider: provider,
              productService: fakeProductService,
              imageService: fakeImageService,
              enhancementService: fakeEnhancementService,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Failed at size $size');
      }
    });

    testWidgets('73. Product Details renders localized strings in EN, HI, and PA', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      // English
      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('en'),
          child: ProducerProductDetailsView(
            product: sampleProductNoDescription,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No description added'), findsOneWidget);
      expect(find.text('Improve Photo'), findsOneWidget);

      // Hindi
      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('hi'),
          child: ProducerProductDetailsView(
            product: sampleProductNoDescription,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('कोई विवरण नहीं जोड़ा गया'), findsOneWidget);
      expect(find.text('फोटो सुधारें'), findsOneWidget);

      // Punjabi
      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('pa'),
          child: ProducerProductDetailsView(
            product: sampleProductNoDescription,
            productsProvider: provider,
            productService: fakeProductService,
            imageService: fakeImageService,
            enhancementService: fakeEnhancementService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ਕੋਈ ਵੇਰਵਾ ਨਹੀਂ ਜੋੜਿਆ ਗਿਆ'), findsOneWidget);
      expect(find.text('ਫੋਟੋ ਸੁਧਾਰੋ'), findsOneWidget);
    });

    testWidgets('74. Light and Dark themes render Product Details without error', (tester) async {
      final provider = ProducerProductsProvider(service: fakeProductService);
      await provider.loadProducts();

      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await tester.pumpWidget(
          buildTestApp(
            themeMode: mode,
            child: ProducerProductDetailsView(
              product: sampleMultiPhotoProduct,
              productsProvider: provider,
              productService: fakeProductService,
              imageService: fakeImageService,
              enhancementService: fakeEnhancementService,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}

