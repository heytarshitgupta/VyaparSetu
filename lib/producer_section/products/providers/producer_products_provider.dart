import 'package:flutter/foundation.dart';
import '../models/producer_product.dart';
import '../services/producer_product_service.dart';

/// Loading lifecycle states for the products provider.
enum ProducerProductsLoadingState {
  initial,
  loading,
  loaded,
  error,
}

/// Filter options for viewing products.
enum ProducerProductFilter {
  all,
  active,
  draft,
  hidden,
}

/// Presentation-safe error classification.
/// Does not leak raw SQL or database error strings to the UI.
enum ProducerProductsErrorType {
  none,
  notAuthenticated,
  loadFailed,
  updateFailed,
  deleteFailed,
}

/// State provider for the Producer Products module.
///
/// Manages loading, caching, local filtering, status transitions, and deletions.
/// Decoupled from UI and presentation frameworks for deterministic testability.
class ProducerProductsProvider extends ChangeNotifier {
  final IProducerProductService _service;

  ProducerProductsProvider({
    IProducerProductService? service,
  }) : _service = service ?? ProducerProductService();

  List<ProducerProduct> _products = [];
  ProducerProductsLoadingState _loadingState = ProducerProductsLoadingState.initial;
  ProducerProductsErrorType _error = ProducerProductsErrorType.none;
  ProducerProductFilter _currentFilter = ProducerProductFilter.all;
  bool _isRefreshing = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Unfiltered list of loaded products.
  List<ProducerProduct> get allProducts => List.unmodifiable(_products);

  /// Current loading state.
  ProducerProductsLoadingState get loadingState => _loadingState;

  /// Safe categorized error state.
  ProducerProductsErrorType get error => _error;

  /// Current active filter tab.
  ProducerProductFilter get currentFilter => _currentFilter;

  /// Whether a pull-to-refresh or background refresh is active.
  bool get isRefreshing => _isRefreshing;

  /// Whether products are initially being loaded.
  bool get isLoading => _loadingState == ProducerProductsLoadingState.loading;

  /// Whether provider is in initial uninitialized state.
  bool get isInitial => _loadingState == ProducerProductsLoadingState.initial;

  /// Whether the fetch succeeded and products are available.
  bool get isLoaded => _loadingState == ProducerProductsLoadingState.loaded;

  /// Whether an error occurred during loading.
  bool get hasError => _loadingState == ProducerProductsLoadingState.error;

  /// Explicit distinction: loaded successfully, but owning producer has 0 products.
  bool get isEmpty =>
      _loadingState == ProducerProductsLoadingState.loaded && _products.isEmpty;

  /// Visible products based on the currently selected filter.
  /// Evaluated purely in-memory to prevent repeated network round-trips.
  List<ProducerProduct> get visibleProducts {
    switch (_currentFilter) {
      case ProducerProductFilter.all:
        return List.unmodifiable(_products);
      case ProducerProductFilter.active:
        return List.unmodifiable(
          _products.where((p) => p.status == ProductStatus.active),
        );
      case ProducerProductFilter.draft:
        return List.unmodifiable(
          _products.where((p) => p.status == ProductStatus.draft),
        );
      case ProducerProductFilter.hidden:
        return List.unmodifiable(
          _products.where((p) => p.status == ProductStatus.hidden),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Filter Management
  // ---------------------------------------------------------------------------

  /// Sets the active filter tab locally without refetching from the server.
  void setFilter(ProducerProductFilter filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    notifyListeners();
  }

  /// Clears any active error state.
  void clearError() {
    if (_error != ProducerProductsErrorType.none) {
      _error = ProducerProductsErrorType.none;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Data Operations
  // ---------------------------------------------------------------------------

  /// Loads products for the authenticated producer.
  ///
  /// Set [isRefresh] to true for pull-to-refresh to retain visible data while updating.
  Future<void> loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
      notifyListeners();
    } else {
      _loadingState = ProducerProductsLoadingState.loading;
      _error = ProducerProductsErrorType.none;
      notifyListeners();
    }

    try {
      final fetched = await _service.fetchProducts();
      _products = fetched;
      _loadingState = ProducerProductsLoadingState.loaded;
      _error = ProducerProductsErrorType.none;
    } on ProductAuthException {
      _loadingState = ProducerProductsLoadingState.error;
      _error = ProducerProductsErrorType.notAuthenticated;
    } catch (_) {
      _loadingState = ProducerProductsLoadingState.error;
      _error = ProducerProductsErrorType.loadFailed;
    } finally {
      if (isRefresh) {
        _isRefreshing = false;
      }
      notifyListeners();
    }
  }

  /// Refreshes the product list.
  Future<void> refresh() => loadProducts(isRefresh: true);

  /// Updates the status of an existing product in the list.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  }) async {
    try {
      final updated = await _service.updateProductStatus(
        productId: productId,
        newStatus: newStatus,
      );

      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updated;
        _error = ProducerProductsErrorType.none;
        notifyListeners();
      }
      return true;
    } on ProductAuthException {
      _error = ProducerProductsErrorType.notAuthenticated;
      notifyListeners();
      return false;
    } catch (_) {
      _error = ProducerProductsErrorType.updateFailed;
      notifyListeners();
      return false;
    }
  }

  /// Hard-deletes an existing product and removes it from the local cache.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> deleteProduct(String productId) async {
    try {
      await _service.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      _error = ProducerProductsErrorType.none;
      notifyListeners();
      return true;
    } on ProductAuthException {
      _error = ProducerProductsErrorType.notAuthenticated;
      notifyListeners();
      return false;
    } catch (_) {
      _error = ProducerProductsErrorType.deleteFailed;
      notifyListeners();
      return false;
    }
  }
}
