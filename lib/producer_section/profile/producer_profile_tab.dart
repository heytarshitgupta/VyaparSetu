// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/localization/language_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/theme_provider.dart';
import '../home/models/producer_shell_profile.dart';
import '../widgets/producer_quick_action_menu.dart';

import '../verification/screens/business_verification_overview_screen.dart';

class ProducerProfileTab extends StatefulWidget {
  final ProducerShellProfile? profile;
  final Future<void> Function()? onSignOut;
  final Future<void> Function(String email)? onResetPassword;
  final VoidCallback? onNavigateToVerification;

  const ProducerProfileTab({
    super.key,
    this.profile,
    this.onSignOut,
    this.onResetPassword,
    this.onNavigateToVerification,
  });

  @override
  State<ProducerProfileTab> createState() => _ProducerProfileTabState();
}

class _ProducerProfileTabState extends State<ProducerProfileTab> {
  bool _isResettingPassword = false;

  Future<void> _handleResetPassword(BuildContext context, String email) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    if (email.trim().isEmpty) return;

    setState(() {
      _isResettingPassword = true;
    });

    try {
      if (widget.onResetPassword != null) {
        await widget.onResetPassword!(email);
      } else {
        await SupabaseService.client.auth.resetPasswordForEmail(email.trim());
      }
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.resetPasswordSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.couldNotUpdateProduct),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profile = widget.profile;

    final fullName = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName.trim()
        : l10n.producerDefaultName;
    final email = profile?.email.trim() ?? '';
    final businessName = profile?.businessName?.trim();
    final craftCategory = profile?.craftCategory?.trim();
    final location = profile?.locationSummary;
    final isVerified = profile?.isIdentityVerified ?? false;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ------------------------------------------------------------
                // A. PROFILE HEADER
                // ------------------------------------------------------------
                _buildProfileHeader(
                  context,
                  l10n: l10n,
                  theme: theme,
                  colorScheme: colorScheme,
                  profile: profile,
                  fullName: fullName,
                  businessName: businessName,
                  location: location,
                  isVerified: isVerified,
                ),
                const SizedBox(height: 24),

                // ------------------------------------------------------------
                // B. BUSINESS & PRODUCER INFORMATION
                // ------------------------------------------------------------
                _buildBusinessInfoSection(
                  context,
                  l10n: l10n,
                  theme: theme,
                  colorScheme: colorScheme,
                  profile: profile,
                  fullName: fullName,
                  businessName: businessName,
                  craftCategory: craftCategory,
                  email: email,
                ),
                const SizedBox(height: 20),

                // ------------------------------------------------------------
                // C. VERIFICATION & COMPLIANCE
                // ------------------------------------------------------------
                _buildVerificationSection(
                  context,
                  l10n: l10n,
                  theme: theme,
                  colorScheme: colorScheme,
                  profile: profile,
                  isVerified: isVerified,
                ),
                const SizedBox(height: 20),

                // ------------------------------------------------------------
                // D. SETTINGS (App Language, Voice Language, Appearance)
                // ------------------------------------------------------------
                _buildSettingsSection(
                  context,
                  l10n: l10n,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),

                // ------------------------------------------------------------
                // E. ACCOUNT & SECURITY
                // ------------------------------------------------------------
                _buildAccountSecuritySection(
                  context,
                  l10n: l10n,
                  theme: theme,
                  colorScheme: colorScheme,
                  email: email,
                ),
                const SizedBox(height: 20),

                // ------------------------------------------------------------
                // F. HELP & ABOUT
                // ------------------------------------------------------------
                _buildHelpAboutSection(
                  context,
                  l10n: l10n,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 28),

