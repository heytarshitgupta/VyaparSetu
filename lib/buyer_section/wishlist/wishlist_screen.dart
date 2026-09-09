import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../home/widgets/product_card.dart';
import 'wishlist_provider.dart';

class BuyerWishlistScreen extends StatelessWidget {
  const BuyerWishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist', style: TextStyle(color: AppColors.primary)),
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, child) {
          final products = provider.wishlistProducts;
          
          if (products.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Your wishlist is empty',
              subtitle: 'Explore the marketplace and save products you like.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ProductCard(product: products[index], width: double.infinity),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.favorite, color: AppColors.primary),
                      onPressed: () {
                        provider.toggleWishlist(products[index].id);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
