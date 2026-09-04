import 'package:flutter/material.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../models/producer_shell_profile.dart';

class ProducerHomeTab extends StatelessWidget {
  final VoidCallback onAddProduct;
  final ValueChanged<int> onNavigateToTab;
  final VoidCallback onOpenWhatBuyersWant;
  final ProducerShellProfile? profile;

  const ProducerHomeTab({
    super.key,
    required this.onAddProduct,
    required this.onNavigateToTab,
    required this.onOpenWhatBuyersWant,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fullName = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName.trim()
        : l10n.producerDefaultName;
    final businessName = profile?.businessName?.trim();
    final craftCategory = profile?.craftCategory?.trim();

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ----------------------------------------------------------------
                // 1. GREETING / IDENTITY AREA (Warm, artisan-friendly, not oversized)
                // ----------------------------------------------------------------
                _buildIdentityArea(
                  context,
                  fullName: fullName,
                  businessName: businessName,
                  craftCategory: craftCategory,
                ),
                const SizedBox(height: 20),

                // ----------------------------------------------------------------
                // 2. ADD PRODUCT HERO (Most dominant action on the screen)
                // ----------------------------------------------------------------
                _buildPrimaryActionCard(context),
                const SizedBox(height: 24),

                // ----------------------------------------------------------------
                // 3. MAIN USEFUL SHORTCUTS (My Products, Buyer Needs, What Buyers Want)
                // ----------------------------------------------------------------
                _buildShortcutsSection(context),
                const SizedBox(height: 24),

                // ----------------------------------------------------------------
                // 4. SUPPORTING INFORMATION (Clean, truthful status states, no filler)
                // ----------------------------------------------------------------
                _buildSupportingStatusSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityArea(
    BuildContext context, {
    required String fullName,
    String? businessName,
    String? craftCategory,
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
          // Warm artisan/storefront badge
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
                    (craftCategory != null && craftCategory.isNotEmpty)) ...[
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
                // Package + Add visual icon combo for low-literacy usability
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

  Widget _buildSupportingStatusSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final item1 = _buildStatusCard(
          context,
          icon: Icons.inventory_2_outlined,
          title: l10n.noProductsListedTitle,
          subtitle: l10n.noProductsListedSubtitle,
        );

        final item2 = _buildStatusCard(
          context,
          icon: Icons.handshake_outlined,
          title: l10n.buyerNeedsWaitingTitle,
          subtitle: l10n.buyerNeedsWaitingSubtitle,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: item1),
              const SizedBox(width: 14),
              Expanded(child: item2),
            ],
          );
        }

        return Column(
          children: [
            item1,
            const SizedBox(height: 12),
            item2,
          ],
        );
      },
    );
  }

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

