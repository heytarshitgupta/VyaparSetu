import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_image_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

/// Test double simulating [IProducerProductService] with in-memory persistence
/// and full support for the Delete Lifecycle (Storage first -> DB second).
class FakeProducerProductService implements IProducerProductService {
  final String currentUserId;
  final IProducerProductImageService? imageService;
  final Map<String, ProducerProduct> _database = {};

  FakeProducerProductService({
    this.currentUserId = 'producer-123',
    this.imageService,
    List<ProducerProduct> initialProducts = const [],
  }) {
    for (final p in initialProducts) {
      _database[p.id] = p;
    }
  }

  Map<String, ProducerProduct> get database => Map.unmodifiable(_database);

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async {
    var list = _database.values
        .where((p) => p.producerId == currentUserId)
        .toList();
    if (statusFilter != null) {
      list = list.where((p) => p.status == statusFilter).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<ProducerProduct> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  }) async {
    final product = _database[productId];
    if (product == null || product.producerId != currentUserId) {
      throw const ProductOperationException('Product not found or not owned');
    }
    final updated = product.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    _database[productId] = updated;
    return updated;
  }

  @override
  Future<ProducerProduct> createDraft(ProducerProductDraft draft) async {
    if (draft.name.trim().isEmpty) {
      throw const ProductOperationException('Product name cannot be empty');
    }

    final now = DateTime.now();
    final newId = 'prod-${_database.length + 1}';
    final product = ProducerProduct(
      id: newId,
      producerId: currentUserId, // strictly server-derived
      name: draft.name.trim(),
      description: draft.description.trim(),
      category: draft.category.trim(),
      pricePaise: draft.pricePaise,
      unit: draft.unit.trim().isEmpty ? 'piece' : draft.unit.trim(),
      status: ProductStatus.draft, // strictly forced to draft
      images: const [],
      createdAt: now,
      updatedAt: now,
    );

    _database[newId] = product;
    return product;
  }

  @override
  Future<ProducerProduct> updateDraft({
    required String productId,
    required ProducerProductDraft draft,
  }) async {
    if (draft.name.trim().isEmpty) {
      throw const ProductOperationException('Product name cannot be empty');
    }

    final existing = _database[productId];
    if (existing == null || existing.producerId != currentUserId) {
      throw const ProductOperationException('Product not found or not owned');
    }

    // Producer, status, and images are intentionally preserved from existing row!
    final updated = existing.copyWith(
      name: draft.name.trim(),
      description: draft.description.trim(),
      category: draft.category.trim(),
      pricePaise: draft.pricePaise,
      setPriceNull: draft.pricePaise == null,
      unit: draft.unit.trim().isEmpty ? 'piece' : draft.unit.trim(),
      updatedAt: DateTime.now(),
    );

    _database[productId] = updated;
    return updated;
  }

  @override
  Future<ProducerProduct> updateProductImages({
    required String productId,
    required List<String> imagePaths,
  }) async {
    final existing = _database[productId];
    if (existing == null || existing.producerId != currentUserId) {
      throw const ProductOperationException('Product not found or not owned');
    }

    // Validate that every path is a valid stable Storage path
    for (final path in imagePaths) {
      ProducerProductImageService.validateStoragePath(path);
    }

    final updated = existing.copyWith(
      images: List.unmodifiable(imagePaths),
      updatedAt: DateTime.now(),
    );
    _database[productId] = updated;
    return updated;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final existing = _database[productId];
    if (existing == null || existing.producerId != currentUserId) {
      return; // Safe no-op if not found or not owned
    }

    // Delete Lifecycle: Storage images MUST be deleted first
    if (existing.images.isNotEmpty) {
      // CASE C: Images are present, but image service is NOT available.
      // Fail-safe: DO NOT delete DB row, throw typed exception.
      if (imageService == null) {
        throw const ProductOperationException(
          'Cannot delete product: product has images but no image service is available for Storage cleanup. Product was not deleted.',
        );
      }

      // CASE B: Images are present and image service is available.
      for (final img in existing.images) {
        try {
          await imageService!.deleteProductImage(img);
        } catch (e) {
          // Partial or total failure: halt DB deletion and retain product row!
          throw ProductOperationException(
            'Failed to clean up product images from storage. Product row was preserved.',
            e,
          );
        }
      }
    }

    // CASE A (no images) OR CASE B (all Storage deletes succeeded):
    // Only after storage succeeds, remove from database.
    _database.remove(productId);
  }
}

