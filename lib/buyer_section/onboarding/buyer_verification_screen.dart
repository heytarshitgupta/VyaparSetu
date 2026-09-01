import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/primary_button.dart';
import 'buyer_profile_provider.dart';

class BuyerVerificationScreen extends StatelessWidget {
  const BuyerVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BuyerProfileProvider>().profile;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Center', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Build Trust',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your verification to get the Verified Buyer badge and connect with trusted sellers.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),
            _buildVerificationTile(
              context, 
              title: 'Mobile Number Verified', 
              subtitle: profile?.mobile ?? 'Verified via OTP',
              isVerified: true,
            ),
            const SizedBox(height: 16),
            _buildVerificationTile(
              context, 
              title: 'Email Address', 
              subtitle: 'A verification link was sent to your email.',
              isVerified: false,
            ),
            const SizedBox(height: 16),
            _buildVerificationTile(
              context, 
              title: 'Business Verification', 
              subtitle: 'Upload documents to verify your business.',
              isVerified: false,
            ),
            const SizedBox(height: 16),
            _buildVerificationTile(
              context, 
              title: 'GST Verification', 
              subtitle: 'Paused',
              isVerified: false,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Go to Dashboard',
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRouter.homeRoute);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationTile(BuildContext context, {required String title, required String subtitle, required bool isVerified}) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isVerified ? AppColors.success : AppColors.border, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Icon(
            isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isVerified ? AppColors.success : AppColors.textSecondary,
            size: 28,
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ),
          trailing: isVerified 
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Verified', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              : TextButton(onPressed: () {}, child: const Text('Verify')),
        ),
      ),
    );
  }
}
