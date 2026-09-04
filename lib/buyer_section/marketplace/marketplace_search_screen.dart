import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/mock_data/products.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../home/widgets/product_card.dart';

class MarketplaceSearchScreen extends StatefulWidget {
  const MarketplaceSearchScreen({super.key});

  @override
  State<MarketplaceSearchScreen> createState() => _MarketplaceSearchScreenState();
}

class _MarketplaceSearchScreenState extends State<MarketplaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = mockProducts;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = mockProducts.where((p) {
        return p.name.toLowerCase().contains(query) || 
               p.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showFilterSheet(BuildContext context, String filterName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter by $filterName', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text('Filter options will appear here.'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search products or categories...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Filter Row
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(context, 'Category'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'Location'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'Price'),
                ],
              ),
            ),
            const Divider(color: AppColors.border),
            // Results Area
            Expanded(
              child: _filteredProducts.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.search_off,
                      title: 'No products found',
                      subtitle: 'Try adjusting your search or filters to find what you are looking for.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.52,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: _filteredProducts[index],
                          width: double.infinity,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () => _showFilterSheet(context, label),
    );
  }
}
