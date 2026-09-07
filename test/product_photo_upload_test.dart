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
import 'package:buyer_section/producer_section/products/services/producer_product_image_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

// -----------------------------------------------------------------------------
// FAKES
// -----------------------------------------------------------------------------

class FakeProductImageService implements IProducerProductImageService {
  final List<String> uploadedPaths = [];
  final List<String> deletedPaths = [];
  final Map<String, Uint8List> storageObjects = {};

  bool throwOnUpload = false;
  bool throwOnDelete = false;
  bool throwOnSignedUrl = false;

  @override
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (throwOnUpload) {
      throw const ProductOperationException('Storage upload failed: network error');
    }
    final ext = ProducerProductImageService.normalizeMimeType(contentType);
    final path = 'test-user/$productId/gen_${uploadedPaths.length + 1}.$ext';
    uploadedPaths.add(path);
    storageObjects[path] = bytes;
    return path;
  }

  @override
  Future<void> deleteProductImage(String storagePath) async {
    if (throwOnDelete) {
      throw const ProductOperationException('Storage delete failed: network error');
    }
    deletedPaths.add(storagePath);
    storageObjects.remove(storagePath);
  }

  @override
  Future<String> createSignedImageUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    if (throwOnSignedUrl) {
      throw const ProductOperationException('Failed to generate signed URL');
    }
    return 'https://supabase.co/storage/v1/sign/$storagePath?token=mock';
  }
}

class FakeProductService implements IProducerProductService {
  final Map<String, ProducerProduct> products = {};
  final List<ProducerProductDraft> updatedDrafts = [];
  bool throwOnUpdate = false;
  int _counter = 1;

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
    updatedDrafts.add(draft);
    if (throwOnUpdate) {
      throw const ProductOperationException('Database update failed');
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
  Future<void> deleteProduct(String productId) async {
    products.remove(productId);
  }

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async {
    return products.values.toList();
  }

  Future<ProducerProduct> getProductById(String productId) async {
    final p = products[productId];
    if (p == null) throw const ProductOperationException('Not found');
    return p;
  }
}

class FakeImagePickerService implements IProducerImagePickerService {
  PickedProductImage? nextPickedImage;
  Exception? nextException;
  ImageSourceOption? lastSource;

  @override
  Future<PickedProductImage?> pickImage(ImageSourceOption source) async {
    lastSource = source;
    if (nextException != null) {
      throw nextException!;
    }
    return nextPickedImage;
  }
}

// -----------------------------------------------------------------------------
// TEST APP BUILDER
// -----------------------------------------------------------------------------

Widget createTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [
      Locale('en'),
      Locale('hi'),
      Locale('pa'),
    ],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: themeMode,
    home: child,
  );
}

