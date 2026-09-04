import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../core/mock_data/products.dart';
import '../../../core/mock_data/requests.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../onboarding/buyer_profile_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/request_summary_card.dart';

class BuyerHomeTab extends StatelessWidget {
  const BuyerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BuyerProfileProvider>().profile;
    final userName = profile?.name.split(' ').first ?? 'Guest';
    final userLocation = profile != null ? '${profile.city}, ${profile.state}' : 'New Delhi, India';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.background,
          floating: true,
          pinned: false,
          elevation: 0,
          toolbarHeight: 70,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, $userName', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(userLocation, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.primary),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.notificationsRoute);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/marketplace');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text('Search products or producers...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text('Explore Local Products', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
          ),
        ),
        SliverToBoxAdapter(
          child: mockProducts.isEmpty
              ? const EmptyStateWidget(title: 'No Products', subtitle: 'No local products found.', icon: Icons.inventory_2_outlined)
              : SizedBox(
                  height: 310,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: mockProducts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: ProductCard(product: mockProducts[index]),
                      );
                    },
                  ),
                ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Text('Your Requests', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
          ),
        ),
        SliverToBoxAdapter(
          child: mockRequests.isEmpty
              ? const EmptyStateWidget(title: 'No Requests', subtitle: 'You haven\'t made any requests yet.', icon: Icons.list_alt_outlined)
              : SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: mockRequests.length,
                    itemBuilder: (context, index) {
                      return RequestSummaryCard(request: mockRequests[index]);
                    },
                  ),
                ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Text('Recommended for You', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.52,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ProductCard(
                  product: mockProducts.reversed.toList()[index % mockProducts.length],
                  width: double.infinity,
                );
              },
              childCount: 4,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
