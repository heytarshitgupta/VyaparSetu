import 'package:flutter/material.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../models/producer_product.dart';

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

/// A responsive, accessible card representing an owned product in the My Products catalog.
class ProducerProductCard extends StatelessWidget {
  final ProducerProduct product;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onDelete;
  final bool isBusy;

  const ProducerProductCard({
    super.key,
    required this.product,
    this.onToggleVisibility,
    this.onDelete,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final formattedPrice = formatPricePaise(product.pricePaise);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. IMAGE AREA / PLACEHOLDER (Step 6C boundary: local material placeholder)
          Container(
            height: 140,
            width: double.infinity,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 44,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.unit.isNotEmpty ? product.unit : 'piece',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge positioned over image area
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildStatusBadge(context, product.status, l10n, colorScheme),
                ),
                // Category Chip if present
                if (product.category.trim().isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category,
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

          // 2. PRODUCT DETAILS
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  product.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Price Display
                if (formattedPrice != null)
                  Text(
                    formattedPrice,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  )
                else
                  Text(
                    l10n.priceNotSet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // 3. ACTION BAR
                Row(
                  children: [
                    // Main status toggle or draft completion guidance
                    Expanded(
                      child: _buildPrimaryAction(context, l10n, colorScheme),
                    ),
                    const SizedBox(width: 8),

                    // Delete overflow action
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.deleteAction,
                      color: colorScheme.error,
                      onPressed: isBusy ? null : () => _showDeleteConfirmation(context, l10n),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        icon = Icons.visibility_off_outlined;
        label = l10n.statusHidden;
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

  Widget _buildPrimaryAction(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    if (product.status == ProductStatus.active) {
      return OutlinedButton.icon(
        onPressed: isBusy ? null : onToggleVisibility,
        icon: isBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.visibility_off_outlined, size: 18),
        label: Text(l10n.hideAction),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          visualDensity: VisualDensity.standard,
        ),
      );
    } else if (product.status == ProductStatus.hidden) {
      return FilledButton.tonalIcon(
        onPressed: isBusy ? null : onToggleVisibility,
        icon: isBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.visibility_outlined, size: 18),
        label: Text(l10n.showAction),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          visualDensity: VisualDensity.standard,
        ),
      );
    } else {
      // Draft product: Needs completion
      return Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.draftNeedsCompletion,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteProductTitle),
        content: Text(l10n.deleteProductConfirmation),
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
              onDelete?.call();
            },
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
  }
}
