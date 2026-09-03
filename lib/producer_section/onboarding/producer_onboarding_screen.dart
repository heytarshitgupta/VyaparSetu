import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/widgets/app_top_bar_controls.dart';
import '../auth/services/producer_auth_service.dart';
import '../verification/producer_verification_service.dart';
import 'producer_onboarding_provider.dart';
import 'steps/basic_details_step.dart';
import 'steps/business_craft_step.dart';
import 'steps/identity_compliance_step.dart';
import 'steps/location_details_step.dart';
import 'widgets/onboarding_navigation_buttons.dart';
import 'widgets/onboarding_progress_header.dart';

class ProducerOnboardingScreen extends StatefulWidget {
  final ProducerOnboardingProvider? provider;
  final Future<void> Function({required String fullName, String? phone})? step1Saver;
  final Future<void> Function({
    required String businessName,
    required String craftCategory,
    String? bio,
  })? step2Saver;
  final Future<void> Function({
    required String state,
    required String district,
    required String city,
    required String pincode,
    required String address,
  })? step3Saver;
  final Future<void> Function({
    required int expectedCurrentStep,
    required int nextStep,
  })? stepAdvancer;
  final ProducerVerificationService? verificationService;

  const ProducerOnboardingScreen({
    super.key,
    this.provider,
    this.step1Saver,
    this.step2Saver,
    this.step3Saver,
    this.stepAdvancer,
    this.verificationService,
  });

  @override
  State<ProducerOnboardingScreen> createState() => _ProducerOnboardingScreenState();
}

class _ProducerOnboardingScreenState extends State<ProducerOnboardingScreen> {
  late final ProducerOnboardingProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? ProducerOnboardingProvider();
    if (widget.step1Saver != null) {
      _provider.step1Saver = widget.step1Saver;
    }
    if (widget.step2Saver != null) {
      _provider.step2Saver = widget.step2Saver;
    }
    if (widget.step3Saver != null) {
      _provider.step3Saver = widget.step3Saver;
    }
    if (widget.stepAdvancer != null) {
      _provider.stepAdvancer = widget.stepAdvancer;
    }
    _provider.addListener(_onProviderUpdate);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = AuthService.instance.currentUser;
      final profile = await ProducerAuthService.instance.fetchProfile();
      final producerProfile = await ProducerAuthService.instance.fetchProducerProfile();
      if (mounted) {
        _provider.initializeFromProfile(
          profile: profile,
          producerProfile: producerProfile,
          user: user,
        );
      }
    } catch (_) {
      // Fallback: provider maintains default empty state
    }
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

  String _getLocalizedStepTitle(BuildContext context, int step) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return _provider.currentStepTitle;
    switch (step) {
      case 0:
        return l10n.step1Title;
      case 1:
        return l10n.step2Title;
      case 2:
        return l10n.step3Title;
      case 3:
        return l10n.step4Title;
      case 4:
        return l10n.step5Title;
      default:
        return _provider.currentStepTitle;
    }
  }

  String _getLocalizedStepSubtitle(BuildContext context, int step) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return _provider.currentStepSubtitle;
    switch (step) {
      case 0:
        return l10n.step1Subtitle;
      case 1:
        return l10n.step2Subtitle;
      case 2:
        return l10n.step3Subtitle;
      case 3:
        return l10n.step4Subtitle;
      case 4:
        return l10n.step5Subtitle;
      default:
        return _provider.currentStepSubtitle;
    }
  }

  void _handleSubmit() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.onboardingReviewSubmitted ??
              'Onboarding review submitted. Full submission will be finalized in upcoming steps.',
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
    Navigator.pushReplacementNamed(context, AppRouter.producerHomeRoute);
  }

  Future<void> _handleNext() async {
    if (_provider.currentStep == 0) {
      // Step 1: Validate and persist to public.profiles
      final saved = await _provider.saveStep1();
      if (saved) {
        _provider.nextStep();
      }
    } else if (_provider.currentStep == 1) {
      // Step 2: Validate and persist to public.producer_profiles
      final saved = await _provider.saveStep2();
      if (saved) {
        _provider.nextStep();
      }
    } else if (_provider.currentStep == 2) {
      // Step 3: Validate and persist to public.producer_profiles
      final saved = await _provider.saveStep3();
      if (saved) {
        _provider.nextStep();
      }
    } else if (_provider.isLastStep) {
      _handleSubmit();
    } else {
      _provider.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final isNarrow = MediaQuery.sizeOf(context).width < 360;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            l10n?.producerSetup ?? 'Producer Setup',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const AppTopBarControls(showLabels: false),
          const SizedBox(width: 4),
          if (isNarrow)
            IconButton(
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
              icon: Icon(
                Icons.logout,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              tooltip: l10n?.exit ?? 'Exit',
            )
          else
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
              icon: Icon(
                Icons.logout,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              label: Text(
                l10n?.exit ?? 'Exit',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 4),
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
                    title: _getLocalizedStepTitle(context, _provider.currentStep),
                    subtitle: _getLocalizedStepSubtitle(context, _provider.currentStep),
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
                    onNext: _handleNext,
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
    final l10n = AppLocalizations.of(context);
    switch (step) {
      case 0:
        return BasicDetailsStep(provider: _provider);
      case 1:
        return BusinessCraftStep(provider: _provider);
      case 2:
        return LocationDetailsStep(provider: _provider);
      case 3:
        return IdentityComplianceStep(
          provider: _provider,
          verificationService: widget.verificationService,
        );
      case 4:
        return _buildStepCard(
          icon: Icons.assignment_turned_in_outlined,
          title: l10n?.step5CardTitle ?? 'Review & Submit Onboarding',
          description: l10n?.step5CardDescription ??
              'Review your profile setup before submitting. You can edit your craft catalog anytime from your dashboard.',
          fields: [
            _buildInfoTile(
              l10n?.profileStatus ?? 'Profile Status',
              l10n?.readyForSubmission ?? 'Ready for Submission',
            ),
            _buildInfoTile(
              l10n?.nextStage ?? 'Next Stage',
              l10n?.nextStageDescription ?? 'Direct access to Buyer Needs & Products',
            ),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 8),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
