import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/routes/app_router.dart';
import '../onboarding/buyer_profile_provider.dart';
import '../../../producer_section/localization/widgets/language_switcher_widget.dart';

class BuyerProfileScreen extends StatelessWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BuyerProfileProvider>().profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile?.name ?? 'Guest User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile != null ? '${profile.city}, ${profile.state}' : 'Location unknown',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      profile?.buyerType ?? 'Buyer',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            const AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.language, color: AppColors.primary),
                title: Text('Language'),
                trailing: LanguageSwitcherWidget(),
              ),
            ),
            const SizedBox(height: 32),
            SecondaryButton(
              text: 'Log out',
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRouter.buyerAuthRoute);
              },
            ),
          ],
        ),
      ),
    );
  }
}
