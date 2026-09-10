import 'package:flutter/material.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/mock_data/products.dart';
import '../../theme/buyer_colors.dart';
import '../../../../core/routes/app_router.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final double width;

  const ProductCard({
    super.key,
    required this.product,
    this.width = 160,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRouter.productDetailRoute, arguments: widget.product);
      },
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: BuyerColors.of(context).surface,
          border: Border.all(color: BuyerColors.of(context).borderLight, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Area
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: BuyerColors.of(context).borderLight),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isFavorite ? l10n?.addedToWishlist ?? 'Added to wishlist' : l10n?.removedFromWishlist ?? 'Removed from wishlist'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: _isFavorite ? BuyerColors.of(context).orangeAccent : BuyerColors.of(context).textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Area
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.producerName,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: BuyerColors.of(context).textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: BuyerColors.of(context).textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${widget.product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: BuyerColors.of(context).textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'MOQ ${RegExp(r'\\d+').firstMatch(widget.product.capacity)?.group(0) ?? '50'}',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: BuyerColors.of(context).textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Orange Order Now Button
                    SizedBox(
                      height: 32,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRouter.productDetailRoute, arguments: widget.product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BuyerColors.of(context).orangeAccent, // Vyapar Setu Orange
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          l10n?.orderNow ?? 'Order Now',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
