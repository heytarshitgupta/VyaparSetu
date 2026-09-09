import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_top_bar_controls.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/auth_exception_handler.dart';
import '../../../core/localization/generated/app_localizations.dart';
import 'buyer_profile_provider.dart';

class BuyerVerificationScreen extends StatefulWidget {
  const BuyerVerificationScreen({super.key});

  @override
  State<BuyerVerificationScreen> createState() => _BuyerVerificationScreenState();
}

class _BuyerVerificationScreenState extends State<BuyerVerificationScreen> {
  bool _isSendingOtp = false;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BuyerProfileProvider>().profile;
    final l10n = AppLocalizations.of(context);
    
    // Check if the required verifications are done
    // For this prototype, Mobile and Email are required.
    final bool canSubmit = (profile?.isMobileVerified ?? false) && (profile?.isEmailVerified ?? false);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Center', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
        actions: const [
          AppTopBarControls(showLabels: false),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                subtitle: profile?.isMobileVerified == true ? 'Mobile verified' : (profile?.mobile ?? 'Verify your mobile via OTP'),
                isVerified: profile?.isMobileVerified ?? false,
                isLoading: _isSendingOtp,
                onVerify: () async {
                  if (profile?.mobile == null || profile!.mobile.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No mobile number found.'), backgroundColor: AppColors.error));
                    return;
                  }
                  
                  setState(() => _isSendingOtp = true);
                  String phone = profile.mobile.trim();
                  if (phone.length == 10) {
                    phone = '+91$phone'; // Default to India for 10-digit numbers
                  }
                  
                  try {
                    // MOCK: Fake delay to simulate network request
                    await Future.delayed(const Duration(seconds: 1));
                    // await AuthService.instance.sendPhoneOtp(phone);
                    
                    if (!mounted) return;
                    
                    final result = await Navigator.pushNamed(
                      context, 
                      AppRouter.otpRoute,
                      arguments: {'isVerificationMode': true, 'mobile': phone},
                    );
                    
                    if (result == true && context.mounted) {
                      context.read<BuyerProfileProvider>().saveProfile(
                        profile.copyWith(isMobileVerified: true),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mobile number verified successfully.'), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      final msg = AuthExceptionHandler.getErrorMessage(e);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
                    }
                  } finally {
                    if (mounted) setState(() => _isSendingOtp = false);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              _buildVerificationTile(
                context, 
                title: l10n?.emailAddress ?? 'Email Address', 
                subtitle: profile?.isEmailVerified == true ? 'Email verified' : 'A verification link was sent to your email.',
                isVerified: profile?.isEmailVerified ?? false,
                onVerify: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verifying email address...')),
                  );
                  await Future.delayed(const Duration(seconds: 1));
                  if (context.mounted && profile != null) {
                    context.read<BuyerProfileProvider>().saveProfile(
                      profile.copyWith(isEmailVerified: true),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              
              const SizedBox(height: 40),
              
              PrimaryButton(
                text: 'Review & Submit',
                onPressed: canSubmit ? () {
                  Navigator.pushNamed(context, AppRouter.buyerCheckSubmitRoute);
                } : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationTile(
    BuildContext context, {
    required String title, 
    required String subtitle, 
    required bool isVerified,
    VoidCallback? onVerify,
    bool isLoading = false,
  }) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(AppLocalizations.of(context)?.badgeVerified ?? 'Verified', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              : isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                : TextButton(
                    onPressed: onVerify, 
                    child: Text(AppLocalizations.of(context)?.verify ?? 'Verify', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
        ),
      ),
    );
  }
}
