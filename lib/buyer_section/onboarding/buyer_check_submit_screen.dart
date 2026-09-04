import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/app_top_bar_controls.dart';
import 'buyer_profile_provider.dart';

class BuyerCheckSubmitScreen extends StatefulWidget {
  const BuyerCheckSubmitScreen({super.key});

  @override
  State<BuyerCheckSubmitScreen> createState() => _BuyerCheckSubmitScreenState();
}

class _BuyerCheckSubmitScreenState extends State<BuyerCheckSubmitScreen> {
  bool _isSubmitting = false;

  void _submitApplication() async {
    setState(() => _isSubmitting = true);
    
    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    Navigator.pushReplacementNamed(context, AppRouter.buyerSuccessRoute);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BuyerProfileProvider>().profile;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Submit'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: const [
          AppTopBarControls(showLabels: false),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Almost there!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please review your details before submitting your application.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        _buildSection(
                          context,
                          title: 'Basic Information',
                          icon: Icons.person_outline,
                          children: [
                            _buildInfoRow('Full Name', profile?.name ?? '-'),
                            if (profile?.businessName != null && profile!.businessName!.isNotEmpty)
                              _buildInfoRow('Business Name', profile.businessName!),
                            _buildInfoRow('Mobile', profile?.mobile ?? '-'),
                            _buildInfoRow('Email', profile?.email ?? '-'),
                            _buildInfoRow('Buyer Type', profile?.buyerType ?? '-'),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildSection(
                          context,
                          title: 'Business Details',
                          icon: Icons.storefront,
                          children: [
                            _buildInfoRow('Category', profile?.businessCategory ?? '-'),
                            _buildInfoRow('Address', profile?.address ?? '-'),
                            _buildInfoRow('City/State', '${profile?.city ?? '-'}, ${profile?.state ?? '-'}'),
                            _buildInfoRow('Pincode', profile?.pincode ?? '-'),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildSection(
                          context,
                          title: 'Verification Status',
                          icon: Icons.verified_user_outlined,
                          children: [
                            _buildVerificationRow('Identity (PAN)', profile?.isBusinessVerified == true),
                            _buildVerificationRow('Mobile Number', profile?.isMobileVerified == true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Sticky Bottom Submit Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Submit Application',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationRow(String label, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.cancel,
            color: isVerified ? AppColors.success : AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
