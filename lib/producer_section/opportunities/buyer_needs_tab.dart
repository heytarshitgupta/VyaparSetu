import 'package:flutter/material.dart';

import '../../core/localization/generated/app_localizations.dart';
import '../home/models/producer_home_models.dart';
import '../home/models/producer_shell_profile.dart';
import '../home/providers/producer_home_dashboard_provider.dart';
import '../home/services/producer_home_service.dart';

/// Available feed filters for active buyer needs.
enum BuyerNeedsFilter {
  all,
  forYou,
  nearby,
  urgent,
}

/// Live Buyer Needs screen showing real active buyer requirements,
/// quantities wanted, target prices, and locations.
class BuyerNeedsTab extends StatefulWidget {
  final ProducerHomeDashboardProvider? dashboardProvider;
  final IProducerHomeService? homeService;
  final ProducerShellProfile? profile;
  final List<ProducerBuyerNeedItem>? buyerNeeds;

  const BuyerNeedsTab({
    super.key,
    this.dashboardProvider,
    this.homeService,
    this.profile,
    this.buyerNeeds,
  });

  @override
  State<BuyerNeedsTab> createState() => _BuyerNeedsTabState();
}

class _BuyerNeedsTabState extends State<BuyerNeedsTab> {
  late final IProducerHomeService _service;
  final TextEditingController _searchController = TextEditingController();

  List<ProducerBuyerNeedItem>? _localNeeds;
  bool _isLoadingLocal = false;
  bool _hasLocalError = false;

  BuyerNeedsFilter _selectedFilter = BuyerNeedsFilter.all;
  String _searchQuery = '';

  static const Map<String, List<String>> _craftCategoryExpansions = {
    'agriculture': ['food', 'grains', 'spices', 'produce'],
    'clothing': ['textiles', 'apparel', 'fabric', 'home'],
    'handicraft': ['crafts', 'home', 'decor'],
  };

