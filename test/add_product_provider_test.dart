import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';
import 'package:buyer_section/producer_section/products/providers/add_product_provider.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

class MockProductService implements IProducerProductService {
  final Map<String, ProducerProduct> products = {};
  int createCalls = 0;
  int updateCalls = 0;
  bool shouldFail = false;

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async =>
      products.values.toList();

  @override
  Future<ProducerProduct> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  }) async {
    final p = products[productId]!;
    final updated = p.copyWith(status: newStatus);
    products[productId] = updated;
    return updated;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    products.remove(productId);
  }

  @override
  Future<ProducerProduct> createDraft(ProducerProductDraft draft) async {
    createCalls++;
    if (shouldFail) {
      throw const ProductOperationException('Simulated create error');
    }
    final id = 'draft-$createCalls';
    final product = ProducerProduct(
      id: id,
      producerId: 'user-001',
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
    products[id] = product;
    return product;
  }

  @override
  Future<ProducerProduct> updateDraft({
    required String productId,
    required ProducerProductDraft draft,
  }) async {
    updateCalls++;
    if (shouldFail) {
      throw const ProductOperationException('Simulated update error');
    }
    final existing = products[productId]!;
    final updated = existing.copyWith(
      name: draft.name,
      description: draft.description,
      category: draft.category,
      pricePaise: draft.pricePaise,
      setPriceNull: draft.pricePaise == null,
      unit: draft.unit,
      images: draft.images,
    );
    products[productId] = updated;
    return updated;
  }

  @override
  Future<ProducerProduct> updateProductImages({
    required String productId,
    required List<String> imagePaths,
  }) async {
    final existing = products[productId]!;
    final updated = existing.copyWith(images: imagePaths);
    products[productId] = updated;
    return updated;
  }
}

