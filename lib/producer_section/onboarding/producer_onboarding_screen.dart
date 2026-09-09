import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/widgets/app_top_bar_controls.dart';
import '../auth/services/producer_auth_service.dart';
import '../verification/producer_verification_service.dart';
import 'producer_onboarding_provider.dart';
import 'steps/your_business_step.dart';
import 'steps/about_your_business_step.dart';
import 'widgets/onboarding_navigation_buttons.dart';
import 'widgets/onboarding_progress_header.dart';

class ProducerOnboardingScreen extends StatefulWidget {
  final ProducerOnboardingProvider? provider;
  final Future<void> Function({
    required String businessName,
    required String craftCategory,
    String? bio,
    required String state,
    required String district,
    required String city,
    required String pincode,
  })? yourBusinessSaver;
  final Future<void> Function({
    String? teamSize,
    String? typicalMonthlySales,
    double? productionCapacityQuantity,
    String? productionCapacityUnit,
    String? productionCapacityPeriod,
    List<String>? sellingChannels,
  })? aboutYourBusinessSaver;
  final Future<Map<String, dynamic>> Function()? onboardingCompleter;
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
    this.yourBusinessSaver,
    this.aboutYourBusinessSaver,
    this.onboardingCompleter,
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
    if (widget.yourBusinessSaver != null) {
      _provider.yourBusinessSaver = widget.yourBusinessSaver;
    }
    if (widget.aboutYourBusinessSaver != null) {
      _provider.aboutYourBusinessSaver = widget.aboutYourBusinessSaver;
    }
    if (widget.onboardingCompleter != null) {
      _provider.onboardingCompleter = widget.onboardingCompleter;
    }
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
    if (step == 0) {
      return l10n?.yourBusinessTitle ?? 'Your Business';
    } else {
      return l10n?.aboutYourBusinessTitle ?? 'About Your Business';
    }
  }

  String _getLocalizedStepSubtitle(BuildContext context, int step) {
    final l10n = AppLocalizations.of(context);
    if (step == 0) {
      return l10n?.yourBusinessSubtitle ??
          'Tell us a little about what you make and where your business is based.';
    } else {
      return l10n?.aboutYourBusinessSubtitle ??
          'Help us understand your business better. You can skip this step.';
    }
  }

  Future<void> _handleNext() async {
    final l10n = AppLocalizations.of(context);
    if (_provider.currentStep == 0) {
      // Step 0 (Your Business): Validate and persist to public.producer_profiles
      final saved = await _provider.saveYourBusiness(l10n: l10n);
      if (saved && mounted) {
        _provider.nextStep();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.yourBusinessSaved ?? 'Business details saved successfully.',
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else if (_provider.currentStep == 1) {
      // Step 1 (About Your Business): Validate, persist, complete onboarding
      final completed = await _provider.saveAboutYourBusiness(l10n: l10n);
      if (completed && mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.producerHomeRoute,
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleSkip() async {
    // Skip for now: complete onboarding without enforcing optional fields
    final completed = await _provider.skipAboutYourBusiness();
    if (completed && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.producerHomeRoute,
        (route) => false,
      );
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
            constraints: const BoxConstraints(maxWidth: 580),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Header (2-stage mental model)
                  OnboardingProgressHeader(
                    currentStep: _provider.currentStep,
                    totalSteps: ProducerOnboardingProvider.totalSteps,
                    title: _getLocalizedStepTitle(context, _provider.currentStep),
                    subtitle: _getLocalizedStepSubtitle(context, _provider.currentStep),
                  ),
                  const SizedBox(height: 12),

                  // Step Content (Scrollable with bottom padding to protect content)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _buildStepContent(_provider.currentStep),
                    ),
                  ),

                  // Navigation Buttons (Back & Complete Setup / Skip for now)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: OnboardingNavigationButtons(
                      isFirstStep: _provider.currentStep == 0,
                      isLastStep: _provider.currentStep == 1,
                      showNext: true,
                      isSubmitting: _provider.isSubmitting,
                      onPrevious: _provider.previousStep,
                      onNext: _handleNext,
                      onSkip: _provider.currentStep == 1 ? _handleSkip : null,
                      nextLabelOverride: _provider.currentStep == 1
                          ? (l10n?.completeSetup ?? 'Complete Setup')
                          : null,
                    ),
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
    if (step == 0) {
      return YourBusinessStep(provider: _provider);
    } else {
      return AboutYourBusinessStep(provider: _provider);
    }
  }
}
