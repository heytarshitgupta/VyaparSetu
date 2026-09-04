import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../auth/services/producer_auth_service.dart';
import '../opportunities/buyer_needs_tab.dart';
import '../products/providers/producer_products_provider.dart';
import '../products/screens/add_product_screen.dart';
import '../products/services/producer_product_service.dart';
import '../products/producer_products_tab.dart';
import '../profile/producer_profile_tab.dart';
import 'models/producer_shell_profile.dart';
import 'tabs/producer_home_tab.dart';
import 'tabs/what_buyers_want_placeholder_screen.dart';

class ProducerMainScreen extends StatefulWidget {
  final int initialIndex;
  final ProducerShellProfile? initialProfile;
  final Future<ProducerShellProfile?> Function()? profileLoader;
  final ProducerProductsProvider? productsProvider;
  final IProducerProductService? productService;

  const ProducerMainScreen({
    super.key,
    this.initialIndex = 0,
    this.initialProfile,
    this.profileLoader,
    this.productsProvider,
    this.productService,
  });

  @override
  State<ProducerMainScreen> createState() => _ProducerMainScreenState();
}

class _ProducerMainScreenState extends State<ProducerMainScreen> {
  late int _currentIndex;
  ProducerShellProfile? _profile;
  late final ProducerProductsProvider _productsProvider;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _profile = widget.initialProfile;
    _productsProvider = widget.productsProvider ??
        ProducerProductsProvider(service: widget.productService);
    if (_profile == null) {
      _loadProfileOnce();
    }
  }

  @override
  void dispose() {
    if (widget.productsProvider == null) {
      _productsProvider.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfileOnce() async {
    try {
      final loader = widget.profileLoader ?? _defaultProfileLoader;
      final loaded = await loader();
      if (mounted && loaded != null) {
        setState(() {
          _profile = loaded;
        });
      }
    } catch (_) {
      // Safe fallback on network or offline failure:
      // continues with non-blocking localized fallback without crashing.
    }
  }

  static Future<ProducerShellProfile?> _defaultProfileLoader() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return null;
      final profile = await ProducerAuthService.instance.fetchProfile();
      final producerProfile = await ProducerAuthService.instance.fetchProducerProfile();
      final fullName = (profile?['full_name'] as String?)?.trim();
      final metaName = (user.userMetadata?['full_name'] as String?)?.trim();

      return ProducerShellProfile(
        fullName: (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (metaName ?? ''),
        email: user.email ?? (profile?['email'] as String?) ?? '',
        businessName: (producerProfile?['business_name'] as String?)?.trim(),
        craftCategory: (producerProfile?['craft_category'] as String?)?.trim(),
      );
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // VOICE-READY NAVIGATION & ACTION METHODS
  // Future voice intent handlers will call these exact methods.
  // --------------------------------------------------------------------------
  void selectDestination(int index) {
    if (index >= 0 && index < 4 && _currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> openAddProduct() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddProductScreen(
          productService: widget.productService,
        ),
      ),
    );

    if (result == true) {
      _productsProvider.loadProducts();
    }
  }

  void openWhatBuyersWant() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WhatBuyersWantPlaceholderScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tabs = <Widget>[
      ProducerHomeTab(
        profile: _profile,
        onAddProduct: openAddProduct,
        onNavigateToTab: selectDestination,
        onOpenWhatBuyersWant: openWhatBuyersWant,
      ),
      ProducerProductsTab(
        provider: _productsProvider,
        service: widget.productService,
        onAddProduct: openAddProduct,
      ),
      const BuyerNeedsTab(),
      ProducerProfileTab(
        profile: _profile,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // --------------------------------------------------------------------
        // 1. PHONE LAYOUT (< 640px): Bottom NavigationBar
        // --------------------------------------------------------------------
        if (width < 640) {
          return Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: tabs,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: selectDestination,
              elevation: 3,
              backgroundColor: colorScheme.surface,
              indicatorColor: colorScheme.primaryContainer,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: colorScheme.onPrimaryContainer),
                  label: l10n.home,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2, color: colorScheme.onPrimaryContainer),
                  label: l10n.myProducts,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.handshake_outlined),
                  selectedIcon: Icon(Icons.handshake, color: colorScheme.onPrimaryContainer),
                  label: l10n.buyerNeeds,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
                  label: l10n.myProfile,
                ),
              ],
            ),
          );
        }

        // --------------------------------------------------------------------
        // 2. TABLET LAYOUT (640px - 1024px): NavigationRail
        // --------------------------------------------------------------------
        if (width <= 1024) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: selectDestination,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: colorScheme.surface,
                  indicatorColor: colorScheme.primaryContainer,
                  minWidth: 72,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Semantics(
                      button: true,
                      label: l10n.addProduct,
                      child: InkWell(
                        onTap: openAddProduct,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle,
                                color: colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.addProduct,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home, color: colorScheme.onPrimaryContainer),
                      label: Text(l10n.home),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2, color: colorScheme.onPrimaryContainer),
                      label: Text(l10n.myProducts),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.handshake_outlined),
                      selectedIcon: Icon(Icons.handshake, color: colorScheme.onPrimaryContainer),
                      label: Text(l10n.buyerNeeds),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
                      label: Text(l10n.myProfile),
                    ),
                  ],
                ),
                VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: tabs,
                  ),
                ),
              ],
            ),
          );
        }

        // --------------------------------------------------------------------
        // 3. DESKTOP LAYOUT (> 1024px): Expanded Left Navigation Sidebar
        // --------------------------------------------------------------------
        return Scaffold(
          body: Row(
            children: [
              _buildDesktopSidebar(context, l10n: l10n),
              VerticalDivider(
                thickness: 1,
                width: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: IndexedStack(
                      index: _currentIndex,
                      children: tabs,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context, {
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 250,
      color: colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand / App Name Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.storefront,
                        color: colorScheme.onPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.appTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Prominent Add Product Hero Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FilledButton.icon(
                  onPressed: openAddProduct,
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    l10n.addProduct,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Navigation Destinations (Exact 4 Destinations)
              _buildSidebarItem(
                context,
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: l10n.home,
              ),
              const SizedBox(height: 6),
              _buildSidebarItem(
                context,
                index: 1,
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2,
                label: l10n.myProducts,
              ),
              const SizedBox(height: 6),
              _buildSidebarItem(
                context,
                index: 2,
                icon: Icons.handshake_outlined,
                selectedIcon: Icons.handshake,
                label: l10n.buyerNeeds,
              ),
              const SizedBox(height: 6),
              _buildSidebarItem(
                context,
                index: 3,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: l10n.myProfile,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _currentIndex == index;

    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => selectDestination(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
