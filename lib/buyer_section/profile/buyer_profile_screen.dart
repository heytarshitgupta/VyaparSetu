import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../onboarding/buyer_profile_provider.dart';
import '../../../producer_section/localization/widgets/language_switcher_widget.dart';

class BuyerProfileScreen extends StatelessWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BuyerProfileProvider>().profile;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n?.myProfile ?? 'Profile', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        children: [
          // User Header
          _buildProfileHeader(context, profile, theme),
          const SizedBox(height: 24),

          // Analytics Overview
          Text('Overview', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildAnalyticsCard(context, 'Total Orders', '12', Icons.shopping_bag_outlined, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildAnalyticsCard(context, 'Saved Producers', '8', Icons.bookmark_border, AppColors.accent)),
            ],
          ),
          const SizedBox(height: 12),
          _buildAnalyticsCard(context, 'Active Enquiries', '3 Pending', Icons.chat_bubble_outline, AppColors.success),
          
          const SizedBox(height: 24),

          // Business Information
          Text('Business Information', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow(Icons.business, 'Business Name', (profile != null && profile.businessName != null && profile.businessName!.isNotEmpty) ? profile.businessName! : 'Not provided', theme),
                const Divider(height: 24),
                _buildInfoRow(Icons.category, 'Category', (profile != null && profile.businessCategory != null && profile.businessCategory!.isNotEmpty) ? profile.businessCategory! : 'Not provided', theme),
                const Divider(height: 24),
                _buildInfoRow(Icons.email, 'Email', (profile != null && profile.email.isNotEmpty) ? profile.email : 'Not provided', theme),
                const Divider(height: 24),
                _buildInfoRow(Icons.phone, 'Phone', (profile != null && profile.mobile.isNotEmpty) ? profile.mobile : 'Not provided', theme),
                const Divider(height: 24),
                _buildInfoRow(Icons.location_on, 'Address', (profile != null && profile.address.isNotEmpty) ? '${profile.address}, ${profile.city}, ${profile.state} - ${profile.pincode}' : 'Not provided', theme),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity (Mock)
          Text('Recent Activity', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActivityTile(context, 'Order placed: Handwoven Stoles', '2 days ago', Icons.check_circle_outline, AppColors.success),
                const Divider(height: 1),
                _buildActivityTile(context, 'Enquiry sent to Sharma Pottery', '5 days ago', Icons.send_outlined, AppColors.primary),
                const Divider(height: 1),
                _buildActivityTile(context, 'Saved "Organic Spices" product', '1 week ago', Icons.bookmark_outline, AppColors.accent),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Preferences
          Text(l10n?.settings ?? 'Preferences', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.primary),
                  title: Text(l10n?.language ?? 'Language'),
                  trailing: const LanguageSwitcherWidget(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                  title: const Text('Notifications'),
                  trailing: Switch(value: true, onChanged: (v) {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          SecondaryButton(
            text: 'Log out',
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRouter.buyerAuthRoute);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, BuyerProfile? profile, ThemeData theme) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(
              (profile != null && profile.name.isNotEmpty) ? profile.name[0].toUpperCase() : 'G',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile?.name ?? 'Guest User',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.buyerType ?? 'Buyer',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
                ),
                if (profile?.isMobileVerified == true) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text('Verified Buyer', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile(BuildContext context, String title, String subtitle, IconData icon, Color iconColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }
}