void main() {
  group('AddProductProvider - State & Lifecycle', () {
    late MockProductService mockService;
    late AddProductProvider provider;

    setUp(() {
      mockService = MockProductService();
      provider = AddProductProvider(productService: mockService);
    });

    test('initializes with clean, unpersisted state', () {
      expect(provider.currentStep, 1);
      expect(provider.persistedProductId, isNull);
      expect(provider.isPersisted, isFalse);
      expect(provider.isSaving, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.isDirty, isFalse);
      expect(provider.canAdvanceToStep2, isFalse);
      expect(provider.canAdvanceToStep3, isFalse);
      expect(provider.canMarkActive, isFalse);
      expect(provider.draft.name, '');
    });

    test('field setters update draft and mark state dirty with Unicode support', () {
      provider.setName('हाथ से बनी कालीन');
      provider.setCategory('हस्तशिल्प');
      provider.setDescription('Pure wool handwoven carpet');
      provider.setUnit('sqft');

      expect(provider.draft.name, 'हाथ से बनी कालीन');
      expect(provider.draft.category, 'हस्तशिल्प');
      expect(provider.draft.description, 'Pure wool handwoven carpet');
      expect(provider.draft.unit, 'sqft');
      expect(provider.isDirty, isTrue);
      expect(provider.canAdvanceToStep2, isTrue);
    });

    test('setPriceFromRupeesText handles valid input and rejects invalid input with safe error', () {
      // Valid input
      final ok = provider.setPriceFromRupeesText('1250.50');
      expect(ok, isTrue);
      expect(provider.draft.pricePaise, 125050);
      expect(provider.hasError, isFalse);

      // Invalid input
      final failed = provider.setPriceFromRupeesText('invalid_price');
      expect(failed, isFalse);
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, isNotEmpty);
    });

    test('image path setters add and remove paths immutably', () {
      provider.addImagePath('user/prod/img1.jpg');
      provider.addImagePath('user/prod/img2.jpg');
      expect(provider.draft.images, ['user/prod/img1.jpg', 'user/prod/img2.jpg']);

      // Duplicate addition is a no-op
      provider.addImagePath('user/prod/img1.jpg');
      expect(provider.draft.images.length, 2);

      provider.removeImagePath('user/prod/img1.jpg');
      expect(provider.draft.images, ['user/prod/img2.jpg']);
    });

    test('first saveDraft creates draft row, subsequent saveDraft updates same row', () async {
      provider.setName('Terracotta Mug');
      provider.setPriceFromPaise(35000);

      // 1. First save: creates new row
      final firstSaveOk = await provider.saveDraft();
      expect(firstSaveOk, isTrue);
      expect(provider.isPersisted, isTrue);
      expect(provider.persistedProductId, 'draft-1');
      expect(mockService.createCalls, 1);
      expect(mockService.updateCalls, 0);
      expect(provider.isDirty, isFalse);

      // 2. Modify draft
      provider.setCategory('Kitchen Pottery');
      expect(provider.isDirty, isTrue);

      // 3. Second save: updates existing row with SAME id (NO duplicate product!)
      final secondSaveOk = await provider.saveDraft();
      expect(secondSaveOk, isTrue);
      expect(provider.persistedProductId, 'draft-1');
      expect(mockService.createCalls, 1); // Still 1!
      expect(mockService.updateCalls, 1);
      expect(mockService.products['draft-1']?.category, 'Kitchen Pottery');
      expect(provider.isDirty, isFalse);
    });

    test('saveDraft rejects empty name with presentation error', () async {
      final ok = await provider.saveDraft();
      expect(ok, isFalse);
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, 'Product name cannot be empty');
      expect(mockService.createCalls, 0);
    });

    test('step navigation enforces prerequisites and automatically persists before Step 3', () async {
      // Cannot advance to Step 2 without name
      final step2WithoutName = await provider.goToStep(2);
      expect(step2WithoutName, isFalse);
      expect(provider.currentStep, 1);

      provider.setName('Silk Scarf');
      final step2WithName = await provider.goToStep(2);
      expect(step2WithName, isTrue);
      expect(provider.currentStep, 2);

      // Advancing to Step 3 requires persisted product:
      // provider automatically calls saveDraft() to ensure an authentic product ID exists for Storage
      final step3Ok = await provider.goToStep(3);
      expect(step3Ok, isTrue);
      expect(provider.currentStep, 3);
      expect(provider.isPersisted, isTrue);
      expect(provider.persistedProductId, isNotNull);
      expect(mockService.createCalls, 1);
    });

    test('failed persistence halts navigation to Step 3', () async {
      provider.setName('Wood Carving');
      mockService.shouldFail = true;

      final step3Ok = await provider.goToStep(3);
      expect(step3Ok, isFalse);
      expect(provider.currentStep, 1);
      expect(provider.hasError, isTrue);
    });

    test('canMarkActive verifies all Migration 009 requirements', () {
      provider.setName('A'); // < 2 chars
      provider.setCategory('Craft');
      provider.setPriceFromPaise(1000);
      expect(provider.canMarkActive, isFalse);

      provider.setName('Ceramic Pot');
      provider.setCategory('P'); // < 2 chars
      expect(provider.canMarkActive, isFalse);

      provider.setCategory('Pottery');
      provider.setPriceFromPaise(null); // null price
      expect(provider.canMarkActive, isFalse);

      provider.setPriceFromPaise(0); // zero price
      expect(provider.canMarkActive, isFalse);

      provider.setPriceFromPaise(50000); // valid positive price
      expect(provider.canMarkActive, isTrue);
    });

    test('markReady fails when canMarkActive is false', () async {
      provider.setName('Item');
      // Category and price are missing
      final success = await provider.markReady();
      expect(success, isFalse);
      expect(provider.hasError, isTrue);
      expect(mockService.updateCalls, 0);
    });

    test('markReady persists draft and updates product status to active', () async {
      provider.setName('Brass Diya');
      provider.setCategory('Handicraft');
      provider.setPriceFromPaise(35000);

      expect(provider.canMarkActive, isTrue);

      final success = await provider.markReady();
      expect(success, isTrue);
      expect(provider.isPersisted, isTrue);
      final id = provider.persistedProductId!;
      expect(mockService.products[id]?.status, ProductStatus.active);
      expect(mockService.products[id]?.name, 'Brass Diya');
    });

    test('reset clears state back to initial defaults', () async {
      provider.setName('Temp Item');
      await provider.saveDraft();
      expect(provider.isPersisted, isTrue);

      provider.reset();
      expect(provider.currentStep, 1);
      expect(provider.persistedProductId, isNull);
      expect(provider.draft.name, '');
      expect(provider.isDirty, isFalse);
    });
  });
}
