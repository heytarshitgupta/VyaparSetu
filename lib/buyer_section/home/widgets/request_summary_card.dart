import 'package:flutter/material.dart';
import '../../../../core/mock_data/requests.dart';
import '../../../../core/mock_data/responses.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class RequestSummaryCard extends StatelessWidget {
  final BuyerRequest request;

  const RequestSummaryCard({
    super.key,
    required this.request,
  });

  Color _getStatusColor() {
    switch (request.status) {
      case 'Open':
        return AppColors.success;
      case 'Responses Received':
        return AppColors.highlightAccent;
      case 'Closed':
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRouter.comparisonRoute, arguments: mockResponses);
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request.status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                request.date,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            'Qty: ${request.quantity}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
}
