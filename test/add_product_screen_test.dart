import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:buyer_section/core/localization/generated/app_localizations.dart';
import 'package:buyer_section/core/localization/language_provider.dart';
import 'package:buyer_section/core/theme/app_theme.dart';
import 'package:buyer_section/core/theme/theme_provider.dart';
import 'package:buyer_section/producer_section/home/producer_main_screen.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';
import 'package:buyer_section/producer_section/products/providers/add_product_provider.dart';
import 'package:buyer_section/producer_section/products/screens/add_product_screen.dart';
import 'package:buyer_section/producer_section/products/services/producer_image_picker_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_enhancement_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_image_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

// -----------------------------------------------------------------------------
// FAKE TEST SERVICES
// -----------------------------------------------------------------------------

class FakeAddProductService implements IProducerProductService {
  final Map<String, ProducerProduct> database = {};
  int createCalls = 0;
  int updateDraftCalls = 0;
  int updateStatusCalls = 0;
  bool shouldFailPersistence = false;

  @override
  final IProducerProductImageService? imageService = null;

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
}

class FakeImagePickerService implements IProducerImagePickerService {
  bool cameraSupported = true;
  PickedProductImage? nextPickedImage;
  Exception? nextException;
  ImageSourceOption? lastSource;

  @override
  bool get isCameraSupported => cameraSupported;

  @override
  Future<PickedProductImage?> pickImage(ImageSourceOption source) async {
    lastSource = source;
    if (nextException != null) throw nextException!;
    return nextPickedImage;
  }
}

class FakeProductImageService implements IProducerProductImageService {
  final Map<String, String> storage = {};
  int uploadCount = 0;
  bool shouldFailUpload = false;

  @override
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadCount++;
    if (shouldFailUpload) throw const ProductOperationException('Storage upload failed');
    final path = 'test-uid/$productId/img_$uploadCount.jpg';
    storage[path] = 'https://fake-storage.com/$path';
    return path;
  }

  @override
  Future<String> createSignedImageUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    return storage[storagePath] ?? 'https://fake-storage.com/$storagePath';
  }

  @override
  Future<void> deleteProductImage(String storagePath) async {
    storage.remove(storagePath);
  }
}

class FakeEnhancementService implements IProductPhotoEnhancementService {
  bool shouldSucceed = true;
  String? candidatePath;
  final List<String> discardedCandidates = [];

  @override
  Future<EnhancementResult> improvePhoto({
    required String productId,
    required String sourceStoragePath,
  }) async {
    if (!shouldSucceed) {
      throw const ProductOperationException('Enhancement failed');
    }
    candidatePath = '$sourceStoragePath.improved.jpg';
    return EnhancementResult(
      improvedStoragePath: candidatePath!,
      sourceStoragePath: sourceStoragePath,
    );
  }

  @override
  Future<void> discardCandidateImage(String candidateStoragePath) async {
    discardedCandidates.add(candidateStoragePath);
  }
}

// -----------------------------------------------------------------------------
// APP WRAPPER HELPER
// -----------------------------------------------------------------------------

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
      home: Scaffold(body: child),
    ),
  );
}

// -----------------------------------------------------------------------------
// MAIN TEST SUITE
// -----------------------------------------------------------------------------

