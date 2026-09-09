import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/mock_data/products.dart';
import '../theme/buyer_colors.dart';
import 'package:provider/provider.dart';
import '../wishlist/wishlist_provider.dart';

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
      backgroundColor: BuyerColors.of(context).background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: BuyerColors.of(context).surface,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: BuyerColors.of(context).textPrimary, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Consumer<WishlistProvider>(
                    builder: (context, provider, child) {
                      final isSaved = provider.isWishlisted(widget.product.id);
                      return IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? BuyerColors.of(context).orangeAccent : BuyerColors.of(context).textSecondary,
                            size: 20,
                          ),
                        ),
                        onPressed: () {
                          provider.toggleWishlist(widget.product.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isSaved ? 'Removed from wishlist' : 'Added to wishlist'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
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
                            placeholder: (context, url) => Container(color: BuyerColors.of(context).background),
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
                                      ? BuyerColors.of(context).primary
                                      : Colors.white.withOpacity(0.5),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Info
                      Container(
                        color: BuyerColors.of(context).surface,
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                color: BuyerColors.of(context).textPrimary,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹${widget.product.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    color: BuyerColors.of(context).primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'per piece',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: BuyerColors.of(context).textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Producer Row
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/seller_dashboard',
                                  arguments: widget.product.producerName,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: BuyerColors.of(context).surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: BuyerColors.of(context).borderLight),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: BuyerColors.of(context).primary.withOpacity(0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.storefront, color: BuyerColors.of(context).primary, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                widget.product.producerName,
                                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textPrimary),
                                              ),
                                              if (widget.product.isProducerVerified) ...[
                                                const SizedBox(width: 4),
                                                Icon(Icons.verified, color: BuyerColors.of(context).badgeGreen, size: 16),
                                              ]
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.product.location,
                                            style: GoogleFonts.inter(fontSize: 13, color: BuyerColors.of(context).textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: BuyerColors.of(context).textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Producer Story
                      Container(
                        color: BuyerColors.of(context).surface,
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Producer Story', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: BuyerColors.of(context).primary)),
                            const SizedBox(height: 12),
                            Text(
                              widget.product.description,
                              style: GoogleFonts.inter(
                                color: BuyerColors.of(context).textPrimary,
                                height: 1.6,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Details Grid
                      Container(
                        color: BuyerColors.of(context).surface,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Details', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: BuyerColors.of(context).primary)),
                            const SizedBox(height: 16),
                            _buildDetailRow(context, 'Category', widget.product.category),
                            Divider(color: BuyerColors.of(context).borderLight, height: 24),
                            _buildDetailRow(context, 'Capacity / MOQ', widget.product.capacity),
                            Divider(color: BuyerColors.of(context).borderLight, height: 24),
                            _buildDetailRow(context, 'Availability', 'In Stock'),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.handyman, size: 18),
                                label: Text('Request Customization', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: BuyerColors.of(context).primary,
                                  side: BorderSide(color: BuyerColors.of(context).primary, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/customization', arguments: widget.product);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Fixed Bottom Action Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: BuyerColors.of(context).surface,
                border: Border(top: BorderSide(color: BuyerColors.of(context).borderLight)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/order_bargain', arguments: widget.product);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: BuyerColors.of(context).primary,
                          side: BorderSide(color: BuyerColors.of(context).primary, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'BARGAIN',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order placed successfully!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: BuyerColors.of(context).orangeAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'ORDER NOW',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
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
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: BuyerColors.of(context).textSecondary),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textPrimary),
          ),
        ),
      ],
    );
  }
}
