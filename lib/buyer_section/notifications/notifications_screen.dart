import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications list
    final List<Map<String, String>> notifications = [
      {'title': 'New Response Received', 'body': 'Green Earth Farms replied to your request for Organic Cotton.', 'time': '2m ago'},
      {'title': 'Verification Complete', 'body': 'Your mobile number has been successfully verified.', 'time': '1h ago'},
      {'title': 'Welcome to VyaparSetu', 'body': 'Start exploring local producers and posting requirements.', 'time': '1d ago'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: notifications.isEmpty
          ? const EmptyStateWidget(
              title: 'No Notifications',
              subtitle: 'You are all caught up!',
              icon: Icons.notifications_off,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 20,
                          child: Icon(Icons.notifications, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notif['title']!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(notif['body']!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Text(notif['time']!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.accent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
