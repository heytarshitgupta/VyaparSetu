import 'package:flutter/material.dart';
import '../../../core/localization/generated/app_localizations.dart';

class BusinessVerificationBanner extends StatelessWidget {
  final VoidCallback onVerify;
  final VoidCallback onDismiss;

  const BusinessVerificationBanner({
    super.key,
    required this.onVerify,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final titleText = l10n?.reachMoreBuyers ?? 'Reach more buyers across India';
    final bodyText = l10n?.verifyBusinessPrompt ??
        'Verify your business to build trust and unlock eligible wider-market features.';
    final buttonText = l10n?.verifyMyBusiness ?? 'Verify My Business';

    return Container(
      key: const ValueKey('business_verification_banner'),
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trust badge icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and Body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bodyText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Session-only dismiss 'X'
                IconButton(
                  key: const ValueKey('verification_banner_close'),
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  color: colorScheme.onSurfaceVariant,
                  tooltip: 'Dismiss',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: onDismiss,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Primary action button
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const ValueKey('verify_my_business_button'),
                onPressed: onVerify,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
