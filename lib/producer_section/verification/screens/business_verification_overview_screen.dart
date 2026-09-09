import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../auth/services/producer_auth_service.dart';
import '../../home/models/producer_shell_profile.dart';
import '../models/business_verification_status.dart';
import '../producer_verification_service.dart';

class BusinessVerificationOverviewScreen extends StatefulWidget {
  final ProducerShellProfile? profile;
  final BusinessVerificationStatus? statusOverride;
  final ProducerVerificationService? verificationService;
  final VoidCallback? onProfileUpdated;

  const BusinessVerificationOverviewScreen({
    super.key,
    this.profile,
    this.statusOverride,
    this.verificationService,
    this.onProfileUpdated,
  });

  @override
  State<BusinessVerificationOverviewScreen> createState() =>
      _BusinessVerificationOverviewScreenState();
}

class _BusinessVerificationOverviewScreenState
    extends State<BusinessVerificationOverviewScreen> {
  late ProducerShellProfile? _currentProfile;
  late BusinessVerificationStatus? _statusOverride;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _statusOverride = widget.statusOverride;
  }

  @override
  void didUpdateWidget(covariant BusinessVerificationOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statusOverride != oldWidget.statusOverride) {
      _statusOverride = widget.statusOverride;
    }
    if (widget.profile != oldWidget.profile) {
      _currentProfile = widget.profile;
    }
  }

  Future<void> _refreshProfile() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;
      final profile = await ProducerAuthService.instance.fetchProfile();
      final producerProfile = await ProducerAuthService.instance.fetchProducerProfile();
      final fullName = (profile?['full_name'] as String?)?.trim();
      final metaName = (user.userMetadata?['full_name'] as String?)?.trim();

      final refreshed = ProducerShellProfile(
        fullName: (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (metaName ?? ''),
        email: user.email ?? (profile?['email'] as String?) ?? '',
        phone: (profile?['phone'] as String?)?.trim(),
        businessName: (producerProfile?['business_name'] as String?)?.trim(),
        craftCategory: (producerProfile?['craft_category'] as String?)?.trim(),
        bio: (producerProfile?['bio'] as String?)?.trim(),
        state: (producerProfile?['state'] as String?)?.trim(),
        district: (producerProfile?['district'] as String?)?.trim(),
        city: (producerProfile?['city'] as String?)?.trim(),
        pincode: (producerProfile?['pincode'] as String?)?.trim(),
        address: (producerProfile?['address'] as String?)?.trim(),
        panLast4: (producerProfile?['pan_last4'] as String?)?.trim(),
        panVerificationStatus: (producerProfile?['pan_verification_status'] as String?) ?? 'unverified',
        gstRegistered: (producerProfile?['gst_registered'] as bool?) ?? false,
        gstin: (producerProfile?['gstin'] as String?)?.trim(),
        gstVerificationStatus: (producerProfile?['gst_verification_status'] as String?) ?? 'not_applicable',
        onboardingStep: (producerProfile?['onboarding_step'] as int?) ?? 1,
      );

      if (mounted) {
        setState(() {
          _currentProfile = refreshed;
          _statusOverride = null;
        });
        widget.onProfileUpdated?.call();
      }
    } catch (_) {
      // Non-blocking fallback
    }
  }

  void _onPanVerifiedSuccess(PanVerificationResult result) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.panVerificationSuccess ?? 'PAN verified successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Optimistically update local profile state for instantaneous UX
    final existing = _currentProfile;
    setState(() {
      if (_statusOverride != null) {
        _statusOverride = BusinessVerificationStatus(
          isEmailVerified: _statusOverride!.isEmailVerified,
          email: _statusOverride!.email,
          isPanVerified: true,
          panLast4: result.panLast4 ?? _statusOverride!.panLast4,
          gstRegistered: _statusOverride!.gstRegistered,
          gstin: _statusOverride!.gstin,
          gstVerificationStatus: _statusOverride!.gstVerificationStatus,
        );
      }
      _currentProfile = ProducerShellProfile(
        fullName: existing?.fullName ?? '',
        email: existing?.email.isNotEmpty == true ? existing!.email : (_statusOverride?.email ?? ''),
        phone: existing?.phone,
        businessName: existing?.businessName,
        craftCategory: existing?.craftCategory,
        bio: existing?.bio,
        state: existing?.state,
        district: existing?.district,
        city: existing?.city,
        pincode: existing?.pincode,
        address: existing?.address,
        panLast4: result.panLast4 ?? existing?.panLast4,
        panVerificationStatus: 'verified',
        gstRegistered: existing?.gstRegistered ?? false,
        gstin: existing?.gstin,
        gstVerificationStatus: existing?.gstVerificationStatus ?? 'not_applicable',
        onboardingStep: existing?.onboardingStep ?? 1,
      );
    });

    widget.onProfileUpdated?.call();
    _refreshProfile();
  }

  void _onGstVerifiedSuccess(GstVerificationResult result, String enteredGstin) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.gstVerificationSuccess ?? 'GSTIN verified successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Optimistically update local profile state for instantaneous UX
    final existing = _currentProfile;
    setState(() {
      if (_statusOverride != null) {
        _statusOverride = BusinessVerificationStatus(
          isEmailVerified: _statusOverride!.isEmailVerified,
          email: _statusOverride!.email,
          isPanVerified: _statusOverride!.isPanVerified,
          panLast4: _statusOverride!.panLast4,
          gstRegistered: true,
          gstin: enteredGstin,
          gstVerificationStatus: 'verified',
        );
      }
      _currentProfile = ProducerShellProfile(
        fullName: existing?.fullName ?? '',
        email: existing?.email.isNotEmpty == true ? existing!.email : (_statusOverride?.email ?? ''),
        phone: existing?.phone,
        businessName: existing?.businessName,
        craftCategory: existing?.craftCategory,
        bio: existing?.bio,
        state: existing?.state,
        district: existing?.district,
        city: existing?.city,
        pincode: existing?.pincode,
        address: existing?.address,
        panLast4: existing?.panLast4,
        panVerificationStatus: existing?.panVerificationStatus ?? 'unverified',
        gstRegistered: true,
        gstin: enteredGstin,
        gstVerificationStatus: 'verified',
        onboardingStep: existing?.onboardingStep ?? 1,
      );
    });

    widget.onProfileUpdated?.call();
    _refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Derive status from auth user and profile if no override is passed
    final status = _statusOverride ??
        BusinessVerificationStatus.fromProfile(
          profile: _currentProfile,
          currentUser: AuthService.instance.currentUser,
        );

    final titleText = l10n?.businessVerification ?? 'Business Verification';
    final introText = l10n?.businessVerificationIntro ??
        'Complete your business details to build trust and access eligible VyaparSetu features.';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. INTRO & PROGRESS SUMMARY CARD
                  _buildHeaderCard(context, status: status, introText: introText),
                  const SizedBox(height: 20),

                  // 2. EMAIL COMPONENT
                  _buildEmailCard(context, status: status),
                  const SizedBox(height: 16),

                  // 3. BUSINESS IDENTITY (PAN) COMPONENT
                  _buildBusinessIdentityCard(context, status: status),
                  const SizedBox(height: 16),

                  // 4. GST REGISTRATION COMPONENT (OPTIONAL)
                  _buildGstCard(context, status: status),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header & Progress Summary Card
  // ---------------------------------------------------------------------------
  Widget _buildHeaderCard(
    BuildContext context, {
    required BusinessVerificationStatus status,
    required String introText,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAllComplete = status.isOverallComplete;
    final completedCount = status.completedStepsCount;
    final totalCount = status.totalApplicableSteps;
    final remainingCount = status.remainingStepsCount;

    final String progressSummary;
    if (isAllComplete) {
      progressSummary = l10n?.businessVerificationComplete ?? 'Business verification complete';
    } else {
      progressSummary = l10n?.verificationStepsRemaining(remainingCount) ??
          (remainingCount == 1 ? '1 step remaining' : '$remainingCount steps remaining');
    }

    final String stepsLabel = l10n?.verificationStepsCompleted(completedCount, totalCount) ??
        '$completedCount of $totalCount completed';

    return Container(
      key: const ValueKey('verification_overview_header'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isAllComplete ? Icons.verified : Icons.shield_outlined,
                color: isAllComplete ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progressSummary,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Pill badge showing "X of Y completed"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAllComplete
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        stepsLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isAllComplete
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            introText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Email Component Card
  // ---------------------------------------------------------------------------
  Widget _buildEmailCard(
    BuildContext context, {
    required BusinessVerificationStatus status,
  }) {
    final l10n = AppLocalizations.of(context);
    final isVerified = status.isEmailVerified;
    final emailDisplay = status.email ?? '';

    return _buildComponentCard(
      context,
      cardKey: const ValueKey('verification_card_email'),
      icon: Icons.mail_outline,
      title: l10n?.emailVerificationLabel ?? 'Email',
      subtitle: emailDisplay.isNotEmpty ? emailDisplay : null,
      badgeText: isVerified
          ? (l10n?.emailVerifiedBadge ?? 'Verified')
          : (l10n?.emailNotVerifiedBadge ?? 'Not verified'),
      badgeIcon: isVerified ? Icons.check_circle : Icons.info_outline,
      isVerified: isVerified,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Business Identity (PAN) Component Card
  // ---------------------------------------------------------------------------
  Widget _buildBusinessIdentityCard(
    BuildContext context, {
    required BusinessVerificationStatus status,
  }) {
    final l10n = AppLocalizations.of(context);
    final isVerified = status.isPanVerified;
    final maskedPan = status.maskedPan;

    final String subtitle = isVerified && maskedPan != null
        ? '${l10n?.panVerifiedBadge ?? 'Details Added'} • $maskedPan'
        : (l10n?.businessIdentityDesc ?? 'Record your PAN to confirm your business identity.');

    return _buildComponentCard(
      context,
      cardKey: const ValueKey('verification_card_pan'),
      icon: Icons.badge_outlined,
      title: l10n?.businessIdentityLabel ?? 'Business Identity',
      subtitle: subtitle,
      badgeText: isVerified
          ? (l10n?.panVerifiedBadge ?? 'Details Added')
          : (l10n?.panNotVerifiedBadge ?? 'Not provided'),
      badgeIcon: isVerified ? Icons.check_circle : Icons.pending_outlined,
      isVerified: isVerified,
      actionButton: !isVerified
          ? OutlinedButton.icon(
              key: const ValueKey('verify_pan_button'),
              onPressed: () => _openPanVerificationModal(context),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(l10n?.verifyPanAction ?? 'Add PAN'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. GST Registration Component Card (Optional)
  // ---------------------------------------------------------------------------
  Widget _buildGstCard(
    BuildContext context, {
    required BusinessVerificationStatus status,
  }) {
    final l10n = AppLocalizations.of(context);

    final String badgeText;
    final IconData badgeIcon;
    final bool isVerified;
    final GstComponentStatus gstStatus = status.gstStatus;

    switch (gstStatus) {
      case GstComponentStatus.verified:
        badgeText = l10n?.gstVerifiedBadge ?? 'Details Added';
        badgeIcon = Icons.check_circle;
        isVerified = true;
        break;
      case GstComponentStatus.pending:
        badgeText = l10n?.gstVerificationPending ?? 'Checking format';
        badgeIcon = Icons.schedule_outlined;
        isVerified = false;
        break;
      case GstComponentStatus.rejected:
        badgeText = l10n?.gstNotVerifiedBadge ?? 'Not provided';
        badgeIcon = Icons.cancel_outlined;
        isVerified = false;
        break;
      case GstComponentStatus.notProvided:
        badgeText = l10n?.gstOptionalNotProvided ?? 'Optional • Not provided';
        badgeIcon = Icons.info_outline;
        isVerified = false;
        break;
    }

    final String subtitle;
    if (isVerified && status.gstin != null && status.gstin!.isNotEmpty) {
      subtitle = '${l10n?.gstRegistrationDesc ?? 'Record your GST registration to access eligible wider-market features on VyaparSetu.'} • ${status.gstin}';
    } else if (!status.gstRegistered || gstStatus == GstComponentStatus.notProvided) {
      subtitle = l10n?.gstOptionalDesc ??
          'GST details are optional here. You can add them later if applicable to your business.';
    } else {
      subtitle = l10n?.gstRegistrationDesc ??
          'Record your GST registration to access eligible wider-market features on VyaparSetu.';
    }

    return _buildComponentCard(
      context,
      cardKey: const ValueKey('verification_card_gst'),
      icon: Icons.receipt_long_outlined,
      title: l10n?.gstRegistrationLabel ?? 'GST Registration',
      subtitle: subtitle,
      badgeText: badgeText,
      badgeIcon: badgeIcon,
      isVerified: isVerified,
      isOptional: !status.gstRegistered,
      actionButton: !isVerified
          ? OutlinedButton.icon(
              key: const ValueKey('verify_gst_button'),
              onPressed: () => _openGstVerificationModal(context),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(l10n?.addOrVerifyGstAction ?? 'Add GSTIN'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: Component Card Container
  // ---------------------------------------------------------------------------
  Widget _buildComponentCard(
    BuildContext context, {
    required Key cardKey,
    required IconData icon,
    required String title,
    String? subtitle,
    required String badgeText,
    required IconData badgeIcon,
    required bool isVerified,
    bool isOptional = false,
    Widget? actionButton,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isVerified
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isVerified
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Status Badge + Optional Action Button
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Status Badge with Icon + Text (never color alone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isVerified
                      ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      badgeIcon,
                      size: 16,
                      color: isVerified
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        badgeText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isVerified
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ?actionButton,
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Real PAN Verification Flow via Secure Backen  // ---------------------------------------------------------------------------
  // Real PAN Verification Flow via Secure Backend RPC
  // ---------------------------------------------------------------------------
  void _openPanVerificationModal(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final verifier = widget.verificationService ?? ProducerVerificationService.instance;

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _PanVerificationSheetContent(
          verifier: verifier,
          onSuccess: (result) {
            _onPanVerifiedSuccess(result);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Real GST Verification Flow via Secure Backend RPC
  // ---------------------------------------------------------------------------
  void _openGstVerificationModal(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final verifier = widget.verificationService ?? ProducerVerificationService.instance;

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _GstVerificationSheetContent(
          verifier: verifier,
          onSuccess: (result, rawGstin) {
            _onGstVerifiedSuccess(result, rawGstin);
          },
        );
      },
    );
  }
}

class _PanVerificationSheetContent extends StatefulWidget {
  final ProducerVerificationService verifier;
  final ValueChanged<PanVerificationResult> onSuccess;

  const _PanVerificationSheetContent({
    required this.verifier,
    required this.onSuccess,
  });

  @override
  State<_PanVerificationSheetContent> createState() => _PanVerificationSheetContentState();
}

class _PanVerificationSheetContentState extends State<_PanVerificationSheetContent> {
  late final TextEditingController _panController;
  String? _localError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _panController = TextEditingController();
  }

  @override
  void dispose() {
    _panController.clear();
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      key: const ValueKey('pan_verification_sheet'),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.panVerificationSheetTitle ?? 'Verify Business Identity (PAN)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n?.panVerificationSheetDesc ??
                  'Enter your 10-character PAN to verify your business identity on VyaparSetu.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('pan_input_field'),
              controller: _panController,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enabled: !_isSubmitting,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: l10n?.panInputLabel ?? 'PAN Number',
                hintText: l10n?.panInputHint ?? 'e.g. ABCDE1234F',
                errorText: _localError,
                prefixIcon: const Icon(Icons.badge_outlined),
                counterText: '',
              ),
              onChanged: (_) {
                if (_localError != null) {
                  setState(() => _localError = null);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const ValueKey('submit_pan_verification_button'),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final rawPan = _panController.text.trim().toUpperCase();
                      final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                      if (!panRegex.hasMatch(rawPan)) {
                        setState(() {
                          _localError = l10n?.panInvalidFormatError ??
                              'Please enter a valid 10-character PAN (e.g. ABCDE1234F).';
                        });
                        return;
                      }

                      setState(() {
                        _isSubmitting = true;
                        _localError = null;
                      });

                      final result = await widget.verifier.verifyPan(
                        pan: rawPan,
                      );

                      if (!context.mounted) return;

                      if (result.success &&
                          (result.status == 'verified' ||
                           result.status == 'already_verified' ||
                           result.status == 'details_recorded' ||
                           result.status == 'already_recorded')) {
                        _panController.clear();
                        Navigator.of(context).pop(true);
                        widget.onSuccess(result);
                      } else {
                        setState(() {
                          _isSubmitting = false;
                          if (result.status == 'already_verified_conflict' ||
                              result.status.contains('conflict') ||
                              result.status.contains('duplicate')) {
                            _localError = l10n?.panAlreadyLinkedError ??
                                'A PAN is already associated with this account.';
                          } else if (result.status == 'invalid_format') {
                            _localError = l10n?.panInvalidFormatError ??
                                'Please enter a valid 10-character PAN (e.g. ABCDE1234F).';
                          } else {
                            _localError = l10n?.panVerificationFailedError ??
                                'PAN details could not be recorded. Please check your details.';
                          }
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n?.verifyAction ?? 'Submit'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _GstVerificationSheetContent extends StatefulWidget {
  final ProducerVerificationService verifier;
  final void Function(GstVerificationResult result, String rawGstin) onSuccess;

  const _GstVerificationSheetContent({
    required this.verifier,
    required this.onSuccess,
  });

  @override
  State<_GstVerificationSheetContent> createState() => _GstVerificationSheetContentState();
}

class _GstVerificationSheetContentState extends State<_GstVerificationSheetContent> {
  late final TextEditingController _gstController;
  String? _localError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _gstController = TextEditingController();
  }

  @override
  void dispose() {
    _gstController.clear();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      key: const ValueKey('gstin_verification_sheet'),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.gstVerificationSheetTitle ?? 'Verify GST Registration',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n?.gstVerificationSheetDesc ??
                  'Enter your 15-character GSTIN to verify your GST registration on VyaparSetu.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('gstin_input_field'),
              controller: _gstController,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enabled: !_isSubmitting,
              maxLength: 15,
              decoration: InputDecoration(
                labelText: l10n?.gstInputLabel ?? 'GSTIN',
                hintText: l10n?.gstInputHint ?? 'e.g. 07AAAAA0000A1Z5',
                errorText: _localError,
                prefixIcon: const Icon(Icons.receipt_long_outlined),
                counterText: '',
              ),
              onChanged: (_) {
                if (_localError != null) {
                  setState(() => _localError = null);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const ValueKey('submit_gst_verification_button'),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final rawGstin = _gstController.text.trim().toUpperCase();
                      // 1. Format validation: 15 alphanumeric characters
                      final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                      if (!gstRegex.hasMatch(rawGstin)) {
                        setState(() {
                          _localError = l10n?.gstInvalidFormatError ??
                              'Please enter a valid 15-character GSTIN (e.g. 07AAAAA0000A1Z5).';
                        });
                        return;
                      }

                      // 2. Validate Indian state/UT code (first 2 digits: 01-38, 97, 99)
                      final stateNum = int.tryParse(rawGstin.substring(0, 2)) ?? 0;
                      if ((stateNum < 1 || stateNum > 38) && stateNum != 97 && stateNum != 99) {
                        setState(() {
                          _localError = l10n?.gstInvalidStateCodeError ??
                              'Invalid state code in GSTIN. First 2 digits must be between 01-38, 97, or 99.';
                        });
                        return;
                      }

                      setState(() {
                        _isSubmitting = true;
                        _localError = null;
                      });

                      final result = await widget.verifier.verifyGst(
                        gstin: rawGstin,
                      );

                      if (!context.mounted) return;

                      if (result.success &&
                          (result.status == 'verified' || result.status == 'already_verified')) {
                        _gstController.clear();
                        Navigator.of(context).pop(true);
                        widget.onSuccess(result, rawGstin);
                      } else {
                        setState(() {
                          _isSubmitting = false;
                          if (result.status == 'already_verified_conflict' ||
                              result.status.contains('conflict') ||
                              result.status.contains('duplicate')) {
                            _localError = l10n?.gstAlreadyLinkedError ??
                                'A GSTIN is already associated with this account.';
                          } else if (result.status == 'invalid_format' || result.status == 'invalid_state_code') {
                            _localError = l10n?.gstInvalidFormatError ??
                                'Please enter a valid 15-character GSTIN (e.g. 07AAAAA0000A1Z5).';
                          } else {
                            _localError = l10n?.gstVerificationFailedError ??
                                'GSTIN details could not be recorded. Please check your 15-digit GSTIN.';
                          }
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n?.verifyAction ?? 'Submit'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
