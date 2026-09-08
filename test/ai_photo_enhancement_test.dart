import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';
import 'package:buyer_section/producer_section/products/providers/add_product_provider.dart';
import 'package:buyer_section/producer_section/products/screens/add_product_screen.dart';
import 'package:buyer_section/producer_section/products/services/producer_image_picker_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_enhancement_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_image_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

// -----------------------------------------------------------------------------
// FAKES FOR TESTING
// -----------------------------------------------------------------------------

class FakeProductPhotoEnhancementService implements IProductPhotoEnhancementService {
  bool throwOnImprove = false;
  Completer<void>? pendingImproveCompleter;
  final List<Map<String, String>> improveCalls = [];
  final List<String> discardedCandidates = [];

  @override
  Future<EnhancementResult> improvePhoto({
    required String productId,
    required String sourceStoragePath,
  }) async {
    improveCalls.add({
      'productId': productId,
      'sourceStoragePath': sourceStoragePath,
    });

    if (pendingImproveCompleter != null) {
      await pendingImproveCompleter!.future;
    }

    if (throwOnImprove) {
      throw const ProductOperationException('AI enhancement provider timeout');
    }

    final ext = sourceStoragePath.split('.').last;
    final candidatePath = 'test-user/$productId/enhanced_${improveCalls.length}.$ext';
    return EnhancementResult(
      improvedStoragePath: candidatePath,
      sourceStoragePath: sourceStoragePath,
    );
  }

  @override
  Future<void> discardCandidateImage(String candidateStoragePath) async {
    discardedCandidates.add(candidateStoragePath);
  }
}

class FakeProductImageService implements IProducerProductImageService {
  final List<String> uploadedPaths = [];
  final List<String> deletedPaths = [];
  final Map<String, Uint8List> storageObjects = {};

  @override
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ext = ProducerProductImageService.normalizeMimeType(contentType);
    final path = 'test-user/$productId/orig_${uploadedPaths.length + 1}.$ext';
    uploadedPaths.add(path);
    storageObjects[path] = bytes;
    return path;
  }

  @override
  Future<void> deleteProductImage(String storagePath) async {
    deletedPaths.add(storagePath);
    storageObjects.remove(storagePath);
  }

  @override
  Future<String> createSignedImageUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    return 'https://supabase.co/storage/v1/sign/$storagePath?token=mock';
  }
}

class FakeProductService implements IProducerProductService {
  final Map<String, ProducerProduct> products = {};
  bool throwOnUpdate = false;
  int _counter = 1;

  @override
  final IProducerProductImageService? imageService = null;

