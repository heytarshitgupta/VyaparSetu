import 'package:flutter/foundation.dart';
import '../models/producer_product.dart';
import '../models/producer_product_draft.dart';
import '../models/product_price_parser.dart';
import '../services/producer_product_image_service.dart';
import '../services/producer_product_service.dart';

/// Provider managing the state and persistence lifecycle of a single Add/Edit Product session.
///
/// Decoupled from presentation frameworks, UI widgets, and hardware APIs (e.g. image_picker).
/// Serves as the canonical state container populated by future UI keyboards, voice inputs, or AI assistants.
class AddProductProvider extends ChangeNotifier {
  final IProducerProductService _productService;
  final IProducerProductImageService? imageService;

  AddProductProvider({
    IProducerProductService? productService,
    this.imageService,
  }) : _productService = productService ?? ProducerProductService();

  ProducerProductDraft _draft = const ProducerProductDraft();
  int _currentStep = 1; // Planned 3-step wizard: 1, 2, 3
  String? _persistedProductId;
  bool _isSaving = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDirty = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Current in-memory editable draft state.
  ProducerProductDraft get draft => _draft;

  /// Current active step index (1, 2, or 3).
  int get currentStep => _currentStep;

  /// The persisted database ID of the product once saved, or null if not yet saved.
  String? get persistedProductId => _persistedProductId;

  /// Whether this draft has been persisted to public.products at least once.
  bool get isPersisted => _persistedProductId != null;

  /// Whether a background save/create operation is currently in flight.
  bool get isSaving => _isSaving;

  /// Whether an image or data loading operation is in flight.
  bool get isLoading => _isLoading;

  /// Safe, human-readable error message or null if no active error.
  String? get errorMessage => _errorMessage;

  /// Whether the provider currently holds an error.
  bool get hasError => _errorMessage != null;

  /// Whether in-memory draft has unpersisted changes.
  bool get isDirty => _isDirty;

  /// Validates whether the draft can advance to Step 2 (requires non-empty name).
  bool get canAdvanceToStep2 => _draft.hasValidDraftName;

  /// Validates whether the draft can advance to Step 3 (requires persisted database row).
  bool get canAdvanceToStep3 => isPersisted;

  /// Whether current draft satisfies all Migration 009 requirements to transition to active.
  /// (Name >= 2, Category >= 2, Price > 0). Photos not required.
  bool get canMarkActive => _draft.canMarkActive;

  // ---------------------------------------------------------------------------
  // Canonical Field Setters
  // ---------------------------------------------------------------------------

  /// Canonical setter for product name.
  void setName(String name) {
    if (_draft.name == name) return;
    _draft = _draft.copyWith(name: name);
    _isDirty = true;
    clearError();
    notifyListeners();
  }

  /// Canonical setter for product category.
  void setCategory(String category) {
    if (_draft.category == category) return;
    _draft = _draft.copyWith(category: category);
    _isDirty = true;
    clearError();
    notifyListeners();
  }

  /// Canonical setter for product description.
  void setDescription(String description) {
    if (_draft.description == description) return;
    _draft = _draft.copyWith(description: description);
    _isDirty = true;
    clearError();
    notifyListeners();
  }

  /// Canonical setter for price directly in integer paise.
  void setPriceFromPaise(int? paise) {
    if (_draft.pricePaise == paise) return;
    _draft = _draft.copyWith(pricePaise: paise, setPriceNull: paise == null);
    _isDirty = true;
    clearError();
    notifyListeners();
  }

