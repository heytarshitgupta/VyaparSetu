import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/mock_data/responses.dart'; // Ensure mock responses exist or we use a basic list

class BuyerRequestsScreen extends StatelessWidget {
  const BuyerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock list of requests
    final List<Map<String, dynamic>> mockRequests = [
      {
        'id': 'REQ-1001',
        'title': 'Premium Handwoven Silk Sarees',
        'status': 'Receiving Quotes',
        'date': 'Oct 24, 2023',
        'responses': 3,
      },
      {
        'id': 'REQ-1002',
        'title': 'Organic Turmeric Powder (500kg)',
        'status': 'Closed',
        'date': 'Oct 15, 2023',
        'responses': 5,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Requests', style: TextStyle(color: AppColors.primary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: mockRequests.isEmpty
          ? const EmptyStateWidget(
              title: 'No requests yet',
              subtitle: 'Post a custom requirement to start receiving quotes from verified producers.',
              icon: Icons.assignment_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: mockRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = mockRequests[index];
                final bool isActive = req['status'] == 'Receiving Quotes';
                
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isActive ? () {
                      // Navigate to comparison screen with mock responses
                      // In a real app we'd fetch the specific responses for this request
                      Navigator.pushNamed(
                        context, 
                        AppRouter.comparisonRoute,
                        arguments: mockResponses, // Assuming mockResponses is available from core/mock_data/responses.dart
                      );
                    } : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(req['id'], style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.border,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  req['status'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? AppColors.success : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            req['title'],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(req['date'], style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.forum_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${req['responses']} Responses', 
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary, 
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