void main() {
  late FakeProductService fakeProductService;
  late FakeProductImageService fakeImageService;
  late FakeImagePickerService fakePickerService;
  late AddProductProvider provider;

  setUp(() {
    fakeProductService = FakeProductService();
    fakeImageService = FakeProductImageService();
    fakePickerService = FakeImagePickerService();
    provider = AddProductProvider(
      productService: fakeProductService,
      imageService: fakeImageService,
      imagePickerService: fakePickerService,
    );
  });

  group('Product Photo Selection & Secure Upload Tests (Step 6C.6A)', () {
    test('Camera selection path triggers picker with ImageSourceOption.camera', () async {
      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        originalFilename: 'camera_shot.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 4,
      );

      provider.setName('Clay Pot');
      final success = await provider.pickAndUploadImage(ImageSourceOption.camera);

      expect(success, isTrue);
      expect(fakePickerService.lastSource, ImageSourceOption.camera);
      expect(provider.draft.images.length, 1);
      expect(provider.draft.images.first, startsWith('test-user/prod-uuid-1/gen_1.jpg'));
    });

    test('Gallery selection path triggers picker with ImageSourceOption.gallery', () async {
      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([10, 20, 30]),
        originalFilename: 'gallery_art.png',
        contentType: 'image/png',
        sizeBytes: 3,
      );

      provider.setName('Brass Vase');
      final success = await provider.pickAndUploadImage(ImageSourceOption.gallery);

      expect(success, isTrue);
      expect(fakePickerService.lastSource, ImageSourceOption.gallery);
      expect(provider.draft.images.length, 1);
      expect(provider.draft.images.first, endsWith('.png'));
    });

    test('Cancel picker safely returns false without mutating draft or error', () async {
      fakePickerService.nextPickedImage = null; // User cancelled

      provider.setName('Silk Scarf');
      final success = await provider.pickAndUploadImage(ImageSourceOption.camera);

      expect(success, isFalse);
      expect(provider.draft.images, isEmpty);
      expect(provider.hasError, isFalse);
    });

    test('Unsupported photo format is rejected and leaves draft unchanged', () async {
      fakePickerService.nextException = const UnsupportedImageFormatException(
        'Unsupported photo format. Please select a JPEG, PNG, or WebP photo.',
        detectedType: 'heic',
      );

      provider.setName('Wooden Bowl');
      final success = await provider.pickAndUploadImage(ImageSourceOption.gallery);

      expect(success, isFalse);
      expect(provider.draft.images, isEmpty);
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, contains('Unsupported photo format'));
    });

    test('Photo > 5MB is rejected and leaves draft unchanged', () async {
      fakePickerService.nextException = const ImageTooLargeException(
        'Photo exceeds 5 MB limit. Please select a smaller photo.',
        actualSizeBytes: 6000000,
      );

      provider.setName('Iron Lamp');
      final success = await provider.pickAndUploadImage(ImageSourceOption.gallery);

      expect(success, isFalse);
      expect(provider.draft.images, isEmpty);
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, contains('5 MB limit'));
    });

    test('Local file path or signed URL NEVER enters ProducerProductDraft.images', () async {
      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        originalFilename: 'local_file.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 3,
      );

      provider.setName('Jute Bag');
      await provider.pickAndUploadImage(ImageSourceOption.camera);

      final path = provider.draft.images.first;
      // Must NOT be a URL
      expect(path.startsWith('http://'), isFalse);
      expect(path.startsWith('https://'), isFalse);
      expect(path.startsWith('file://'), isFalse);
      expect(path.startsWith('/data/user'), isFalse);
      expect(path.contains('token='), isFalse);

      // Must be standard 3-segment relative Storage object path
      expect(path.split('/').length, 3);
      expect(path.startsWith('test-user/'), isTrue);
    });

    test('Signed URL is cached in provider for preview but never written to DB images', () async {
      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([1, 2]),
        originalFilename: 'test.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 2,
      );

      provider.setName('Bamboo Flute');
      await provider.pickAndUploadImage(ImageSourceOption.gallery);

      final storagePath = provider.draft.images.first;
      expect(provider.signedUrls.containsKey(storagePath), isTrue);
      expect(provider.signedUrls[storagePath], contains('https://supabase.co/storage/v1/sign/'));

      // Check product row in DB
      final productInDb = fakeProductService.products[provider.persistedProductId]!;
      expect(productInDb.images.first, equals(storagePath));
      expect(productInDb.images.first.contains('https://'), isFalse);
    });

    test('Maximum 4 photos limit prevents 5th upload', () async {
      provider.setName('Wool Blanket');

      // Upload 4 images
      for (int i = 0; i < 4; i++) {
        fakePickerService.nextPickedImage = PickedProductImage(
          bytes: Uint8List.fromList([i, i + 1]),
          originalFilename: 'photo_$i.jpg',
          contentType: 'image/jpeg',
          sizeBytes: 2,
        );
        final ok = await provider.pickAndUploadImage(ImageSourceOption.camera);
        expect(ok, isTrue);
      }

      expect(provider.draft.images.length, 4);

      // Attempt 5th upload
      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([99]),
        originalFilename: 'photo_5.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1,
      );
      final fifth = await provider.pickAndUploadImage(ImageSourceOption.camera);

      expect(fifth, isFalse);
      expect(provider.draft.images.length, 4);
      expect(provider.errorMessage, contains('Maximum 4 photos'));
    });

    test('DB update failure after Storage upload triggers best-effort cleanup of NEW object', () async {
      provider.setName('Leather Wallet');

      // First image succeeds
      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([1, 2]),
        originalFilename: 'first.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 2,
      );
      await provider.pickAndUploadImage(ImageSourceOption.gallery);
      final firstPath = provider.draft.images.first;
      expect(fakeImageService.storageObjects.containsKey(firstPath), isTrue);

      // Second image: Storage succeeds, but DB update fails
      fakeProductService.throwOnUpdate = true;
      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([3, 4]),
        originalFilename: 'second.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 2,
      );

      final secondSuccess = await provider.pickAndUploadImage(ImageSourceOption.camera);

      expect(secondSuccess, isFalse);
      // Canonical images remains unchanged with only 1 image
      expect(provider.draft.images.length, 1);
      expect(provider.draft.images.first, equals(firstPath));

      // Newly uploaded object was cleaned up
      final secondPath = fakeImageService.uploadedPaths.last;
      expect(fakeImageService.deletedPaths, contains(secondPath));
      expect(fakeImageService.storageObjects.containsKey(secondPath), isFalse);

      // Existing good image was NOT deleted
      expect(fakeImageService.storageObjects.containsKey(firstPath), isTrue);
    });

    test('Successful removal updates DB list before deleting Storage object', () async {
      provider.setName('Copper Jug');

      // Upload two photos
      for (int i = 1; i <= 2; i++) {
        fakePickerService.nextPickedImage = PickedProductImage(
          bytes: Uint8List.fromList([i]),
          originalFilename: 'img$i.jpg',
          contentType: 'image/jpeg',
          sizeBytes: 1,
        );
        await provider.pickAndUploadImage(ImageSourceOption.gallery);
      }

      expect(provider.draft.images.length, 2);
      final removedPath = provider.draft.images.first;
      final keptPath = provider.draft.images.last;

      final success = await provider.removeImage(removedPath);

      expect(success, isTrue);
      expect(provider.draft.images.length, 1);
      expect(provider.draft.images, contains(keptPath));
      expect(provider.draft.images.contains(removedPath), isFalse);

      // DB was updated without removedPath
      final productInDb = fakeProductService.products[provider.persistedProductId]!;
      expect(productInDb.images, [keptPath]);

      // Storage object was deleted
      expect(fakeImageService.deletedPaths, contains(removedPath));
    });

    test('DB removal update failure does NOT delete Storage object', () async {
      provider.setName('Silver Anklet');

      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([5]),
        originalFilename: 'silver.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1,
      );
      await provider.pickAndUploadImage(ImageSourceOption.camera);
      final path = provider.draft.images.first;

      // Make DB update fail on removal
      fakeProductService.throwOnUpdate = true;

      final success = await provider.removeImage(path);

      expect(success, isFalse);
      // Canonical images remains intact
      expect(provider.draft.images, contains(path));

      // Storage object was NOT deleted
      expect(fakeImageService.deletedPaths, isEmpty);
      expect(fakeImageService.storageObjects.containsKey(path), isTrue);
    });

    test('Signed URL generation failure does not crash provider', () async {
      fakeImageService.throwOnSignedUrl = true;

      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([7]),
        originalFilename: 'item.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1,
      );

      provider.setName('Stone Carving');
      final success = await provider.pickAndUploadImage(ImageSourceOption.gallery);

      expect(success, isTrue);
      expect(provider.draft.images.length, 1);
      // Attempting to fetch signed url returns null gracefully
      final url = await provider.getOrFetchSignedUrl(provider.draft.images.first);
      expect(url, isNull);
    });

    test('Duplicate/busy tap protection prevents concurrent uploads', () async {
      provider.setName('Kashmiri Rug');

      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([1, 2]),
        originalFilename: 'rug.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 2,
      );

      // Start upload
      final future1 = provider.uploadAndAddImage(
        bytes: Uint8List.fromList([1]),
        contentType: 'image/jpeg',
        originalFilename: 'rug.jpg',
      );
      // Concurrent call
      final future2 = provider.uploadAndAddImage(
        bytes: Uint8List.fromList([2]),
        contentType: 'image/jpeg',
        originalFilename: 'rug2.jpg',
      );

      final results = await Future.wait([future1, future2]);
      // One succeeds, second is rejected by busy lock
      expect(results, contains(true));
      expect(results, contains(false));
    });

    test('Mark Ready still works without requiring any photos', () async {
      provider.setName('Handmade Soap');
      provider.setCategory('beauty');
      provider.setPriceFromPaise(15000); // ₹150

      expect(provider.draft.images, isEmpty);
      expect(provider.canMarkActive, isTrue);

      final marked = await provider.markReady();
      expect(marked, isTrue);

      final product = fakeProductService.products[provider.persistedProductId]!;
      expect(product.status, ProductStatus.active);
      expect(product.images, isEmpty);
    });

    test('Save Draft still works with photos attached', () async {
      provider.setName('Herbal Oil');

      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([8, 9]),
        originalFilename: 'oil.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 2,
      );
      await provider.pickAndUploadImage(ImageSourceOption.camera);

      expect(provider.draft.images.length, 1);
      final saved = await provider.saveDraft();
      expect(saved, isTrue);

      final product = fakeProductService.products[provider.persistedProductId]!;
      expect(product.images.length, 1);
    });
  });

  group('AddProductScreen Widget Tests for Step 3 Photos (Step 6C.6A)', () {
    testWidgets('Tapping Add Photo opens bottom sheet with Camera and Gallery options', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('Silk Saree');
      provider.setCategory('clothing');
      provider.setPriceFromPaise(250000);
      await provider.goToStep(3);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);

      // Tap Add Photo tile
      await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
      await tester.pumpAndSettle();

      // Bottom sheet is visible with options
      expect(find.text('Add Product Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);

      // Tap Take Photo
      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        originalFilename: 'shot.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 3,
      );

      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      // Bottom sheet dismissed and photo added
      expect(fakePickerService.lastSource, ImageSourceOption.camera);
      expect(provider.draft.images.length, 1);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('Delete icon shows confirmation dialog and removes photo on confirmation', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('Wooden Elephant');
      provider.setCategory('handicraft');
      await provider.goToStep(3);

      // Upload a photo
      fakePickerService.nextPickedImage = PickedProductImage(
        bytes: Uint8List.fromList([1, 2]),
        originalFilename: 'elephant.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 2,
      );
      await provider.pickAndUploadImage(ImageSourceOption.gallery);
      expect(provider.draft.images.length, 1);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Tap Delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirmation dialog opens
      expect(find.text('Do you want to remove this photo?'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(provider.draft.images, isEmpty);
      expect(find.text('Photo removed'), findsOneWidget);
    });

    testWidgets('Photo upload renders and functions in Hindi', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('कढ़ाई वाला शॉल');
      provider.setCategory('clothing');
      await provider.goToStep(3);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
          locale: const Locale('hi'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('फोटो जोड़ें'), findsWidgets);

      // Tap Add Photo tile
      await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
      await tester.pumpAndSettle();

      expect(find.text('उत्पाद फ़ोटो जोड़ें'), findsOneWidget);
      expect(find.text('फ़ोटो खींचें'), findsOneWidget);
      expect(find.text('गैलरी से चुनें'), findsOneWidget);
    });

    testWidgets('Photo upload renders and functions in Punjabi', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('ਫੁਲਕਾਰੀ');
      provider.setCategory('clothing');
      await provider.goToStep(3);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
          locale: const Locale('pa'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Add Photo tile
      await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
      await tester.pumpAndSettle();

      expect(find.text('ਉਤਪਾਦ ਫੋਟੋ ਸ਼ਾਮਲ ਕਰੋ'), findsOneWidget);
      expect(find.text('ਫੋਟੋ ਖਿੱਚੋ'), findsOneWidget);
      expect(find.text('ਗੈਲਰੀ ਤੋਂ ਚੁਣੋ'), findsOneWidget);
    });

    testWidgets('Dark theme renders photo slots cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      provider.setName('Dark Mode Item');
      provider.setCategory('handicraft');
      await provider.goToStep(3);

      await tester.pumpWidget(
        createTestApp(
          child: AddProductScreen(provider: provider),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    });
  });
}
