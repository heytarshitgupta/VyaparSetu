import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/mock_data/responses.dart';
import '../../../core/widgets/primary_button.dart';

class ComparisonScreen extends StatelessWidget {
  final List<ProducerResponse> responses;

  const ComparisonScreen({super.key, required this.responses});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Compare Responses', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: responses.isEmpty
          ? const Center(child: Text('No responses available.'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: responses.map((response) => _buildProducerColumn(context, response)).toList(),
              ),
            ),
    );
  }

  Widget _buildProducerColumn(BuildContext context, ProducerResponse response) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (response.isBestMatch)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Best Match',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 24), // Maintain height if no tag
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        response.producerName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (response.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: AppColors.success, size: 16),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Rows
          _buildDataRow(context, 'Price', '₹${response.price.toStringAsFixed(0)}', isHighlight: true),
          _buildDataRow(context, 'Quantity', response.quantity),
          _buildDataRow(context, 'Lead Time', response.leadTime),
          _buildDataRow(context, 'Location', response.location, isLast: true),

          // Action
          Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              text: 'Select',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You\'ve selected ${response.producerName}. They\'ll be notified.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, String label, String value, {bool isLast = false, bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
