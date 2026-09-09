import 'package:flutter/material.dart';
import '../../../core/localization/generated/app_localizations.dart';

class OnboardingNavigationButtons extends StatelessWidget {
  final bool isFirstStep;
  final bool isLastStep;
  final bool showNext;
  final bool isSubmitting;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final String? nextLabelOverride;
  final String? skipLabelOverride;

  const OnboardingNavigationButtons({
    super.key,
    required this.isFirstStep,
    required this.isLastStep,
    this.showNext = true,
    this.isSubmitting = false,
    required this.onPrevious,
    this.onNext,
    this.onSkip,
    this.nextLabelOverride,
    this.skipLabelOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final backLabel = l10n?.back ?? 'Back';
    final nextLabel = nextLabelOverride ??
        (isLastStep
            ? (l10n?.completeSetup ?? 'Complete Setup')
            : (l10n?.continueButton ?? 'Continue'));
    final skipLabel = skipLabelOverride ?? (l10n?.skipForNow ?? 'Skip for now');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Previous button (hidden on first step)
              if (!isFirstStep) ...[
                Expanded(
                  flex: showNext ? 2 : 1,
                  child: OutlinedButton.icon(
                    key: const ValueKey('onboarding_back_button'),
                    onPressed: isSubmitting ? null : onPrevious,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(backLabel),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(color: theme.dividerColor),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (showNext) const SizedBox(width: 12),
              ],

              // Next / Continue / Complete Setup button
              if (showNext)
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    key: const ValueKey('onboarding_next_button'),
                    onPressed: isSubmitting ? null : onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  nextLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isLastStep
                                      ? Icons.check_circle_outline
                                      : Icons.arrow_forward,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
            ],
          ),
          if (onSkip != null) ...[
            const SizedBox(height: 10),
            TextButton(
              key: const ValueKey('onboarding_skip_button'),
              onPressed: isSubmitting ? null : onSkip,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                minimumSize: const Size(140, 40),
              ),
              child: Text(
                skipLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
