import 'package:flutter/material.dart';
import '../../core/mock_data/products.dart';
import '../../core/theme/app_colors.dart';
import '../home/widgets/product_card.dart';

class SellerDashboardScreen extends StatefulWidget {
  final String producerName;

  const SellerDashboardScreen({super.key, required this.producerName});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  double? _maxPrice;

  List<String> get _categories {
    final producerProducts = mockProducts.where((p) => p.producerName == widget.producerName).toList();
    final categories = producerProducts.map((p) => p.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }

  List<Product> get _filteredProducts {
    return mockProducts.where((p) {
      if (p.producerName != widget.producerName) return false;
      if (_selectedCategory != 'All' && p.category != _selectedCategory) return false;
      if (_maxPrice != null && p.price > _maxPrice!) return false;
      if (_searchController.text.isNotEmpty && !p.name.toLowerCase().contains(_searchController.text.toLowerCase())) return false;
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producerName, style: const TextStyle(color: AppColors.primary)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          widget.producerName[0],
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.producerName, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.verified, size: 16, color: AppColors.success),
                                const SizedBox(width: 4),
                                Text('Verified Producer', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.success)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products by ${widget.producerName}...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text('Max Price: ${_maxPrice == null ? 'Any' : '₹${_maxPrice!.toStringAsFixed(0)}'}', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  Slider(
                    value: _maxPrice ?? 10000,
                    min: 0,
                    max: 10000,
                    divisions: 20,
                    label: _maxPrice?.toStringAsFixed(0) ?? '10000',
                    onChanged: (value) {
                      setState(() {
                        if (value == 10000) {
                          _maxPrice = null;
                        } else {
                          _maxPrice = value;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: filtered.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No products match your filters.'),
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(product: filtered[index], width: double.infinity),
                      childCount: filtered.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
