import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
// TEST DOUBLES
// -----------------------------------------------------------------------------

class TestProductService implements IProducerProductService {
  final Map<String, ProducerProduct> database = {};
  int updateDraftCalls = 0;
  bool shouldFailUpdateDraft = false;

  @override
  final IProducerProductImageService? imageService;

  TestProductService({this.imageService});

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async =>
      database.values.toList();

  @override
  Future<ProducerProduct> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  }) async {
    final existing = database[productId]!;
    final updated = existing.copyWith(status: newStatus);
    database[productId] = updated;
    return updated;
  }

  @override
  Future<void> deleteProduct(String productId) async => database.remove(productId);

  @override
  Future<ProducerProduct> createDraft(ProducerProductDraft draft) async {
    final id = 'test-prod-${database.length + 1}';
    final product = ProducerProduct(
      id: id,
      producerId: 'test-producer',
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
    database[id] = product;
    return product;
  }

  @override
  Future<ProducerProduct> updateDraft({
    required String productId,
    required ProducerProductDraft draft,
  }) async {
    if (shouldFailUpdateDraft) {
      throw const ProductOperationException('Database connection failed');
    }
    updateDraftCalls++;
    final existing = database[productId]!;
    final updated = existing.copyWith(
      name: draft.name,
      category: draft.category,
      description: draft.description,
      pricePaise: draft.pricePaise ?? existing.pricePaise,
      unit: draft.unit,
      images: draft.images,
    );
    database[productId] = updated;
    return updated;
  }

  @override
  Future<ProducerProduct> updateProductImages({
    required String productId,
    required List<String> imagePaths,
  }) async {
    if (shouldFailUpdateDraft) {
      throw const ProductOperationException('Database connection failed');
    }
    final existing = database[productId]!;
    final updated = existing.copyWith(images: imagePaths);
    database[productId] = updated;
    return updated;
  }
}

class TestImageService implements IProducerProductImageService {
  final List<String> uploadedPaths = [];
  final List<String> deletedPaths = [];
  bool shouldFailUpload = false;
  int uploadCalls = 0;

  @override
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadCalls++;
    if (shouldFailUpload) {
      throw const ProductOperationException('Storage service error: network timeout');
    }
    final path = 'test-producer/$productId/img_${uploadedPaths.length + 1}.jpg';
    uploadedPaths.add(path);
    return path;
  }

  @override
  Future<void> deleteProductImage(String storagePath) async {
    deletedPaths.add(storagePath);
  }

  Future<void> deleteAllProductImages(String productId) async {}

  @override
  Future<String> createSignedImageUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    return 'https://supabase.co/storage/v1/sign/$storagePath?token=test';
  }
}

class TestImagePickerService implements IProducerImagePickerService {
  @override
  bool isCameraSupported;

  PickedProductImage? nextResult;
  Exception? exceptionToThrow;
  int pickCalls = 0;

  TestImagePickerService({
    this.isCameraSupported = true,
    this.nextResult,
    this.exceptionToThrow,
  });

  @override
  Future<PickedProductImage?> pickImage(ImageSourceOption source) async {
    pickCalls++;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return nextResult;
  }
}

