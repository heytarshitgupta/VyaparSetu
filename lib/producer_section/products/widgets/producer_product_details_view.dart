import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../models/producer_product.dart';
import '../providers/producer_products_provider.dart';
import '../screens/add_product_screen.dart';
import '../services/producer_product_enhancement_service.dart';
import '../services/producer_product_image_service.dart';
import '../services/producer_product_service.dart';
import 'producer_product_card.dart';

/// A responsive, comprehensive Product Details viewing and management experience.
///
/// Displayed as:
/// - A near-full-height modal bottom sheet on Phone (<640px)
/// - A centered dialog modal on Tablet & Desktop (>=640px)
///
/// Features:
/// - Real available product data only (name, category, price/unit, status, description)
/// - Private Storage image display with transient signed URLs
/// - Multiple photo thumbnail selector (tapping thumbnail swaps active image)
/// - ✨ Improve Photo button triggering existing AI enhancement pipeline
/// - Keep Original / Use Improved Photo comparison flow
/// - Active / Inactive switch with complete product validation
/// - Edit Product (opening single-sheet AddProductScreen)
/// - Safe Delete Product with confirmation (Storage-first -> DB-second)
class ProducerProductDetailsView extends StatefulWidget {
  final ProducerProduct product;
  final ProducerProductsProvider productsProvider;
  final IProducerProductService? productService;
  final IProducerProductImageService? imageService;
  final IProductPhotoEnhancementService? enhancementService;
  final VoidCallback? onProductUpdated;
  final bool isBottomSheet;
  final ScaffoldMessengerState? rootMessenger;

  const ProducerProductDetailsView({
    super.key,
    required this.product,
    required this.productsProvider,
    this.productService,
    this.imageService,
    this.enhancementService,
    this.onProductUpdated,
    this.isBottomSheet = false,
    this.rootMessenger,
  });

  /// Displays the Product Details in a responsive modal.
  static Future<void> show(
    BuildContext context, {
    required ProducerProduct product,
    required ProducerProductsProvider productsProvider,
    IProducerProductService? productService,
    IProducerProductImageService? imageService,
    IProductPhotoEnhancementService? enhancementService,
    VoidCallback? onProductUpdated,
  }) async {
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 640;
    final rootMessenger = ScaffoldMessenger.maybeOf(context);

    if (isPhone) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => FractionallySizedBox(
          heightFactor: 0.92,
          child: ProducerProductDetailsView(
            product: product,
            productsProvider: productsProvider,
            productService: productService,
            imageService: imageService,
            enhancementService: enhancementService,
            onProductUpdated: onProductUpdated,
            isBottomSheet: true,
            rootMessenger: rootMessenger,
          ),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 920,
              maxHeight: 760,
            ),
            child: ProducerProductDetailsView(
              product: product,
              productsProvider: productsProvider,
              productService: productService,
              imageService: imageService,
              enhancementService: enhancementService,
              onProductUpdated: onProductUpdated,
              isBottomSheet: false,
              rootMessenger: rootMessenger,
            ),
          ),
        ),
      );
    }
  }

  @override
  State<ProducerProductDetailsView> createState() => _ProducerProductDetailsViewState();
}

