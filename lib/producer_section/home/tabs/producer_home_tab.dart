import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../products/models/producer_product.dart';
import '../../products/providers/producer_products_provider.dart';
import '../../verification/models/business_verification_status.dart';
import '../models/producer_home_models.dart';
import '../models/producer_shell_profile.dart';
import '../providers/producer_home_dashboard_provider.dart';
import '../widgets/business_verification_banner.dart';

class ProducerHomeTab extends StatelessWidget {
  final VoidCallback onAddProduct;
  final ValueChanged<int> onNavigateToTab;
  final VoidCallback onOpenWhatBuyersWant;
  final ProducerShellProfile? profile;
  final VoidCallback? onVerifyBusiness;
  final VoidCallback? onDismissVerificationBanner;
  final bool isBannerDismissed;
  final bool? overrideEmailVerified;
  final ProducerProductsProvider? productsProvider;
  final ProducerHomeDashboardProvider? dashboardProvider;
  final Future<void> Function()? onRefresh;

  const ProducerHomeTab({
    super.key,
    required this.onAddProduct,
    required this.onNavigateToTab,
    required this.onOpenWhatBuyersWant,
    this.profile,
    this.onVerifyBusiness,
    this.onDismissVerificationBanner,
    this.isBannerDismissed = false,
    this.overrideEmailVerified,
    this.productsProvider,
    this.dashboardProvider,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fullName = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName.trim()
        : l10n.producerDefaultName;
    final businessName = profile?.businessName?.trim();
    final craftCategory = profile?.craftCategory?.trim();
    final location = [
      if (profile?.district?.trim().isNotEmpty ?? false) profile!.district!.trim(),
      if (profile?.state?.trim().isNotEmpty ?? false) profile!.state!.trim(),
    ].join(', ');

    final verificationStatus = BusinessVerificationStatus.fromProfile(
      profile: profile,
      currentUser: AuthService.instance.currentUser,
      overrideEmailVerified: overrideEmailVerified,
    );
    final showBanner = !isBannerDismissed && verificationStatus.shouldShowHomeBanner;

    final content = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. GREETING / IDENTITY AREA
                _buildIdentityArea(
                  context,
                  fullName: fullName,
                  businessName: businessName,
                  craftCategory: craftCategory,
                  location: location.isNotEmpty ? location : null,
                ),
                const SizedBox(height: 20),

                // 2. VERIFICATION BANNER
                if (showBanner) ...[
                  BusinessVerificationBanner(
                    onVerify: onVerifyBusiness ?? () {},
                    onDismiss: onDismissVerificationBanner ?? () {},
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. ADD PRODUCT HERO
                _buildPrimaryActionCard(context),
                const SizedBox(height: 24),

                // 4. MAIN SHORTCUTS
                _buildShortcutsSection(context),
                const SizedBox(height: 24),

                // 5. LIVE PRODUCT SUMMARY
                _buildProductSummarySection(context),
                const SizedBox(height: 24),

                // 6. LIVE ORDER SUMMARY (KPIs)
                _buildOrderSummarySection(context),
                const SizedBox(height: 24),

                // 7. LIVE BUYER NEEDS PREVIEW
                _buildBuyerNeedsSection(context),
                const SizedBox(height: 24),

                // 8. LIVE WHAT BUYERS WANT / MARKET DEMAND PREVIEW
                _buildMarketDemandSection(context),
              ],
            ),
          ),
        ),
      ),
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return content;
  }

  // ---------------------------------------------------------------------------
  // 1. IDENTITY AREA
  // ---------------------------------------------------------------------------

  Widget _buildIdentityArea(
    BuildContext context, {
    required String fullName,
    String? businessName,
    String? craftCategory,
    String? location,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.welcomeProducer(fullName),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.producerHomeSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                if ((businessName != null && businessName.isNotEmpty) ||
                    (craftCategory != null && craftCategory.isNotEmpty) ||
                    (location != null && location.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (businessName != null && businessName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            businessName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (craftCategory != null && craftCategory.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            craftCategory,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (location != null && location.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. PRIMARY ACTION CARD (ADD PRODUCT)
  // ---------------------------------------------------------------------------

  Widget _buildPrimaryActionCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: '${l10n.addProduct}. ${l10n.addProductActionSubtitle}',
      child: Material(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        shadowColor: colorScheme.primary.withValues(alpha: 0.28),
        child: InkWell(
          onTap: onAddProduct,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 30,
                        color: colorScheme.onPrimary,
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.addProduct,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.addProductActionSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.92),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. SHORTCUTS
  // ---------------------------------------------------------------------------

  Widget _buildShortcutsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final cards = [
          _buildShortcutCard(
            context,
            icon: Icons.inventory_2_rounded,
            badgeColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
            iconColor: colorScheme.primary,
            title: l10n.myProducts,
            subtitle: l10n.myProductsShortcutSubtitle,
            onTap: () => onNavigateToTab(1),
          ),
          _buildShortcutCard(
            context,
            icon: Icons.handshake_rounded,
            badgeColor: colorScheme.secondaryContainer.withValues(alpha: 0.6),
            iconColor: colorScheme.secondary,
            title: l10n.buyerNeeds,
            subtitle: l10n.buyerNeedsShortcutSubtitle,
            onTap: () => onNavigateToTab(2),
          ),
          _buildShortcutCard(
            context,
            icon: Icons.lightbulb_rounded,
            badgeColor: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
            iconColor: colorScheme.tertiary,
            title: l10n.whatBuyersWant,
            subtitle: l10n.whatBuyersWantShortcutSubtitle,
            onTap: onOpenWhatBuyersWant,
          ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 14),
              Expanded(child: cards[1]),
              const SizedBox(width: 14),
              Expanded(child: cards[2]),
            ],
          );
        }

        return Column(
          children: [
            cards[0],
            const SizedBox(height: 12),
            cards[1],
            const SizedBox(height: 12),
            cards[2],
          ],
        );
      },
    );
  }

  Widget _buildShortcutCard(
    BuildContext context, {
    required IconData icon,
    required Color badgeColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. LIVE PRODUCT SUMMARY
  // ---------------------------------------------------------------------------

  Widget _buildProductSummarySection(BuildContext context) {
    final provider = productsProvider;
    if (provider == null) {
      return _buildEmptyProductsCard(context);
    }

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final products = provider.allProducts;
        if (products.isEmpty) {
          return _buildEmptyProductsCard(context);
        }

        final activeCount = products.where((p) => p.status == ProductStatus.active).length;
        final previewProducts = products.take(2).toList();

        return _buildLiveProductsCard(context, activeCount, previewProducts);
      },
    );
  }

  Widget _buildLiveProductsCard(
    BuildContext context,
    int activeCount,
    List<ProducerProduct> previewProducts,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.yourProductsTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.activeProductsBadge(activeCount),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => onNavigateToTab(1),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l10n.viewAllAction),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...previewProducts.map((p) => _buildProductPreviewRow(context, p)),
        ],
      ),
    );
  }

  Widget _buildProductPreviewRow(BuildContext context, ProducerProduct product) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => onNavigateToTab(1),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.priceDecimalString != null
                        ? '₹${product.priceDecimalString} / ${product.unit}'
                        : l10n.priceNotSet,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(context, product.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, ProductStatus status) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case ProductStatus.active:
        bg = colorScheme.primaryContainer;
        fg = colorScheme.onPrimaryContainer;
        label = l10n.statusActive;
        break;
      case ProductStatus.draft:
        bg = colorScheme.surfaceContainerHighest;
        fg = colorScheme.onSurfaceVariant;
        label = l10n.statusDraft;
        break;
      case ProductStatus.hidden:
        bg = colorScheme.outlineVariant.withValues(alpha: 0.4);
        fg = colorScheme.onSurfaceVariant;
        label = l10n.statusHidden;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyProductsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildStatusCard(
      context,
      icon: Icons.inventory_2_outlined,
      title: l10n.noProductsListedTitle,
      subtitle: l10n.noProductsListedSubtitle,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. LIVE ORDER SUMMARY (KPIS)
  // ---------------------------------------------------------------------------

  Widget _buildOrderSummarySection(BuildContext context) {
    final provider = dashboardProvider;
    if (provider == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (provider.isLoadingOrders && provider.ordersSummary == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(l10n.loadingDashboard, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          );
        }

        if (provider.hasOrdersError && provider.ordersSummary == null) {
          return _buildStatusCard(
            context,
            icon: Icons.info_outline_rounded,
            title: l10n.ordersAndSalesTitle,
            subtitle: l10n.dashboardUnavailable,
          );
        }

        final summary = provider.ordersSummary ?? const ProducerOrdersSummary.empty();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ordersAndSalesTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.ordersSummarySubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 500;
                  final kpi1 = _buildKpiTile(
                    context,
                    title: summary.formattedCompletedSales,
                    label: l10n.completedSalesLabel,
                    icon: Icons.currency_rupee_rounded,
                    color: colorScheme.primary,
                  );
                  final kpi2 = _buildKpiTile(
                    context,
                    title: '${summary.completedOrders}',
                    label: l10n.completedOrdersLabel,
                    icon: Icons.check_circle_outline_rounded,
                    color: colorScheme.secondary,
                  );
                  final kpi3 = _buildKpiTile(
                    context,
                    title: '${summary.pendingOrConfirmedOrders}',
                    label: l10n.pendingOrdersLabel,
                    icon: Icons.access_time_rounded,
                    color: colorScheme.tertiary,
                  );
                  final kpi4 = _buildKpiTile(
                    context,
                    title: '${summary.totalOrders}',
                    label: l10n.totalOrdersLabel,
                    icon: Icons.receipt_long_rounded,
                    color: colorScheme.onSurfaceVariant,
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: kpi1),
                        const SizedBox(width: 10),
                        Expanded(child: kpi2),
                        const SizedBox(width: 10),
                        Expanded(child: kpi3),
                        const SizedBox(width: 10),
                        Expanded(child: kpi4),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: kpi1),
                          const SizedBox(width: 10),
                          Expanded(child: kpi2),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: kpi3),
                          const SizedBox(width: 10),
                          Expanded(child: kpi4),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiTile(
    BuildContext context, {
    required String title,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. LIVE BUYER NEEDS PREVIEW
  // ---------------------------------------------------------------------------

  Widget _buildBuyerNeedsSection(BuildContext context) {
    final provider = dashboardProvider;
    if (provider == null) {
      return _buildEmptyBuyerNeedsCard(context);
    }

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (provider.isLoadingBuyerNeeds && provider.buyerNeeds.isEmpty) {
          return const SizedBox.shrink();
        }

        if (provider.hasBuyerNeedsError && provider.buyerNeeds.isEmpty) {
          return _buildStatusCard(
            context,
            icon: Icons.handshake_outlined,
            title: l10n.activeBuyerNeedsTitle,
            subtitle: l10n.dashboardUnavailable,
          );
        }

        final needs = provider.buyerNeeds;
        if (needs.isEmpty) {
          return _buildEmptyBuyerNeedsCard(context);
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.activeBuyerNeedsTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigateToTab(2),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(l10n.viewAllAction),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...needs.take(3).map((item) => _buildBuyerNeedCard(context, item)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuyerNeedCard(BuildContext context, ProducerBuyerNeedItem item) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final location = [item.district, item.state].where((s) => s.isNotEmpty).join(', ');
    final targetPriceStr = item.targetPrice != null
        ? l10n.targetPriceLabel(formatIndianRupees(item.targetPrice!))
        : null;

    final qtyStr = l10n.quantityWithUnit(
      item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1),
      item.unit,
    );

    return InkWell(
      onTap: () => onNavigateToTab(2),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.handshake_rounded,
                size: 20,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildUrgencyBadge(context, item.urgency),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        qtyStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (targetPriceStr != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• $targetPriceStr',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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

  Widget _buildUrgencyBadge(BuildContext context, String urgency) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String label;
    final Color bg;
    final Color fg;

    switch (urgency.toLowerCase()) {
      case 'high':
        label = l10n.highUrgency;
        bg = colorScheme.errorContainer.withValues(alpha: 0.6);
        fg = colorScheme.onErrorContainer;
        break;
      case 'medium':
        label = l10n.mediumUrgency;
        bg = colorScheme.primaryContainer.withValues(alpha: 0.5);
        fg = colorScheme.onPrimaryContainer;
        break;
      default:
        label = l10n.lowUrgency;
        bg = colorScheme.surfaceContainerHighest;
        fg = colorScheme.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildEmptyBuyerNeedsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildStatusCard(
      context,
      icon: Icons.handshake_outlined,
      title: l10n.buyerNeedsWaitingTitle,
      subtitle: l10n.buyerNeedsWaitingSubtitle,
    );
  }

  // ---------------------------------------------------------------------------
  // 7. LIVE MARKET DEMAND SIGNALS PREVIEW
  // ---------------------------------------------------------------------------

  Widget _buildMarketDemandSection(BuildContext context) {
    final provider = dashboardProvider;
    if (provider == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (provider.isLoadingSignals && provider.marketSignals.isEmpty) {
          return const SizedBox.shrink();
        }

        if (provider.hasSignalsError || provider.marketSignals.isEmpty) {
          return const SizedBox.shrink();
        }

        final signals = provider.marketSignals;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.marketDemandTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenWhatBuyersWant,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(l10n.viewMarketRadarAction),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...signals.map((s) => _buildMarketSignalTile(context, s)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarketSignalTile(BuildContext context, ProducerMarketSignalItem signal) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String badgeLabel;
    final Color badgeBg;
    final Color badgeFg;

    switch (signal.level) {
      case MarketDemandLevel.high:
        badgeLabel = l10n.highInterestDemand;
        badgeBg = colorScheme.primaryContainer;
        badgeFg = colorScheme.onPrimaryContainer;
        break;
      case MarketDemandLevel.growing:
        badgeLabel = l10n.growingDemand;
        badgeBg = colorScheme.secondaryContainer;
        badgeFg = colorScheme.onSecondaryContainer;
        break;
      case MarketDemandLevel.steady:
        badgeLabel = l10n.steadyDemand;
        badgeBg = colorScheme.surfaceContainerHighest;
        badgeFg = colorScheme.onSurfaceVariant;
        break;
    }

    return InkWell(
      onTap: onOpenWhatBuyersWant,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signal.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    signal.subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: badgeFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: STATUS CARD
  // ---------------------------------------------------------------------------

  Widget _buildStatusCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
