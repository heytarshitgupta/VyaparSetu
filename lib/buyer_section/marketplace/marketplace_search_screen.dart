import 'package:flutter/material.dart';
import '../../../core/localization/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/mock_data/products.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../theme/buyer_colors.dart';
import '../home/widgets/product_card.dart';
import '../../buyer_section/screens/shared/placeholder_screen.dart';

class MarketplaceSearchScreen extends StatefulWidget {
  const MarketplaceSearchScreen({super.key});

  @override
  State<MarketplaceSearchScreen> createState() => _MarketplaceSearchScreenState();
}

class _MarketplaceSearchScreenState extends State<MarketplaceSearchScreen> {
  String _selectedCategory = 'For You';
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Extract unique categories from mock data
  late final List<String> _categories;
  
  @override
  void initState() {
    super.initState();
    final uniqueCats = mockProducts.map((p) => p.category).toSet().toList();
    _categories = ['For You', ...uniqueCats];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _categories.contains(args)) {
      _selectedCategory = args;
    }
  }

  List<Product> get _filteredProducts {
    List<Product> products;
    if (_selectedCategory == 'For You') {
      products = mockProducts;
    } else {
      products = mockProducts.where((p) => p.category == _selectedCategory).toList();
    }
    
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      products = products.where((p) => p.name.toLowerCase().contains(query) || p.producerName.toLowerCase().contains(query)).toList();
    }
    return products;
  }

  // Helper mapping for category icons (Flipkart style)
  String _getCategoryImageUrl(String category) {
    switch (category) {
      case 'Textiles':
        return 'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?w=200';
      case 'Spices':
        return 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=200';
      case 'Handicrafts':
        return 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=200';
      case 'Food':
        return 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=200';
      case 'For You':
      default:
        return 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=200';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: BuyerColors.of(context).background,
      appBar: AppBar(
        backgroundColor: BuyerColors.of(context).surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: BuyerColors.of(context).textPrimary),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
                style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n?.searchProducts ?? 'Search products...',
                  hintStyle: GoogleFonts.inter(color: BuyerColors.of(context).textSecondary, fontSize: 14),
                  border: InputBorder.none,
                ),
              )
            : Text(
                l10n?.allCategories ?? 'All Categories',
                style: GoogleFonts.inter(
                  color: BuyerColors.of(context).textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: BuyerColors.of(context).textPrimary),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined, color: BuyerColors.of(context).textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlaceholderScreen(title: l10n?.myCart ?? 'My Cart')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // LEFT SIDEBAR (Categories)
          Container(
            width: 80,
            color: BuyerColors.of(context).background, // Light grey background
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      if (_isSearching) {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent, // Seamless with right side
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? BuyerColors.of(context).primary : Colors.transparent,
                          width: 4, // Bold left indicator
                        ),
                        bottom: BorderSide(
                          color: Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: _getCategoryImageUrl(category).startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: _getCategoryImageUrl(category),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  _getCategoryImageUrl(category),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category == 'For You' ? (l10n?.forYou ?? 'For You') : category == 'Textiles' ? (l10n?.textiles ?? 'Textiles') : category == 'Spices' ? (l10n?.spices ?? 'Spices') : category == 'Handicrafts' ? (l10n?.handicrafts ?? 'Handicrafts') : category == 'Food' ? (l10n?.food ?? 'Food') : category,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? BuyerColors.of(context).primary : BuyerColors.of(context).textSecondary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // RIGHT CONTENT AREA (Products)
          Expanded(
            child: Container(
              color: Colors.white, // Pure white for content
              child: _filteredProducts.isEmpty
                  ? EmptyStateWidget(
                      title: l10n?.noProducts ?? 'No Products',
                      subtitle: l10n?.noProductsCategory ?? 'No products available in this category yet.',
                      icon: Icons.inventory_2_outlined,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        // Grid of filtered products
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 0,
                            childAspectRatio: 1.15,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            return ProductCard(
                              product: _filteredProducts[index],
                              width: double.infinity,
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