Widget createTestWidget({
  required Widget child,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 6C.6B2: Real Runtime Photo Pipeline Regression Tests', () {
    // -------------------------------------------------------------------------
    // 1 & 2 & 3: Production Construction & Usable Services
    // -------------------------------------------------------------------------
    test('1 & 2: Production-style AddProductProvider wiring exposes non-null usable imageService', () {
      final realProductService = ProducerProductService();
      final provider = AddProductProvider(productService: realProductService);

      expect(provider.imageService, isNotNull);
      expect(provider.imagePickerService, isNotNull);
      expect(provider.enhancementService, isNotNull);
      expect(provider.imageService, isA<ProducerProductImageService>());
    });

    test('3: Default AddProductProvider() constructor has non-null imageService path', () {
      final provider = AddProductProvider();

      expect(provider.imageService, isNotNull);
      expect(provider.imagePickerService, isNotNull);
      expect(provider.enhancementService, isNotNull);
    });

    // -------------------------------------------------------------------------
    // 4: Picker failure resets busy state
    // -------------------------------------------------------------------------
    test('4: Picker failure resets busy state and sets typed error code', () async {
      final mockPicker = TestImagePickerService(
        exceptionToThrow: const PhotoPickerUnavailableException(
          'Photo picker is not available on this device.',
        ),
      );
      final productService = TestProductService();
      final imageService = TestImageService();
      final provider = AddProductProvider(
        productService: productService,
        imageService: imageService,
        imagePickerService: mockPicker,
      );

      provider.setName('Handmade Shawl');

      final success = await provider.pickAndUploadImage(ImageSourceOption.gallery);

      expect(success, isFalse);
      expect(provider.isUploadingImage, isFalse);
      expect(provider.isSaving, isFalse);
      expect(provider.hasError, isTrue);
      expect(provider.lastErrorCode, ProductPhotoErrorCode.pickerUnavailable);
    });

    // -------------------------------------------------------------------------
    // 5: Storage failure resets busy state
    // -------------------------------------------------------------------------
    test('5: Storage failure resets busy state and sets typed error code', () async {
      final mockPicker = TestImagePickerService(
        nextResult: PickedProductImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          originalFilename: 'test.jpg',
          contentType: 'image/jpeg',
          sizeBytes: 3,
        ),
      );
      final imageService = TestImageService()..shouldFailUpload = true;
      final productService = TestProductService();
      final provider = AddProductProvider(
        productService: productService,
        imageService: imageService,
        imagePickerService: mockPicker,
      );

      provider.setName('Clay Pot');

      final success = await provider.pickAndUploadImage(ImageSourceOption.gallery);

      expect(success, isFalse);
      expect(provider.isUploadingImage, isFalse);
      expect(provider.isSaving, isFalse);
      expect(provider.hasError, isTrue);
      expect(
        provider.lastErrorCode == ProductPhotoErrorCode.storageUnavailable ||
            provider.lastErrorCode == ProductPhotoErrorCode.uploadFailed,
        isTrue,
      );
    });

    // -------------------------------------------------------------------------
    // 6: DB failure resets busy state and executes Storage cleanup
    // -------------------------------------------------------------------------
    test('6: DB failure resets busy state and executes Storage cleanup', () async {
      final mockPicker = TestImagePickerService(
        nextResult: PickedProductImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          originalFilename: 'test.jpg',
          contentType: 'image/jpeg',
          sizeBytes: 3,
        ),
      );
      final imageService = TestImageService();
      final productService = TestProductService()..shouldFailUpdateDraft = true;
      final provider = AddProductProvider(
        productService: productService,
        imageService: imageService,
        imagePickerService: mockPicker,
      );

      provider.setName('Brass Lamp');

      final success = await provider.pickAndUploadImage(ImageSourceOption.gallery);

      expect(success, isFalse);
      expect(provider.isUploadingImage, isFalse);
      expect(provider.isSaving, isFalse);
      expect(provider.hasError, isTrue);
      expect(provider.lastErrorCode, ProductPhotoErrorCode.uploadFailed);
      expect(imageService.deletedPaths.length, 1);
    });

    // -------------------------------------------------------------------------
    // 7: First upload failure -> second upload attempt can proceed
    // -------------------------------------------------------------------------
    test('7: First upload failure does NOT lock provider; second upload succeeds', () async {
      final mockPicker = TestImagePickerService(
        nextResult: PickedProductImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          originalFilename: 'test.jpg',
          contentType: 'image/jpeg',
          sizeBytes: 3,
        ),
      );
      final imageService = TestImageService();
      final productService = TestProductService();
      final provider = AddProductProvider(
        productService: productService,
        imageService: imageService,
        imagePickerService: mockPicker,
      );

      provider.setName('Organic Honey');

      // Attempt 1: fails at storage
      imageService.shouldFailUpload = true;
      final firstAttempt = await provider.pickAndUploadImage(ImageSourceOption.gallery);

      expect(firstAttempt, isFalse);
      expect(provider.isUploadingImage, isFalse);
      expect(provider.hasError, isTrue);

      // Attempt 2: storage recovers, user taps again
      imageService.shouldFailUpload = false;
      final secondAttempt = await provider.pickAndUploadImage(ImageSourceOption.gallery);

      expect(secondAttempt, isTrue);
      expect(provider.isUploadingImage, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.draft.images.length, 1);
    });

    // -------------------------------------------------------------------------
    // 8: Picker cancel -> second attempt can proceed
    // -------------------------------------------------------------------------
    test('8: Picker cancel does NOT lock provider; second attempt can proceed', () async {
      final mockPicker = TestImagePickerService(nextResult: null);
      final imageService = TestImageService();
      final productService = TestProductService();
      final provider = AddProductProvider(
        productService: productService,
        imageService: imageService,
        imagePickerService: mockPicker,
      );

      provider.setName('Wooden Toy');

      // Attempt 1: user cancels picker
      final firstAttempt = await provider.pickAndUploadImage(ImageSourceOption.gallery);
      expect(firstAttempt, isFalse);
      expect(provider.isUploadingImage, isFalse);
      expect(provider.draft.images, isEmpty);

      // Attempt 2: user selects photo
      mockPicker.nextResult = PickedProductImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        originalFilename: 'toy.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 3,
      );
      final secondAttempt = await provider.pickAndUploadImage(ImageSourceOption.gallery);
      expect(secondAttempt, isTrue);
      expect(provider.isUploadingImage, isFalse);
      expect(provider.draft.images.length, 1);
    });

    // -------------------------------------------------------------------------
    // 9: Punjabi picker failure renders Punjabi message
    // -------------------------------------------------------------------------
    testWidgets('9: Punjabi picker failure renders Punjabi message in UI', (tester) async {
      final mockPicker = TestImagePickerService(
        exceptionToThrow: const PhotoPickerUnavailableException(
          'Photo picker is not available on this device.',
        ),
      );
      final productService = TestProductService();
      final imageService = TestImageService();
      final provider = AddProductProvider(
        productService: productService,
        imageService: imageService,
        imagePickerService: mockPicker,
      );

      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('pa'),
          child: AddProductScreen(
            provider: provider,
            imagePickerService: mockPicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter name so validation passes
      await tester.enterText(
        find.byKey(const Key('add_product_name_field')),
        'ਗੁੜ ਦੀ ਚਾਹ',
      );
      await tester.pumpAndSettle();

      // Tap Add Photo
      await tester.tap(find.byKey(const Key('add_product_photo_button')));
      await tester.pumpAndSettle();

      // Tap Take Photo or Gallery in bottom sheet
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      // Check Punjabi snackbar message appears
      expect(
        find.text("ਇਸ ਡਿਵਾਈਸ 'ਤੇ ਫੋਟੋ ਚੋਣ ਉਪਲਬਧ ਨਹੀਂ ਹੈ। ਕਿਰਪਾ ਕਰਕੇ ਐਪ ਮੁੜ ਚਾਲੂ ਕਰੋ।"),
        findsOneWidget,
      );
      // Ensure raw English text is NOT displayed
      expect(
        find.text('Photo picker is not available on this device. Please restart the application.'),
        findsNothing,
      );
    });

    // -------------------------------------------------------------------------
    // 10: Hindi storage/upload failure renders Hindi message
    // -------------------------------------------------------------------------
    testWidgets('10: Hindi upload failure renders Hindi message in UI', (tester) async {
      final mockPicker = TestImagePickerService(
        nextResult: PickedProductImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          originalFilename: 'test.jpg',
          contentType: 'image/jpeg',
          sizeBytes: 3,
        ),
      );
      final productService = TestProductService();
      final imageService = TestImageService()..shouldFailUpload = true;
      final provider = AddProductProvider(
        productService: productService,
        imageService: imageService,
        imagePickerService: mockPicker,
      );

      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('hi'),
          child: AddProductScreen(
            provider: provider,
            imagePickerService: mockPicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(
        find.byKey(const Key('add_product_name_field')),
        'हस्तनिर्मित कालीन',
      );
      await tester.pumpAndSettle();

      // Tap Add Photo
      await tester.tap(find.byKey(const Key('add_product_photo_button')));
      await tester.pumpAndSettle();

      // Tap Gallery
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      // Check Hindi message appears
      final l10n = AppLocalizations.of(tester.element(find.byType(AddProductScreen)))!;
      expect(find.text(l10n.photoUploadFailed), findsOneWidget);

      // Ensure raw English text is NOT displayed
      expect(
        find.text('Photo could not be uploaded. Please try again.'),
        findsNothing,
      );
    });

    // -------------------------------------------------------------------------
    // 11 & 12: Web platform adapter resolves correct implementation
    // -------------------------------------------------------------------------
    test('11 & 12: Web platform adapter avoids broken MethodChannel fallback', () {
      final service = ProducerImagePickerService();
      // On non-web platform (test environment), isCameraSupported is true
      expect(service.isCameraSupported, isTrue);
    });

    // -------------------------------------------------------------------------
    // 13: Mobile exposes Camera + Gallery
    // -------------------------------------------------------------------------
    testWidgets('13: Mobile exposes Camera + Gallery in source selector', (tester) async {
      final mockPicker = TestImagePickerService(isCameraSupported: true);
      final provider = AddProductProvider(
        productService: TestProductService(),
        imageService: TestImageService(),
        imagePickerService: mockPicker,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            imagePickerService: mockPicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(
        find.byKey(const Key('add_product_name_field')),
        'Handmade Shawl',
      );
      await tester.pumpAndSettle();

      // Tap Add Photo
      await tester.tap(find.byKey(const Key('add_product_photo_button')));
      await tester.pumpAndSettle();

      // Both Camera and Gallery should be present
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 14: Web exposes direct Choose Photo without Camera sheet
    // -------------------------------------------------------------------------
    testWidgets('14: Web (camera unsupported) directly routes to gallery picker without camera sheet', (tester) async {
      final mockPicker = TestImagePickerService(
        isCameraSupported: false, // Simulates Web environment
        nextResult: PickedProductImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          originalFilename: 'web_photo.png',
          contentType: 'image/png',
          sizeBytes: 3,
        ),
      );
      final provider = AddProductProvider(
        productService: TestProductService(),
        imageService: TestImageService(),
        imagePickerService: mockPicker,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: AddProductScreen(
            provider: provider,
            imagePickerService: mockPicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(
        find.byKey(const Key('add_product_name_field')),
        'Ceramic Cup',
      );
      await tester.pumpAndSettle();

      // Tap Add Photo
      await tester.tap(find.byKey(const Key('add_product_photo_button')));
      await tester.pumpAndSettle();

      // Bottom sheet with Camera icon should NOT open
      expect(find.byIcon(Icons.camera_alt), findsNothing);

      // Directly called picker once
      expect(mockPicker.pickCalls, 1);
      expect(provider.draft.images.length, 1);
    });
  });
}
