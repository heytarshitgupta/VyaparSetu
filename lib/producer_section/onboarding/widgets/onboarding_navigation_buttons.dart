import 'package:flutter/material.dart';
import '../../../core/localization/generated/app_localizations.dart';

class OnboardingNavigationButtons extends StatelessWidget {
  final bool isFirstStep;
  final bool isLastStep;
  final bool isSubmitting;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const OnboardingNavigationButtons({
    super.key,
    required this.isFirstStep,
    required this.isLastStep,
    this.isSubmitting = false,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final backLabel = l10n?.back ?? 'Back';
    final nextLabel = isLastStep
        ? (l10n?.submitApplication ?? 'Submit Application')
        : (l10n?.continueButton ?? 'Continue');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Previous button (hidden on first step)
          if (!isFirstStep) ...[
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: isSubmitting ? null : onPrevious,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(backLabel),
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
            const SizedBox(width: 12),
          ],

          // Next / Continue / Submit button
          Expanded(
            flex: 3,
            child: ElevatedButton(
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
                            isLastStep ? Icons.check_circle_outline : Icons.arrow_forward,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