class FakeFailingImageService implements IProducerProductImageService {
  final List<String> deletedPaths = [];
  bool shouldFail = false;
  String? failOnSpecificPath;

  @override
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String contentType,
  }) async => 'path/to/img.jpg';

  @override
  Future<void> deleteProductImage(String storagePath) async {
    if (shouldFail || (failOnSpecificPath != null && storagePath == failOnSpecificPath)) {
      throw const ProductOperationException('Storage delete error');
    }
    deletedPaths.add(storagePath);
  }

  @override
  Future<String> createSignedImageUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async => 'https://signed.url';
}

void main() {
  group('ProducerProductService - Draft & Image Extensions', () {
    late FakeProducerProductService service;

    setUp(() {
      service = FakeProducerProductService(currentUserId: 'prod-user-1');
    });

    test('createDraft forces current auth user and status = draft', () async {
      const draft = ProducerProductDraft(
        name: 'Handcrafted Bowl',
        category: 'Pottery',
        pricePaise: 45000,
      );

      final product = await service.createDraft(draft);

      expect(product.producerId, 'prod-user-1');
      expect(product.status, ProductStatus.draft);
      expect(product.name, 'Handcrafted Bowl');
      expect(product.pricePaise, 45000);
      expect(service.database.containsKey(product.id), isTrue);
    });

    test('createDraft rejects empty product name', () async {
      const draft = ProducerProductDraft(name: '   ');
      expect(
        () => service.createDraft(draft),
        throwsA(isA<ProductOperationException>()),
      );
    });

    test('updateDraft updates editable fields while preserving status, producer_id, and images', () async {
      final initial = await service.createDraft(const ProducerProductDraft(name: 'Initial Name'));
      await service.updateProductImages(
        productId: initial.id,
        imagePaths: ['prod-user-1/${initial.id}/img.jpg'],
      );

      // Attempt update
      const updatedDraft = ProducerProductDraft(
        name: 'Updated Name',
        category: 'New Category',
        pricePaise: 150000,
        description: 'New Description',
        unit: 'box',
      );

      final result = await service.updateDraft(
        productId: initial.id,
        draft: updatedDraft,
      );

      expect(result.name, 'Updated Name');
      expect(result.category, 'New Category');
      expect(result.pricePaise, 150000);
      expect(result.unit, 'box');
      // Verify immutable fields were preserved
      expect(result.status, ProductStatus.draft);
      expect(result.producerId, 'prod-user-1');
      expect(result.images, ['prod-user-1/${initial.id}/img.jpg']);
    });

    test('updateDraft rejects updating a non-existent or unowned product', () async {
      expect(
        () => service.updateDraft(
          productId: 'non-existent-id',
          draft: const ProducerProductDraft(name: 'Valid Name'),
        ),
        throwsA(isA<ProductOperationException>()),
      );
    });

    test('updateProductImages updates images list correctly for valid stable paths', () async {
      final initial = await service.createDraft(const ProducerProductDraft(name: 'Product 1'));
      final validPaths = [
        'prod-user-1/${initial.id}/img1.jpg',
        'prod-user-1/${initial.id}/img2.png',
      ];
      final updated = await service.updateProductImages(
        productId: initial.id,
        imagePaths: validPaths,
      );

      expect(updated.images, validPaths);
      expect(service.database[initial.id]?.images, validPaths);
    });

    test('updateProductImages rejects non-stable paths (URLs, bucket prefixes, invalid segments)', () async {
      final initial = await service.createDraft(const ProducerProductDraft(name: 'Product 1'));

      // URL rejected
      expect(
        () => service.updateProductImages(
          productId: initial.id,
          imagePaths: ['https://example.com/photo.jpg'],
        ),
        throwsA(isA<ProductOperationException>()),
      );

      // Bucket prefix rejected
      expect(
        () => service.updateProductImages(
          productId: initial.id,
          imagePaths: ['product-images/user/prod/photo.jpg'],
        ),
        throwsA(isA<ProductOperationException>()),
      );

      // Malformed segment count (2 segments) rejected
      expect(
        () => service.updateProductImages(
          productId: initial.id,
          imagePaths: ['user/photo.jpg'],
        ),
        throwsA(isA<ProductOperationException>()),
      );
    });
  });

  group('ProducerProductService - Delete Lifecycle Order (Storage First -> DB Second)', () {
    late FakeFailingImageService imageService;
    late FakeProducerProductService service;

    setUp(() {
      imageService = FakeFailingImageService();
      service = FakeProducerProductService(
        currentUserId: 'prod-user-1',
        imageService: imageService,
      );
    });

    test('CASE A: product with no images deletes DB row normally', () async {
      final product = await service.createDraft(const ProducerProductDraft(name: 'No Image Product'));
      expect(service.database.containsKey(product.id), isTrue);

      await service.deleteProduct(product.id);

      expect(service.database.containsKey(product.id), isFalse);
      expect(imageService.deletedPaths, isEmpty);
    });

    test('CASE B: product with images + image service cleans Storage before DB row', () async {
      final product = await service.createDraft(const ProducerProductDraft(name: 'Product With Images'));
      final imagePaths = [
        'prod-user-1/${product.id}/photo1.jpg',
        'prod-user-1/${product.id}/photo2.jpg',
      ];
      await service.updateProductImages(productId: product.id, imagePaths: imagePaths);

      await service.deleteProduct(product.id);

      // Verify Storage was deleted first
      expect(imageService.deletedPaths, equals(imagePaths));
      // Verify DB row was subsequently removed
      expect(service.database.containsKey(product.id), isFalse);
    });

    test('CASE C: product with images + NO image service FAILS and DB row is NOT deleted', () async {
      // Service constructed without image service capability
      final serviceWithoutImages = FakeProducerProductService(
        currentUserId: 'prod-user-1',
        imageService: null,
      );

      final product = await serviceWithoutImages.createDraft(
        const ProducerProductDraft(name: 'Product With Images No Service'),
      );
      final imagePaths = ['prod-user-1/${product.id}/photo1.jpg'];
      await serviceWithoutImages.updateProductImages(
        productId: product.id,
        imagePaths: imagePaths,
      );

      // Attempt deletion: MUST throw and MUST NOT delete DB row
      expect(
        () => serviceWithoutImages.deleteProduct(product.id),
        throwsA(isA<ProductOperationException>()),
      );

      // CRITICAL: DB row MUST be preserved for retry
      expect(serviceWithoutImages.database.containsKey(product.id), isTrue);
      expect(
        serviceWithoutImages.database[product.id]?.images,
        equals(imagePaths),
      );
    });

    test('PARTIAL FAILURE: one Storage deletion failure keeps DB row and halts remaining', () async {
      final product = await service.createDraft(const ProducerProductDraft(name: 'Product With 3 Images'));
      final imagePaths = [
        'prod-user-1/${product.id}/photoA.jpg',
        'prod-user-1/${product.id}/photoB.jpg',
        'prod-user-1/${product.id}/photoC.jpg',
      ];
      await service.updateProductImages(productId: product.id, imagePaths: imagePaths);

      // Simulate failure on second image B
      imageService.failOnSpecificPath = 'prod-user-1/${product.id}/photoB.jpg';

      expect(
        () => service.deleteProduct(product.id),
        throwsA(isA<ProductOperationException>()),
      );

      // Storage cleanup: A succeeded, B failed, C was never attempted
      expect(imageService.deletedPaths, equals(['prod-user-1/${product.id}/photoA.jpg']));
      // DB row MUST remain intact to preserve ownership evidence for recovery
      expect(service.database.containsKey(product.id), isTrue);
      expect(service.database[product.id]?.name, 'Product With 3 Images');
    });

    test('Storage cleanup failure ABORTS deletion and leaves DB row intact', () async {
      final product = await service.createDraft(const ProducerProductDraft(name: 'Product With Images'));
      final imagePaths = ['prod-user-1/${product.id}/photo1.jpg'];
      await service.updateProductImages(productId: product.id, imagePaths: imagePaths);

      // Trigger simulated storage failure
      imageService.shouldFail = true;

      expect(
        () => service.deleteProduct(product.id),
        throwsA(isA<ProductOperationException>()),
      );

      // CRITICAL VERIFICATION: DB row MUST still exist so Storage RLS ownership evidence is not lost
      expect(service.database.containsKey(product.id), isTrue);
      expect(service.database[product.id]?.name, 'Product With Images');
    });
  });

  group('ProducerProductService - Runtime Dependency Wiring', () {
    test('default constructor wires ProducerProductImageService', () {
      final prodService = ProducerProductService();
      expect(prodService.imageService, isNotNull);
      expect(prodService.imageService, isA<ProducerProductImageService>());
    });

    test('constructor allows disabling imageService with enableImageService: false', () {
      final prodService = ProducerProductService(enableImageService: false);
      expect(prodService.imageService, isNull);
    });
  });
}


