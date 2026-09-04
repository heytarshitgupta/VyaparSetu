import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_router.dart';
import '../home/models/producer_shell_profile.dart';

class ProducerProfileTab extends StatelessWidget {
  final ProducerShellProfile? profile;
  final Future<void> Function()? onSignOut;

  const ProducerProfileTab({
    super.key,
    this.profile,
    this.onSignOut,
  });

  Future<void> _defaultSignOut(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.producerLoginRoute,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fullName = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName.trim()
        : l10n.producerDefaultName;
    final email = profile?.email.trim() ?? '';
    final businessName = profile?.businessName?.trim();

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.person_outline,
                    size: 44,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (businessName != null && businessName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    businessName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.featureComingSoon,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => onSignOut != null ? onSignOut!() : _defaultSignOut(context),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOutAction),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                    minimumSize: const Size(200, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
