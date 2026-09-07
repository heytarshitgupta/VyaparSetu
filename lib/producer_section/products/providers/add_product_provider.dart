import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/producer_product.dart';
import '../models/producer_product_draft.dart';
import '../models/product_price_parser.dart';
import '../services/producer_image_picker_service.dart';
import '../services/producer_product_enhancement_service.dart';
import '../services/producer_product_image_service.dart';
import '../services/producer_product_service.dart';

/// Typed error category for photo picking, upload, and processing operations.
/// Mapped to localized messages at the presentation layer.
enum ProductPhotoErrorCode {
  pickerUnavailable,
  storageUnavailable,
  unsupportedFormat,
  imageTooLarge,
  maxPhotosExceeded,
  uploadFailed,
  nameRequired,
  authRequired,
  operationFailed,
}

/// Provider managing the state and persistence lifecycle of a single Add/Edit Product session.
///
/// Decoupled from presentation frameworks, UI widgets, and hardware APIs (e.g. image_picker).
/// Serves as the canonical state container populated by future UI keyboards, voice inputs, or AI assistants.
class AddProductProvider extends ChangeNotifier {
  final IProducerProductService _productService;
  final IProducerProductImageService imageService;
  final IProducerImagePickerService imagePickerService;
  final IProductPhotoEnhancementService enhancementService;
  ProducerProduct? _existingProduct;

  AddProductProvider({
    IProducerProductService? productService,
    IProducerProductImageService? imageService,
    IProducerImagePickerService? imagePickerService,
    IProductPhotoEnhancementService? enhancementService,
    ProducerProduct? existingProduct,
  })  : _productService = productService ?? ProducerProductService(),
        imageService = imageService ??
            productService?.imageService ??
            (productService is ProducerProductService
                ? (productService.imageService ?? ProducerProductImageService(client: productService.client))
                : ProducerProductImageService()),
        imagePickerService = imagePickerService ?? ProducerImagePickerService(),
        enhancementService = enhancementService ??
            ProducerProductEnhancementService(
              imageService: imageService ??
                  productService?.imageService ??
                  (productService is ProducerProductService
                      ? (productService.imageService ?? ProducerProductImageService(client: productService.client))
                      : ProducerProductImageService()),
            ),
        _existingProduct = existingProduct,
        _persistedProductId = existingProduct?.id,
        _draft = existingProduct != null
            ? ProducerProductDraft.fromProduct(existingProduct)
            : const ProducerProductDraft();

  /// Named constructor to initialize provider directly for editing an existing product.
  factory AddProductProvider.forExistingProduct({
    required ProducerProduct product,
    IProducerProductService? productService,
    IProducerProductImageService? imageService,
    IProducerImagePickerService? imagePickerService,
    IProductPhotoEnhancementService? enhancementService,
  }) {
    return AddProductProvider(
      existingProduct: product,
      productService: productService,
      imageService: imageService,
      imagePickerService: imagePickerService,
      enhancementService: enhancementService,
    );
  }

  ProducerProductDraft _draft = const ProducerProductDraft();
  int _currentStep = 1; // Planned 3-step wizard: 1, 2, 3
  String? _persistedProductId;
  bool _isSaving = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _improvingPhotoPath;
  final Map<String, String> _improvedCandidates = {};
  final Map<String, String> _signedUrlCache = {};
  String? _errorMessage;
  ProductPhotoErrorCode? _lastErrorCode;
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

  /// The existing product being edited, or null if creating a new product.
  ProducerProduct? get existingProduct => _existingProduct;

  /// Whether the provider is in edit mode for an existing product.
  bool get isEditMode => _existingProduct != null;

  /// The original status of the existing product, or null if creating a new product.
  ProductStatus? get existingStatus => _existingProduct?.status;

  /// Whether this draft has been persisted to public.products at least once.
  bool get isPersisted => _persistedProductId != null;

  /// Whether a background save/create operation is currently in flight.
  bool get isSaving => _isSaving;

  /// Whether an image or data loading operation is in flight.
  bool get isLoading => _isLoading;

  /// Whether a photo upload operation is currently in flight.
  bool get isUploadingImage => _isUploadingImage;

  /// Whether an AI photo improvement is currently in flight.
  bool get isImprovingPhoto => _improvingPhotoPath != null;

  /// The storage path of the image currently being improved, if any.
  String? get improvingPhotoPath => _improvingPhotoPath;

  /// Checks if [storagePath] is currently being improved by AI.
  bool isPhotoBeingImproved(String storagePath) => _improvingPhotoPath == storagePath;