  /// Canonical setter for price using UI rupee text (e.g. "1250", "1250.50").
  /// Uses centralized [ProductPriceParser.parseRupeesTextOptional].
  /// Sets safe presentation error if format is invalid.
  bool setPriceFromRupeesText(String text) {
    try {
      final paise = ProductPriceParser.parseRupeesTextOptional(text);
      setPriceFromPaise(paise);
      return true;
    } on FormatException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Canonical setter for product unit (defaults to 'piece').
  void setUnit(String unit) {
    if (_draft.unit == unit) return;
    _draft = _draft.copyWith(unit: unit);
    _isDirty = true;
    clearError();
    notifyListeners();
  }

  /// Adds a stable Storage object path to the draft images list.
  void addImagePath(String storagePath) {
    if (_draft.images.contains(storagePath)) return;
    _draft = _draft.copyWith(images: [..._draft.images, storagePath]);
    _isDirty = true;
    notifyListeners();
  }

  /// Removes a stable Storage object path from the draft images list.
  void removeImagePath(String storagePath) {
    if (!_draft.images.contains(storagePath)) return;
    _draft = _draft.copyWith(
      images: _draft.images.where((p) => p != storagePath).toList(),
    );
    _isDirty = true;
    notifyListeners();
  }

  /// Clears active error messages.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence & Draft Management
  // ---------------------------------------------------------------------------

  /// Explicitly persists current in-memory draft to Supabase.
  ///
  /// - First Save: Calls [createDraft], stores returned product ID, sets isDirty = false.
  /// - Subsequent Saves: Calls [updateDraft] using [persistedProductId], sets isDirty = false.
  ///
  /// Guarantees that repeated calls update the same product record instead of
  /// spawning duplicate draft rows.
  Future<bool> saveDraft() async {
    if (!_draft.hasValidDraftName) {
      _errorMessage = 'Product name cannot be empty';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    clearError();
    notifyListeners();

    try {
      if (_persistedProductId == null) {
        // First persistence: create draft row
        final created = await _productService.createDraft(_draft);
        _persistedProductId = created.id;
        _isDirty = false;
        return true;
      } else {
        // Subsequent persistence: update existing draft row
        await _productService.updateDraft(
          productId: _persistedProductId!,
          draft: _draft,
        );
        _isDirty = false;
        return true;
      }
    } on ProductAuthException {
      _errorMessage = 'Authentication required. Please log in again.';
      return false;
    } on ProductOperationException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to save product draft. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Persists any unpersisted draft changes and explicitly transitions the
  /// product status to [ProductStatus.active] via [_productService.updateProductStatus].
  ///
  /// Enforces prerequisites:
  /// - [canMarkActive] must be true (name >= 2, category >= 2, price > 0).
  /// - Draft must be persisted first.
  ///
  /// Returns true on success, false on failure (setting [errorMessage]).
  Future<bool> markReady() async {
    if (!canMarkActive) {
      _errorMessage = 'Please complete name, category, and price first';
      notifyListeners();
      return false;
    }

    if (_persistedProductId == null || _isDirty) {
      final saved = await saveDraft();
      if (!saved) return false;
    }

    _isSaving = true;
    clearError();
    notifyListeners();

    try {
      await _productService.updateProductStatus(
        productId: _persistedProductId!,
        newStatus: ProductStatus.active,
      );
      return true;
    } on ProductAuthException {
      _errorMessage = 'Authentication required. Please log in again.';
      return false;
    } on ProductOperationException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to mark product ready. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Step Navigation Foundation
  // ---------------------------------------------------------------------------

  /// Transitions between wizard steps (1, 2, 3).
  ///
  /// Enforces prerequisites:
  /// - Step 2: requires non-empty name.
  /// - Step 3: requires a persisted product ID in public.products so that
  ///   Storage RLS policies have an authentic owned product for image upload.
  ///   Automatically persists or updates draft before transitioning to Step 3.
  Future<bool> goToStep(int step) async {
    if (step < 1 || step > 3) return false;

    if (step == 1) {
      _currentStep = 1;
      notifyListeners();
      return true;
    }

    if (step == 2) {
      if (!_draft.hasValidDraftName) {
        _errorMessage = 'Please enter a product name first';
        notifyListeners();
        return false;
      }
      _currentStep = 2;
      clearError();
      notifyListeners();
      return true;
    }

    if (step == 3) {
      if (!_draft.hasValidDraftName) {
        _errorMessage = 'Please enter a product name first';
        notifyListeners();
        return false;
      }

      // Step 3 requires persisted product ID. Persist now if needed.
      if (_persistedProductId == null || _isDirty) {
        final success = await saveDraft();
        if (!success) return false;
      }

      _currentStep = 3;
      clearError();
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Resets the provider back to initial blank state.
  void reset() {
    _draft = const ProducerProductDraft();
    _currentStep = 1;
    _persistedProductId = null;
    _isSaving = false;
    _isLoading = false;
    _errorMessage = null;
    _isDirty = false;
    notifyListeners();
  }
}
