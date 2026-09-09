import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/mock_data/products.dart';
import '../theme/buyer_colors.dart';

class OrderBargainScreen extends StatefulWidget {
  final Product product;
  
  const OrderBargainScreen({super.key, required this.product});

  @override
  State<OrderBargainScreen> createState() => _OrderBargainScreenState();
}

class _OrderBargainScreenState extends State<OrderBargainScreen> {
  late TextEditingController _priceController;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BuyerColors.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Offer Sent', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: BuyerColors.of(context).textPrimary)),
        content: Text(
          'Your bargain request has been successfully sent to the producer. They will review it and reply shortly.',
          style: GoogleFonts.inter(color: BuyerColors.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to product details
            },
            child: Text('OK', style: GoogleFonts.inter(color: BuyerColors.of(context).primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuyerColors.of(context).background,
      appBar: AppBar(
        backgroundColor: BuyerColors.of(context).surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: BuyerColors.of(context).textPrimary),
        title: Text(
          'Place Offer', 
          style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: BuyerColors.of(context).surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _submitOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: BuyerColors.of(context).primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Submit Request',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BuyerColors.of(context).surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BuyerColors.of(context).borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.product.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name, 
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: BuyerColors.of(context).textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.producerName, 
                          style: GoogleFonts.inter(fontSize: 12, color: BuyerColors.of(context).textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Base Price: ₹${widget.product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: BuyerColors.of(context).primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Bargain Input
            Text(
              'Your Offer Price', 
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textPrimary),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textSecondary),
                hintText: 'Enter your offer',
                hintStyle: GoogleFonts.inter(color: BuyerColors.of(context).textSecondary.withOpacity(0.5)),
                filled: true,
                fillColor: BuyerColors.of(context).surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: BuyerColors.of(context).borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: BuyerColors.of(context).borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: BuyerColors.of(context).primary, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Message Input
            Text(
              'Message to Producer (Optional)', 
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              style: GoogleFonts.inter(fontSize: 14, color: BuyerColors.of(context).textPrimary),
              decoration: InputDecoration(
                hintText: 'Explain why you are offering this price (e.g., bulk volume, regular customer)...',
                hintStyle: GoogleFonts.inter(color: BuyerColors.of(context).textSecondary.withOpacity(0.5), fontSize: 13),
                filled: true,
                fillColor: BuyerColors.of(context).surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: BuyerColors.of(context).borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: BuyerColors.of(context).borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: BuyerColors.of(context).primary, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: BuyerColors.of(context).textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Producers are more likely to accept offers that are reasonable and close to the base price.',
                    style: GoogleFonts.inter(fontSize: 12, color: BuyerColors.of(context).textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
