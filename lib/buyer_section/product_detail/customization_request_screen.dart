import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/mock_data/products.dart';
import '../theme/buyer_colors.dart';

class CustomizationRequestScreen extends StatefulWidget {
  final Product product;

  const CustomizationRequestScreen({super.key, required this.product});

  @override
  State<CustomizationRequestScreen> createState() => _CustomizationRequestScreenState();
}

class _CustomizationRequestScreenState extends State<CustomizationRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _requirementsController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _requirementsController.dispose();
    _dimensionsController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: BuyerColors.of(context).surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Request Sent', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: BuyerColors.of(context).textPrimary)),
          content: Text(
            'Your customization request has been sent to the producer. They will review it and get back to you with a quote.',
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
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuyerColors.of(context).background,
      appBar: AppBar(
        title: Text('Request Customization', style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor: BuyerColors.of(context).surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: BuyerColors.of(context).textPrimary),
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
            onPressed: _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: BuyerColors.of(context).primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Send Customization Request',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BuyerColors.of(context).primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BuyerColors.of(context).primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize ${widget.product.name}',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: BuyerColors.of(context).primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell the producer exactly what you need. Be specific about materials, dimensions, or special requests.',
                      style: GoogleFonts.inter(fontSize: 13, color: BuyerColors.of(context).primary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Text('Detailed Requirements *', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _requirementsController,
                maxLines: 4,
                style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary),
                decoration: _buildInputDecoration('E.g., I want this painted blue, using teak wood instead of pine...'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your requirements' : null,
              ),
              const SizedBox(height: 24),
              
              Text('Specific Dimensions (Optional)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dimensionsController,
                style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary),
                decoration: _buildInputDecoration('E.g., 20x30 inches'),
              ),
              const SizedBox(height: 24),
              
              Text('Quantity *', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary),
                decoration: _buildInputDecoration('Enter quantity'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter quantity' : null,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