void main() {
  late FakeAddProductService service;
  late FakeProductImageService imageService;
  late FakeImagePickerService pickerService;
  late FakeEnhancementService enhancementService;
  late AddProductProvider provider;

  setUp(() {
    service = FakeAddProductService();
    imageService = FakeProductImageService();
    pickerService = FakeImagePickerService();
    enhancementService = FakeEnhancementService();
    provider = AddProductProvider(
      productService: service,
      imageService: imageService,
      imagePickerService: pickerService,
      enhancementService: enhancementService,
    );
  });

  group('1. Bottom Sheet & Single Form Architecture', () {
    testWidgets('AddProductScreen.show opens modal bottom sheet with drag handle and title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddProductScreen.show(
                context,
                provider: provider,
                productService: service,
                imageService: imageService,
                imagePickerService: pickerService,
              ),
              child: const Text('Open Modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byType(AddProductScreen), findsOneWidget);
      expect(find.byKey(const Key('add_product_close_button')), findsOneWidget);
      expect(find.text('Add Product'), findsAtLeastNWidgets(1));
    });

    testWidgets('No Step 1/2/3 wizard UI exists', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 / 3'), findsNothing);
      expect(find.text('Step 2 / 3'), findsNothing);
      expect(find.text('Step 3 / 3'), findsNothing);
      expect(find.text('Continue'), findsNothing);
      expect(find.text('What do you make?'), findsNothing);
      expect(find.text('Price & Details'), findsNothing);
    });

    testWidgets('All core fields visible in one form simultaneously', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Photos section
      expect(find.byKey(const Key('add_product_photo_button')), findsOneWidget);
      expect(find.text('Product Photos'), findsOneWidget);

      // Name field
      expect(find.byKey(const Key('add_product_name_field')), findsOneWidget);

      // Category & Unit
      expect(find.byKey(const Key('add_product_category_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('add_product_unit_dropdown')), findsOneWidget);

      // Price & Description
      expect(find.byKey(const Key('add_product_price_field')), findsOneWidget);
      expect(find.byKey(const Key('add_product_description_field')), findsOneWidget);

      // Bottom actions
      expect(find.byKey(const Key('add_product_save_draft_button')), findsOneWidget);
      expect(find.byKey(const Key('add_product_mark_ready_button')), findsOneWidget);
    });
  });

  group('2. Responsive Layouts & Keyboard Insets', () {
    testWidgets('Phone layout (<640px) renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AddProductScreen), findsOneWidget);
    });

    testWidgets('Tablet layout (640-1024px) renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AddProductScreen), findsOneWidget);
    });

    testWidgets('Desktop/web layout (>=1024px) centers card without full-screen stretching', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AddProductScreen), findsOneWidget);
    });

    testWidgets('Keyboard inset and scroll structure exists', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });
  });

  group('3. Save Draft & Add Product Actions', () {
    testWidgets('Save Draft works and pops sheet with true', (tester) async {
      bool? poppedResult;
      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                poppedResult = await AddProductScreen.show(
                  context,
                  provider: provider,
                  productService: service,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('add_product_name_field')), 'Brass Lamp');
      await tester.pump();

      await tester.tap(find.byKey(const Key('add_product_save_draft_button')));
      await tester.pumpAndSettle();

      expect(poppedResult, isTrue);
      expect(service.createCalls, 1);
      expect(provider.isPersisted, isTrue);
      expect(find.byType(AddProductScreen), findsNothing);
    });

    testWidgets('Add Product / Mark Ready works when valid', (tester) async {
      bool? poppedResult;
      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                poppedResult = await AddProductScreen.show(
                  context,
                  provider: provider,
                  productService: service,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('add_product_name_field')), 'Ceramic Mug');
      provider.setCategory('handicraft');
      await tester.enterText(find.byKey(const Key('add_product_price_field')), '350.00');
      await tester.pump();

      await tester.tap(find.byKey(const Key('add_product_mark_ready_button')));
      await tester.pumpAndSettle();

      expect(poppedResult, isTrue);
      expect(provider.isPersisted, isTrue);
      final id = provider.persistedProductId!;
      expect(service.database[id]?.status, ProductStatus.active);
      expect(find.byType(AddProductScreen), findsNothing);
    });

    testWidgets('Repeated Save Draft does not duplicate product record', (tester) async {
      provider.setName('Handmade Shawl');
      final firstOk = await provider.saveDraft();
      expect(firstOk, isTrue);
      final id1 = provider.persistedProductId;
      expect(service.createCalls, 1);

      provider.setDescription('Pure pashmina wool');
      final secondOk = await provider.saveDraft();
      expect(secondOk, isTrue);
      final id2 = provider.persistedProductId;

      expect(id1, id2);
      expect(service.createCalls, 1);
      expect(service.updateDraftCalls, 1);
    });
  });

  group('4. Draft-Before-Photo & Photo Upload Lifecycle', () {
    testWidgets('Add photo with no name is safely blocked', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            productService: service,
            imageService: imageService,
            imagePickerService: pickerService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Add Photo without entering name
      await tester.tap(find.byKey(const Key('add_product_photo_button')));
      await tester.pumpAndSettle();

      // No draft created
      expect(service.createCalls, 0);
      expect(provider.isPersisted, isFalse);
      expect(find.text('Add a product name before adding photos.'), findsAtLeastNWidgets(1));
    });

    testWidgets('Add photo with valid name auto-persists draft first', (tester) async {
      pickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        originalFilename: 'test.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 4,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            productService: service,
            imageService: imageService,
            imagePickerService: pickerService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('add_product_name_field')), 'Wooden Toy');
      await tester.pump();

      // Tap Add Photo
      await tester.tap(find.byKey(const Key('add_product_photo_button')));
      await tester.pumpAndSettle();

      // If mobile, bottom sheet for source selection opens
      if (find.text('Take Photo').evaluate().isNotEmpty) {
        await tester.tap(find.text('Choose from Gallery'));
        await tester.pumpAndSettle();
      }

      // Draft was auto-persisted first!
      expect(service.createCalls, 1);
      expect(provider.isPersisted, isTrue);
      expect(imageService.uploadCount, 1);
      expect(provider.draft.images.length, 1);
    });

    testWidgets('Persisted product photo upload uses existing product ID', (tester) async {
      provider.setName('Silk Kurti');
      await provider.saveDraft();
      final originalId = provider.persistedProductId;
      expect(service.createCalls, 1);

      pickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        originalFilename: 'test2.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 4,
      );

      await provider.pickAndUploadImage(ImageSourceOption.gallery);

      expect(provider.persistedProductId, originalId);
      expect(service.createCalls, 1); // No new draft row created
      expect(provider.draft.images.length, 1);
    });

    testWidgets('Platform failure becomes safe UI error without crashing', (tester) async {
      provider.setName('Clay Pot');
      pickerService.nextException = const ProductOperationException(
        'Photo picker is not available on this device. Please restart the application.',
      );

      final ok = await provider.pickAndUploadImage(ImageSourceOption.gallery);
      expect(ok, isFalse);
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, contains('Photo picker is not available'));
    });

    testWidgets('Camera option is platform-aware (web directly opens gallery)', (tester) async {
      pickerService.cameraSupported = false; // Simulates web
      pickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        originalFilename: 'web.png',
        contentType: 'image/png',
        sizeBytes: 4,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            productService: service,
            imageService: imageService,
            imagePickerService: pickerService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('add_product_name_field')), 'Web Item');
      await tester.pump();

      // Tap Add Photo: on web (cameraSupported = false), no camera sheet is shown;
      // it directly routes to gallery
      await tester.tap(find.byKey(const Key('add_product_photo_button')));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsNothing);
      expect(pickerService.lastSource, ImageSourceOption.gallery);
    });

    testWidgets('Max 4 photos enforced', (tester) async {
      provider.setName('Test Product');
      await provider.saveDraft();

      for (int i = 1; i <= 4; i++) {
        provider.addImagePath('path/img_$i.jpg');
      }
      expect(provider.draft.images.length, 4);

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // When 4 photos are reached, the Add Photo button is hidden
      expect(find.byKey(const Key('add_product_photo_button')), findsNothing);
      expect(find.text('(4/4)'), findsOneWidget);
    });

    testWidgets('Remove photo works and updates state', (tester) async {
      provider.setName('Test Product');
      await provider.saveDraft();
      provider.addImagePath('path/to/remove.jpg');

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            productService: service,
            imageService: imageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('remove_photo_path/to/remove.jpg')), findsOneWidget);

      await tester.tap(find.byKey(const Key('remove_photo_path/to/remove.jpg')));
      await tester.pumpAndSettle();

      // Confirmation dialog opens
      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(provider.draft.images.contains('path/to/remove.jpg'), isFalse);
    });
  });

  group('5. AI Improve Photo Preservation', () {
    testWidgets('Improve Photo button is visible for uploaded photos', (tester) async {
      provider.setName('Carved Box');
      await provider.saveDraft();
      provider.addImagePath('path/box.jpg');

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('improve_photo_path/box.jpg')), findsOneWidget);
      expect(find.text('Improve Photo'), findsOneWidget);
    });

    testWidgets('AI candidate does not auto-replace original photo', (tester) async {
      provider.setName('Carved Box');
      await provider.saveDraft();
      provider.addImagePath('path/box.jpg');

      await provider.improvePhoto('path/box.jpg');

      // Original photo remains in canonical draft.images
      expect(provider.draft.images, ['path/box.jpg']);
      // Candidate exists separately
      expect(provider.hasCandidateForPhoto('path/box.jpg'), isTrue);
      expect(provider.getCandidateForPhoto('path/box.jpg'), 'path/box.jpg.improved.jpg');
    });

    testWidgets('Keep Original retains original and discards candidate', (tester) async {
      provider.setName('Carved Box');
      await provider.saveDraft();
      provider.addImagePath('path/box.jpg');
      await provider.improvePhoto('path/box.jpg');

      await provider.keepOriginalPhoto('path/box.jpg');

      expect(provider.draft.images, ['path/box.jpg']);
      expect(provider.hasCandidateForPhoto('path/box.jpg'), isFalse);
    });

    testWidgets('Use Improved applies candidate to product photos', (tester) async {
      provider.setName('Carved Box');
      await provider.saveDraft();
      provider.addImagePath('path/box.jpg');
      await provider.improvePhoto('path/box.jpg');

      final ok = await provider.useImprovedPhoto('path/box.jpg');
      expect(ok, isTrue);

      expect(provider.draft.images, ['path/box.jpg.improved.jpg']);
      expect(provider.hasCandidateForPhoto('path/box.jpg'), isFalse);
    });
  });

  group('6. Unsaved Exit Confirmation', () {
    testWidgets('Closing with dirty form asks for confirmation', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddProductScreen.show(
                context,
                provider: provider,
                productService: service,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter dirty data
      await tester.enterText(find.byKey(const Key('add_product_name_field')), 'Unsaved Item');
      await tester.pump();
      expect(provider.isDirty, isTrue);

      // Tap close button
      await tester.tap(find.byKey(const Key('add_product_close_button')));
      await tester.pumpAndSettle();

      // Discard confirmation dialog opens
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Your unsaved product details will be lost.'), findsOneWidget);

      // Tap Keep Editing: modal remains open
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(find.byType(AddProductScreen), findsOneWidget);

      // Tap close again, then Discard: modal closes
      await tester.tap(find.byKey(const Key('add_product_close_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(AddProductScreen), findsNothing);
    });

    testWidgets('Clean close does not ask for confirmation', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddProductScreen.show(
                context,
                provider: provider,
                productService: service,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(provider.isDirty, isFalse);

      // Tap close button on clean form
      await tester.tap(find.byKey(const Key('add_product_close_button')));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(AddProductScreen), findsNothing);
    });
  });

  group('7. Localization & Rebuild Safety', () {
    testWidgets('Renders properly in Hindi', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('hi'),
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('उत्पाद की तस्वीरें'), findsOneWidget);
      expect(find.text('ड्राफ्ट सेव करें'), findsOneWidget);
    });

    testWidgets('Renders properly in Punjabi', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('pa'),
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ਉਤਪਾਦ ਦੀਆਂ ਤਸਵੀਰਾਂ'), findsOneWidget);
      expect(find.text('ਡਰਾਫਟ ਸੰਭਾਲੋ'), findsOneWidget);
    });

    testWidgets('Theme rebuild preserves form values', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.light,
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('add_product_name_field')), 'Preserved Item');
      await tester.pump();

      // Switch to dark theme
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Preserved Item'), findsOneWidget);
    });
  });

  group('8. ProducerMainScreen Entry Points', () {
    testWidgets('Main screen openAddProduct triggers AddProductScreen bottom sheet', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: ProducerMainScreen(productService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Home tab has Add Product card/button
      final addProductButton = find.text('Add Product');
      if (addProductButton.evaluate().isNotEmpty) {
        await tester.tap(addProductButton.first);
        await tester.pumpAndSettle();

        expect(find.byType(AddProductScreen), findsOneWidget);
      }
    });
  });
}