                // ------------------------------------------------------------
                // G. SIGN OUT
                // ------------------------------------------------------------
                Center(
                  child: OutlinedButton.icon(
                    key: const ValueKey('sign_out_button'),
                    onPressed: () => ProducerQuickActionMenu.showSignOutConfirmation(
                      context,
                      onSignOut: widget.onSignOut,
                    ),
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.signOutAction),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error.withValues(alpha: 0.6)),
                      minimumSize: const Size(220, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // A. Header Card
  // ---------------------------------------------------------------------------
  Widget _buildProfileHeader(
    BuildContext context, {
    required AppLocalizations l10n,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required ProducerShellProfile? profile,
    required String fullName,
    required String? businessName,
    required String? location,
    required bool isVerified,
  }) {
    final initials = profile?.initials ?? 'P';
    final craftCategory = profile?.craftCategory?.trim();
    final headerSubtitle = (craftCategory != null && craftCategory.isNotEmpty)
        ? craftCategory
        : businessName;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Initials Avatar
            CircleAvatar(
              radius: 42,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                initials,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Producer Name
            Text(
              fullName,
              key: const ValueKey('profile_name_text'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // Craft / Business Subtitle in Header
            if (headerSubtitle != null && headerSubtitle.isNotEmpty && headerSubtitle != fullName) ...[
              const SizedBox(height: 4),
              Text(
                headerSubtitle,
                key: const ValueKey('profile_business_text'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Location Summary
            if (location != null && location.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      location,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Verification Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isVerified
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isVerified
                      ? colorScheme.primary.withValues(alpha: 0.4)
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVerified ? Icons.verified : Icons.shield_outlined,
                    size: 16,
                    color: isVerified
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isVerified ? l10n.verifiedProducer : l10n.unverifiedProducer,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isVerified
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // B. Business & Producer Details Card
  // ---------------------------------------------------------------------------
  Widget _buildBusinessInfoSection(
    BuildContext context, {
    required AppLocalizations l10n,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required ProducerShellProfile? profile,
    required String fullName,
    required String? businessName,
    required String? craftCategory,
    required String email,
  }) {
    final phone = profile?.phone?.trim();
    final addressParts = <String>[
      if (profile?.address != null && profile!.address!.trim().isNotEmpty) profile.address!.trim(),
      if (profile?.city != null && profile!.city!.trim().isNotEmpty) profile.city!.trim(),
      if (profile?.district != null && profile!.district!.trim().isNotEmpty) profile.district!.trim(),
      if (profile?.state != null && profile!.state!.trim().isNotEmpty) profile.state!.trim(),
      if (profile?.pincode != null && profile!.pincode!.trim().isNotEmpty) profile.pincode!.trim(),
    ];
    final fullAddress = addressParts.isNotEmpty ? addressParts.join(', ') : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_outlined, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.businessProducerInfo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              context,
              label: l10n.businessName,
              value: (businessName != null && businessName.isNotEmpty)
                  ? businessName
                  : l10n.notProvided,
            ),
            _buildDetailRow(
              context,
              label: l10n.craftCategory,
              value: (craftCategory != null && craftCategory.isNotEmpty)
                  ? craftCategory
                  : l10n.notProvided,
            ),
            _buildDetailRow(
              context,
              label: l10n.phoneLabel,
              value: (phone != null && phone.isNotEmpty) ? phone : l10n.notProvided,
            ),
            _buildDetailRow(
              context,
              label: l10n.workshopLocationLabel,
              value: fullAddress ?? l10n.notProvided,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // C. Verification & Compliance Card
  // ---------------------------------------------------------------------------
  Widget _buildVerificationSection(
    BuildContext context, {
    required AppLocalizations l10n,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required ProducerShellProfile? profile,
    required bool isVerified,
  }) {
    final panMasked = profile?.maskedPan;
    final isPanVerified = profile?.isPanVerified ?? false;
    final gstRegistered = profile?.gstRegistered ?? false;

    return Card(
      key: const ValueKey('verification_section'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.verificationAndCompliance,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Permanent Business Verification Entry Point
            InkWell(
              key: const ValueKey('business_verification_entry'),
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (widget.onNavigateToVerification != null) {
                  widget.onNavigateToVerification!();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BusinessVerificationOverviewScreen(
                        profile: profile,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.businessVerification,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.businessVerificationSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Identity Verification Row
            _buildStatusItem(
              context,
              icon: isVerified ? Icons.check_circle : Icons.pending_outlined,
              iconColor: isVerified ? colorScheme.primary : colorScheme.onSurfaceVariant,
              title: l10n.identityVerification,
              subtitle: isVerified ? l10n.identityVerified : l10n.identityNotVerified,
              isComplete: isVerified,
            ),
            const Divider(height: 20),

            // PAN Identity Row (Strictly Masked: •••• 1234)
            _buildStatusItem(
              context,
              icon: isPanVerified ? Icons.check_circle : Icons.credit_card_outlined,
              iconColor: isPanVerified ? colorScheme.primary : colorScheme.onSurfaceVariant,
              title: l10n.panIdentityLabel,
              subtitle: isPanVerified
                  ? (panMasked != null ? '${l10n.panVerified} • $panMasked' : l10n.panVerified)
                  : l10n.panNotVerified,
              isComplete: isPanVerified,
              statusKey: 'pan_verification_status',
            ),
            const Divider(height: 20),

            // GST Compliance Row (Truthful: Registered / Not Registered)
            _buildStatusItem(
              context,
              icon: gstRegistered ? Icons.check_circle : Icons.receipt_long_outlined,
              iconColor: gstRegistered ? colorScheme.primary : colorScheme.onSurfaceVariant,
              title: l10n.gstComplianceLabel,
              subtitle: gstRegistered
                  ? l10n.gstRegisteredBadge
                  : l10n.gstNotRegisteredBadge,
              isComplete: gstRegistered,
              statusKey: 'gst_verification_status',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // D. Settings Card
  // ---------------------------------------------------------------------------
  Widget _buildSettingsSection(
    BuildContext context, {
    required AppLocalizations l10n,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    LanguageProvider? langProvider;
    try {
      langProvider = Provider.of<LanguageProvider>(context);
    } catch (_) {}

    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context);
    } catch (_) {}

    final appLang = langProvider?.appLanguage ?? AppLanguage.english;
    final voiceOption = langProvider?.voiceGuidanceOption ?? VoiceGuidanceOption.sameAsApp;
    final themeOption = themeProvider?.themeOption ?? AppThemeOption.system;

    return Card(
      key: const ValueKey('settings_section'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.settings,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. App Language Section
            Row(
              children: [
                const Icon(Icons.language, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.language,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RadioListTile<AppLanguage>(
              key: const ValueKey('lang_radio_en'),
              contentPadding: EdgeInsets.zero,
              title: const Text('English'),
              value: AppLanguage.english,
              groupValue: appLang,
              onChanged: (val) {
                if (val != null) langProvider?.setAppLanguage(val);
              },
            ),
            RadioListTile<AppLanguage>(
              key: const ValueKey('lang_radio_hi'),
              contentPadding: EdgeInsets.zero,
              title: const Text('हिन्दी (Hindi)'),
              value: AppLanguage.hindi,
              groupValue: appLang,
              onChanged: (val) {
                if (val != null) langProvider?.setAppLanguage(val);
              },
            ),
            RadioListTile<AppLanguage>(
              key: const ValueKey('lang_radio_pa'),
              contentPadding: EdgeInsets.zero,
              title: const Text('ਪੰਜਾਬੀ (Punjabi)'),
              value: AppLanguage.punjabi,
              groupValue: appLang,
              onChanged: (val) {
                if (val != null) langProvider?.setAppLanguage(val);
              },
            ),
            const Divider(height: 24),

            // 2. Voice Guidance Language Section
            Row(
              children: [
                const Icon(Icons.record_voice_over_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.voiceGuidanceLanguage,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RadioListTile<VoiceGuidanceOption>(
              key: const ValueKey('voice_radio_same'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.voiceGuidanceSameAsApp),
              value: VoiceGuidanceOption.sameAsApp,
              groupValue: voiceOption,
              onChanged: (val) {
                if (val != null) langProvider?.setVoiceGuidanceOption(val);
              },
            ),
            RadioListTile<VoiceGuidanceOption>(
              key: const ValueKey('voice_radio_en'),
              contentPadding: EdgeInsets.zero,
              title: const Text('English'),
              value: VoiceGuidanceOption.english,
              groupValue: voiceOption,
              onChanged: (val) {
                if (val != null) langProvider?.setVoiceGuidanceOption(val);
              },
            ),
            RadioListTile<VoiceGuidanceOption>(
              key: const ValueKey('voice_radio_hi'),
              contentPadding: EdgeInsets.zero,
              title: const Text('हिन्दी (Hindi)'),
              value: VoiceGuidanceOption.hindi,
              groupValue: voiceOption,
              onChanged: (val) {
                if (val != null) langProvider?.setVoiceGuidanceOption(val);
              },
            ),
            RadioListTile<VoiceGuidanceOption>(
              key: const ValueKey('voice_radio_pa'),
              contentPadding: EdgeInsets.zero,
              title: const Text('ਪੰਜਾਬੀ (Punjabi)'),
              value: VoiceGuidanceOption.punjabi,
              groupValue: voiceOption,
              onChanged: (val) {
                if (val != null) langProvider?.setVoiceGuidanceOption(val);
              },
            ),
            const Divider(height: 24),

            // 3. Appearance Section
            Row(
              children: [
                const Icon(Icons.palette_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.appearance,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RadioListTile<AppThemeOption>(
              key: const ValueKey('theme_radio_system'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.themeSystem),
              secondary: const Icon(Icons.brightness_auto),
              value: AppThemeOption.system,
              groupValue: themeOption,
              onChanged: (val) {
                if (val != null) themeProvider?.setThemeOption(val);
              },
            ),
            RadioListTile<AppThemeOption>(
              key: const ValueKey('theme_radio_light'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.themeLight),
              secondary: const Icon(Icons.light_mode),
              value: AppThemeOption.light,
              groupValue: themeOption,
              onChanged: (val) {
                if (val != null) themeProvider?.setThemeOption(val);
              },
            ),
            RadioListTile<AppThemeOption>(
              key: const ValueKey('theme_radio_dark'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.themeDark),
              secondary: const Icon(Icons.dark_mode),
              value: AppThemeOption.dark,
              groupValue: themeOption,
              onChanged: (val) {
                if (val != null) themeProvider?.setThemeOption(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // E. Account & Security Card
  // ---------------------------------------------------------------------------
  Widget _buildAccountSecuritySection(
    BuildContext context, {
    required AppLocalizations l10n,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String email,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.accountAndSecurity,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email Display
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: Text(l10n.email),
              subtitle: Text(
                email.isNotEmpty ? email : l10n.notProvided,
                key: const ValueKey('profile_email_text'),
              ),
            ),
            const Divider(height: 16),

            // Reset Password Flow
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.key_outlined),
              title: Text(l10n.resetPassword),
              subtitle: Text(l10n.resetPasswordDesc),
              trailing: _isResettingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : FilledButton.tonal(
                      key: const ValueKey('reset_password_button'),
                      onPressed: email.isNotEmpty && !_isResettingPassword
                          ? () => _handleResetPassword(context, email)
                          : null,
                      child: Text(l10n.resetPassword),
                    ),
            ),
            const Divider(height: 16),

            // Current Session (Truthful)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.login_outlined),
              title: Text(l10n.activeSession),
              subtitle: Text(l10n.activeSessionTruthful),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.statusActive,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // F. Help & About Card
  // ---------------------------------------------------------------------------
  Widget _buildHelpAboutSection(
    BuildContext context, {
    required AppLocalizations l10n,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.helpAndAbout,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListTile(
              key: const ValueKey('how_works_tile'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.explore_outlined),
              title: Text(l10n.howVyaparSetuWorks),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showInfoModal(
                context,
                title: l10n.howVyaparSetuWorks,
                body: l10n.howVyaparSetuWorksContent,
                icon: Icons.explore_outlined,
              ),
            ),
            const Divider(height: 12),

            ListTile(
              key: const ValueKey('privacy_data_tile'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.security_outlined),
              title: Text(l10n.privacyAndData),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showInfoModal(
                context,
                title: l10n.privacyAndData,
                body: l10n.privacyAndDataContent,
                icon: Icons.security_outlined,
              ),
            ),
            const Divider(height: 12),

            ListTile(
              key: const ValueKey('about_app_tile'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.aboutVyaparSetu),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showInfoModal(
                context,
                title: l10n.aboutVyaparSetu,
                body: l10n.aboutVyaparSetuContent,
                icon: Icons.info_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoModal(
    BuildContext context, {
    required String title,
    required String body,
    required IconData icon,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Widgets
  // ---------------------------------------------------------------------------
  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    String? valueKey,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 420;

    if (isCompact) {
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              key: valueKey != null ? ValueKey(valueKey) : null,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              key: valueKey != null ? ValueKey(valueKey) : null,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isComplete,
    String? statusKey,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                key: statusKey != null ? ValueKey(statusKey) : null,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isComplete ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight: isComplete ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
