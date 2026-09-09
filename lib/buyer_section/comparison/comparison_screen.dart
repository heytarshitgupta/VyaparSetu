import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/buyer_colors.dart';
import '../../../core/mock_data/responses.dart';

class ComparisonScreen extends StatelessWidget {
  final List<ProducerResponse> responses;

  const ComparisonScreen({super.key, required this.responses});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuyerColors.of(context).background,
      appBar: AppBar(
        title: Text('Compare Responses', style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: BuyerColors.of(context).surface,
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(color: BuyerColors.of(context).primary),
        surfaceTintColor: Colors.transparent,
      ),
      body: responses.isEmpty
          ? const Center(child: Text('No responses available.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: responses.length,
              itemBuilder: (context, index) {
                return _buildProducerCard(context, responses[index]);
              },
            ),
    );
  }

  Widget _buildProducerCard(BuildContext context, ProducerResponse response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: BuyerColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BuyerColors.of(context).borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: BuyerColors.of(context).borderLight)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (response.isBestMatch)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: BuyerColors.of(context).orangeAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Best Match',
                            style: GoogleFonts.inter(
                              color: BuyerColors.of(context).orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              response.producerName,
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: BuyerColors.of(context).textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (response.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified, color: BuyerColors.of(context).badgeGreen, size: 16),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${response.price.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: BuyerColors.of(context).primary),
                ),
              ],
            ),
          ),
          
          // Rows
          _buildDataRow(context, 'Quantity', response.quantity),
          _buildDataRow(context, 'Lead Time', response.leadTime),
          _buildDataRow(context, 'Location', response.location, isLast: true),

          // Action
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuyerColors.of(context).primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Select Supplier', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You\'ve selected ${response.producerName}. They\'ll be notified.'),
                      backgroundColor: BuyerColors.of(context).badgeGreen,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: BuyerColors.of(context).borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: BuyerColors.of(context).textSecondary),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textPrimary),
          ),
        ],
      ),
    );
  }
}