  @override
  void initState() {
    super.initState();
    _service = widget.homeService ?? ProducerHomeService();

    if (widget.buyerNeeds != null) {
      _localNeeds = widget.buyerNeeds;
    } else if (widget.dashboardProvider != null) {
      final provider = widget.dashboardProvider!;
      if (provider.buyerNeeds.isEmpty &&
          !provider.isLoadingBuyerNeeds &&
          !provider.hasBuyerNeedsError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final craftCat = widget.profile?.craftCategory;
            provider.loadDashboard(
              relevantCategories: (craftCat != null && craftCat.isNotEmpty) ? [craftCat] : null,
              state: widget.profile?.state,
              district: widget.profile?.district,
            );
          }
        });
      }
    } else {
      _fetchNeedsDirectly();
    }
  }

  @override
  void didUpdateWidget(covariant BuyerNeedsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.buyerNeeds != oldWidget.buyerNeeds) {
      setState(() {
        _localNeeds = widget.buyerNeeds;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNeedsDirectly() async {
    setState(() {
      _isLoadingLocal = true;
      _hasLocalError = false;
    });

    try {
      final craftCat = widget.profile?.craftCategory;
      final res = await _service.fetchActiveBuyerNeeds(
        relevantCategories: (craftCat != null && craftCat.isNotEmpty) ? [craftCat] : null,
        state: widget.profile?.state,
        district: widget.profile?.district,
      );
      if (mounted) {
        setState(() {
          _localNeeds = res;
          _isLoadingLocal = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasLocalError = true;
          _isLoadingLocal = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (widget.dashboardProvider != null) {
      final craftCat = widget.profile?.craftCategory;
      await widget.dashboardProvider!.refresh(
        relevantCategories: (craftCat != null && craftCat.isNotEmpty) ? [craftCat] : null,
        state: widget.profile?.state,
        district: widget.profile?.district,
      );
    } else {
      await _fetchNeedsDirectly();
    }
  }

  String _normalize(String input) {
    final cleaned = input
        .toLowerCase()
        .replaceAll('&', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    if (cleaned == 'handicrafts') return 'handicraft';
    if (cleaned == 'clothing textiles' ||
        cleaned == 'clothing and textiles' ||
        cleaned == 'textiles' ||
        cleaned == 'apparel') {
      return 'clothing';
    }
    if (cleaned == 'agriculture products' || cleaned == 'agriculture and food') {
      return 'agriculture';
    }
    return cleaned;
  }

  Set<String> _getProducerCategoryExpansion() {
    final craft = widget.profile?.craftCategory;
    if (craft == null || craft.trim().isEmpty) return const {};
    final norm = _normalize(craft);
    final set = <String>{norm};
    if (_craftCategoryExpansions.containsKey(norm)) {
      set.addAll(_craftCategoryExpansions[norm]!);
    }
    return set;
  }

  List<ProducerBuyerNeedItem> _filterAndSearchList(List<ProducerBuyerNeedItem> items) {
    var result = items;

    // 1. Search Query Filter (Case-insensitive over product name, category, district, state)
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((item) {
        final prod = item.productName.toLowerCase();
        final cat = item.category.toLowerCase();
        final dist = item.district.toLowerCase();
        final st = item.state.toLowerCase();
        return prod.contains(query) ||
            cat.contains(query) ||
            dist.contains(query) ||
            st.contains(query);
      }).toList();
    }

    // 2. Primary Filter
    switch (_selectedFilter) {
      case BuyerNeedsFilter.all:
        return result;

      case BuyerNeedsFilter.forYou:
        final producerCats = _getProducerCategoryExpansion();
        if (producerCats.isEmpty) return result;
        return result.where((item) {
          final itemCat = _normalize(item.category);
          if (producerCats.contains(itemCat)) return true;
          for (final pCat in producerCats) {
            if (itemCat.contains(pCat) || pCat.contains(itemCat)) return true;
          }
          return false;
        }).toList();

      case BuyerNeedsFilter.nearby:
        final producerDistrict = widget.profile?.district?.toLowerCase().trim();
        final producerState = widget.profile?.state?.toLowerCase().trim();

        if (producerDistrict != null && producerDistrict.isNotEmpty) {
          final districtMatches = result.where((item) {
            return item.district.toLowerCase().trim() == producerDistrict;
          }).toList();
          if (districtMatches.isNotEmpty) {
            return districtMatches;
          }
        }

        if (producerState != null && producerState.isNotEmpty) {
          return result.where((item) {
            return item.state.toLowerCase().trim() == producerState;
          }).toList();
        }
        return result;

      case BuyerNeedsFilter.urgent:
        return result.where((item) => item.urgency.toLowerCase() == 'high').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.dashboardProvider != null && widget.buyerNeeds == null) {
      return ListenableBuilder(
        listenable: widget.dashboardProvider!,
        builder: (context, _) {
          final provider = widget.dashboardProvider!;
          return _buildScaffoldContent(
            context,
            l10n: l10n,
            theme: theme,
            colorScheme: colorScheme,
            isLoading: provider.isLoadingBuyerNeeds,
            hasError: provider.hasBuyerNeedsError,
            rawItems: provider.buyerNeeds,
          );
        },
      );
    }

    return _buildScaffoldContent(
      context,
      l10n: l10n,
      theme: theme,
      colorScheme: colorScheme,
      isLoading: _isLoadingLocal,
      hasError: _hasLocalError,
      rawItems: _localNeeds ?? widget.buyerNeeds ?? const [],
    );
  }

  Widget _buildScaffoldContent(
    BuildContext context, {
    required AppLocalizations l10n,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isLoading,
    required bool hasError,
    required List<ProducerBuyerNeedItem> rawItems,
  }) {
    final filteredItems = _filterAndSearchList(rawItems);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Header
                  _buildHeader(theme, colorScheme, l10n),
                  const SizedBox(height: 16),

                  // Search Bar
                  _buildSearchBar(theme, colorScheme, l10n),
                  const SizedBox(height: 12),

                  // Filter Chips
                  _buildFilterChips(theme, colorScheme, l10n),
                  const SizedBox(height: 16),

                  // Main State View
                  if (isLoading)
                    _buildLoadingState(theme, colorScheme)
                  else if (hasError)
                    _buildErrorState(theme, colorScheme, l10n)
                  else if (rawItems.isEmpty)
                    _buildEmptyRawState(theme, colorScheme, l10n)
                  else if (_searchQuery.trim().isNotEmpty && filteredItems.isEmpty)
                    _buildEmptySearchState(theme, colorScheme, l10n)
                  else if (filteredItems.isEmpty)
                    _buildEmptyFilterState(theme, colorScheme, l10n)
                  else
                    _buildFeedList(theme, colorScheme, l10n, filteredItems),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.6),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.handshake_rounded,
              color: colorScheme.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.buyerNeeds,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.buyerNeedsSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return TextField(
      controller: _searchController,
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      decoration: InputDecoration(
        hintText: l10n.searchBuyerNeedsHint,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterChips(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: l10n.filterAll,
            filter: BuyerNeedsFilter.all,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: l10n.filterForYou,
            filter: BuyerNeedsFilter.forYou,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: l10n.filterNearby,
            filter: BuyerNeedsFilter.nearby,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: l10n.filterUrgent,
            filter: BuyerNeedsFilter.urgent,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required BuyerNeedsFilter filter,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2.5),
    );
  }

  Widget _buildErrorState(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.buyerNeedsLoadError,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRawState(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return _buildEmptyContainer(
      icon: Icons.inbox_outlined,
      message: l10n.noActiveBuyerNeeds,
      theme: theme,
      colorScheme: colorScheme,
    );
  }

  Widget _buildEmptySearchState(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return _buildEmptyContainer(
      icon: Icons.search_off_rounded,
      message: l10n.noBuyerNeedsMatchSearch,
      theme: theme,
      colorScheme: colorScheme,
    );
  }

  Widget _buildEmptyFilterState(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return _buildEmptyContainer(
      icon: Icons.filter_alt_off_outlined,
      message: l10n.noBuyerNeedsMatchFilter,
      theme: theme,
      colorScheme: colorScheme,
    );
  }

  Widget _buildEmptyContainer({
    required IconData icon,
    required String message,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    List<ProducerBuyerNeedItem> items,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildOpportunityCard(
          context,
          theme: theme,
          colorScheme: colorScheme,
          l10n: l10n,
          item: items[index],
        );
      },
    );
  }

  Widget _buildOpportunityCard(
    BuildContext context, {
    required ThemeData theme,
    required ColorScheme colorScheme,
    required AppLocalizations l10n,
    required ProducerBuyerNeedItem item,
  }) {
    final isUrgent = item.urgency.toLowerCase() == 'high';
    final locationText = [item.district, item.state]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Product Name & Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.urgentBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Metrics Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Quantity Wanted
                  _buildDetailRow(
                    icon: Icons.inventory_2_outlined,
                    label: l10n.buyerWantsLabel,
                    value:
                        '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit}',
                    theme: theme,
                    colorScheme: colorScheme,
                  ),

                  // Target Price (only if positive & present)
                  if (item.targetPrice != null && item.targetPrice! > 0) ...[
                    const Divider(height: 14, thickness: 0.5),
                    _buildDetailRow(
                      icon: Icons.currency_rupee_rounded,
                      label: l10n.buyerTargetPriceLabel,
                      value: '₹${item.targetPrice!.toStringAsFixed(0)} / ${item.unit}',
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                  ],

                  // Location
                  if (locationText.isNotEmpty) ...[
                    const Divider(height: 14, thickness: 0.5),
                    _buildDetailRow(
                      icon: Icons.location_on_outlined,
                      label: l10n.whereBuyersAreLabel,
                      value: locationText,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                  ],
                ],
              ),
            ),

            // Optional Buyer Notes
            if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.notes!.trim(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
