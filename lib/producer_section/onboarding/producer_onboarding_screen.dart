import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import 'producer_onboarding_provider.dart';
import 'widgets/onboarding_navigation_buttons.dart';
import 'widgets/onboarding_progress_header.dart';

class ProducerOnboardingScreen extends StatefulWidget {
  const ProducerOnboardingScreen({super.key});

  @override
  State<ProducerOnboardingScreen> createState() => _ProducerOnboardingScreenState();
}

class _ProducerOnboardingScreenState extends State<ProducerOnboardingScreen> {
  late final ProducerOnboardingProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ProducerOnboardingProvider();
    _provider.addListener(_onProviderUpdate);
  }

  void _onProviderUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    _provider.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Onboarding review submitted. Full data persistence will be enabled in Step 4B.',
        ),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 4),
      ),
    );
    // Route to placeholder/home for now
    Navigator.pushReplacementNamed(context, AppRouter.producerHomeRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Producer Setup',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await AuthService.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.producerLoginRoute,
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, size: 16, color: AppColors.textSecondary),
            label: const Text(
              'Exit',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Header
                  OnboardingProgressHeader(
                    currentStep: _provider.currentStep,
                    totalSteps: ProducerOnboardingProvider.totalSteps,
                    title: _provider.currentStepTitle,
                    subtitle: _provider.currentStepSubtitle,
                  ),
                  const SizedBox(height: 20),

                  // Step Content (Scrollable)
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildStepContent(_provider.currentStep),
                    ),
                  ),

                  // Navigation Buttons (Back & Continue / Submit)
                  OnboardingNavigationButtons(
                    isFirstStep: _provider.isFirstStep,
                    isLastStep: _provider.isLastStep,
                    isSubmitting: _provider.isSubmitting,
                    onPrevious: _provider.previousStep,
                    onNext: () {
                      if (_provider.isLastStep) {
                        _handleSubmit();
                      } else {
                        _provider.nextStep();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildStepCard(
          icon: Icons.person_outline,
          title: 'Basic Artisan Profile',
          description:
              'Provide your primary display name, phone number, and preferred language for order notifications.',
          fields: [
            _buildInfoTile('Full Name', 'Ramesh Kumar (from account)'),
            _buildInfoTile('Primary Language', 'Hindi / English'),
            _buildInfoTile('Voice Assistance', 'Enabled (Hindi)'),
          ],
        );
      case 1:
        return _buildStepCard(
          icon: Icons.storefront_outlined,
          title: 'Business & Craft Category',
          description:
              'Select your artisanal craft specializations, workshop name, and primary product materials.',
          fields: [
            _buildInfoTile('Craft Category', 'Handloom Textiles / Pottery / Woodcraft'),
            _buildInfoTile('Workshop Name', 'e.g. Ramesh Handloom Creations'),
            _buildInfoTile('Experience', '5+ Years of Craftsmanship'),
          ],
        );
      case 2:
        return _buildStepCard(
          icon: Icons.location_on_outlined,
          title: 'Workshop Location',
          description:
              'Enter your workshop or unit address so verified commercial buyers can calculate logistics and shipping.',
          fields: [
            _buildInfoTile('State & District', 'Rajasthan / Jaipur'),
            _buildInfoTile('City / Village', 'Sanganer'),
            _buildInfoTile('Pincode', '302029'),
          ],
        );
      case 3:
        return _buildStepCard(
          icon: Icons.verified_user_outlined,
          title: 'Identity & Artisan Compliance',
          description:
              'Verify your artisan status with government-recognized ID (Artisan Card, Udyam MSME, or Aadhaar).',
          fields: [
            _buildInfoTile('Verification ID', 'Artisan Pehchan Card / Udyam'),
            _buildInfoTile('Status', 'Pending document upload in Step 4B'),
            _buildInfoTile('Privacy', 'Private & encrypted strictly for verification'),
          ],
        );
      case 4:
        return _buildStepCard(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Review & Submit Onboarding',
          description:
              'Review your profile setup before submitting. You can edit your craft catalog anytime from your dashboard.',
          fields: [
            _buildInfoTile('Profile Status', 'Ready for Submission'),
            _buildInfoTile('Next Stage', 'Direct access to Buyer Requests & AI Studio'),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> fields,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 8),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
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
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
