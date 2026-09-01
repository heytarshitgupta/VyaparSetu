import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
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
                backgroundColor: AppColors.primary,
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
                            isLastStep ? 'Submit Application' : 'Continue',
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
