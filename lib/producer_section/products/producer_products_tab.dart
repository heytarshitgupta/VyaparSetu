import 'package:flutter/material.dart';
import '../../core/localization/generated/app_localizations.dart';
import 'models/producer_product.dart';
import 'providers/producer_products_provider.dart';
import 'services/producer_product_service.dart';
import 'widgets/producer_product_card.dart';

/// The primary My Products tab inside the responsive Producer navigation shell.
///
/// Implements responsive phone (1-col), tablet (2-col), and desktop (3-col) layouts,
/// in-memory filter switching, true empty vs filtered empty states, pull-to-refresh,
/// and safe feedback on product visibility and deletion.
class ProducerProductsTab extends StatefulWidget {
  final VoidCallback? onAddProduct;
  final ProducerProductsProvider? provider;
  final IProducerProductService? service;

  const ProducerProductsTab({
    super.key,
    this.onAddProduct,
    this.provider,
    this.service,
  });

  @override
  State<ProducerProductsTab> createState() => _ProducerProductsTabState();
}

class _ProducerProductsTabState extends State<ProducerProductsTab> {
  late final ProducerProductsProvider _provider;
  final Set<String> _busyProductIds = {};

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? ProducerProductsProvider(service: widget.service);
    _provider.addListener(_onProviderChanged);

