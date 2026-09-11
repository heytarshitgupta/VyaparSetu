import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../products/producer_market_intelligence_dashboard.dart';
import '../models/producer_home_models.dart';
import '../providers/producer_home_dashboard_provider.dart';
import '../services/producer_home_service.dart';

/// Live Market Intelligence screen showing real buyer demand, quantities,
/// price ranges, and regional concentration.
class WhatBuyersWantScreen extends StatefulWidget {
  final ProducerHomeDashboardProvider? dashboardProvider;
  final IProducerHomeService? homeService;
  final List<ProducerMarketSignalItem>? signals;
  final List<String>? relevantCategories;
  final String? state;
  final String? district;

  const WhatBuyersWantScreen({
    super.key,
    this.dashboardProvider,
    this.homeService,
    this.signals,
    this.relevantCategories,
    this.state,
    this.district,
  });

  @override
  State<WhatBuyersWantScreen> createState() => _WhatBuyersWantScreenState();
}

class _WhatBuyersWantScreenState extends State<WhatBuyersWantScreen> {
  late final IProducerHomeService _service;
  List<ProducerMarketSignalItem>? _localSignals;
  bool _isLoadingLocal = false;
  bool _hasLocalError = false;

  @override
  void initState() {
    super.initState();
    _service = widget.homeService ?? ProducerHomeService();

    if (widget.signals != null) {
      _localSignals = widget.signals;
    } else if (widget.dashboardProvider != null) {
      final provider = widget.dashboardProvider!;
      if (provider.marketSignals.isEmpty &&
          !provider.isLoadingSignals &&
          !provider.hasSignalsError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            provider.loadDashboard(
              relevantCategories: widget.relevantCategories,
              state: widget.state,
              district: widget.district,
            );
          }
        });
      }
    } else {
      _fetchSignalsDirectly();
    }
  }

  Future<void> _fetchSignalsDirectly() async {
    setState(() {
      _isLoadingLocal = true;
      _hasLocalError = false;
    });

    try {
      final res = await _service.fetchMarketSignals(
        relevantCategories: widget.relevantCategories,
        state: widget.state,
        district: widget.district,
      );
      if (mounted) {
        setState(() {
          _localSignals = res;
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
      await widget.dashboardProvider!.refresh(
        relevantCategories: widget.relevantCategories,
        state: widget.state,
        district: widget.district,
      );
    } else {
      await _fetchSignalsDirectly();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.whatBuyersWant),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.tryAgain,
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: SafeArea(
        child: widget.dashboardProvider != null && widget.signals == null
            ? ListenableBuilder(
                listenable: widget.dashboardProvider!,
                builder: (context, _) {
                  final provider = widget.dashboardProvider!;
                  return _buildContent(
                    context,
                    l10n: l10n,
                    theme: theme,
                    colorScheme: colorScheme,
                    isLoading: provider.isLoadingSignals,
                    hasError: provider.hasSignalsError,
                    signals: provider.marketSignals,
                  );
                },
              )
            : _buildContent(
                context,
                l10n: l10n,
                theme: theme,
                colorScheme: colorScheme,
                isLoading: _isLoadingLocal,
                hasError: _hasLocalError,
                signals: _localSignals ?? widget.signals ?? const [],
              ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required AppLocalizations l10n,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isLoading,
    required bool hasError,
    required List<ProducerMarketSignalItem> signals,
  }) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Introduction Banner
                _buildHeroBanner(theme, colorScheme, l10n),
                const SizedBox(height: 20),

                // State Views
                if (isLoading)
                  _buildLoadingState(theme, colorScheme)
                else if (hasError)
                  _buildErrorState(theme, colorScheme, l10n)
                else if (signals.isEmpty)
                  _buildEmptyState(theme, colorScheme, l10n)
                else
                  _buildSignalsList(theme, colorScheme, l10n, signals),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: colorScheme.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.whatBuyersWantLiveSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
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
            l10n.marketDemandLoadError,
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

  Widget _buildEmptyState(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.query_stats_outlined,
            size: 44,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noActiveBuyerDemand,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSignalsList(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    List<ProducerMarketSignalItem> signals,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: signals.map((signal) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: _buildSignalCard(theme, colorScheme, l10n, signal),
        );
      }).toList(),
    );
  }

  Widget _buildSignalCard(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    ProducerMarketSignalItem signal,
  ) {
    final localizedCategory = ProducerMarketIntelligenceDashboard.localizeCategory(
      signal.category,
      l10n,
    );

    // Demand badge styling
    final String demandBadgeText;
    final Color badgeBg;
    final Color badgeFg;

    switch (signal.level) {
      case MarketDemandLevel.high:
        demandBadgeText = l10n.highInterestDemand;
        badgeBg = colorScheme.primaryContainer;
        badgeFg = colorScheme.onPrimaryContainer;
        break;
      case MarketDemandLevel.growing:
        demandBadgeText = l10n.growingDemand;
        badgeBg = colorScheme.secondaryContainer;
        badgeFg = colorScheme.onSecondaryContainer;
        break;
      case MarketDemandLevel.steady:
        demandBadgeText = l10n.steadyDemand;
        badgeBg = colorScheme.surfaceContainerHighest;
        badgeFg = colorScheme.onSurfaceVariant;
        break;
    }

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
            // Top Row: Category Title & Demand Level Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        signal.title.isNotEmpty ? signal.title : localizedCategory,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (localizedCategory != signal.title)
                        Text(
                          localizedCategory,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        demandBadgeText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: badgeFg,
                        ),
                      ),
                    ),
                    if (signal.highUrgencyCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.urgentNeedsCount(signal.highUrgencyCount),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Grid of 4 Key Producer Questions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 1. How much demand is there? (Requests count)
                  _buildMetricRow(
                    icon: Icons.assignment_outlined,
                    colorScheme: colorScheme,
                    theme: theme,
                    label: l10n.activeBuyerNeedsLabel,
                    value: l10n.requestsCount(signal.activeRequestCount),
                  ),

                  // 2. Quantity Wanted (when available)
                  if (signal.totalRequestedQuantity != null &&
                      signal.representativeUnit != null) ...[
                    const Divider(height: 14, thickness: 0.5),
                    _buildMetricRow(
                      icon: Icons.inventory_2_outlined,
                      colorScheme: colorScheme,
                      theme: theme,
                      label: l10n.quantityWantedLabel,
                      value:
                          '${signal.totalRequestedQuantity!.toStringAsFixed(signal.totalRequestedQuantity! % 1 == 0 ? 0 : 1)} ${signal.representativeUnit}',
                    ),
                  ] else if (signal.activeRequestCount > 1) ...[
                    const Divider(height: 14, thickness: 0.5),
                    _buildMetricRow(
                      icon: Icons.inventory_2_outlined,
                      colorScheme: colorScheme,
                      theme: theme,
                      label: l10n.quantityWantedLabel,
                      value: l10n.multipleUnitTypes,
                    ),
                  ],

                  // 3. What price are buyers asking?
                  if (signal.minTargetPrice != null && signal.maxTargetPrice != null) ...[
                    const Divider(height: 14, thickness: 0.5),
                    _buildMetricRow(
                      icon: Icons.currency_rupee_rounded,
                      colorScheme: colorScheme,
                      theme: theme,
                      label: l10n.buyerPriceRangeLabel,
                      value: signal.minTargetPrice == signal.maxTargetPrice
                          ? '₹${signal.minTargetPrice!.toStringAsFixed(0)}'
                          : '₹${signal.minTargetPrice!.toStringAsFixed(0)} – ₹${signal.maxTargetPrice!.toStringAsFixed(0)}',
                    ),
                  ],

                  // 4. Where is demand coming from?
                  if (signal.topDistrict != null || signal.topState != null) ...[
                    const Divider(height: 14, thickness: 0.5),
                    _buildMetricRow(
                      icon: Icons.location_on_outlined,
                      colorScheme: colorScheme,
                      theme: theme,
                      label: l10n.whereBuyersAreLabel,
                      value: [signal.topDistrict, signal.topState]
                          .where((s) => s != null && s.isNotEmpty)
                          .join(', '),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required ColorScheme colorScheme,
    required ThemeData theme,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
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
