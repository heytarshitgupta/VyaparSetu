import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_localizations.dart';
import 'producer_market_intelligence.dart';

class ProducerMarketIntelligenceDashboard extends StatelessWidget {
  final List<ProducerMarketSignal>? signals;

  const ProducerMarketIntelligenceDashboard({
    super.key,
    this.signals,
  });

  static String localizeCategory(String rawCategory, AppLocalizations l10n) {
    switch (rawCategory.toLowerCase().trim()) {
      case 'agriculture':
        return l10n.categoryAgriculture;
      case 'textile':
        return l10n.categoryTextile;
      case 'food processing':
      case 'food_processing':
        return l10n.categoryFoodProcessing;
      case 'manufacturing':
        return l10n.categoryManufacturing;
      case 'handicraft':
        return l10n.categoryHandicraft;
      case 'food':
        return l10n.categoryFood;
      case 'clothing':
        return l10n.categoryClothing;
      case 'home':
        return l10n.categoryHome;
      case 'beauty':
        return l10n.categoryBeauty;
      case 'jewellery':
        return l10n.categoryJewellery;
      default:
        return rawCategory;
    }
  }

  static String getDemandLabel(MarketDemandLevel level, AppLocalizations l10n) {
    switch (level) {
      case MarketDemandLevel.high:
        return l10n.demandHigh;
      case MarketDemandLevel.medium:
        return l10n.demandMedium;
      case MarketDemandLevel.low:
        return l10n.demandLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeSignals = signals ?? ProducerMarketIntelligenceService.csvSeedSignals;

    if (activeSignals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.noMarketInsights,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading: Sample market insights
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.sampleMarketInsightsBadge,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.sampleMarketInsightsNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Responsive Signal Cards
          Column(
            children: activeSignals.map((signal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MarketSignalTile(signal: signal),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MarketSignalTile extends StatelessWidget {
  final ProducerMarketSignal signal;

  const _MarketSignalTile({required this.signal});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final demandLevel = signal.demandLevel;
    final demandLabel = ProducerMarketIntelligenceDashboard.getDemandLabel(demandLevel, l10n);
    final localizedCategory = ProducerMarketIntelligenceDashboard.localizeCategory(
      signal.category,
      l10n,
    );

    final Color badgeColor;
    final Color badgeTextColor;
    switch (demandLevel) {
      case MarketDemandLevel.high:
        badgeColor = Colors.green.withValues(alpha: 0.14);
        badgeTextColor = Colors.green.shade800;
        break;
      case MarketDemandLevel.medium:
        badgeColor = Colors.amber.withValues(alpha: 0.18);
        badgeTextColor = Colors.amber.shade900;
        break;
      case MarketDemandLevel.low:
        badgeColor = colorScheme.surfaceContainerHighest;
        badgeTextColor = colorScheme.onSurfaceVariant;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Demand Level with Wrap to prevent narrow-screen overflow
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    signal.productName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    localizedCategory,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$demandLabel • ${l10n.demandScoreOutOf(signal.marketDemandScore.round().toString())}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Location Row
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${l10n.signalDistrictLabel(signal.district)} · ${l10n.topBuyingCityLabel(signal.topCity)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Details Rows using multi-line text span to prevent overflow
          _DetailRow(
            icon: Icons.trending_up,
            label: l10n.estimatedMonthlyDemandLabel,
            value: l10n.estimatedUnitsValue(signal.monthlyUnits.toString()),
          ),
          const SizedBox(height: 5),
          _DetailRow(
            icon: Icons.currency_rupee,
            label: l10n.typicalOrderValueLabel,
            value: '₹${signal.avgOrderValue.round()}',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 14,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '$label: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