  /// Read-only map of original storage paths to candidate improved storage paths.
  Map<String, String> get improvedCandidates => Map.unmodifiable(_improvedCandidates);

  /// Returns candidate improved path for [originalPath], or null if none.
  String? getCandidateForPhoto(String originalPath) => _improvedCandidates[originalPath];

  /// Checks if [originalPath] has a pending improved candidate.
  bool hasCandidateForPhoto(String originalPath) => _improvedCandidates.containsKey(originalPath);

  /// Read-only view of cached signed URLs for in-memory display.
  Map<String, String> get signedUrls => Map.unmodifiable(_signedUrlCache);

  /// Safe, human-readable error message or null if no active error.
  String? get errorMessage => _errorMessage;

  /// Whether the provider currently holds an error.
  bool get hasError => _errorMessage != null;

  /// Typed error category for localized UI mapping.
  ProductPhotoErrorCode? get lastErrorCode => _lastErrorCode;

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
    if (_errorMessage != null || _lastErrorCode != null) {
      _errorMessage = null;
      _lastErrorCode = null;
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
      _lastErrorCode = ProductPhotoErrorCode.nameRequired;
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
        _existingProduct = created;
        _isDirty = false;
        return true;
      } else {
        // Subsequent persistence: update existing draft row
        final updated = await _productService.updateDraft(
          productId: _persistedProductId!,
          draft: _draft,
        );
        _existingProduct = updated;
        _isDirty = false;
        return true;
      }
    } on ProductAuthException {
      _lastErrorCode = ProductPhotoErrorCode.authRequired;
      _errorMessage = 'Authentication required. Please log in again.';
      return false;
    } on ProductOperationException catch (e) {
      _lastErrorCode = ProductPhotoErrorCode.operationFailed;
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _lastErrorCode = ProductPhotoErrorCode.operationFailed;
      _errorMessage = 'Failed to save product draft. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Saves changes to an existing or draft product without altering its current status.
  Future<bool> saveChanges() => saveDraft();

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
      _lastErrorCode = ProductPhotoErrorCode.operationFailed;
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
      final updated = await _productService.updateProductStatus(
        productId: _persistedProductId!,
        newStatus: ProductStatus.active,
      );
      _existingProduct = updated;
      return true;
    } on ProductAuthException {
      _lastErrorCode = ProductPhotoErrorCode.authRequired;
      _errorMessage = 'Authentication required. Please log in again.';
      return false;
    } on ProductOperationException catch (e) {
      _lastErrorCode = ProductPhotoErrorCode.operationFailed;
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _lastErrorCode = ProductPhotoErrorCode.operationFailed;
      _errorMessage = 'Failed to mark product ready. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Ensures product is persisted in public.products before photo selection or upload.
  ///
  /// In the single-form UX:
  /// - If persistedProductId already exists and state is not dirty, returns true.
  /// - If unpersisted or dirty, verifies minimum draft requirements (valid non-empty name).
  /// - If name is missing/empty:
  ///   - Does NOT create a blank/orphan product.
  ///   - Sets friendly error message: "Add a product name before adding photos."
  ///   - Returns false.
  /// - If name is valid:
  ///   - Silently creates or updates the draft row in the database.
  ///   - Obtains authentic persistedProductId.
  ///   - Returns true.
  Future<bool> ensurePersistedForPhotos() async {
    if (_persistedProductId != null && !_isDirty) {
      return true;
    }

    if (!_draft.hasValidDraftName) {
      _lastErrorCode = ProductPhotoErrorCode.nameRequired;
      _errorMessage = 'Add a product name before adding photos.';
      notifyListeners();
      return false;
    }

    final success = await saveDraft();
    if (!success || _persistedProductId == null) {
      _lastErrorCode ??= ProductPhotoErrorCode.operationFailed;
      _errorMessage ??= 'Could not save draft before adding photos.';
      notifyListeners();
      return false;
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Step Navigation Foundation (Legacy / Test Support)
  // ---------------------------------------------------------------------------

  /// Transitions between wizard steps (1, 2, 3).
  ///
  /// In single-sheet UX, all fields live on one page and photo uploads call
  /// [ensurePersistedForPhotos]. This method is retained for compatibility with existing tests.
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
      final ready = await ensurePersistedForPhotos();
      if (!ready) return false;

      _currentStep = 3;
      clearError();
      notifyListeners();
      return true;
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // Photo Selection & Storage Lifecycle
  // ---------------------------------------------------------------------------

  /// Prompts the user to pick an image from [source] (camera or gallery),
  /// validates format and size, and securely uploads it to Storage.
  Future<bool> pickAndUploadImage(ImageSourceOption source) async {
    if (_isUploadingImage || _isSaving) return false;

    if (_draft.images.length >= 4) {
      _lastErrorCode = ProductPhotoErrorCode.maxPhotosExceeded;
      _errorMessage = 'Maximum 4 photos allowed';
      notifyListeners();
      return false;
    }

    // Enforce draft persistence rule before opening photo picker
    final isPersistedOk = await ensurePersistedForPhotos();
    if (!isPersistedOk) {
      return false;
    }

    _isUploadingImage = true;
    clearError();
    notifyListeners();

    final PickedProductImage? picked;
    try {
      picked = await imagePickerService.pickImage(source);
    } on UnsupportedImageFormatException catch (e) {
      _lastErrorCode = ProductPhotoErrorCode.unsupportedFormat;
      _errorMessage = e.message;
      return false;
    } on ImageTooLargeException catch (e) {
      _lastErrorCode = ProductPhotoErrorCode.imageTooLarge;
      _errorMessage = e.message;
      return false;
    } on PhotoPickerUnavailableException catch (e) {
      _lastErrorCode = ProductPhotoErrorCode.pickerUnavailable;
      _errorMessage = e.message;
      return false;
    } on ProductOperationException catch (e) {
      _lastErrorCode = ProductPhotoErrorCode.pickerUnavailable;
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _lastErrorCode = ProductPhotoErrorCode.pickerUnavailable;
      _errorMessage = 'Photo picker is not available on this device. Please restart the application.';
      return false;
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }

    if (picked == null) {
      return false; // User cancelled
    }

    return uploadAndAddImage(
      bytes: picked.bytes,
      contentType: picked.contentType,
      originalFilename: picked.originalFilename,
    );
  }

  /// Securely uploads image [bytes] to the private 'product-images' bucket,
  /// updates the product row in the database, and records the stable storage path
  /// in the canonical [draft.images] list.
  ///
  /// Failure Cleanup Contract:
  /// Storage and PostgreSQL are not transactionally atomic. If the database update
  /// fails after a Storage upload succeeds, this method executes a best-effort
  /// deletion of ONLY the newly uploaded Storage object, preserving previously
  /// persisted images and preventing orphaned objects.
  Future<bool> uploadAndAddImage({
    required Uint8List bytes,
    required String contentType,
    required String originalFilename,
  }) async {
    if (_isUploadingImage || _isSaving) return false;

    if (_draft.images.length >= 4) {
      _lastErrorCode = ProductPhotoErrorCode.maxPhotosExceeded;
      _errorMessage = 'Maximum 4 photos allowed';
      notifyListeners();
      return false;
    }

    // Enforce: Product ID must exist before Storage upload
    if (_persistedProductId == null || _isDirty) {
      final saved = await ensurePersistedForPhotos();
      if (!saved || _persistedProductId == null) {
        _lastErrorCode = ProductPhotoErrorCode.nameRequired;
        _errorMessage ??= 'Please save product draft before uploading photos';
        notifyListeners();
        return false;
      }
    }

    final productId = _persistedProductId!;

    _isUploadingImage = true;
    clearError();
    notifyListeners();

    String? newlyUploadedPath;
    try {
      if (kDebugMode) {
        developer.log(
          '[PHOTO PIPELINE] Step A: Starting storage upload for product=$productId imagesCount=${_draft.images.length}',
          name: 'AddProductProvider',
        );
      }

      // Step A: Upload to Supabase Storage
      newlyUploadedPath = await imageService.uploadProductImage(
        productId: productId,
        bytes: bytes,
        contentType: contentType,
      );

      if (kDebugMode) {
        developer.log(
          '[PHOTO PIPELINE] storage-upload-ok path-segments=${newlyUploadedPath.split('/').length}',
          name: 'AddProductProvider',
        );
      }

      // Step B: Persist new image path to products.images via dedicated updateProductImages.
      // Uses updateProductImages (not updateDraft) to avoid the name-not-empty guard
      // and to keep the images update isolated from draft field overwrites.
      final updatedImages = [..._draft.images, newlyUploadedPath];
      final updatedProduct = await _productService.updateProductImages(
        productId: productId,
        imagePaths: updatedImages,
      );

      if (kDebugMode) {
        developer.log(
          '[PHOTO PIPELINE] db-images-update-ok product-images-count=${updatedProduct.images.length}',
          name: 'AddProductProvider',
        );
      }

      // Verify the returned product actually contains the new image path.
      // If the DB update somehow dropped it, fail cleanly rather than show false success.
      if (!updatedProduct.images.contains(newlyUploadedPath)) {
        if (kDebugMode) {
          developer.log(
            '[PHOTO PIPELINE] WARNING: DB returned product does NOT contain new path. Uploaded path=$newlyUploadedPath returnedImages=${updatedProduct.images}',
            name: 'AddProductProvider',
          );
        }
        throw ProductOperationException(
          'Image upload succeeded but the database did not save the path. Please try again.',
        );
      }

      // Step C: Update in-memory state with canonical stable path
      _draft = _draft.copyWith(images: updatedImages);
      _isDirty = false;

      // Pre-warm signed URL cache for smooth preview
      try {
        final signedUrl = await imageService.createSignedImageUrl(
          storagePath: newlyUploadedPath,
        );
        _signedUrlCache[newlyUploadedPath] = signedUrl;
        if (kDebugMode) {
          developer.log(
            '[PHOTO PIPELINE] signed-url-ok total-images=${_draft.images.length}',
            name: 'AddProductProvider',
          );
        }
      } catch (_) {
        // Non-critical if signed URL fetch fails; preview tile will retry on render
        if (kDebugMode) {
          developer.log(
            '[PHOTO PIPELINE] signed-url-failed (non-critical, image IS saved)',
            name: 'AddProductProvider',
          );
        }
      }

      return true;
    } on ProductAuthException {
      _lastErrorCode = ProductPhotoErrorCode.authRequired;
      _errorMessage = 'Authentication required. Please log in again.';
      if (kDebugMode) {
        developer.log('[PHOTO PIPELINE] FAILED: auth-required', name: 'AddProductProvider');
      }
      return false;
    } catch (e) {
      // Step D: Best-effort failure cleanup of newly uploaded object if DB update failed
      if (newlyUploadedPath != null) {
        if (kDebugMode) {
          developer.log(
            '[PHOTO PIPELINE] FAILED: cleaning up storage object. error=$e',
            name: 'AddProductProvider',
          );
        }
        try {
          await imageService.deleteProductImage(newlyUploadedPath);
        } catch (_) {
          // Ignore secondary cleanup error to expose original root cause
        }
      } else {
        if (kDebugMode) {
          developer.log(
            '[PHOTO PIPELINE] FAILED before storage upload. error=$e',
            name: 'AddProductProvider',
          );
        }
      }

      _lastErrorCode = ProductPhotoErrorCode.uploadFailed;
      if (e is ProductOperationException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'Photo could not be uploaded. Please try again.';
      }
      return false;
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// Removes a photo with [storagePath] from the product.
  ///
  /// Consistent Removal Lifecycle:
  /// 1. Updates the database row first with the image path removed.
  /// 2. Only after the database update succeeds, deletes the object from Storage.
  /// 3. Never deletes the product row.
  Future<bool> removeImage(String storagePath) async {
    if (_isUploadingImage || _isSaving) return false;
    if (!_draft.images.contains(storagePath)) return false;

    final productId = _persistedProductId;
    if (productId == null) {
      // Unpersisted product: remove from in-memory draft only
      removeImagePath(storagePath);
      _signedUrlCache.remove(storagePath);
      return true;
    }

    _isSaving = true;
    clearError();
    notifyListeners();

    try {
      // Step 1: Update DB first
      final updatedImages = _draft.images.where((p) => p != storagePath).toList();
      await _productService.updateDraft(
        productId: productId,
        draft: _draft.copyWith(images: updatedImages),
      );

      // Update in-memory draft
      _draft = _draft.copyWith(images: updatedImages);
      _isDirty = false;
      _signedUrlCache.remove(storagePath);

      // Step 2: Delete from Storage only AFTER DB update succeeds
      try {
        await imageService.deleteProductImage(storagePath);
      } catch (_) {
        // DB remains consistent even if Storage cleanup experiences network hiccup
      }

      // Cleanup any pending candidate for this removed image
      final candidatePath = _improvedCandidates.remove(storagePath);
      if (candidatePath != null) {
        _signedUrlCache.remove(candidatePath);
        enhancementService.discardCandidateImage(candidatePath);
      }

      return true;
    } on ProductAuthException {
      _errorMessage = 'Authentication required. Please log in again.';
      return false;
    } on ProductOperationException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to remove photo. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // AI Photo Improvement Lifecycle (Step 6C.6B)
  // ---------------------------------------------------------------------------

  /// Triggers server-side AI photo improvement for [sourceStoragePath].
  ///
  /// Invariants:
  /// - Server generates an improved version on a clean neutral background.
  /// - The improved image is saved as a new immutable object in private Storage.
  /// - Canonical [draft.images] and the database are NOT modified here.
  /// - The candidate path is recorded in [_improvedCandidates] until the user explicitly decides.
  Future<bool> improvePhoto(String sourceStoragePath) async {
    if (_isUploadingImage || _isSaving || _improvingPhotoPath != null) return false;
    if (!_draft.images.contains(sourceStoragePath)) return false;

    // Ensure product is persisted before calling Edge Function
    if (_persistedProductId == null || _isDirty) {
      final saved = await saveDraft();
      if (!saved || _persistedProductId == null) {
        _errorMessage = 'Please save product draft before improving photos';
        notifyListeners();
        return false;
      }
    }

    final productId = _persistedProductId!;
    final svc = enhancementService;

    _improvingPhotoPath = sourceStoragePath;
    clearError();
    notifyListeners();

    try {
      final result = await svc.improvePhoto(
        productId: productId,
        sourceStoragePath: sourceStoragePath,
      );

      _improvedCandidates[sourceStoragePath] = result.improvedStoragePath;

      // Pre-warm signed URL for candidate preview
      await getOrFetchSignedUrl(result.improvedStoragePath);

      return true;
    } on ProductOperationException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not improve photo. Please try again.';
      return false;
    } finally {
      _improvingPhotoPath = null;
      notifyListeners();
    }
  }

  /// User chooses "Use Improved Photo":
  /// Replaces [sourceStoragePath] with the improved candidate path in the canonical
  /// product images list, updates the database row FIRST, and then updates in-memory draft.
  ///
  /// The original Storage file is retained in Storage for recoverability.
  Future<bool> useImprovedPhoto(String sourceStoragePath) async {
    if (_isSaving || _isUploadingImage || _improvingPhotoPath != null) return false;
    final candidatePath = _improvedCandidates[sourceStoragePath];
    if (candidatePath == null) return false;
    if (!_draft.images.contains(sourceStoragePath)) return false;

    final productId = _persistedProductId;
    if (productId == null) return false;

    _isSaving = true;
    clearError();
    notifyListeners();

    try {
      // Step 1: Compute new images list replacing the original path with candidate path
      final updatedImages = _draft.images
          .map((p) => p == sourceStoragePath ? candidatePath : p)
          .toList();

      // Step 2: Persist to DB FIRST
      await _productService.updateDraft(
        productId: productId,
        draft: _draft.copyWith(images: updatedImages),
      );

      // Step 3: Only after DB update succeeds, update canonical draft
      _draft = _draft.copyWith(images: updatedImages);
      _isDirty = false;
      _improvedCandidates.remove(sourceStoragePath);

      return true;
    } on ProductAuthException {
      _errorMessage = 'Authentication required. Please log in again.';
      return false;
    } on ProductOperationException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to apply improved photo. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// User chooses "Keep Original":
  /// Leaves canonical [draft.images] and DB unchanged, removes candidate from state,
  /// and triggers best-effort cleanup of the unused candidate Storage object.
  Future<void> keepOriginalPhoto(String sourceStoragePath) async {
    final candidatePath = _improvedCandidates.remove(sourceStoragePath);
    if (candidatePath == null) return;

    _signedUrlCache.remove(candidatePath);
    notifyListeners();

    final svc = enhancementService;

    try {
      await svc.discardCandidateImage(candidatePath);
    } catch (_) {
      // Non-critical cleanup failure
    }
  }

  /// Returns a cached signed URL for [storagePath], or generates and caches a new one.
  Future<String?> getOrFetchSignedUrl(String storagePath) async {
    final cached = _signedUrlCache[storagePath];
    if (cached != null) return cached;

    try {
      final signedUrl = await imageService.createSignedImageUrl(
        storagePath: storagePath,
      );
      _signedUrlCache[storagePath] = signedUrl;
      notifyListeners();
      return signedUrl;
    } catch (_) {
      return null;
    }
  }

  /// Resets the provider back to initial blank state.
  void reset() {
    _draft = const ProducerProductDraft();
    _currentStep = 1;
    _persistedProductId = null;
    _isSaving = false;
    _isLoading = false;
    _isUploadingImage = false;
    _improvingPhotoPath = null;
    _improvedCandidates.clear();
    _signedUrlCache.clear();
    _errorMessage = null;
    _isDirty = false;
    notifyListeners();
  }
}