    if (_provider.isInitial) {
      _provider.loadProducts();
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    if (widget.provider == null) {
      _provider.dispose();
    }
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleToggleVisibility(ProducerProduct product) async {
    final l10n = AppLocalizations.of(context)!;
    final newStatus = product.status == ProductStatus.active
        ? ProductStatus.hidden
        : ProductStatus.active;

    setState(() {
      _busyProductIds.add(product.id);
    });

    final success = await _provider.updateProductStatus(
      productId: product.id,
      newStatus: newStatus,
    );

    if (!mounted) return;

    setState(() {
      _busyProductIds.remove(product.id);
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            newStatus == ProductStatus.hidden
                ? l10n.productHiddenSuccess
                : l10n.productActivatedSuccess,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.productActionFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDelete(ProducerProduct product) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _busyProductIds.add(product.id);
    });

    final success = await _provider.deleteProduct(product.id);

    if (!mounted) return;

    setState(() {
      _busyProductIds.remove(product.id);
    });

    final messenger = ScaffoldMessenger.of(context);
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
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isPhone = width < 640;
          final isTablet = width >= 640 && width < 1024;

          final int crossAxisCount = isPhone ? 1 : (isTablet ? 2 : 3);
          final double horizontalPadding = isPhone ? 16 : (isTablet ? 24 : 32);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: RefreshIndicator(
                onRefresh: () => _provider.refresh(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 1. HEADER SECTION
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
                        12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _buildHeader(context, l10n, colorScheme, isPhone),
                      ),
                    ),

                    // 2. FILTER BAR (Rendered if products exist overall)
                    if (_provider.isLoaded && _provider.allProducts.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 6,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildFilterBar(context, l10n, colorScheme),
                        ),
                      ),

                    // 3. CONTENT AREA
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        32,
                      ),
                      sliver: _buildContentSliver(
                        context,
                        l10n,
                        colorScheme,
                        crossAxisCount,
                        isPhone,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    bool isPhone,
  ) {
    final theme = Theme.of(context);

    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.myProducts,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.myProductsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (widget.onAddProduct != null &&
              (_provider.isLoaded && _provider.allProducts.isNotEmpty)) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onAddProduct,
                icon: const Icon(Icons.add),
                label: Text(l10n.addProduct),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Tablet & Desktop Header: Side-by-side title and Add Product action
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.myProducts,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.myProductsSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (widget.onAddProduct != null &&
            (_provider.isLoaded && _provider.allProducts.isNotEmpty))
          FilledButton.icon(
            onPressed: widget.onAddProduct,
            icon: const Icon(Icons.add),
            label: Text(l10n.addProduct),
            style: FilledButton.styleFrom(
              minimumSize: const Size(160, 48),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            label: l10n.filterAll,
            filter: ProducerProductFilter.all,
            isSelected: _provider.currentFilter == ProducerProductFilter.all,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: l10n.filterActive,
            filter: ProducerProductFilter.active,
            isSelected: _provider.currentFilter == ProducerProductFilter.active,
            colorScheme: colorScheme,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: l10n.filterDraft,
            filter: ProducerProductFilter.draft,
            isSelected: _provider.currentFilter == ProducerProductFilter.draft,
            colorScheme: colorScheme,
            icon: Icons.edit_note_outlined,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: l10n.filterHidden,
            filter: ProducerProductFilter.hidden,
            isSelected: _provider.currentFilter == ProducerProductFilter.hidden,
            colorScheme: colorScheme,
            icon: Icons.visibility_off_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required ProducerProductFilter filter,
    required bool isSelected,
    required ColorScheme colorScheme,
    IconData? icon,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _provider.setFilter(filter),
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: isSelected
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            )
          : null,
      showCheckmark: icon == null,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurfaceVariant,
      ),
      selectedColor: colorScheme.secondaryContainer,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      side: BorderSide(
        color: isSelected
            ? colorScheme.secondary
            : colorScheme.outline.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildContentSliver(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    int crossAxisCount,
    bool isPhone,
  ) {
    // 1. Loading State
    if (_provider.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.myProductsSubtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Error State
    if (_provider.hasError) {
      final isAuthError = _provider.error == ProducerProductsErrorType.notAuthenticated;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  isAuthError
                      ? l10n.notAuthenticatedMessage
                      : l10n.unableToLoadProducts,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isAuthError
                      ? l10n.notAuthenticatedMessage
                      : l10n.unableToLoadSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _provider.loadProducts(),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. True Zero-Products Empty State
    if (_provider.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.noProductsListedTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Text(
                    l10n.noProductsListedSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.onAddProduct != null) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: widget.onAddProduct,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addProduct),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(220, 52),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // 4. Filtered-Empty State (products exist overall, but none in this filter)
    final visible = _provider.visibleProducts;
    if (visible.isEmpty) {
      final String emptyTitle;
      final String emptySubtitle;
      switch (_provider.currentFilter) {
        case ProducerProductFilter.active:
          emptyTitle = l10n.noActiveProductsTitle;
          emptySubtitle = l10n.noActiveProductsSubtitle;
          break;
        case ProducerProductFilter.draft:
          emptyTitle = l10n.noDraftProductsTitle;
          emptySubtitle = l10n.noDraftProductsSubtitle;
          break;
        case ProducerProductFilter.hidden:
          emptyTitle = l10n.noHiddenProductsTitle;
          emptySubtitle = l10n.noHiddenProductsSubtitle;
          break;
        case ProducerProductFilter.all:
          emptyTitle = l10n.noProductsListedTitle;
          emptySubtitle = l10n.noProductsListedSubtitle;
          break;
      }

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list_off_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 14),
                Text(
                  emptyTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    emptySubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => _provider.setFilter(ProducerProductFilter.all),
                  child: Text(l10n.showAllProducts),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 5. Loaded Product List / Grid
    if (crossAxisCount == 1) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = visible[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ProducerProductCard(
                product: product,
                isBusy: _busyProductIds.contains(product.id),
                onToggleVisibility: () => _handleToggleVisibility(product),
                onDelete: () => _handleDelete(product),
              ),
            );
          },
          childCount: visible.length,
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = visible[index];
          return ProducerProductCard(
            product: product,
            isBusy: _busyProductIds.contains(product.id),
            onToggleVisibility: () => _handleToggleVisibility(product),
            onDelete: () => _handleDelete(product),
          );
        },
        childCount: visible.length,
      ),
    );
  }
}
