import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/mock_data/products.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images.isNotEmpty ? widget.product.images : [widget.product.imageUrl];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Space for bottom bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Image Carousel Hero
                SizedBox(
                  height: 350,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppColors.surface),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          );
                        },
                      ),
                      if (images.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? AppColors.primary
                                      : Colors.white.withOpacity(0.5),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // 2. Header Info
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${widget.product.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Producer Row
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.storefront, color: AppColors.textSecondary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          widget.product.producerName,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        if (widget.product.isProducerVerified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified, color: AppColors.success, size: 16),
                                        ]
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.product.location,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.border),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Producer Story
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Producer Story', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Details Grid
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Details', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      _buildDetailRow(context, 'Category', widget.product.category),
                      const Divider(color: AppColors.border, height: 24),
                      _buildDetailRow(context, 'Capacity', widget.product.capacity),
                      const Divider(color: AppColors.border, height: 24),
                      _buildDetailRow(context, 'Availability', 'In Stock'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 5. Sticky Bottom Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SecondaryButton(
                        text: 'Contact',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contact request sent!')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        text: 'Post Requirement',
                        onPressed: () {
                          Navigator.pushNamed(
                            context, 
                            '/post_requirement',
                            arguments: widget.product.category,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