  @override
  Future<ProducerProduct> createDraft(ProducerProductDraft draft) async {
    final id = 'prod-uuid-$_counter';
    _counter++;
    final product = ProducerProduct(
      id: id,
      producerId: 'test-user',
      name: draft.name,
      category: draft.category,
      description: draft.description,
      pricePaise: draft.pricePaise ?? 0,
      unit: draft.unit,
      status: ProductStatus.draft,
      images: draft.images,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    products[id] = product;
    return product;
  }

  @override
  Future<ProducerProduct> updateDraft({
    required String productId,
    required ProducerProductDraft draft,
  }) async {
    if (throwOnUpdate) {
      throw const ProductOperationException('Database draft update failed');
    }
    final existing = products[productId];
    final updated = ProducerProduct(
      id: productId,
      producerId: existing?.producerId ?? 'test-user',
      name: draft.name,
      category: draft.category,
      description: draft.description,
      pricePaise: draft.pricePaise ?? 0,
      unit: draft.unit,
      status: existing?.status ?? ProductStatus.draft,
      images: draft.images,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    products[productId] = updated;
    return updated;
  }

  @override
  Future<ProducerProduct> updateProductImages({
    required String productId,
    required List<String> imagePaths,
  }) async {
    if (throwOnUpdate) {
      throw const ProductOperationException('Database images update failed');
    }
    final existing = products[productId];
    if (existing == null) {
      throw const ProductOperationException('Product not found');
    }
    final updated = ProducerProduct(
      id: productId,
      producerId: existing.producerId,
      name: existing.name,
      category: existing.category,
      description: existing.description,
      pricePaise: existing.pricePaise,
      unit: existing.unit,
      status: existing.status,
      images: List.unmodifiable(imagePaths),
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    products[productId] = updated;
    return updated;
  }

  @override
  Future<ProducerProduct> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  }) async {
    final existing = products[productId];
    if (existing == null) {
      throw const ProductOperationException('Product not found');
    }
    final updated = ProducerProduct(
      id: productId,
      producerId: existing.producerId,
      name: existing.name,
      category: existing.category,
      description: existing.description,
      pricePaise: existing.pricePaise,
      unit: existing.unit,
      status: newStatus,
      images: existing.images,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    products[productId] = updated;
    return updated;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    products.remove(productId);
  }

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async {
    return products.values.toList();
  }
}

class FakeImagePickerService implements IProducerImagePickerService {
  @override
  bool get isCameraSupported => true;

  @override
  Future<PickedProductImage?> pickImage(ImageSourceOption source) async {
    return null;
  }
}

// -----------------------------------------------------------------------------
// APP WRAPPER HELPER
// -----------------------------------------------------------------------------

Widget createTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    locale: locale,
    themeMode: themeMode,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
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

// -----------------------------------------------------------------------------
// MAIN TEST SUITE
// -----------------------------------------------------------------------------

void main() {
  group('AI Photo Enhancement Domain & Provider Tests (Step 6C.6B)', () {
    late FakeProductService fakeProductService;
    late FakeProductImageService fakeImageService;
    late FakeProductPhotoEnhancementService fakeEnhancementService;
    late FakeImagePickerService fakePickerService;
    late AddProductProvider provider;

    setUp(() {
      fakeProductService = FakeProductService();
      fakeImageService = FakeProductImageService();
      fakeEnhancementService = FakeProductPhotoEnhancementService();
      fakePickerService = FakeImagePickerService();

      provider = AddProductProvider(
        productService: fakeProductService,
        imageService: fakeImageService,
        imagePickerService: fakePickerService,
        enhancementService: fakeEnhancementService,
      );
    });

    test('Test 2: AI service called with correct productId + source stable path', () async {
      provider.setName('Handmade Shawl');
      provider.setCategory('clothing');
      await provider.saveDraft();
      final productId = provider.persistedProductId!;

      const originalPath = 'test-user/prod-1/orig_1.jpg';
      provider.addImagePath(originalPath);

      final ok = await provider.improvePhoto(originalPath);

      expect(ok, true);
      expect(fakeEnhancementService.improveCalls.length, 1);
      expect(fakeEnhancementService.improveCalls.first['productId'], productId);
      expect(fakeEnhancementService.improveCalls.first['sourceStoragePath'], originalPath);
      expect(provider.hasCandidateForPhoto(originalPath), true);
    });

    test('Test 3: Busy state prevents duplicate concurrent enhancement requests', () async {
      provider.setName('Handmade Shawl');
      const path1 = 'test-user/prod-1/orig_1.jpg';
      const path2 = 'test-user/prod-1/orig_2.jpg';
      provider.addImagePath(path1);
      provider.addImagePath(path2);
      await provider.saveDraft();

      final completer = Completer<void>();
      fakeEnhancementService.pendingImproveCompleter = completer;

      // Trigger first improvement
      final future1 = provider.improvePhoto(path1);
      expect(provider.isImprovingPhoto, true);
      expect(provider.isPhotoBeingImproved(path1), true);

      // Concurrently try path 2
      final ok2 = await provider.improvePhoto(path2);
      expect(ok2, false);

      completer.complete();
      await future1;
      expect(provider.isImprovingPhoto, false);
    });

    test('Test 4: Failure leaves original photo and canonical DB unchanged', () async {
      provider.setName('Clay Pot');
      await provider.saveDraft();
      const originalPath = 'test-user/prod-1/pot.jpg';
      provider.addImagePath(originalPath);
      await provider.saveDraft();

      fakeEnhancementService.throwOnImprove = true;

      final ok = await provider.improvePhoto(originalPath);

      expect(ok, false);
      expect(provider.hasError, true);
      expect(provider.errorMessage, contains('AI enhancement provider timeout'));
      expect(provider.draft.images, [originalPath]);
      expect(provider.hasCandidateForPhoto(originalPath), false);
    });

    test('Test 5: Successful candidate does NOT automatically change products.images', () async {
      provider.setName('Clay Pot');
      await provider.saveDraft();
      const originalPath = 'test-user/prod-1/pot.jpg';
      provider.addImagePath(originalPath);
      await provider.saveDraft();

      final ok = await provider.improvePhoto(originalPath);
      expect(ok, true);

      // Invariant: draft.images and DB products.images MUST still be originalPath
      expect(provider.draft.images, [originalPath]);
      final persisted = fakeProductService.products[provider.persistedProductId!]!;
      expect(persisted.images, [originalPath]);

      // Candidate path exists only in transient state
      final candidate = provider.getCandidateForPhoto(originalPath);
      expect(candidate, isNotNull);
      expect(candidate, isNot(originalPath));
    });

    test('Test 6: Signed candidate URL remains transient and never written to DB', () async {
      provider.setName('Brass Lamp');
      await provider.saveDraft();
      const originalPath = 'test-user/prod-1/lamp.jpg';
      provider.addImagePath(originalPath);

      await provider.improvePhoto(originalPath);
      final candidatePath = provider.getCandidateForPhoto(originalPath)!;

      // Signed URL exists in transient cache
      final signedUrl = provider.signedUrls[candidatePath];
      expect(signedUrl, isNotNull);
      expect(signedUrl, startsWith('https://'));

      // Invariant: DB row images must NEVER contain signed URL
      final dbProduct = fakeProductService.products[provider.persistedProductId!]!;
      for (final img in dbProduct.images) {
        expect(img.startsWith('http'), false);
        expect(img.contains('?token='), false);
      }
    });

    test('Test 8: Keep Original leaves DB canonical images unchanged', () async {
      provider.setName('Silk Scarf');
      await provider.saveDraft();
      const originalPath = 'test-user/prod-1/scarf.jpg';
      provider.addImagePath(originalPath);
      await provider.saveDraft();

      await provider.improvePhoto(originalPath);
      expect(provider.hasCandidateForPhoto(originalPath), true);

      // User taps "Keep Original"
      await provider.keepOriginalPhoto(originalPath);

      expect(provider.hasCandidateForPhoto(originalPath), false);
      expect(provider.draft.images, [originalPath]);
      final dbProduct = fakeProductService.products[provider.persistedProductId!]!;
      expect(dbProduct.images, [originalPath]);
    });

    test('Test 9: Keep Original triggers best-effort cleanup of candidate from Storage', () async {
      provider.setName('Silk Scarf');
      await provider.saveDraft();
      const originalPath = 'test-user/prod-1/scarf.jpg';
      provider.addImagePath(originalPath);

      await provider.improvePhoto(originalPath);
      final candidate = provider.getCandidateForPhoto(originalPath)!;

      await provider.keepOriginalPhoto(originalPath);

      expect(fakeEnhancementService.discardedCandidates, contains(candidate));
    });

    test('Test 10: Use Improved replaces correct image path in canonical list', () async {
      provider.setName('Wood Carving');
      await provider.saveDraft();
      const path1 = 'test-user/prod-1/wood1.jpg';
      const path2 = 'test-user/prod-1/wood2.jpg';
      provider.addImagePath(path1);
      provider.addImagePath(path2);
      await provider.saveDraft();

      await provider.improvePhoto(path1);
      final candidate1 = provider.getCandidateForPhoto(path1)!;

      final ok = await provider.useImprovedPhoto(path1);

      expect(ok, true);
      // Canonical draft has candidate1 in place of path1
      expect(provider.draft.images, [candidate1, path2]);
      // Database has candidate1 in place of path1
      final dbProduct = fakeProductService.products[provider.persistedProductId!]!;
      expect(dbProduct.images, [candidate1, path2]);
      // Candidate entry is cleared
      expect(provider.hasCandidateForPhoto(path1), false);
    });

    test('Test 11: DB failure when selecting improved preserves original canonical path', () async {
      provider.setName('Jute Bag');
      await provider.saveDraft();
      const originalPath = 'test-user/prod-1/bag.jpg';
      provider.addImagePath(originalPath);
      await provider.saveDraft();

      await provider.improvePhoto(originalPath);
      final candidate = provider.getCandidateForPhoto(originalPath)!;

      // Simulate DB update error
      fakeProductService.throwOnUpdate = true;

      final ok = await provider.useImprovedPhoto(originalPath);

      expect(ok, false);
      expect(provider.hasError, true);
      // Canonical draft still holds originalPath
      expect(provider.draft.images, [originalPath]);
      // Candidate is still retained in state for retry
      expect(provider.getCandidateForPhoto(originalPath), candidate);
    });

    test('Test 12: Other photos in list remain unchanged when one photo is improved', () async {
      provider.setName('Three Pottery Vases');
      await provider.saveDraft();
      const p1 = 'test-user/prod-1/vase1.jpg';
      const p2 = 'test-user/prod-1/vase2.jpg';
      const p3 = 'test-user/prod-1/vase3.jpg';
      provider.addImagePath(p1);
      provider.addImagePath(p2);
      provider.addImagePath(p3);
      await provider.saveDraft();

      await provider.improvePhoto(p2);
      final cand2 = provider.getCandidateForPhoto(p2)!;
      await provider.useImprovedPhoto(p2);

      expect(provider.draft.images, [p1, cand2, p3]);
    });

    test('Test 13: Candidate path cannot be local/public/signed URL (3-segment validation)', () {
      const validCandidate = 'user-123/prod-456/enhanced_1.png';
      ProducerProductImageService.validateStoragePath(validCandidate);

      // Verify malformed shapes are rejected by existing validation
      expect(
        () => ProducerProductImageService.validateStoragePath('file:///local/enhanced.png'),
        throwsA(isA<ProductOperationException>()),
      );
      expect(
        () => ProducerProductImageService.validateStoragePath('https://supabase.co/enhanced.png'),
        throwsA(isA<ProductOperationException>()),
      );
      expect(
        () => ProducerProductImageService.validateStoragePath('data:image/png;base64,abc'),
        throwsA(isA<ProductOperationException>()),
      );
    });

    test('Test 17: Mark Ready still works with improved photo', () async {
      provider.setName('Kashmiri Shawl');
      provider.setCategory('clothing');
      provider.setPriceFromRupeesText('2500');
      await provider.saveDraft();

      const p1 = 'test-user/prod-1/shawl.jpg';
      provider.addImagePath(p1);
      await provider.saveDraft();

      await provider.improvePhoto(p1);
      await provider.useImprovedPhoto(p1);

      final marked = await provider.markReady();
      expect(marked, true);
      final dbProduct = fakeProductService.products[provider.persistedProductId!]!;
      expect(dbProduct.status, ProductStatus.active);
    });

    test('Test 18: Save Draft still works with candidate in progress', () async {
      provider.setName('Bamboo Basket');
      provider.setCategory('handicraft');
      provider.setPriceFromRupeesText('450');
      await provider.saveDraft();

      const p1 = 'test-user/prod-1/basket.jpg';
      provider.addImagePath(p1);
      await provider.saveDraft();

      await provider.improvePhoto(p1);
      // Candidate exists but user hasn't chosen yet
      expect(provider.hasCandidateForPhoto(p1), true);

      final saved = await provider.saveDraft();
      expect(saved, true);
      final dbProduct = fakeProductService.products[provider.persistedProductId!]!;
      // Canonical images remain the original
      expect(dbProduct.images, [p1]);
    });
  });

  group('AddProductScreen Widget Tests for AI Photo Improvement (Step 6C.6B)', () {
    late FakeProductService fakeProductService;
    late FakeProductImageService fakeImageService;
    late FakeProductPhotoEnhancementService fakeEnhancementService;
    late FakeImagePickerService fakePickerService;
    late AddProductProvider provider;

    setUp(() {
      fakeProductService = FakeProductService();
      fakeImageService = FakeProductImageService();
      fakeEnhancementService = FakeProductPhotoEnhancementService();
      fakePickerService = FakeImagePickerService();

      provider = AddProductProvider(
        productService: fakeProductService,
        imageService: fakeImageService,
        imagePickerService: fakePickerService,
        enhancementService: fakeEnhancementService,
      );
    });

    testWidgets('Test 1: Improve Photo action button is visible on each uploaded image tile',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('Phulkari Dupatta');
      provider.setCategory('clothing');
      await provider.goToStep(3);

      const path1 = 'test-user/prod-1/phulkari.jpg';
      provider.addImagePath(path1);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Find the "Improve Photo" button
      expect(find.text('Improve Photo'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('Test 7: Tapping Improve Photo generates candidate and shows comparison modal',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('Clay Diyas');
      provider.setCategory('pottery');
      await provider.goToStep(3);

      const path1 = 'test-user/prod-1/diya.jpg';
      provider.addImagePath(path1);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Improve Photo"
      await tester.tap(find.text('Improve Photo'));
      await tester.pumpAndSettle();

      // Comparison modal opens showing Original and Improved titles
      expect(find.text('Photo Improved'), findsOneWidget);
      expect(find.text('Original'), findsOneWidget);
      expect(find.text('Improved'), findsOneWidget);
      expect(find.text('Keep Original'), findsOneWidget);
      expect(find.text('Use Improved Photo'), findsOneWidget);
      expect(
        find.text('AI improves only the presentation, not your product.'),
        findsOneWidget,
      );

      // Tap "Use Improved Photo"
      await tester.tap(find.text('Use Improved Photo'));
      await tester.pumpAndSettle();

      // Candidate is applied, modal closes, success message shown
      expect(find.text('Photo Improved'), findsNothing);
      expect(find.text('Improved photo applied'), findsOneWidget);
    });

    testWidgets('Test 14: AI Improvement UI renders in Hindi (Devanagari)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('मिट्टी के दीये');
      provider.setCategory('pottery');
      await provider.goToStep(3);

      const path1 = 'test-user/prod-1/diya.jpg';
      provider.addImagePath(path1);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
          locale: const Locale('hi'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('फोटो सुधारें'), findsOneWidget);

      // Tap Improve Photo
      await tester.tap(find.text('फोटो सुधारें'));
      await tester.pumpAndSettle();

      expect(find.text('फोटो में सुधार हुआ'), findsOneWidget);
      expect(find.text('मूल फोटो'), findsOneWidget);
      expect(find.text('सुधारी गई फोटो'), findsOneWidget);
      expect(find.text('मूल फोटो रखें'), findsOneWidget);
      expect(find.text('सुधारी गई फोटो उपयोग करें'), findsOneWidget);
    });

    testWidgets('Test 14: AI Improvement UI renders in Punjabi (Gurmukhi)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('ਫੁਲਕਾਰੀ');
      provider.setCategory('clothing');
      await provider.goToStep(3);

      const path1 = 'test-user/prod-1/phulkari.jpg';
      provider.addImagePath(path1);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
          locale: const Locale('pa'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ਫੋਟੋ ਸੁਧਾਰੋ'), findsOneWidget);

      // Tap Improve Photo
      await tester.tap(find.text('ਫੋਟੋ ਸੁਧਾਰੋ'));
      await tester.pumpAndSettle();

      expect(find.text('ਫੋਟੋ ਵਿੱਚ ਸੁਧਾਰ ਹੋਇਆ'), findsOneWidget);
      expect(find.text('ਅਸਲ ਫੋਟੋ'), findsOneWidget);
      expect(find.text('ਸੁਧਾਰੀ ਗਈ ਫੋਟੋ'), findsOneWidget);
      expect(find.text('ਅਸਲ ਫੋਟੋ ਰੱਖੋ'), findsOneWidget);
      expect(find.text('ਸੁਧਾਰੀ ਗਈ ਫੋਟੋ ਵਰਤੋ'), findsOneWidget);
    });

    testWidgets('Test 15: Dark Theme renders photo comparison modal cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('Dark Craft Item');
      provider.setCategory('art');
      await provider.goToStep(3);

      const path1 = 'test-user/prod-1/item.jpg';
      provider.addImagePath(path1);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Improve Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Photo Improved'), findsOneWidget);
    });

    testWidgets('Test 16: Responsive layout at 320px narrow mobile renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('Narrow Mobile Item');
      provider.setCategory('crafts');
      await provider.goToStep(3);

      const path1 = 'test-user/prod-1/mobile.jpg';
      provider.addImagePath(path1);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Improve Photo on narrow display
      await tester.tap(find.text('Improve Photo'));
      await tester.pumpAndSettle();

      // Verify modal opens cleanly without RenderFlex overflow
      expect(find.text('Photo Improved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Test 16: Responsive layout at 768px tablet renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('Tablet Craft Item');
      provider.setCategory('crafts');
      await provider.goToStep(3);

      const path1 = 'test-user/prod-1/tablet.jpg';
      provider.addImagePath(path1);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Test 16: Responsive layout at 1440px desktop renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('Desktop Craft Item');
      provider.setCategory('crafts');
      await provider.goToStep(3);

      const path1 = 'test-user/prod-1/desktop.jpg';
      provider.addImagePath(path1);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
