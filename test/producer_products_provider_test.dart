import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';
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

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async {
    fetchCallCount++;
    if (shouldThrowAuthError) {
      throw const ProductAuthException('Not authenticated');
    }
    if (shouldThrowOperationError) {
      throw const ProductOperationException('Internal Postgres error: relation "products" violation');
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
      throw const ProductOperationException('Check constraint chk_products_active_requires_price failed');
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
      throw const ProductOperationException('Delete constraint error');
    }
    productsToReturn.removeWhere((p) => p.id == productId);
  }
}

void main() {
  final testTimestamp = DateTime.parse('2026-09-04T12:00:00.000Z');

  final sampleProducts = [
    ProducerProduct(
      id: 'p-1',
      producerId: 'user-001',
      name: 'Active Shawl',
      category: 'Textiles',
      pricePaise: 120000,
      status: ProductStatus.active,
      createdAt: testTimestamp,
      updatedAt: testTimestamp,
    ),
    ProducerProduct(
      id: 'p-2',
      producerId: 'user-001',
      name: 'Draft Pottery',
      category: 'Pottery',
      pricePaise: null,
      status: ProductStatus.draft,
      createdAt: testTimestamp,
      updatedAt: testTimestamp,
    ),
    ProducerProduct(
      id: 'p-3',
      producerId: 'user-001',
      name: 'Hidden Wooden Toy',
      category: 'Woodcraft',
      pricePaise: 45000,
      status: ProductStatus.hidden,
      createdAt: testTimestamp,
      updatedAt: testTimestamp,
    ),
  ];

  group('ProducerProductsProvider', () {
    test('initial state is properly initialized and empty', () {
      final fakeService = FakeProducerProductService();
      final provider = ProducerProductsProvider(service: fakeService);

      expect(provider.loadingState, ProducerProductsLoadingState.initial);
      expect(provider.isInitial, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.isLoaded, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.isEmpty, isFalse);
      expect(provider.allProducts, isEmpty);
      expect(provider.visibleProducts, isEmpty);
      expect(provider.currentFilter, ProducerProductFilter.all);
      expect(provider.error, ProducerProductsErrorType.none);
    });

    test('successful load populates products and sets isLoaded true', () async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);

      await provider.loadProducts();

      expect(provider.loadingState, ProducerProductsLoadingState.loaded);
      expect(provider.isLoaded, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.isEmpty, isFalse);
      expect(provider.allProducts.length, 3);
      expect(provider.visibleProducts.length, 3);
      expect(provider.error, ProducerProductsErrorType.none);
    });

    test('empty state is clearly distinguished from error state', () async {
      final fakeService = FakeProducerProductService(initialProducts: []);
      final provider = ProducerProductsProvider(service: fakeService);

      await provider.loadProducts();

      expect(provider.loadingState, ProducerProductsLoadingState.loaded);
      expect(provider.isLoaded, isTrue);
      expect(provider.isEmpty, isTrue);
      expect(provider.hasError, isFalse);
      expect(provider.error, ProducerProductsErrorType.none);
    });

    test('loading failure sets error state without exposing raw error text', () async {
      final fakeService = FakeProducerProductService();
      fakeService.shouldThrowOperationError = true;
      final provider = ProducerProductsProvider(service: fakeService);

      await provider.loadProducts();

      expect(provider.loadingState, ProducerProductsLoadingState.error);
      expect(provider.hasError, isTrue);
      expect(provider.isLoaded, isFalse);
      expect(provider.isEmpty, isFalse);
      expect(provider.error, ProducerProductsErrorType.loadFailed);
    });

    test('unauthenticated loading failure sets notAuthenticated error', () async {
      final fakeService = FakeProducerProductService();
      fakeService.shouldThrowAuthError = true;
      final provider = ProducerProductsProvider(service: fakeService);

      await provider.loadProducts();

      expect(provider.loadingState, ProducerProductsLoadingState.error);
      expect(provider.hasError, isTrue);
      expect(provider.error, ProducerProductsErrorType.notAuthenticated);
    });

    test('refresh sets isRefreshing and retains data on completion', () async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);

      await provider.loadProducts();
      expect(provider.allProducts.length, 3);

      await provider.refresh();

      expect(provider.isRefreshing, isFalse);
      expect(provider.isLoaded, isTrue);
      expect(provider.allProducts.length, 3);
    });

    test('filtering All, Active, Draft, and Hidden returns correct subsets', () async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      // All
      provider.setFilter(ProducerProductFilter.all);
      expect(provider.visibleProducts.length, 3);

      // Active
      provider.setFilter(ProducerProductFilter.active);
      expect(provider.visibleProducts.length, 1);
      expect(provider.visibleProducts.first.status, ProductStatus.active);

      // Draft
      provider.setFilter(ProducerProductFilter.draft);
      expect(provider.visibleProducts.length, 1);
      expect(provider.visibleProducts.first.status, ProductStatus.draft);

      // Hidden
      provider.setFilter(ProducerProductFilter.hidden);
      expect(provider.visibleProducts.length, 1);
      expect(provider.visibleProducts.first.status, ProductStatus.hidden);
    });

    test('filter switching does not refetch from server (pure local filtering)', () async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      expect(fakeService.fetchCallCount, 1);

      provider.setFilter(ProducerProductFilter.active);
      provider.setFilter(ProducerProductFilter.draft);
      provider.setFilter(ProducerProductFilter.hidden);
      provider.setFilter(ProducerProductFilter.all);

      // Verify no network requests were triggered by local filter switching
      expect(fakeService.fetchCallCount, 1);
    });

    test('updateProductStatus updates local item and returns true on success', () async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      final success = await provider.updateProductStatus(
        productId: 'p-2',
        newStatus: ProductStatus.active,
      );

      expect(success, isTrue);
      expect(provider.error, ProducerProductsErrorType.none);
      final updated = provider.allProducts.firstWhere((p) => p.id == 'p-2');
      expect(updated.status, ProductStatus.active);
    });

    test('updateProductStatus sets updateFailed on failure and returns false', () async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      fakeService.shouldThrowOperationError = true;
      final success = await provider.updateProductStatus(
        productId: 'p-1',
        newStatus: ProductStatus.hidden,
      );

      expect(success, isFalse);
      expect(provider.error, ProducerProductsErrorType.updateFailed);
    });

    test('updateProductStatus sets notAuthenticated when auth exception occurs', () async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      fakeService.shouldThrowAuthError = true;
      final success = await provider.updateProductStatus(
        productId: 'p-1',
        newStatus: ProductStatus.hidden,
      );

      expect(success, isFalse);
      expect(provider.error, ProducerProductsErrorType.notAuthenticated);
    });

    test('deleteProduct removes item from local list and returns true on success', () async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();
      expect(provider.allProducts.length, 3);

      final success = await provider.deleteProduct('p-1');

      expect(success, isTrue);
      expect(provider.error, ProducerProductsErrorType.none);
      expect(provider.allProducts.length, 2);
      expect(provider.allProducts.any((p) => p.id == 'p-1'), isFalse);
    });

    test('deleteProduct sets deleteFailed on error and returns false', () async {
      final fakeService = FakeProducerProductService(initialProducts: sampleProducts);
      final provider = ProducerProductsProvider(service: fakeService);
      await provider.loadProducts();

      fakeService.shouldThrowOperationError = true;
      final success = await provider.deleteProduct('p-1');

      expect(success, isFalse);
      expect(provider.error, ProducerProductsErrorType.deleteFailed);
      expect(provider.allProducts.length, 3);
    });

    test('safe error state uses enum classification without raw DB text', () async {
      final fakeService = FakeProducerProductService();
      fakeService.shouldThrowOperationError = true;
      final provider = ProducerProductsProvider(service: fakeService);

      await provider.loadProducts();

      expect(provider.error, ProducerProductsErrorType.loadFailed);
      expect(provider.error.name, 'loadFailed');
      // Verify no raw DB error text in error representation
      expect(provider.error.toString(), isNot(contains('Postgres')));
      expect(provider.error.toString(), isNot(contains('relation')));
    });
  });
}
