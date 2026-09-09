import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../models/producer_product.dart';
import '../services/producer_product_image_service.dart';

/// Presentation helper to format integer paise to INR string without floating-point math.
String? formatPricePaise(int? pricePaise) {
  if (pricePaise == null) return null;
  final isNegative = pricePaise < 0;
  final absPaise = pricePaise.abs();
  final rupees = absPaise ~/ 100;
  final paise = absPaise % 100;

  final rupeeStr = rupees.toString();
  String groupedRupees;
  if (rupeeStr.length <= 3) {
    groupedRupees = rupeeStr;
  } else {
    final lastThree = rupeeStr.substring(rupeeStr.length - 3);
    final remaining = rupeeStr.substring(0, rupeeStr.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }
    groupedRupees = '${buffer.toString()},$lastThree';
  }

  final paiseStr = paise.toString().padLeft(2, '0');
  final prefix = isNegative ? '-₹' : '₹';
  return '$prefix$groupedRupees.$paiseStr';
}

/// A compact marketplace-management card representing an owned product in My Products.
///
/// Redesigned in Step 6D.2:
/// - Compact, content-driven card height
/// - Whole card clickable/tappable to open Product Details
/// - Desktop hover transition (subtle elevation and border highlight)
/// - Private Storage image display via transient signed URLs
/// - Adaptive Switch for Active/Inactive status toggle
/// - Compact circular Edit icon button (Icons.edit_outlined)
/// - Compact overflow menu (Icons.more_vert) for Delete
/// - Draft state with Draft badge and Continue Editing button
class ProducerProductCard extends StatefulWidget {
  final ProducerProduct product;
  final VoidCallback? onOpenDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onDelete;
  final bool isBusy;
  final IProducerProductImageService? imageService;
  final Map<String, String>? signedUrlCache;

  const ProducerProductCard({
    super.key,
    required this.product,
    this.onOpenDetails,
    this.onEdit,
    this.onToggleVisibility,
    this.onDelete,
    this.isBusy = false,
    this.imageService,
    this.signedUrlCache,
  });

  @override
  State<ProducerProductCard> createState() => _ProducerProductCardState();
}

