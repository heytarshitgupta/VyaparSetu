import 'package:flutter/material.dart';
import '../../../core/localization/generated/app_localizations.dart';

class OnboardingProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;

  const OnboardingProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final step1Label = l10n?.yourBusinessTitle ?? 'Your Business';
    final step2Label = l10n?.aboutYourBusinessTitle ?? 'About Your Business';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clean 2-Stage Progress Indicator
        Row(
          children: [
            // Stage 1 Indicator
            Expanded(
              child: _buildStageIndicator(
                theme: theme,
                isActive: currentStep == 0,
                isCompleted: currentStep > 0,
                label: step1Label,
                stepNumber: 1,
              ),
            ),
            // Connecting Line
            Container(
              width: 16,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: currentStep > 0
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
            ),
            // Stage 2 Indicator
            Expanded(
              child: _buildStageIndicator(
                theme: theme,
                isActive: currentStep == 1,
                isCompleted: false,
                label: step2Label,
                stepNumber: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Step Title
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),

        // Step Subtitle
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildStageIndicator({
    required ThemeData theme,
    required bool isActive,
    required bool isCompleted,
    required String label,
    required int stepNumber,
  }) {
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive ? primaryColor : theme.dividerColor,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : onSurfaceColor.withValues(alpha: 0.6),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? primaryColor : onSurfaceColor.withValues(alpha: 0.65),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
