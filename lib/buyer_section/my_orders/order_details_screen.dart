import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import 'buyer_orders_screen.dart'; // To get MockOrder

class OrderDetailsScreen extends StatelessWidget {
  final MockOrder order;

  const OrderDetailsScreen({super.key, required this.order});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered': return AppColors.success;
      case 'In Progress': return AppColors.accent;
      case 'Pending': return Colors.orange;
      case 'Cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  void _showAlterOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alter Order'),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe the changes you want (e.g. modify quantity, change address)...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alteration request sent to the seller.')),
              );
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order cancelled successfully.'), backgroundColor: AppColors.error),
              );
              Navigator.pop(context); // Go back to orders list
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canModify = order.status == 'Pending' || order.status == 'In Progress';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(color: AppColors.primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order ID', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                Text(order.id, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                Text(order.date, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 32),
            
            Text('Item Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.productName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Seller: ${order.producerName}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('₹${order.amount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            
            if (canModify) ...[
              const SizedBox(height: 48),
              SecondaryButton(
                text: 'Alter Order',
                onPressed: () => _showAlterOrderDialog(context),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _showCancelOrderDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel Order'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