class _ProducerProductCardState extends State<ProducerProductCard> {
  /// Stable Future for signed URL generation.
  Future<String>? _signedUrlFuture;
  String? _currentCoverPath;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _refreshSignedUrlFutureIfNeeded();
  }

  @override
  void didUpdateWidget(ProducerProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newCoverPath =
        widget.product.images.isNotEmpty ? widget.product.images.first : null;
    if (newCoverPath != _currentCoverPath ||
        oldWidget.imageService != widget.imageService) {
      _refreshSignedUrlFutureIfNeeded();
    }
  }

  void _refreshSignedUrlFutureIfNeeded() {
    if (widget.product.images.isEmpty) {
      _signedUrlFuture = null;
      _currentCoverPath = null;
      return;
    }

    final coverPath = widget.product.images.first;
    _currentCoverPath = coverPath;

    // If cache already has the signed URL, no Future needed.
    if (widget.signedUrlCache?[coverPath] != null) {
      _signedUrlFuture = null;
      return;
    }

    final imgSvc = widget.imageService;
    if (imgSvc == null) {
      _signedUrlFuture = null;
      return;
    }

    _signedUrlFuture =
        imgSvc.createSignedImageUrl(storagePath: coverPath).then((url) {
      if (kDebugMode) {
        developer.log(
          '[MY PRODUCTS] signed-url-ok for product=${widget.product.id}',
          name: 'ProducerProductCard',
        );
      }
      return url;
    }).catchError((Object e) {
      if (kDebugMode) {
        developer.log(
          '[MY PRODUCTS] signed-url-FAILED for product=${widget.product.id}. error=$e',
          name: 'ProducerProductCard',
        );
      }
      throw e;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final formattedPrice = formatPricePaise(widget.product.pricePaise);
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    final imageHeight = isPhone ? 130.0 : 145.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isHovered
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: _isHovered ? 1.5 : 1.0,
            ),
          ),
          child: InkWell(
            onTap: widget.onOpenDetails,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. COMPACT COVER IMAGE AREA
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildProductImage(context, colorScheme),

                      // Status Badge positioned over top-right
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildStatusBadge(
                          context,
                          widget.product.status,
                          l10n,
                          colorScheme,
                        ),
                      ),

                      // Category Chip positioned over top-left
                      if (widget.product.category.trim().isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.product.category,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 2. COMPACT PRODUCT INFORMATION & ACTIONS
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product Name (max 2 lines)
                      Text(
                        widget.product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Price / Unit
                      if (formattedPrice != null)
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              formattedPrice,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ ${widget.product.unit.isNotEmpty ? widget.product.unit : 'piece'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          l10n.priceNotSet,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 6),

                      // 3. COMPACT ACTION BAR (Switch + Edit + Overflow)
                      _buildCompactActionBar(context, l10n, colorScheme, theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context, ColorScheme colorScheme) {
    if (widget.product.images.isEmpty) {
      return Container(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 38,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.unit.isNotEmpty ? widget.product.unit : 'piece',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final coverPath = widget.product.images.first;
    final cachedUrl = widget.signedUrlCache?[coverPath];

    if (cachedUrl != null) {
      return Image.network(
        cachedUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallback(colorScheme, isError: true),
      );
    }

    final future = _signedUrlFuture;
    if (future == null) {
      return _buildFallback(colorScheme);
    }

    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildFallback(colorScheme, isError: true);
        }

        final signedUrl = snapshot.data!;
        return Image.network(
          signedUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallback(colorScheme, isError: true),
        );
      },
    );
  }

  Widget _buildFallback(ColorScheme colorScheme, {bool isError = false}) {
    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Center(
        child: Icon(
          isError ? Icons.broken_image_outlined : Icons.image_outlined,
          size: 36,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: fgColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionBar(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isDraft = widget.product.status == ProductStatus.draft;

    // Overflow menu for Delete Product
    final overflowMenu = PopupMenuButton<String>(
      key: ValueKey('overflow_product_${widget.product.id}'),
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: l10n.deleteProductTitle,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onSelected: (value) {
        if (value == 'delete') {
          _showDeleteConfirmation(context, l10n);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          key: ValueKey('delete_product_${widget.product.id}'),
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
              const SizedBox(width: 8),
              Text(
                l10n.deleteProductAction,
                style: TextStyle(color: colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );

    if (isDraft) {
      // Draft product: No switch. Draft badge, Continue Editing, overflow with Delete.
      return Row(
        children: [
          Expanded(
            child: TextButton.icon(
              key: ValueKey('edit_product_${widget.product.id}'),
              onPressed: widget.isBusy ? null : widget.onEdit,
              icon: const Icon(Icons.edit_note, size: 18),
              label: Text(
                l10n.continueEditingAction,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 40),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          overflowMenu,
        ],
      );
    }

    // Active / Inactive product: Active switch on left, compact edit + overflow on right.
    final isProductActive = widget.product.status == ProductStatus.active;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Active/Inactive Switch + Label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 32,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Switch.adaptive(
                  key: ValueKey('toggle_visibility_${widget.product.id}'),
                  value: isProductActive,
                  onChanged: widget.isBusy
                      ? null
                      : (_) => widget.onToggleVisibility?.call(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isProductActive ? l10n.statusActive : l10n.statusInactive,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isProductActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        // Compact Edit & Overflow Menu
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: ValueKey('edit_product_${widget.product.id}'),
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: l10n.editProductTitle,
              onPressed: widget.isBusy ? null : widget.onEdit,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            overflowMenu,
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppLocalizations l10n) {
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
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onDelete?.call();
            },
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
  }
}