class _ProducerProductDetailsViewState extends State<ProducerProductDetailsView> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late ProducerProduct _currentProduct;
  int _selectedImageIndex = 0;
  bool _isImprovingPhoto = false;
  bool _isStatusBusy = false;

  final Map<String, String> _signedUrlCache = {};
  final Map<String, Future<String>> _signedUrlFutures = {};

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
  }

  IProducerProductImageService get _effectiveImageService {
    final svc = widget.imageService ??
        widget.productService?.imageService ??
        widget.productsProvider.effectiveImageService;
    return svc ?? ProducerProductImageService();
  }

  IProductPhotoEnhancementService get _effectiveEnhancementService {
    return widget.enhancementService ??
        ProducerProductEnhancementService(imageService: _effectiveImageService);
  }

  Future<String?> _getOrFetchSignedUrl(String storagePath) {
    final cleanPath = storagePath.trim();
    if (cleanPath.isEmpty) return Future.value(null);

    // 1. Check local cache with stable Future
    final localCached = _signedUrlCache[cleanPath];
    if (localCached != null) {
      _signedUrlFutures[cleanPath] ??= Future.value(localCached);
      return _signedUrlFutures[cleanPath]!;
    }

    // 2. Check provider cache with stable Future
    final providerCached = widget.productsProvider.signedUrlCache[cleanPath];
    if (providerCached != null) {
      _signedUrlCache[cleanPath] = providerCached;
      _signedUrlFutures[cleanPath] ??= Future.value(providerCached);
      return _signedUrlFutures[cleanPath]!;
    }

    // 3. Fetch from image service using stable Future
    if (!_signedUrlFutures.containsKey(cleanPath)) {
      _signedUrlFutures[cleanPath] = _effectiveImageService
          .createSignedImageUrl(storagePath: cleanPath)
          .then((url) {
        _signedUrlCache[cleanPath] = url;
        return url;
      }).catchError((Object error) {
        if (kDebugMode) {
          developer.log(
            '[PRODUCT DETAILS] Signed URL fetch error for path=$cleanPath: $error',
            name: 'ProducerProductDetailsView',
          );
        }
        throw error;
      });
    }

    return _signedUrlFutures[cleanPath]!;
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleToggleStatus() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = _scaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);

    // Validation for activating an inactive product
    if (_currentProduct.status == ProductStatus.hidden) {
      final canActivate = _currentProduct.name.trim().length >= 2 &&
          _currentProduct.category.trim().length >= 2 &&
          _currentProduct.pricePaise != null &&
          _currentProduct.pricePaise! > 0;
      if (!canActivate) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.incompleteProductCannotActivate),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final newStatus = _currentProduct.status == ProductStatus.active
        ? ProductStatus.hidden
        : ProductStatus.active;

    setState(() {
      _isStatusBusy = true;
    });

    final success = await widget.productsProvider.updateProductStatus(
      productId: _currentProduct.id,
      newStatus: newStatus,
    );

    if (!mounted) return;

    setState(() {
      _isStatusBusy = false;
      if (success) {
        _currentProduct = _currentProduct.copyWith(status: newStatus);
      }
    });

    messenger.hideCurrentSnackBar();
    if (success) {
      widget.onProductUpdated?.call();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            newStatus == ProductStatus.hidden
                ? l10n.productMadeInactiveSuccess
                : l10n.productMadeActiveSuccess,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.couldNotUpdateProduct),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleEditProduct() async {
    final result = await AddProductScreen.show(
      context,
      existingProduct: _currentProduct,
      productService: widget.productService,
      imageService: _effectiveImageService,
    );

    if (result == true && mounted) {
      await widget.productsProvider.refresh();
      final refreshed = widget.productsProvider.allProducts
          .where((p) => p.id == _currentProduct.id)
          .firstOrNull;
      if (refreshed != null && mounted) {
        setState(() {
          _currentProduct = refreshed;
          if (_selectedImageIndex >= _currentProduct.images.length) {
            _selectedImageIndex = 0;
          }
        });
      }
      widget.onProductUpdated?.call();
    }
  }

  void _showDeleteConfirmation(BuildContext context, AppLocalizations l10n) {
    final errorColor = Theme.of(context).colorScheme.error;
    final onErrorColor = Theme.of(context).colorScheme.onError;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteProductConfirmTitle),
        content: Text(l10n.deleteProductConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: onErrorColor,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final messenger = widget.rootMessenger ?? ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              final success = await widget.productsProvider.deleteProduct(_currentProduct.id);
              if (mounted) {
                nav.pop(); // Close details view
                messenger.hideCurrentSnackBar();
                if (success) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.productDeletedSuccess),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.productDeleteFailed),
                      backgroundColor: errorColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI Improve Photo Pipeline (Step 6D.2 Part B)
  // ---------------------------------------------------------------------------

  Future<void> _handleImprovePhoto() async {
    if (_isImprovingPhoto || _currentProduct.images.isEmpty) return;

    final imageIndex = _selectedImageIndex.clamp(0, _currentProduct.images.length - 1);
    final sourcePath = _currentProduct.images[imageIndex];
    final enhancementSvc = _effectiveEnhancementService;
    final l10n = AppLocalizations.of(context)!;
    final errorColor = Theme.of(context).colorScheme.error;
    final messenger = _scaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);

    setState(() {
      _isImprovingPhoto = true;
    });

    try {
      final result = await enhancementSvc.improvePhoto(
        productId: _currentProduct.id,
        sourceStoragePath: sourcePath,
      );

      // Pre-warm candidate signed URL
      await _getOrFetchSignedUrl(result.improvedStoragePath);

      if (!mounted) return;

      setState(() {
        _isImprovingPhoto = false;
      });

      await _showComparisonDialog(
        sourcePath: sourcePath,
        candidatePath: result.improvedStoragePath,
        enhancementSvc: enhancementSvc,
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = (e is ProductOperationException && e.message.isNotEmpty)
          ? e.message
          : l10n.photoImproveFailed;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted && _isImprovingPhoto) {
        setState(() {
          _isImprovingPhoto = false;
        });
      }
    }
  }

  Future<void> _showComparisonDialog({
    required String sourcePath,
    required String candidatePath,
    required IProductPhotoEnhancementService enhancementSvc,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (modalContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title + AI icon
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: colorScheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.photoImprovedTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Truthful disclaimer
                  Text(
                    l10n.aiImproveDisclaimer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.aiImproveHelpText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comparison Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;

                      final originalCard = _buildComparisonCard(
                        title: l10n.originalPhotoLabel,
                        storagePath: sourcePath,
                        colorScheme: colorScheme,
                        theme: theme,
                      );

                      final improvedCard = _buildComparisonCard(
                        title: l10n.improvedPhotoLabel,
                        storagePath: candidatePath,
                        colorScheme: colorScheme,
                        theme: theme,
                        isImproved: true,
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            originalCard,
                            const SizedBox(height: 12),
                            improvedCard,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: originalCard),
                          const SizedBox(width: 12),
                          Expanded(child: improvedCard),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons: Keep Original vs Use Improved Photo
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.of(modalContext).pop();
                            await enhancementSvc.discardCandidateImage(candidatePath);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: Text(l10n.keepOriginalAction),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(l10n.useImprovedAction),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () async {
                            Navigator.of(modalContext).pop();
                            await _applyImprovedPhoto(sourcePath, candidatePath);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required String storagePath,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isImproved = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isImproved ? colorScheme.primary : colorScheme.outlineVariant,
          width: isImproved ? 2.0 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            color: isImproved
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isImproved) ...[
                  Icon(Icons.auto_awesome, size: 14, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 4),
                ],
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isImproved
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1.0,
            child: () {
              final cachedUrl = _signedUrlCache[storagePath.trim()] ??
                  widget.productsProvider.signedUrlCache[storagePath.trim()];
              if (cachedUrl != null) {
                return Image.network(
                  cachedUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.broken_image_outlined, color: colorScheme.error),
                  ),
                );
              }

              return FutureBuilder<String?>(
                future: _getOrFetchSignedUrl(storagePath),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final url = snapshot.data;
                  if (url != null) {
                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.broken_image_outlined, color: colorScheme.error),
                      ),
                    );
                  }
                  return Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  );
                },
              );
            }(),
          ),
        ],
      ),
    );
  }

  Future<void> _applyImprovedPhoto(String sourcePath, String candidatePath) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = _scaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);

    // Replace source path with candidate path
    final updatedImages = _currentProduct.images
        .map((p) => p == sourcePath ? candidatePath : p)
        .toList();

    try {
      if (widget.productService != null) {
        final updated = await widget.productService!.updateProductImages(
          productId: _currentProduct.id,
          imagePaths: updatedImages,
        );
        _currentProduct = updated;
      } else {
        _currentProduct = _currentProduct.copyWith(images: updatedImages);
      }

      widget.productsProvider.upsertProduct(_currentProduct);
      widget.onProductUpdated?.call();

      if (mounted) {
        setState(() {});
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.photoImproveSuccessMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.couldNotUpdateProduct),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build Methods
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isPhone = MediaQuery.sizeOf(context).width < 640;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          top: widget.isBottomSheet,
          bottom: true,
          child: Column(
            children: [
              // Top Drag Handle (Mobile bottom sheet only)
              if (widget.isBottomSheet) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // App Bar / Top Navigation
              _buildTopBar(context, l10n, colorScheme, theme),
              const Divider(height: 1),

              // Scrollable Content
              Expanded(
                child: isPhone
                    ? _buildPhoneLayout(context, l10n, colorScheme, theme)
                    : _buildDesktopLayout(context, l10n, colorScheme, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Category Chip
          if (_currentProduct.category.trim().isNotEmpty) ...[
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentProduct.category,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Status Badge
          _buildStatusBadge(context, _currentProduct.status, l10n, colorScheme),

          const Spacer(),

          // Overflow Menu (Delete Product)
          PopupMenuButton<String>(
            key: ValueKey('details_overflow_${_currentProduct.id}'),
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.deleteProductTitle,
            onSelected: (val) {
              if (val == 'delete') {
                _showDeleteConfirmation(context, l10n);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                key: ValueKey('delete_product_${_currentProduct.id}'),
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.deleteProductAction,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Close Button
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final hasImages = _currentProduct.images.isNotEmpty;
    final selectedPath = hasImages
        ? _currentProduct.images[_selectedImageIndex.clamp(0, _currentProduct.images.length - 1)]
        : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. MAIN IMAGE
          _buildMainImageViewer(colorScheme, selectedPath, height: 260),
          const SizedBox(height: 12),

          // 2. THUMBNAILS (if multiple)
          if (_currentProduct.images.length > 1) ...[
            _buildThumbnailRow(colorScheme),
            const SizedBox(height: 12),
          ],

          // 3. ✨ IMPROVE PHOTO (if image exists)
          if (hasImages) ...[
            _buildImprovePhotoButton(l10n, colorScheme),
            const SizedBox(height: 16),
          ],

          // 4. PRODUCT INFO
          _buildInfoSection(l10n, colorScheme, theme),
          const SizedBox(height: 24),

          // 5. MANAGEMENT ACTIONS (Edit + Switch)
          _buildManagementSection(l10n, colorScheme, theme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final hasImages = _currentProduct.images.isNotEmpty;
    final selectedPath = hasImages
        ? _currentProduct.images[_selectedImageIndex.clamp(0, _currentProduct.images.length - 1)]
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT COLUMN: Photos & AI Action
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMainImageViewer(colorScheme, selectedPath, height: 360),
                const SizedBox(height: 12),
                if (_currentProduct.images.length > 1) ...[
                  _buildThumbnailRow(colorScheme),
                  const SizedBox(height: 12),
                ],
                if (hasImages) ...[
                  _buildImprovePhotoButton(l10n, colorScheme),
                ],
              ],
            ),
          ),
          const SizedBox(width: 24),

          // RIGHT COLUMN: Details & Actions
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoSection(l10n, colorScheme, theme),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 20),
                _buildManagementSection(l10n, colorScheme, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Component Builders
  // ---------------------------------------------------------------------------

  Widget _buildMainImageViewer(ColorScheme colorScheme, String? storagePath, {required double height}) {
    if (storagePath == null) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                _currentProduct.unit.isNotEmpty ? _currentProduct.unit : 'piece',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final cachedUrl = _signedUrlCache[storagePath];
    if (cachedUrl != null) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          cachedUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: colorScheme.error,
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<String?>(
        future: _getOrFetchSignedUrl(storagePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          }

          final url = snapshot.data;
          if (url != null) {
            return Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: colorScheme.error,
                ),
              ),
            );
          }

          return Center(
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumbnailRow(ColorScheme colorScheme) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _currentProduct.images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final isSelected = idx == _selectedImageIndex;
          final path = _currentProduct.images[idx];
          final cachedUrl = _signedUrlCache[path];

          final Widget thumbnailImage = cachedUrl != null
              ? Image.network(
                  cachedUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.broken_image_outlined, size: 18, color: colorScheme.error),
                  ),
                )
              : FutureBuilder<String?>(
                  future: _getOrFetchSignedUrl(path),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      );
                    }
                    final url = snapshot.data;
                    if (url != null) {
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(Icons.broken_image_outlined, size: 18, color: colorScheme.error),
                        ),
                      );
                    }
                    return Center(
                      child: Icon(Icons.image_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                    );
                  },
                );

          return InkWell(
            onTap: () {
              setState(() {
                _selectedImageIndex = idx;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                  width: isSelected ? 2.5 : 1.0,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: thumbnailImage,
            ),
          );
        },
      ),
    );
  }

  Widget _buildImprovePhotoButton(AppLocalizations l10n, ColorScheme colorScheme) {
    return FilledButton.tonalIcon(
      key: const ValueKey('improve_photo_button'),
      onPressed: _isImprovingPhoto ? null : _handleImprovePhoto,
      icon: _isImprovingPhoto
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome, size: 18),
      label: Text(
        _isImprovingPhoto ? l10n.improvingPhotoProgress : l10n.improvePhotoAction,
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
      ),
    );
  }

  Widget _buildInfoSection(AppLocalizations l10n, ColorScheme colorScheme, ThemeData theme) {
    final formattedPrice = formatPricePaise(_currentProduct.pricePaise);
    final hasDescription = _currentProduct.description.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          _currentProduct.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        // Price / Unit
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (formattedPrice != null) ...[
              Text(
                formattedPrice,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${_currentProduct.unit.isNotEmpty ? _currentProduct.unit : 'piece'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Text(
                l10n.priceNotSet,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Description Section
        Text(
          'Description',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasDescription ? _currentProduct.description : l10n.noDescriptionAdded,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: hasDescription ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontStyle: hasDescription ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementSection(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isDraft = _currentProduct.status == ProductStatus.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Active / Inactive Switch row (only for non-draft products)
        if (!isDraft) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _currentProduct.status == ProductStatus.active
                        ? l10n.statusActive
                        : l10n.statusInactive,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  key: ValueKey('details_toggle_visibility_${_currentProduct.id}'),
                  value: _currentProduct.status == ProductStatus.active,
                  onChanged: _isStatusBusy ? null : (bool val) => _handleToggleStatus(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Edit Product Button
        FilledButton.icon(
          key: ValueKey('details_edit_product_${_currentProduct.id}'),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(isDraft ? l10n.continueEditingAction : l10n.editProductTitle),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
          ),
          onPressed: _handleEditProduct,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    ProductStatus status,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final IconData icon;
    final String label;
    final Color bgColor;
    final Color fgColor;

    switch (status) {
      case ProductStatus.active:
        icon = Icons.check_circle_outline;
        label = l10n.statusActive;
        bgColor = colorScheme.primaryContainer;
        fgColor = colorScheme.onPrimaryContainer;
        break;
      case ProductStatus.draft:
        icon = Icons.edit_note_outlined;
        label = l10n.statusDraft;
        bgColor = colorScheme.tertiaryContainer;
        fgColor = colorScheme.onTertiaryContainer;
        break;
      case ProductStatus.hidden:
        icon = Icons.pause_circle_outline;
        label = l10n.statusInactive;
        bgColor = colorScheme.surfaceContainerHighest;
        fgColor = colorScheme.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fgColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
